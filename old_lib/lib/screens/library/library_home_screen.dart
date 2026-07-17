import 'package:flutter/material.dart';
import '../../services/medical_library_service.dart';
import '../../l10n/app_localizations.dart';
import 'disease_list_screen.dart';
import 'drug_reference_screen.dart';
import 'emergency_procedures_screen.dart';
import 'clinical_guidelines_screen.dart';

class LibraryHomeScreen extends StatelessWidget {
  const LibraryHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final library = MedicalLibraryService.instance;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.medicalLibrary),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                l10n.translate('quickReference') ?? 'Quick Reference',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.translate('offlineMedicalKnowledge') ?? 'Offline medical knowledge at your fingertips',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 16),

              // Changed to ClampingScrollPhysics to fix over-scroll bounce
              Expanded(
                child: ListView(
                  physics: const ClampingScrollPhysics(),
                  children: [
                    _buildLibraryCard(
                      context,
                      title: l10n.translate('diseases') ?? 'Diseases',
                      subtitle: '${library.diseases.length} ${l10n.translate('conditions') ?? 'conditions'}',
                      icon: Icons.healing,
                      color: Colors.blue,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const DiseaseListScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildLibraryCard(
                      context,
                      title: l10n.translate('medications') ?? 'Medications',
                      subtitle: '${library.drugs.length} ${l10n.translate('drugs') ?? 'drugs'}',
                      icon: Icons.medication,
                      color: Colors.purple,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const DrugReferenceScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildLibraryCard(
                      context,
                      title: l10n.translate('emergencies') ?? 'Emergencies',
                      subtitle: '8 ${l10n.translate('protocols') ?? 'protocols'}',
                      icon: Icons.emergency,
                      color: Colors.red,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const EmergencyProceduresScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildLibraryCard(
                      context,
                      title: l10n.translate('guidelines') ?? 'Guidelines',
                      subtitle: '8 ${l10n.translate('whoGuidelines') ?? 'WHO guidelines'}',
                      icon: Icons.book,
                      color: Colors.green,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ClinicalGuidelinesScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),

                    // Stats Footer inside ListView (scrolls together)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IntrinsicHeight(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Expanded(
                              child: _buildStat(
                                '${library.diseases.length}',
                                l10n.translate('diseases') ?? 'Diseases',
                                Icons.healing,
                              ),
                            ),
                            VerticalDivider(
                              width: 1,
                              thickness: 1,
                              color: Colors.grey[300],
                            ),
                            Expanded(
                              child: _buildStat(
                                '${library.drugs.length}',
                                l10n.translate('drugs') ?? 'Drugs',
                                Icons.medication,
                              ),
                            ),
                            VerticalDivider(
                              width: 1,
                              thickness: 1,
                              color: Colors.grey[300],
                            ),
                            Expanded(
                              child: _buildStat(
                                '100%',
                                l10n.offlineMode,
                                Icons.offline_bolt,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLibraryCard(
      BuildContext context, {
        required String title,
        required String subtitle,
        required IconData icon,
        required Color color,
        required VoidCallback onTap,
      }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withAlpha((255 * 0.1).round()),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 40,
                  color: color,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStat(String value, String label, IconData icon) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 24, color: Colors.teal),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
