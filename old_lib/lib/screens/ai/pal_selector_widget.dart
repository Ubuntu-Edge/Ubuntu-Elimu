import 'package:flutter/material.dart';
import '../../models/ai_pal.dart';

/// Helper function to convert hex string color to Flutter Color
Color _colorFromHex(String? hexColor) {
  if (hexColor == null) return Colors.blue;
  try {
    return Color(int.parse(hexColor.replaceFirst('#', '0xff')));
  } catch (e) {
    return Colors.blue;
  }
}

class PalSelectorWidget extends StatelessWidget {
  final List<AIPal> pals;
  final AIPal? selectedPal;
  final ValueChanged<AIPal> onPalSelected;
  final VoidCallback onCreatePal;

  const PalSelectorWidget({
    super.key,
    required this.pals,
    required this.selectedPal,
    required this.onPalSelected,
    required this.onCreatePal,
  });

  void _showPalBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Select AI Pal',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: pals.length,
                itemBuilder: (context, index) {
                  final pal = pals[index];
                  final isSelected = selectedPal?.id == pal.id;

                  return Material(
                    child: InkWell(
                      onTap: () {
                        onPalSelected(pal);
                        Navigator.pop(context);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color:
                              isSelected ? Colors.blue[50] : Colors.transparent,
                          border: Border(
                            left: BorderSide(
                              color: isSelected
                                  ? _colorFromHex(pal.color)
                                  : Colors.transparent,
                              width: 4,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: _colorFromHex(pal.color),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    pal.name,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                      color: isSelected
                                          ? Colors.blue[900]
                                          : Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Temp: ${pal.temperature.toStringAsFixed(1)} | Top-P: ${pal.topP.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              Icon(
                                Icons.check_circle,
                                color: Colors.blue[600],
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  onCreatePal();
                },
                icon: const Icon(Icons.add),
                label: const Text('Create New Pal'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (selectedPal == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text(
          'No Pal selected',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return GestureDetector(
      onTap: () => _showPalBottomSheet(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              _colorFromHex(selectedPal!.color).withValues(alpha: 0.8),
              _colorFromHex(selectedPal!.color).withValues(alpha: 0.6),
            ],
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: _colorFromHex(selectedPal!.color),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              selectedPal!.name,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(
              Icons.arrow_drop_down,
              color: Colors.white,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}
