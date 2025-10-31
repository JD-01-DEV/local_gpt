import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:localgpt/databases/ai_model_db.dart';
import 'package:localgpt/schemas/ai_model_model.dart';
import 'package:localgpt/widgets/model_tile.dart';
import 'package:localgpt/services/api_service.dart';
import 'package:localgpt/widgets/parameter_dialog.dart';
import 'package:provider/provider.dart';

class ModelManagerScreen extends StatefulWidget {
  const ModelManagerScreen({super.key}); // constructor

  // creating MpdelManagerScreen's state with type of ModelManagerScreen Class
  @override
  State<ModelManagerScreen> createState() => _ModelManagerScreenState();
}

// extending State<ModelManagerScreen> to use fetures of StatefulWidget
class _ModelManagerScreenState extends State<ModelManagerScreen>
    with WidgetsBindingObserver {
  final List<String> _modelsInApp = [];
  bool _isPickingFile = false;

  // it runs when the state / ModelManagerScreen is initialized
  @override
  void initState() {
    super.initState();
    context
        .read<AiModelDb>()
        .fetchAiModels(); // fetches / refreshes the AiModel list so that it can show existing ones at start
  }

  String extractParams(String fileName) {
    final match = RegExp(r'(\d+)(b|B).*?Q(\d+)').firstMatch(fileName);
    if (match != null) {
      return "${match.group(1)}B Q${match.group(3)}";
    }
    return "Unknown";
  }

  // handling adding model from local file / storage to database
  Future<void> _addModel() async {
    if (_isPickingFile) return;
    setState(() => _isPickingFile = true);
    debugPrint("Is Picking File? =  $_isPickingFile");
    // getting model from storage as result
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom, // allows to pick / choose custom file format
      allowedExtensions: ['gguf'], //only GGUF models are allowed
    );

    if (result == null || result.files.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("No model added")));
      setState(() => _isPickingFile = false);
      debugPrint("Is Picking File? =  $_isPickingFile");
      return;
    }

    // if model file selected and the file is not empty then

    final file = result.files.single; // setting file informations
    final filePath = file.path; // getting file path
    final fileName = file.name; // file name
    final fileSize =
        "${(file.size / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB"; // and size of file in GB

    final indexOfDot = fileName.lastIndexOf(
      ".",
    ); // modifying file name to exlude extention ( GGUF )

    final filteredFileName =
        indexOfDot !=
            -1 // if find index of a ' . ' symbol that represents extention afterwards at last then
        ? fileName.substring(0, indexOfDot) // filted name
        : fileName; // and if couldn't then full / original file name
    final modelParameters = extractParams(fileName);

    // creating new AiModel with available info.
    final aiModel = AiModel()
      ..name = filteredFileName
      ..size = fileSize
      ..dateAdded = DateTime.now()
      ..filePath = filePath!
      ..parameters = modelParameters
      ..isLoaded = false;

    for (var model in _modelsInApp) {
      if (aiModel.name == model) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("${aiModel.name} already exist")),
        );
        setState(() => _isPickingFile = false);
        debugPrint("Is Picking File? =  $_isPickingFile");
        return;
      }
    }

    _modelsInApp.add(aiModel.name);
    _isPickingFile = false;

    await context.read<AiModelDb>().addModelToDb(
      aiModel,
    ); // awaiting for AiModelDb to add Model to DB

    // showing a message using snackbar
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("${aiModel.name} added")));
  }

  Future<void> _handleModelLoading(String path, int modelId) async {
    final db = context.read<AiModelDb>();
    bool anyModelLoaded = db.aiModels.any((m) => m.isLoaded);

    if (anyModelLoaded) {
      final modelId = await db.getActiveModelId();
      await _unloadModel(modelId);
    }

    await _loadModel(path, modelId);
  }

  // handles loading model with the help of ApiService
  Future<void> _loadModel(String path, int modelId) async {
    final db = context.read<AiModelDb>();

    final loaded = await ApiService.loadModel(
      path,
    ); // loading model using path through ApiSevice

    // if model is loaded then
    if (loaded) {
      await db.setActiveModel(modelId); // ensures only this model is active
    }

    final String modelName = await db.getModleNameById(modelId);
    // showing message that model loaded of not
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          loaded ? "$modelName Loaded" : "Failed to load $modelName",
        ),
      ),
    );
  }

  // hadnling unloading of AI model
  Future<void> _unloadModel(int modelId) async {
    final db = context.read<AiModelDb>();

    final unLoaded = await ApiService.unloadModel();
    if (unLoaded) {
      await db.unloadModel(modelId);
    }

    final String modelName = await db.getModleNameById(modelId);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          unLoaded
              ? "$modelName Unloaded successfully"
              : "Failed to unload $modelName",
        ),
      ),
    );
  }

  // func to delete model from DB
  void _deleteModel(int modelId) async {
    final db = context.read<AiModelDb>();
    final String modelName = await db.getModleNameById(modelId);
    // deleting model using model ID
    await db.deleteModel(modelId);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(" $modelName deleted")));
  }

  // func to handle model setting dialog
  void _openModelSettings() {
    showDialog(
      context: context,
      builder: (context) => ParameterDialog(
        temperature: 1,
        topP: 0.5,
        maxTokens: 265,
        onTempChange: (value) {},
        onTopPChange: (value) {},
        onMaxTokensChange: (value) {},
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Models"),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back),
        ),
      ),

      body: Column(
        children: [
          Expanded(
            child: Consumer<AiModelDb>(
              // ✅ ensures rebuild
              builder: (context, db, _) {
                final aiModels = db.aiModels;
                return ListView.builder(
                  itemCount: aiModels.length,
                  itemBuilder: (context, index) {
                    final model = aiModels[index];
                    return ModelTile(
                      name: model.name,
                      size: model.size,
                      parameters: model.parameters,
                      isLoaded: model.isLoaded,
                      onLoadUnlaod: () async {
                        if (model.isLoaded) {
                          await _unloadModel(model.id);
                        } else {
                          // await _loadModel(model.filePath, model.id);
                          _handleModelLoading(model.filePath, model.id);
                        }
                        debugPrint(
                          "Model ${model.name} loaded=${model.isLoaded}",
                        );
                      },
                      onDelete: () => _deleteModel(model.id),
                      onSettings: () => _openModelSettings(),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () => _isPickingFile ? null : _addModel(),
        child: Icon(Icons.add_outlined),
      ),
    );
  }
}
