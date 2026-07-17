import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/drug.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class DrugDosageCalculatorScreen extends StatefulWidget {
  final Drug drug;

  const DrugDosageCalculatorScreen({
    super.key,
    required this.drug,
  });

  @override
  State<DrugDosageCalculatorScreen> createState() => _DrugDosageCalculatorScreenState();
}

class _DrugDosageCalculatorScreenState extends State<DrugDosageCalculatorScreen> {
  final _weightController = TextEditingController();
  String _ageGroup = 'child';
  double? _calculatedDosage;

  @override
  void dispose() {
    _weightController.dispose();
    super.dispose();
  }

  void _calculateDosage() {
    final weight = double.tryParse(_weightController.text);
    if (weight == null || weight <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid weight')),
      );
      return;
    }

    setState(() {
      if (_ageGroup == 'child') {
        _calculatedDosage = widget.drug.calculateChildDosage(weight);
      } else {
        _calculatedDosage = null; // Use adult dosage string
      }
    });
  }

  Widget _buildAgeGroupButton(String label, String value) {
    final isSelected = _ageGroup == value;
    return CustomButton(
      text: label,
      onPressed: () {
        setState(() {
          _ageGroup = value;
          _calculatedDosage = null; // Reset dosage when age group changes
          _weightController.clear();
        });
      },
      backgroundColor: isSelected ? Colors.purple : Colors.grey[300],
      textColor: isSelected ? Colors.white : Colors.black87,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dosage Calculator'),
      ),
      resizeToAvoidBottomInset: false, // Added this line to prevent overflow
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drug Name Card
            Card(
              color: Colors.purple[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Icon(Icons.medication, size: 48, color: Colors.purple),
                    const SizedBox(height: 12),
                    Text(
                      widget.drug.name.split('(')[0].trim(),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Age Group Selection
            const Text(
              'Select Age Group',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildAgeGroupButton('Child', 'child'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildAgeGroupButton('Adult', 'adult'),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Weight Input (for children)
            if (_ageGroup == 'child') ...[
              CustomTextField(
                label: 'Patient Weight (kg)',
                hint: 'Enter weight in kilograms',
                controller: _weightController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                prefixIcon: Icons.monitor_weight,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
              ),
              const SizedBox(height: 16),

              // Calculation Info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info, color: Colors.blue, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.drug.dosageCalculation,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Calculate Button
              CustomButton(
                text: 'Calculate Dosage',
                icon: Icons.calculate,
                onPressed: _calculateDosage,
              ),
            ],

            // Result Display
            if (_calculatedDosage != null || _ageGroup == 'adult') ...[
              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 16),

              // Result Card
              Card(
                color: Colors.green[50],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.green[300]!, width: 2),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle, color: Colors.green[700], size: 32),
                          const SizedBox(width: 12),
                          const Text(
                            'Recommended Dosage',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      
                      if (_ageGroup == 'child' && _calculatedDosage != null) ...[
                        Text(
                          '${_calculatedDosage!.toStringAsFixed(0)} mg',
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[700],
                          ),
                        ),
                        const Text(
                          'per dose',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'For a ${_weightController.text}kg child',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ] else ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: Text(
                            widget.drug.dosageAdult,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Administration Instructions
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.amber[900]),
                        const SizedBox(width: 8),
                        Text(
                          'How to Give',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber[900],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...widget.drug.administration.map((instruction) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('• '),
                              Expanded(child: Text(instruction)),
                            ],
                          ),
                        )),
                  ],
                ),
              ),

              // Warnings
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.warning_amber, color: Colors.red[900]),
                        const SizedBox(width: 8),
                        Text(
                          'Important Warnings',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.red[900],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...widget.drug.warnings.map((warning) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('• '),
                              Expanded(child: Text(warning)),
                            ],
                          ),
                        )),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}