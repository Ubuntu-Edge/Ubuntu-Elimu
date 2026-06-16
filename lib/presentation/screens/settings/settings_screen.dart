import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../providers/settings_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          _buildSectionTitle('OFFLINE MODELS'),
          const SizedBox(height: 10),
          _buildModelCard(context, settings),
          const SizedBox(height: 24),
          _buildSectionTitle('PREFERENCES'),
          const SizedBox(height: 10),
          _buildPreferenceSwitches(context, settings),
          const SizedBox(height: 24),
          _buildSectionTitle('LOCAL SYSTEM INFO'),
          const SizedBox(height: 10),
          _buildSystemInfoCard(context),
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

  Widget _buildModelCard(BuildContext context, SettingsProvider settings) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: UEColors.surface,
        border: Border.all(color: UEColors.border, width: 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(TablerIcons.database, color: UEColors.accent, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Local LLM Database',
                      style: UETypography.spaceGrotesk(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: UEColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      settings.modelName,
                      style: UETypography.inter(
                        fontSize: 11,
                        color: UEColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (settings.isDownloading) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: settings.downloadProgress,
                backgroundColor: UEColors.iconBg,
                color: UEColors.accent,
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Downloading model weights...',
                  style: UETypography.inter(fontSize: 11, color: UEColors.textMuted),
                ),
                Text(
                  '${(settings.downloadProgress * 100).toInt()}%',
                  style: UETypography.inter(fontSize: 11, color: UEColors.accent, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ] else if (settings.isModelDownloaded) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Status: Fully Offline Capable',
                  style: UETypography.inter(fontSize: 12, color: UEColors.green, fontWeight: FontWeight.w500),
                ),
                GestureDetector(
                  onTap: () => settings.deleteModel(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      border: Border.all(color: UEColors.pdfFg, width: 0.5),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Delete Weights',
                      style: UETypography.inter(fontSize: 11, color: UEColors.pdfFg, fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            GestureDetector(
              onTap: () => settings.startModelDownload(),
              child: Container(
                height: 38,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: UEColors.accent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    'Download Local Model Weights',
                    style: UETypography.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
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
            activeColor: UEColors.accent,
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
            activeColor: UEColors.accent,
            onChanged: (val) => settings.togglePowerMode(val),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemInfoCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: UEColors.surface,
        border: Border.all(color: UEColors.border, width: 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _buildInfoRow('Local Storage Used', '11.6 MB / 64 GB'),
          const SizedBox(height: 10),
          _buildInfoRow('Server Sync Status', 'Ready (Kiswahili & English packs)'),
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
        Text(
          value,
          style: UETypography.inter(fontSize: 12, color: UEColors.textPrimary, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
