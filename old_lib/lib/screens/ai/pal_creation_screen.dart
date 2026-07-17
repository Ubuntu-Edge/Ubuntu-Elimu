import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../models/ai_pal.dart';

class PalCreationScreen extends StatefulWidget {
  final Function(AIPal) onPalCreated;

  const PalCreationScreen({
    super.key,
    required this.onPalCreated,
  });

  @override
  State<PalCreationScreen> createState() => _PalCreationScreenState();
}

class _PalCreationScreenState extends State<PalCreationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _systemPromptController = TextEditingController();

  double _temperature = 0.7;
  double _topP = 0.9;
  int _nCtx = 2048;
  int _selectedColorIndex = 0;

  // Predefined color palette for pals
  final List<Color> _colorPalette = [
    Colors.blue,
    Colors.green,
    Colors.purple,
    Colors.orange,
    Colors.red,
    Colors.teal,
    Colors.indigo,
    Colors.pink,
  ];

  final List<String> _colorHexes = [
    '#2196F3', // blue
    '#4CAF50', // green
    '#9C27B0', // purple
    '#FF9800', // orange
    '#F44336', // red
    '#009688', // teal
    '#3F51B5', // indigo
    '#E91E63', // pink
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _systemPromptController.dispose();
    super.dispose();
  }

  void _createPal() {
    if (_formKey.currentState!.validate()) {
      final newPal = AIPal(
        id: const Uuid().v4(),
        name: _nameController.text,
        systemPrompt: _systemPromptController.text,
        temperature: _temperature,
        topP: _topP,
        nCtx: _nCtx,
        color: _colorHexes[_selectedColorIndex],
      );

      widget.onPalCreated(newPal);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New AI Pal'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Name Field
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Pal Name',
                  hintText: 'e.g., Medical Expert',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.person),
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Please enter a name';
                  }
                  if (value!.length > 50) {
                    return 'Name must be less than 50 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // System Prompt Field
              TextFormField(
                controller: _systemPromptController,
                maxLines: 5,
                minLines: 3,
                decoration: InputDecoration(
                  labelText: 'System Prompt',
                  hintText: 'Define how this Pal should behave and respond...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignLabelWithHint: true,
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Please enter a system prompt';
                  }
                  if (value!.length > 1000) {
                    return 'System prompt must be less than 1000 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Color Selection
              const Text(
                'Pal Color',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: List.generate(
                  _colorPalette.length,
                  (index) {
                    final isSelected = index == _selectedColorIndex;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedColorIndex = index),
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: _colorPalette[index],
                          shape: BoxShape.circle,
                          border: isSelected
                              ? Border.all(color: Colors.black, width: 3)
                              : null,
                        ),
                        child: isSelected
                            ? const Icon(Icons.check, color: Colors.white)
                            : null,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 28),

              // Temperature Slider
              _buildSliderSetting(
                label: 'Temperature',
                value: _temperature,
                min: 0.0,
                max: 2.0,
                onChanged: (v) => setState(() => _temperature = v),
              ),
              const SizedBox(height: 24),

              // Top-P Slider
              _buildSliderSetting(
                label: 'Top-P',
                value: _topP,
                min: 0.0,
                max: 1.0,
                onChanged: (v) => setState(() => _topP = v),
              ),
              const SizedBox(height: 24),

              // Context Size Slider
              _buildSliderSetting(
                label: 'Context Size (nCtx)',
                value: _nCtx.toDouble(),
                min: 512,
                max: 4096,
                step: 256,
                onChanged: (v) => setState(() => _nCtx = v.toInt()),
              ),
              const SizedBox(height: 28),

              // Create Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _createPal,
                  icon: const Icon(Icons.add),
                  label: const Text('Create Pal'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Cancel Button
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSliderSetting({
    required String label,
    required double value,
    required double min,
    required double max,
    double step = 0.1,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                value.toStringAsFixed(2),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: ((max - min) / step).toInt(),
          label: value.toStringAsFixed(2),
          onChanged: onChanged,
        ),
      ],
    );
  }
}
