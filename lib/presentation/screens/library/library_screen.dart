import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../providers/document_provider.dart';
// CRITICAL FIX: Importing the model file exposes the official DocType enum to this screen
import '../../../models/document.dart';
import 'widgets/document_card.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final docProvider = Provider.of<DocumentProvider>(context);

    return Scaffold(
      backgroundColor: UEColors.bg,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            _buildSearchBar(context, docProvider),
            const SizedBox(height: 14),
            _buildCategoryChips(context, docProvider),
            const SizedBox(height: 16),
            Expanded(
              child: _buildDocumentList(context, docProvider),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _simulateUpload(context, docProvider),
        backgroundColor: UEColors.accent,
        label: Text(
          'Upload Doc',
          style: UETypography.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        icon: const Icon(TablerIcons.plus, color: Colors.white, size: 16),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context, DocumentProvider provider) {
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: UEColors.surface,
        border: Border.all(color: UEColors.border, width: 0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Icon(TablerIcons.search, color: UEColors.textMuted, size: 18),
          ),
          Expanded(
            child: TextField(
              style: UETypography.inter(fontSize: 13, color: UEColors.textPrimary),
              decoration: const InputDecoration(
                hintText: 'Search offline files...',
                border: InputBorder.none,
                isDense: true,
              ),
              onChanged: (val) => provider.setSearchQuery(val),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChips(BuildContext context, DocumentProvider provider) {
    final categories = ['all', 'pdf', 'pptx', 'docx'];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: categories.map((cat) {
          final isSelected = provider.selectedCategory == cat;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => provider.setSelectedCategory(cat),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected ? UEColors.iconBg : UEColors.surface,
                  border: Border.all(
                    color: isSelected ? UEColors.accent : UEColors.border,
                    width: 0.5,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  cat.toUpperCase(),
                  style: UETypography.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? UEColors.accent : UEColors.textMuted,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDocumentList(BuildContext context, DocumentProvider provider) {
    final docs = provider.documents;

    if (docs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(TablerIcons.file_off, size: 36, color: UEColors.border),
            const SizedBox(height: 12),
            Text(
              'No matching offline files found',
              style: UETypography.inter(fontSize: 13, color: UEColors.textMuted),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: docs.length,
      itemBuilder: (context, index) {
        return DocumentCard(doc: docs[index]);
      },
    );
  }

  void _simulateUpload(BuildContext context, DocumentProvider provider) {
    final random = Random();
    final names = [
      'Anatomy Exam Prep — Q2.pdf',
      'Calculus Formulas Guide.docx',
      'Advanced Astrophysics presentation.pptx',
      'Kiswahili Grammar guide.pdf',
      'Microeconomics lecture slides.pptx'
    ];

    // Now cleanly mapping directly to the official DocType enum definitions from your model
    final docTypes = [
      DocType.pdf,
      DocType.docx,
      DocType.pptx,
      DocType.pdf,
      DocType.pptx
    ];

    final idx = random.nextInt(names.length);
    final name = names[idx];
    final selectedType = docTypes[idx];
    final size = 1000000 + random.nextInt(15000000);

    provider.uploadDocument(name, selectedType, size);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Uploaded $name successfully to local storage'),
        backgroundColor: UEColors.surface,
      ),
    );
  }
}