import 'package:flutter/material.dart';

class ModelTile extends StatelessWidget {
  final String name;
  final String size;
  final String parameters;
  final bool isLoaded;
  final VoidCallback onLoadUnlaod;
  final VoidCallback onSettings;
  final VoidCallback onDelete;

  const ModelTile({
    required this.name,
    required this.size,
    required this.parameters,
    required this.isLoaded,
    required this.onLoadUnlaod,
    required this.onSettings,
    required this.onDelete,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(Icons.memory, color: Colors.blueAccent, size: 28),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name),
                  Text(
                    "Size: $size • Params: $parameters",
                    style: TextStyle(color: Colors.white60),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onLoadUnlaod,
              icon: Icon(
                isLoaded
                    ? Icons.stop_circle_outlined
                    : Icons.play_arrow, // ✅ clearer
                color: isLoaded ? Colors.redAccent : Colors.greenAccent,
              ),
            ),

            IconButton(onPressed: onSettings, icon: Icon(Icons.tune)),
            IconButton(onPressed: onDelete, icon: Icon(Icons.delete)),
          ],
        ),
      ),
    );
  }
}
