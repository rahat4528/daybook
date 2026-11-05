import 'package:flutter/material.dart';
import '../../core/design/app_tokens.dart';
import '../../domain/services/alarm_health_service.dart';

class AlarmHealthScreen extends StatefulWidget {
  final bool isBangla;
  final AlarmHealthService healthService;
  final DiagnosticReport? initialReport;

  const AlarmHealthScreen({
    super.key,
    this.isBangla = false,
    required this.healthService,
    this.initialReport,
  });

  @override
  State<AlarmHealthScreen> createState() => _AlarmHealthScreenState();
}

class _AlarmHealthScreenState extends State<AlarmHealthScreen> {
  DiagnosticReport? _report;
  bool _isLoading = true;
  int _selectedOemIndex = 0;

  @override
  void initState() {
    super.initState();
    if (widget.initialReport != null) {
      _report = widget.initialReport;
      _isLoading = false;
    } else {
      _refreshReport();
    }
  }

  final List<Map<String, dynamic>> _oemGuides = [
    {
      'name': 'Xiaomi / POCO',
      'bangla': 'শাওমি / পোকো',
      'steps': [
        '১. Security অ্যাপ ওপেন করে Manage Apps > DayBook এ যান।',
        '২. "Autostart" অপশন চালু করুন।',
        '৩. Battery Saver সেটিংসে "No restrictions" নির্বাচন করুন।',
      ],
      'stepsEn': [
        '1. Open Security app > Manage Apps > DayBook.',
        '2. Enable the "Autostart" permission toggle.',
        '3. Under Battery Saver, select "No restrictions".',
      ],
    },
    {
      'name': 'Samsung',
      'bangla': 'স্যামসাং',
      'steps': [
        '১. Settings > Battery and device care > Battery তে যান।',
        '২. Background usage limits > Never sleeping apps এ যান।',
        '৩. DayBook অ্যাপটি তালিকায় যুক্ত করুন।',
      ],
      'stepsEn': [
        '1. Go to Settings > Battery and device care > Battery.',
        '2. Tap "Background usage limits" > "Never sleeping apps".',
        '3. Add DayBook to the never sleeping list.',
      ],
    },
    {
      'name': 'Realme / Oppo',
      'bangla': 'রিয়েলমি / অপ্পো',
      'steps': [
        '১. Settings > Apps > App Management > DayBook এ যান।',
        '২. Battery usage > "Allow background activity" চালু করুন।',
        '৩. "Allow auto-launch" অপশন সক্রিয় করুন।',
      ],
      'stepsEn': [
        '1. Go to Settings > Apps > App Management > DayBook.',
        '2. Tap Battery usage > Enable "Allow background activity".',
        '3. Turn on "Allow auto-launch".',
      ],
    },
    {
      'name': 'Vivo',
      'bangla': 'ভিভো',
      'steps': [
        '১. Settings > Battery > Background power consumption এ যান।',
        '২. DayBook খুঁজে বের করুন।',
        '৩. "Allow high background power consumption" নির্বাচন করুন।',
      ],
      'stepsEn': [
        '1. Open Settings > Battery > Background power consumption.',
        '2. Locate DayBook.',
        '3. Select "Allow high background power consumption".',
      ],
    },
  ];

