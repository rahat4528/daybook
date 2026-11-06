import 'package:flutter/material.dart';
import '../../data/app_repository.dart';
import 'money_screen.dart';
import 'people_screen.dart';

class SettingsScreen extends StatelessWidget {
  final AppRepository repository;

  const SettingsScreen({super.key, required this.repository});

  void _showBatteryGuide(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.battery_alert, color: Color(0xFFEF4444)),
              SizedBox(width: 8),
              Text('Battery Saver Whitelist'),
            ],
          ),
          content: const SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'To ensure your Smart Alarms ring on time without being killed by Android manufacturer battery cleaners:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                SizedBox(height: 12),
                Text('• Xiaomi (MIUI / HyperOS): Enable "Autostart" in Security app and set Battery Saver to "No restrictions".'),
                SizedBox(height: 8),
                Text('• Samsung (One UI): Add Daybook to "Never Sleeping Apps" in Device Care > Battery.'),
                SizedBox(height: 8),
                Text('• Oppo / Realme (ColorOS): Allow background activity and turn off "Deep Optimisation".'),
                SizedBox(height: 8),
                Text('• Vivo (Funtouch OS): Enable "High background power consumption" in App Management.'),
                SizedBox(height: 12),
                Text(
                  'Daybook uses Android\'s setAlarmClock() API which is exempt from Doze, but OEM task killers must be configured.',
                  style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.grey),
                ),
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Understood'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings & Device Sync', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Language Card
          ListTile(
            tileColor: isDark ? const Color(0xFF1E293B) : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            leading: const Icon(Icons.language, color: Color(0xFF6366F1)),
            title: const Text('App Language (ভাষা)'),
            subtitle: Text(repository.isBangla ? 'বাংলা (Bangla)' : 'English'),
            trailing: Switch(
              value: repository.isBangla,
              activeColor: const Color(0xFF6366F1),
              onChanged: (_) => repository.toggleLanguage(),
            ),
          ),
          const SizedBox(height: 12),
          // Theme Card
          ListTile(
            tileColor: isDark ? const Color(0xFF1E293B) : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            leading: const Icon(Icons.palette_outlined, color: Color(0xFFF59E0B)),
            title: const Text('Display Appearance'),
            subtitle: Text(repository.themeMode.name.toUpperCase()),
            trailing: DropdownButton<ThemeMode>(
              value: repository.themeMode,
              underline: const SizedBox(),
              items: const [
                DropdownMenuItem(value: ThemeMode.system, child: Text('System')),
                DropdownMenuItem(value: ThemeMode.light, child: Text('Light')),
                DropdownMenuItem(value: ThemeMode.dark, child: Text('Dark')),
              ],
              onChanged: (val) {
                if (val != null) repository.setThemeMode(val);
              },
            ),
          ),
          const SizedBox(height: 12),
          // Money & Dhar
          ListTile(
            tileColor: isDark ? const Color(0xFF1E293B) : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            leading: const Icon(Icons.account_balance_wallet_outlined, color: Color(0xFF10B981)),
            title: const Text('Money & Dhar Ledger'),
            subtitle: const Text('Track BDT transactions, accounts, and loan balances'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => MoneyScreen(
                    isBangla: repository.isBangla,
                    moneyService: repository.moneyService,
                    dharService: repository.dharService,
                    entriesRepo: repository.entriesRepository,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          // People & Circles
          ListTile(
            tileColor: isDark ? const Color(0xFF1E293B) : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            leading: const Icon(Icons.people_outline, color: Color(0xFF38BDF8)),
            title: const Text('People & Circles CRM'),
            subtitle: const Text('Keep-in-touch cadence and birthday reminders'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => PeopleScreen(
                    isBangla: repository.isBangla,
                    peopleService: repository.peopleService,
                    dharService: repository.dharService,
                    entriesRepo: repository.entriesRepository,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          // Battery Killers Onboarding Guide
          ListTile(
            tileColor: isDark ? const Color(0xFF1E293B) : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            leading: const Icon(Icons.battery_charging_full, color: Color(0xFF10B981)),
            title: const Text('Alarm Reliability Guide'),
            subtitle: const Text('Configure OEM background battery permissions'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showBatteryGuide(context),
          ),
          const SizedBox(height: 12),
          // About Daybook
          ListTile(
            tileColor: isDark ? const Color(0xFF1E293B) : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            leading: const Icon(Icons.info_outline, color: Color(0xFF8B5CF6)),
            title: const Text('About Daybook'),
            subtitle: const Text('v1.0.0 • Offline-First Personal OS'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'Daybook',
                applicationVersion: '1.0.0',
                applicationLegalese: '© 2026 Mahamudol Hasan Rahat. All rights reserved.',
                children: const [
                  SizedBox(height: 12),
                  Text('Daybook combines Eisenhower task prioritization, deterministic daily time-blocking, challenge-based smart alarms, and dynamic weather sky simulations into an offline-first companion.'),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

