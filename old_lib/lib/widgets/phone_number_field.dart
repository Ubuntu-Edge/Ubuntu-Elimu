import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/phone_formatter.dart';

/// Custom text field for phone number input with validation and formatting
class PhoneNumberField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final bool isRequired;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;

  const PhoneNumberField({
    super.key,
    required this.controller,
    this.label = 'Phone Number',
    this.hint = 'Enter phone number',
    this.isRequired = false,
    this.validator,
    this.onChanged,
  });

  @override
  State<PhoneNumberField> createState() => _PhoneNumberFieldState();
}

class _PhoneNumberFieldState extends State<PhoneNumberField> {
  String? _formattedValue;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() {
    final text = widget.controller.text;
    if (text.isNotEmpty) {
      final formatted = PhoneFormatter.formatToInternational(text);
      if (formatted != _formattedValue) {
        setState(() {
          _formattedValue = formatted;
        });
      }
    } else {
      setState(() {
        _formattedValue = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: widget.controller,
          decoration: InputDecoration(
            labelText: widget.label + (widget.isRequired ? ' *' : ''),
            hintText: widget.hint,
            prefixIcon: const Icon(Icons.phone),
            suffixIcon: _formattedValue != null
                ? Icon(
                    PhoneFormatter.isValidKenyanNumber(_formattedValue)
                        ? Icons.check_circle
                        : Icons.error,
                    color: PhoneFormatter.isValidKenyanNumber(_formattedValue)
                        ? Colors.green
                        : Colors.orange,
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.grey[50],
            helperText: _formattedValue != null
                ? 'Will be saved as: $_formattedValue'
                : null,
            helperStyle: TextStyle(
              fontSize: 12,
              color: PhoneFormatter.isValidKenyanNumber(_formattedValue)
                  ? Colors.green[700]
                  : Colors.grey[600],
            ),
          ),
          keyboardType: TextInputType.phone,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9+\s]')),
            LengthLimitingTextInputFormatter(15),
          ],
          validator: widget.validator ??
              (widget.isRequired
                  ? (value) {
                      if (value == null || value.trim().isEmpty) {
                        return '${widget.label} is required';
                      }
                      final formatted =
                          PhoneFormatter.formatToInternational(value);
                      if (formatted == null ||
                          !PhoneFormatter.isValidKenyanNumber(formatted)) {
                        return 'Please enter a valid Kenyan phone number';
                      }
                      return null;
                    }
                  : (value) {
                      if (value != null && value.trim().isNotEmpty) {
                        final formatted =
                            PhoneFormatter.formatToInternational(value);
                        if (formatted == null ||
                            !PhoneFormatter.isValidKenyanNumber(formatted)) {
                          return 'Please enter a valid Kenyan phone number';
                        }
                      }
                      return null;
                    }),
          onChanged: widget.onChanged,
        ),
      ],
    );
  }
}