  Future<void> _refreshReport() async {
    setState(() => _isLoading = true);
    final report = await widget.healthService.runDiagnosticSelfTest();
    if (mounted) {
      setState(() {
        _report = report;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTokens.bg,
      appBar: AppBar(
        backgroundColor: AppTokens.bg,
        elevation: 0,
        title: Text(
          widget.isBangla ? 'অ্যালার্ম স্বাস্থ্য ও ডায়াগনস্টিক' : 'Alarm Health & Diagnostics',
          style: const TextStyle(color: AppTokens.accentLime, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTokens.accentLime),
            onPressed: _refreshReport,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTokens.accentLime))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Overall Reliability Banner
                  _buildReliabilityBanner(),
                  const SizedBox(height: 20),

                  // Diagnostics Checklist
                  Text(
                    widget.isBangla ? 'সিস্টেম অনুমতি ও স্ট্যাটাস' : 'System Permissions & Status',
                    style: const TextStyle(color: AppTokens.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  ..._report!.items.map(_buildDiagnosticCard),

                  const SizedBox(height: 24),

                  // OEM Autostart Guide
                  Text(
                    widget.isBangla ? 'ডিভাইস প্রস্তুতকারক গাইড (OEM Setup)' : 'Manufacturer Autostart Guides',
                    style: const TextStyle(color: AppTokens.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.isBangla
                        ? 'স্মার্টফোনের আক্রমণাত্মক ব্যাটারি সেভার বন্ধ করতে নিচের ধাপগুলো অনুসরণ করুন।'
                        : 'Prevent aggressive OEM task killers from delaying your wake alarms.',
                    style: const TextStyle(color: AppTokens.textSecondary, fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  _buildOemSelector(),
                  const SizedBox(height: 12),
                  _buildOemGuideDetails(),
                ],
              ),
            ),
    );
  }

  Widget _buildReliabilityBanner() {
    final isGood = _report?.isFullyCompliant ?? false;
    final color = isGood ? AppTokens.accentLime : AppTokens.errorRed;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTokens.surface1,
        borderRadius: BorderRadius.circular(AppTokens.radiusCard),
        border: Border.all(color: color),
      ),
      child: Row(
        children: [
          Icon(isGood ? Icons.verified_user : Icons.warning_amber_rounded, color: color, size: 36),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isGood
                      ? (widget.isBangla ? '১০০% নির্ভরযোগ্য ও প্রস্তুত' : '100% Reliable & Fully Compliant')
                      : (widget.isBangla ? 'কিছু অনুমতি বাকি রয়েছে' : 'Configuration Attention Needed'),
                  style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.isBangla
                      ? 'ডজ মোড এবং রিবুট প্রতিরোধী অ্যালার্ম নিশ্চিত করা হয়েছে।'
                      : 'Alarms survive deep Doze, OEM power killers, and system reboots.',
                  style: const TextStyle(color: AppTokens.textSecondary, fontSize: 11.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiagnosticCard(DiagnosticItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTokens.surface1,
        borderRadius: BorderRadius.circular(AppTokens.radiusCard),
        border: Border.all(color: item.isHealthy ? AppTokens.border : AppTokens.errorRed.withValues(alpha: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            item.isHealthy ? Icons.check_circle : Icons.error_outline,
            color: item.isHealthy ? AppTokens.accentLime : AppTokens.errorRed,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.isBangla ? item.titleBangla : item.titleEnglish,
                  style: const TextStyle(color: AppTokens.textPrimary, fontWeight: FontWeight.bold, fontSize: 13.5),
                ),
                const SizedBox(height: 3),
                Text(
                  widget.isBangla ? item.detailsBangla : item.detailsEnglish,
                  style: const TextStyle(color: AppTokens.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          if (!item.isHealthy)
            TextButton(
              style: TextButton.styleFrom(foregroundColor: AppTokens.accentLime),
              onPressed: () {
                if (item.titleEnglish.contains('Exact')) {
                  widget.healthService.requestExactAlarmPermission();
                } else {
                  widget.healthService.requestIgnoreBatteryOptimization();
                }
              },
              child: Text(
                widget.isBangla ? item.actionLabelBangla : item.actionLabelEnglish,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOemSelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(_oemGuides.length, (index) {
          final isSelected = index == _selectedOemIndex;
          final oem = _oemGuides[index];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              selected: isSelected,
              label: Text(widget.isBangla ? oem['bangla'] as String : oem['name'] as String),
              selectedColor: AppTokens.accentLime,
              backgroundColor: AppTokens.surface2,
              labelStyle: TextStyle(
                color: isSelected ? Colors.black : AppTokens.textPrimary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              side: BorderSide(color: isSelected ? AppTokens.accentLime : AppTokens.border),
              onSelected: (_) => setState(() => _selectedOemIndex = index),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildOemGuideDetails() {
    final oem = _oemGuides[_selectedOemIndex];
    final steps = widget.isBangla ? (oem['steps'] as List<String>) : (oem['stepsEn'] as List<String>);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTokens.surface2,
        borderRadius: BorderRadius.circular(AppTokens.radiusCard),
        border: Border.all(color: AppTokens.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.isBangla ? '${oem['bangla']} কনফিগারেশন' : '${oem['name']} Optimization Guide',
                style: const TextStyle(color: AppTokens.accentLime, fontWeight: FontWeight.bold, fontSize: 14),
              ),
              IconButton(
                icon: const Icon(Icons.open_in_new, color: AppTokens.accentLime, size: 18),
                tooltip: widget.isBangla ? 'সেটিংস ওপেন করুন' : 'Open OEM Settings',
                onPressed: () => widget.healthService.openOemAutostartSettings(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...steps.map(
            (s) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                s,
                style: const TextStyle(color: AppTokens.textPrimary, fontSize: 13, height: 1.4),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTokens.accentLime,
                side: const BorderSide(color: AppTokens.accentLime),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.settings, size: 16),
              label: Text(widget.isBangla ? 'ডিভাইস সেটিংস খুলুন' : 'Open System App Settings'),
              onPressed: () => widget.healthService.openOemAutostartSettings(),
            ),
          ),
        ],
      ),
    );
  }
}
