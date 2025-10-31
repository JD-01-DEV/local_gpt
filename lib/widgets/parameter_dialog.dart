import 'package:flutter/material.dart';

class ParameterDialog extends StatefulWidget {
  final double temperature;
  final double topP;
  final int maxTokens;
  final ValueChanged<double> onTempChange;
  final ValueChanged<double> onTopPChange;
  final ValueChanged<int> onMaxTokensChange;

  const ParameterDialog({
    required this.temperature,
    required this.topP,
    required this.maxTokens,
    required this.onTempChange,
    required this.onTopPChange,
    required this.onMaxTokensChange,
    super.key,
  });

  @override
  State<ParameterDialog> createState() => _ParameterDialogState();
}

class _ParameterDialogState extends State<ParameterDialog> {
  late double lateTemperature;
  late double lateTopP;
  late int lateMaxTokens;

  @override
  void initState() {
    super.initState();
    lateTemperature = widget.temperature;
    lateTopP = widget.topP;
    lateMaxTokens = widget.maxTokens;
  }

  Widget _buildSlider(
    String label,
    double value,
    double min,
    double max,
    ValueChanged<double> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$label: ${value.toStringAsFixed(2)}",
            style: TextStyle(fontSize: 18),
          ),
          Slider(
            label: label,
            value: value,
            min: min,
            max: max,
            divisions: 100,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSlider("Temperature", lateTemperature, 0.1, 1.5, (value) {
            setState(() {
              lateTemperature = value;
            });
            widget.onTempChange(value);
          }),
          _buildSlider("Top P", lateTopP, 0.1, 1.0, (value) {
            setState(() {
              lateTopP = value;
            });
            widget.onTopPChange(value);
          }),
          _buildSlider("Max Tokens", lateMaxTokens.toDouble(), 64, 1024, (val) {
            setState(() {
              lateMaxTokens = val.toInt();
            });
            widget.onMaxTokensChange(val.toInt());
          }),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            setState(() {
              lateTemperature = widget.temperature;
              lateTopP = widget.topP;
              lateMaxTokens = widget.maxTokens;
            });
            widget.onTempChange(widget.temperature);
            widget.onTopPChange(widget.topP);
            widget.onMaxTokensChange(widget.maxTokens);
          },
          child: Text("Reset", style: TextStyle(fontSize: 18)),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text("Close", style: TextStyle(fontSize: 20)),
        ),
      ],
    );
  }
}
