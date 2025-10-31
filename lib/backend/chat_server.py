# chat_server.py
import os
import gc
import logging
import threading
from typing import Dict, Any

import uvicorn
from fastapi import FastAPI, Request, UploadFile, File, HTTPException
from fastapi.responses import StreamingResponse, JSONResponse
from pydantic import BaseModel
from llama_cpp import Llama

app = FastAPI()
model = None
model_lock = threading.Lock()     # prevent concurrent create_chat_completion calls
stop_event = threading.Event()    # used to signal stopping generation

log = logging.getLogger("localgpt")
logging.basicConfig(level=logging.INFO)


class ChatInput(BaseModel):
    prompt: str
    temperature: float = 0.7
    top_p: float = 0.9
    max_tokens: int = 256
    n_ctx: int | None = None  # optional override


@app.post("/add_model")
async def add_model(file: UploadFile = File(...)):
    """Accept file upload and return basic info - not storing the full model here."""
    temp_path = f"/tmp/{file.filename}"
    with open(temp_path, "wb") as f:
        f.write(await file.read())

    size = os.path.getsize(temp_path)
    model_name = os.path.basename(temp_path)

    # remove temporary copy (caller should provide path later to load_model)
    os.remove(temp_path)

    return {"model_name": model_name, "size": size, "parameters": "Unknown", "status": "success"}


@app.post("/load_model")
async def load_model(request: Request):
    """
    Load a GGUF model. Body: {"model_path": "/path/to/gguf", "n_ctx": 1024}
    This will unload any previously loaded model first.
    """
    global model
    body = await request.json()
    model_path = body.get("model_path")
    n_ctx = body.get("n_ctx", 1024)  # default to 1024 (lower memory than 2048)

    if not model_path or not os.path.exists(model_path):
        raise HTTPException(status_code=400, detail="model_path missing or file not found")

    # unload previous model safely
    if model is not None:
        log.info("Unloading previous model before loading new one...")
        try:
            with model_lock:
                model = None
                gc.collect()
        except Exception:
            log.exception("Error while unloading previous model")
            model = None
            gc.collect()

    try:
        # create new model instance
        # n_ctx controls memory usage; lower values use less RAM.
        log.info("Loading model: %s (n_ctx=%s)", model_path, n_ctx)
        model = Llama(model_path=model_path, n_ctx=int(n_ctx))
        log.info("Model loaded successfully.")
        return {"status": "success", "message": "Model loaded"}
    except Exception as e:
        log.exception("Failed to load model")
        # ensure model variable is clean on failure
        model = None
        gc.collect()
        return JSONResponse({"status": "error", "message": str(e)}, status_code=500)


@app.post("/unload_model")
async def unload_model():
    """Unload model and free memory."""
    global model
    try:
        with model_lock:
            model = None
            gc.collect()
        return {"status": "success", "message": "Model unloaded"}
    except Exception as e:
        log.exception("unload_model error")
        return {"status": "error", "message": str(e)}


@app.post("/stop")
async def stop_stream():
    """Signal the streaming loop to stop early."""
    stop_event.set()
    return {"status": "stopping"}


@app.post("/chat")
async def chat_endpoint(request: Request):
    """
    Streaming chat endpoint.
    Accepts JSON body with keys: prompt, temperature, top_p, max_tokens, optional n_ctx.
    Streams plain text tokens as they are produced.
    """
    global model, stop_event

    data: Dict[str, Any] = await request.json()
    prompt = data.get("prompt")
    if not prompt:
        raise HTTPException(status_code=400, detail="prompt is required")

    if model is None:
        raise HTTPException(status_code=400, detail="No model loaded")

    # clear any previous stop signal
    stop_event.clear()

    messages = [
        {"role": "system", "content": "You are a helpful assistant."},
        {"role": "user", "content": prompt},
    ]

    def token_generator():
        """
        Synchronous generator used by StreamingResponse.
        We use a threading.Lock around the model inference to avoid concurrent access.
        """
        if model is None:
            # immediate finish if no model
            yield ""
            return

        # Ensure only one inference runs at a time:
        with model_lock:
            try:
                stream = model.create_chat_completion(
                    messages=messages,
                    temperature=data.get("temperature", 0.7),
                    top_p=data.get("top_p", 0.9),
                    max_tokens=data.get("max_tokens", 256),
                    stream=True,
                )

                # stream yields dictionaries similar to OpenAI streaming chunks
                for chunk in stream:
                    if stop_event.is_set():
                        # client requested stop; break out
                        log.info("Stop event set, breaking stream.")
                        break

                    # chunk usually contains a 'choices' list with a 'delta' piece
                    if "choices" in chunk:
                        try:
                            delta = chunk["choices"][0].get("delta", {})
                            # If delta contains content, yield it
                            if isinstance(delta, dict) and "content" in delta:
                                text = delta["content"]
                                if text:
                                    # Yield as tiny text chunks so client receives them progressively
                                    yield text
                        except Exception:
                            # be robust against unexpected chunk shapes
                            log.exception("Malformed chunk: %s", chunk)
                            continue

            except Exception as e:
                # Log exceptions (including potential underlying C crashes sometimes)
                log.exception("Exception during model streaming: %s", e)
                # Optionally yield an error token so client sees something
                yield f"\n[Error during generation: {e}]\n"
            finally:
                # Make sure to clear stop flag for next request
                stop_event.clear()

    # Use text/plain so the Flutter client can stream and append text chunks
    return StreamingResponse(token_generator(), media_type="text/plain")


if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000, log_level="info")
