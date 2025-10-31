import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _darkTheme = true; // will be helpful for toggling themes
  String _language = "English"; // default language is English
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Settings"),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back),
        ),
      ),
      body: ListView(
        children: [
          SwitchListTile(
            title: Text("Dark Theme", style: TextStyle(fontSize: 20)),
            value: _darkTheme,
            onChanged: (value) {
              setState(() {
                _darkTheme = value;
              });
            },
          ),
          ListTile(
            title: Text("Language", style: TextStyle(fontSize: 20)),
            subtitle: Text(_language),
            trailing: Icon(Icons.arrow_forward_ios),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text("Select Languange"),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      RadioListTile(
                        title: Text("English"),
                        value: 'English',
                        groupValue: _language,
                        onChanged: (value) => setState(() {
                          _language = value.toString();
                        }),
                      ),
                      RadioListTile(
                        title: Text("Italian"),
                        value: 'Italian',
                        groupValue: _language,
                        onChanged: (value) => setState(() {
                          _language = value.toString();
                        }),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.info_outline),
            title: Text("About", style: TextStyle(fontSize: 20)),
            subtitle: Text("Local GPT version 1.0"),
          ),
        ],
      ),
    );
  }
}
