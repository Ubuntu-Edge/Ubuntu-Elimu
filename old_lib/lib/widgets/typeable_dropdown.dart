import 'package:flutter/material.dart';

/// Dropdown with typing support - allows both selection and custom input
class TypeableDropdownField extends StatefulWidget {
  final String label;
  final String? hint;
  final List<String> options;
  final String? initialValue;
  final ValueChanged<String?> onChanged;
  final IconData? prefixIcon;
  final String? Function(String?)? validator;
  final bool isRequired;

  const TypeableDropdownField({
    super.key,
    required this.label,
    this.hint,
    required this.options,
    this.initialValue,
    required this.onChanged,
    this.prefixIcon,
    this.validator,
    this.isRequired = false,
  });

  @override
  State<TypeableDropdownField> createState() => _TypeableDropdownFieldState();
}

class _TypeableDropdownFieldState extends State<TypeableDropdownField> {
  late TextEditingController _controller;
  String? _selectedValue;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _selectedValue = widget.initialValue;
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Autocomplete<String>(
          initialValue: TextEditingValue(text: widget.initialValue ?? ''),
          optionsBuilder: (TextEditingValue textEditingValue) {
            if (textEditingValue.text.isEmpty) {
              return widget.options;
            }
            return widget.options.where((String option) {
              return option
                  .toLowerCase()
                  .contains(textEditingValue.text.toLowerCase());
            });
          },
          onSelected: (String selection) {
            setState(() {
              _selectedValue = selection;
              _controller.text = selection;
            });
            widget.onChanged(selection);
          },
          fieldViewBuilder: (context, textEditingController, focusNode,
              onFieldSubmitted) {
            // Keep reference to the autocomplete controller
            _controller = textEditingController;
            if (_selectedValue != null && _controller.text != _selectedValue) {
              _controller.text = _selectedValue!;
            }
            
            return TextFormField(
              controller: _controller,
              focusNode: focusNode,
              decoration: InputDecoration(
                labelText: widget.label + (widget.isRequired ? ' *' : ''),
                hintText: widget.hint,
                prefixIcon: widget.prefixIcon != null
                    ? Icon(widget.prefixIcon)
                    : null,
                suffixIcon: _controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: () {
                          setState(() {
                            _controller.clear();
                            _selectedValue = null;
                          });
                          widget.onChanged(null);
                        },
                      )
                    : const Icon(Icons.arrow_drop_down),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              validator: widget.validator ??
                  (widget.isRequired
                      ? (value) {
                          if (value == null || value.trim().isEmpty) {
                            return '${widget.label} is required';
                          }
                          return null;
                        }
                      : null),
              onChanged: (value) {
                setState(() {
                  _selectedValue = value.isNotEmpty ? value : null;
                });
                widget.onChanged(value.isNotEmpty ? value : null);
              },
            );
          },
          optionsViewBuilder: (context, onSelected, options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4.0,
                borderRadius: BorderRadius.circular(12),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxHeight: 200,
                    maxWidth: 400,
                  ),
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (context, index) {
                      final option = options.elementAt(index);
                      return ListTile(
                        dense: true,
                        title: Text(option),
                        onTap: () {
                          onSelected(option);
                        },
                      );
                    },
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

/// Multi-select chip input for conditions, allergies, medications
class ChipInputField extends StatefulWidget {
  final String label;
  final String? hint;
  final List<String> suggestedItems;
  final List<String> selectedItems;
  final ValueChanged<List<String>> onChanged;
  final IconData? prefixIcon;

  const ChipInputField({
    super.key,
    required this.label,
    this.hint,
    required this.suggestedItems,
    required this.selectedItems,
    required this.onChanged,
    this.prefixIcon,
  });

  @override
  State<ChipInputField> createState() => _ChipInputFieldState();
}

class _ChipInputFieldState extends State<ChipInputField> {
  final TextEditingController _controller = TextEditingController();
  List<String> _filteredSuggestions = [];
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    _filteredSuggestions = widget.suggestedItems;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _filterSuggestions(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredSuggestions = widget.suggestedItems;
      } else {
        _filteredSuggestions = widget.suggestedItems
            .where((item) =>
                item.toLowerCase().contains(query.toLowerCase()) &&
                !widget.selectedItems.contains(item))
            .toList();
      }
      _showSuggestions = query.isNotEmpty;
    });
  }

  void _addItem(String item) {
    if (item.isNotEmpty && !widget.selectedItems.contains(item)) {
      final updatedList = List<String>.from(widget.selectedItems)..add(item);
      widget.onChanged(updatedList);
      _controller.clear();
      setState(() {
        _showSuggestions = false;
        _filteredSuggestions = widget.suggestedItems;
      });
    }
  }

  void _removeItem(String item) {
    final updatedList = List<String>.from(widget.selectedItems)..remove(item);
    widget.onChanged(updatedList);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _controller,
          decoration: InputDecoration(
            labelText: widget.label,
            hintText: widget.hint,
            prefixIcon:
                widget.prefixIcon != null ? Icon(widget.prefixIcon) : null,
            suffixIcon: IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () {
                if (_controller.text.isNotEmpty) {
                  _addItem(_controller.text.trim());
                }
              },
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
          onChanged: _filterSuggestions,
          onFieldSubmitted: (value) => _addItem(value.trim()),
        ),
        if (_showSuggestions && _filteredSuggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            constraints: const BoxConstraints(maxHeight: 150),
            child: ListView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: _filteredSuggestions.length,
              itemBuilder: (context, index) {
                final suggestion = _filteredSuggestions[index];
                return ListTile(
                  dense: true,
                  title: Text(suggestion),
                  onTap: () => _addItem(suggestion),
                );
              },
            ),
          ),
        if (widget.selectedItems.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.selectedItems.map((item) {
              return Chip(
                label: Text(item),
                deleteIcon: const Icon(Icons.close, size: 18),
                onDeleted: () => _removeItem(item),
                backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                labelStyle: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.w500,
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}
