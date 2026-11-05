import 'package:flutter/material.dart';
import 'app_tokens.dart';
import 'app_typography.dart';

class ComponentGalleryScreen extends StatefulWidget {
  const ComponentGalleryScreen({super.key});

  @override
  State<ComponentGalleryScreen> createState() => _ComponentGalleryScreenState();
}

class _ComponentGalleryScreenState extends State<ComponentGalleryScreen> {
  bool _toggleState = true;
  int _selectedSegment = 0;

  void _showUndoToast() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.surface2,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.border),
        ),
        content: const Row(
          children: [
            Icon(Icons.info_outline, color: AppColors.textPrimary, size: 18),
            SizedBox(width: 10),
            Text('Entry deleted from Day Page', style: TextStyle(color: AppColors.textPrimary)),
          ],
        ),
        action: SnackBarAction(
          label: 'UNDO',
          textColor: AppColors.accentLime,
          onPressed: () {},
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        title: const Text('Design System Gallery', style: AppTypography.screenTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          // Section 1: Color Tokens & Surfaces
          _buildSectionHeader('1. Surface Cards & Borders'),
          _buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Surface-1 Container (#0A0A0A)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 6),
                RichText(
                  text: TextSpan(
                    children: AppTypography.parseLimeBold(
                      'This card demonstrates **1px border (#262626)** with **lime bold accents** inside OLED black.',
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Section 2: Lime Heatmap Cells
          _buildSectionHeader('2. Habit Heatmap Tiers (5 Opacities)'),
          _buildCard(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildHeatmapCell('0%', AppColors.heatmapTier0),
                _buildHeatmapCell('25%', AppColors.heatmapTier1),
                _buildHeatmapCell('50%', AppColors.heatmapTier2),
                _buildHeatmapCell('75%', AppColors.heatmapTier3),
                _buildHeatmapCell('100%', AppColors.heatmapTier4),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Section 3: Buttons & Actions
          _buildSectionHeader('3. Primary, Secondary & Destructive Buttons'),
          _buildCard(
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentLime,
                      foregroundColor: AppColors.textOnLime,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button)),
                    ),
                    onPressed: () {},
                    child: const Text('PRIMARY ACTION', style: AppTypography.buttonText),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      side: const BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button)),
                    ),
                    onPressed: _showUndoToast,
                    child: const Text('TRIGGER UNDO TOAST'),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.errorRed,
                      side: const BorderSide(color: AppColors.errorRed),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button)),
                    ),
                    onPressed: () {},
                    icon: const Icon(Icons.delete_forever, color: AppColors.errorRed),
                    label: const Text('DESTRUCTIVE ACTION (COLOR + ICON + LABEL)'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Section 4: Tabular Numbers & Clock
          _buildSectionHeader('4. Tabular Figures & Alarm Displays'),
          _buildCard(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('06:30:00', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white, fontFeatures: [FontFeature.tabularFigures()])),
                    Text('WAKE QUEST ACTIVE', style: TextStyle(fontSize: 11, color: AppColors.accentLime, fontWeight: FontWeight.bold)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.accentLime.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.accentLime),
                  ),
                  child: const Text('Math: Medium', style: TextStyle(color: AppColors.accentLime, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Section 5: Segmented Control & Toggles
          _buildSectionHeader('5. Segmented Controls & Toggles'),
          _buildCard(
            child: Column(
              children: [
                Row(
                  children: ['Today', 'Upcoming', 'All'].asMap().entries.map((entry) {
                    final idx = entry.key;
                    final label = entry.value;
                    final isSel = _selectedSegment == idx;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedSegment = idx),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: isSel ? AppColors.accentLime : AppColors.surface2,
                            borderRadius: BorderRadius.circular(AppRadius.chip),
                          ),
                          child: Center(
                            child: Text(
                              label,
                              style: TextStyle(
                                color: isSel ? AppColors.textOnLime : AppColors.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Strict Alarm Lockout Mode', style: TextStyle(color: Colors.white)),
                    Switch(
                      value: _toggleState,
                      activeColor: AppColors.accentLime,
                      onChanged: (val) => setState(() => _toggleState = val),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title, style: AppTypography.sectionHeader),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface1,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border, width: 1.0),
      ),
      child: child,
    );
  }

  Widget _buildHeatmapCell(String label, Color color) {
    return Column(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppColors.border, width: 0.8),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
      ],
    );
  }
}
