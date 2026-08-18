import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:denizen_ai/denizen_ai.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../providers/settings_provider.dart';
import '../../../providers/offline_model_provider.dart';
import 'model_registry_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _openModelRegistry(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ModelRegistryScreen()),
    );
    // Refresh model provider state upon return
    if (context.mounted) {
      final provider = Provider.of<OfflineModelProvider>(context, listen: false);
      await provider.initialize();
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final modelProvider = Provider.of<OfflineModelProvider>(context);
    final denizen = DenizenAI();
    final isRealModelActive = denizen.isModelLoaded;
    final activeModelName = modelProvider.activeModel?.name ?? denizen.engine.loadedModel?.name ?? 'No Model Loaded';

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          _buildSectionTitle('OFFLINE AI ENGINE'),
          const SizedBox(height: 10),

          // Engine Status Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isRealModelActive ? UEColors.greenBg : UEColors.surface,
              border: Border.all(
                color: isRealModelActive ? UEColors.greenBorder : UEColors.border,
                width: isRealModelActive ? 1.5 : 0.5,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      isRealModelActive ? TablerIcons.brain : TablerIcons.cloud_download,
                      color: isRealModelActive ? UEColors.green : UEColors.accent,
                      size: 26,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                isRealModelActive ? 'LIVE NEURAL ENGINE ACTIVE' : 'NO MODEL IN MEMORY',
                                style: UETypography.spaceGrotesk(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: isRealModelActive ? UEColors.green : UEColors.textPrimary,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isRealModelActive
                                ? 'Loaded Model: $activeModelName\n100% on-device AI inference is active for your Tutor & Library.'
                                : 'Select and load a compact GGUF model in the registry to activate offline AI.',
                            style: UETypography.inter(
                              fontSize: 12,
                              color: isRealModelActive ? UEColors.textPrimary : UEColors.textSecondary,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _openModelRegistry(context),
                        child: Container(
                          height: 40,
                          decoration: BoxDecoration(
                            color: isRealModelActive ? UEColors.green : UEColors.accent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(TablerIcons.database, size: 16, color: Colors.white),
                              const SizedBox(width: 8),
                              Text(
                                isRealModelActive ? 'MANAGE MODELS' : 'OPEN MODEL REGISTRY',
                                style: UETypography.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (isRealModelActive) ...[
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: () => modelProvider.clearActiveModel(),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            border: Border.all(color: UEColors.pdfFg, width: 0.5),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'Unload',
                            style: UETypography.inter(fontSize: 12, color: UEColors.pdfFg, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          _buildSectionTitle('PREFERENCES'),
          const SizedBox(height: 10),
          _buildPreferenceSwitches(context, settings),
          const SizedBox(height: 24),
          _buildSectionTitle('LOCAL SYSTEM INFO'),
          const SizedBox(height: 10),
          _buildSystemInfoCard(context, modelProvider, activeModelName),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String text) {
    return Text(
      text,
      style: UETypography.inter(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        color: UEColors.textMuted,
        letterSpacing: 1.1,
      ),
    );
  }

  Widget _buildPreferenceSwitches(BuildContext context, SettingsProvider settings) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: UEColors.surface,
        border: Border.all(color: UEColors.border, width: 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          SwitchListTile(
            title: Text(
              'Socratic Coaching Mode',
              style: UETypography.spaceGrotesk(fontSize: 13, fontWeight: FontWeight.w500, color: UEColors.textPrimary),
            ),
            subtitle: Text(
              'Guides learning by asking step-by-step questions instead of solving directly.',
              style: UETypography.inter(fontSize: 11, color: UEColors.textMuted),
            ),
            value: settings.socraticMode,
            activeThumbColor: UEColors.accent,
            activeTrackColor: UEColors.accent.withOpacity(0.5),
            onChanged: (val) => settings.toggleSocraticMode(val),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Divider(color: UEColors.border, height: 0.5),
          ),
          SwitchListTile(
            title: Text(
              'System Power Mode',
              style: UETypography.spaceGrotesk(fontSize: 13, fontWeight: FontWeight.w500, color: UEColors.textPrimary),
            ),
            subtitle: Text(
              'Optimizes CPU cores for local model inference speeds.',
              style: UETypography.inter(fontSize: 11, color: UEColors.textMuted),
            ),
            value: settings.powerMode,
            activeThumbColor: UEColors.accent,
            activeTrackColor: UEColors.accent.withOpacity(0.5),
            onChanged: (val) => settings.togglePowerMode(val),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemInfoCard(BuildContext context, OfflineModelProvider modelProvider, String activeModelName) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: UEColors.surface,
        border: Border.all(color: UEColors.border, width: 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          FutureBuilder<int>(
            future: modelProvider.getUsedStorageBytes(),
            builder: (context, snapshot) {
              final usedMB = ((snapshot.data ?? 0) / (1024 * 1024)).toStringAsFixed(1);
              return _buildInfoRow('Local Storage Used', '$usedMB MB');
            },
          ),
          const SizedBox(height: 10),
          _buildInfoRow(
            'Active Model',
            activeModelName,
          ),
          const SizedBox(height: 10),
          _buildInfoRow('Engine Status', DenizenAI().isModelLoaded ? 'Loaded in Native RAM' : 'Idle'),
          const SizedBox(height: 10),
          _buildInfoRow('App Version', '1.0.0 (Ubuntu-Edge Custom)'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: UETypography.inter(fontSize: 12, color: UEColors.textMuted),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: UETypography.inter(fontSize: 12, color: UEColors.textPrimary, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}
