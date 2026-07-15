import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../providers/offline_model_provider.dart';
import '../../../providers/settings_provider.dart';
import 'offline_model_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Check if provider is available
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
          if (settings.activeBackend == AIBackend.groq) ...[
            _buildSectionTitle('GROQ CONFIGURATION'),
            const SizedBox(height: 10),
            _buildGroqConfigCard(context, settings),
            const SizedBox(height: 24),
          ],
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
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const OfflineModelScreen()),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: UEColors.surface,
          border: Border.all(color: UEColors.border, width: 0.5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
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
                  Consumer<OfflineModelProvider>(
                    builder: (_, provider, __) {
                      final active = provider.activeModel;
                      final downloaded = provider.models
                          .where((m) => m.isDownloaded)
                          .length;
                      return Text(
                        active != null
                            ? '${active.name} · Active'
                            : downloaded > 0
                            ? '$downloaded model(s) downloaded · Tap to manage'
                            : 'No models · Tap to download',
                        style: UETypography.inter(
                          fontSize: 11,
                          color: active != null
                              ? UEColors.green
                              : UEColors.textMuted,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: UEColors.textMuted,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreferenceSwitches(
    BuildContext context,
    SettingsProvider settings,
  ) {
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
              style: UETypography.spaceGrotesk(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: UEColors.textPrimary,
              ),
            ),
            subtitle: Text(
              'Guides learning by asking step-by-step questions instead of solving directly.',
              style: UETypography.inter(
                fontSize: 11,
                color: UEColors.textMuted,
              ),
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
              style: UETypography.spaceGrotesk(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: UEColors.textPrimary,
              ),
            ),
            subtitle: Text(
              'Optimizes CPU cores for local model inference speeds.',
              style: UETypography.inter(
                fontSize: 11,
                color: UEColors.textMuted,
              ),
            ),
            value: settings.powerMode,
            activeThumbColor: UEColors.accent,
            activeTrackColor: UEColors.accent.withOpacity(0.5),
            onChanged: (val) => settings.togglePowerMode(val),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Divider(color: UEColors.border, height: 0.5),
          ),
          ListTile(
            title: Text(
              'AI Backend Model',
              style: UETypography.spaceGrotesk(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: UEColors.textPrimary,
              ),
            ),
            subtitle: Text(
              'Switch between offline local model and Groq cloud model.',
              style: UETypography.inter(
                fontSize: 11,
                color: UEColors.textMuted,
              ),
            ),
            trailing: DropdownButton<AIBackend>(
              value: settings.activeBackend,
              dropdownColor: UEColors.surface,
              underline: const SizedBox(),
              icon: const Icon(Icons.arrow_drop_down, color: UEColors.accent),
              onChanged: (AIBackend? newValue) {
                if (newValue != null) {
                  settings.setAIBackend(newValue);
                }
              },
              items: const [
                DropdownMenuItem(
                  value: AIBackend.local,
                  child: Text(
                    'Local Offline',
                    style: TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ),
                DropdownMenuItem(
                  value: AIBackend.groq,
                  child: Text(
                    'Groq Cloud',
                    style: TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroqConfigCard(BuildContext context, SettingsProvider settings) {
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
          Text(
            'Groq API Key',
            style: UETypography.spaceGrotesk(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: UEColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            obscureText: true,
            onChanged: (val) => settings.setGroqApiKey(val),
            controller: TextEditingController(text: settings.groqApiKey)
              ..selection = TextSelection.fromPosition(
                TextPosition(offset: settings.groqApiKey.length),
              ),
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'gsk_...',
              hintStyle: TextStyle(color: UEColors.textMuted.withOpacity(0.5)),
              filled: true,
              fillColor: UEColors.bgPrimary,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: UEColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: UEColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: UEColors.accent),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Get your free API key at console.groq.com. Your key is stored securely on your device.',
            style: UETypography.inter(fontSize: 10, color: UEColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemInfoCard(BuildContext context) {
    return FutureBuilder<Map<String, String>>(
      future: _getSystemInfo(context),
      builder: (context, snapshot) {
        final info =
            snapshot.data ??
            {
              'storage': 'Calculating...',
              'models': 'Calculating...',
              'version': '1.0.0+1',
            };

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: UEColors.surface,
            border: Border.all(color: UEColors.border, width: 0.5),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              _buildInfoRow('Local Storage Used', info['storage']!),
              const SizedBox(height: 10),
              _buildInfoRow('Downloaded Models', info['models']!),
              const SizedBox(height: 10),
              _buildInfoRow('App Version', info['version']!),
            ],
          ),
        );
      },
    );
  }

  Future<Map<String, String>> _getSystemInfo(BuildContext context) async {
    try {
      // Calculate actual storage used
      final appDir = await getApplicationDocumentsDirectory();
      int totalSize = 0;

      if (await appDir.exists()) {
        await for (var entity in appDir.list(
          recursive: true,
          followLinks: false,
        )) {
          if (entity is File) {
            try {
              totalSize += await entity.length();
            } catch (_) {}
          }
        }
      }

      // Format size
      String storageText;
      if (totalSize < 1024 * 1024) {
        storageText = '${(totalSize / 1024).toStringAsFixed(1)} KB';
      } else if (totalSize < 1024 * 1024 * 1024) {
        storageText = '${(totalSize / (1024 * 1024)).toStringAsFixed(1)} MB';
      } else {
        storageText =
            '${(totalSize / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
      }

      // Get model info
      final modelProvider = Provider.of<OfflineModelProvider>(
        context,
        listen: false,
      );
      final downloadedCount = modelProvider.models
          .where((m) => m.isDownloaded)
          .length;
      final totalCount = modelProvider.models.length;
      final modelsText = '$downloadedCount of $totalCount downloaded';

      return {
        'storage': storageText,
        'models': modelsText,
        'version': '1.0.0+1',
      };
    } catch (e) {
      return {
        'storage': 'Unable to calculate',
        'models': 'See above',
        'version': '1.0.0+1',
      };
    }
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
          style: UETypography.inter(
            fontSize: 12,
            color: UEColors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
