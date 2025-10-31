import 'package:flutter/material.dart';

class FileTile extends StatelessWidget {
  final String fileName;

  const FileTile({required this.fileName, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(15),
      margin: EdgeInsets.only(left: 15, bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white24,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.file_present_outlined, size: 30),
          SizedBox(height: 8),
          Text(fileName),
        ],
      ),
    );
  }
}
