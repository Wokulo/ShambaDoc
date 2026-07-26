import 'package:flutter/material.dart';
import 'package:shambadoc/app/theme.dart';
// import 'package:shambadoc/services/auth_service.dart';
import 'package:shambadoc/services/storage_service.dart';

class SettingsScreen extends StatefulWidget {
  final bool embedded;
  const SettingsScreen({super.key, this.embedded = false});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _language = 'en';
  bool _offlineMode = true;
  bool _notifications = true;

  @override
  void initState() {
    super.initState();
    _language = StorageService().getLanguage();
    _offlineMode = StorageService().getOfflineMode();
  }

  @override
  Widget build(BuildContext context) {
    dynamic user; try { user = null; } catch(e) { user = null; }

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: widget.embedded ? null : AppBar(title: const Text('Settings')),
      body: ListView(
        padding: EdgeInsets.only(
          top: widget.embedded
              ? MediaQuery.of(context).padding.top
              : 0,
          bottom: 40,
        ),
        children: [
          // Embedded header
          if (widget.embedded)
            Container(
              color: AppColors.primary,
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 8,
                left: 16, right: 16, bottom: 12,
              ),
              child: const Align(
                alignment: Alignment.centerLeft,
                child: Text('Settings',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700,
                      color: Colors.white)),
              ),
            ),

          // Profile card
          _SectionCard(children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                Container(
                  width: 52, height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person_rounded,
                      color: AppColors.primary, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.phoneNumber ?? 'Guest Farmer',
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user != null ? 'Verified via Firebase' : 'Not signed in',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                )),
                if (user != null)
                  const Icon(Icons.verified_rounded,
                      color: AppColors.info, size: 20),
              ]),
            ),
          ]),

          _SectionHeader(title: 'Preferences'),
          _SectionCard(children: [
            // Language
            ListTile(
              leading: const _LeadIcon(
                  icon: Icons.language_rounded, color: AppColors.info),
              title: const Text('Language / Lugha'),
              subtitle: Text(_language == 'sw' ? 'Kiswahili' : 'English'),
              trailing: DropdownButton<String>(
                value: _language,
                underline: const SizedBox(),
                borderRadius: BorderRadius.circular(12),
                items: const [
                  DropdownMenuItem(value: 'en', child: Text('English')),
                  DropdownMenuItem(value: 'sw', child: Text('Kiswahili')),
                ],
                onChanged: (val) async {
                  if (val == null) return;
                  await StorageService().setLanguage(val);
                  setState(() => _language = val);
                },
              ),
            ),
            const Divider(indent: 56),

            // Offline mode
            SwitchListTile(
              secondary: const _LeadIcon(
                  icon: Icons.offline_bolt_rounded,
                  color: AppColors.primary),
              title: const Text('Offline-First Mode'),
              subtitle: const Text('Use on-device AI without internet'),
              value: _offlineMode,
              activeColor: AppColors.primary,
              onChanged: (val) async {
                await StorageService().setOfflineMode(val);
                setState(() => _offlineMode = val);
              },
            ),
            const Divider(indent: 56),

            // Notifications
            SwitchListTile(
              secondary: const _LeadIcon(
                  icon: Icons.notifications_rounded,
                  color: AppColors.warning),
              title: const Text('Disease Alerts'),
              subtitle: const Text('Regional outbreak notifications'),
              value: _notifications,
              activeColor: AppColors.primary,
              onChanged: (val) => setState(() => _notifications = val),
            ),
          ]),

          _SectionHeader(title: 'About'),
          _SectionCard(children: [
            ListTile(
              leading: const _LeadIcon(
                  icon: Icons.info_rounded, color: AppColors.primary),
              title: const Text('About ShambaDoc'),
              subtitle: const Text('Version 1.0.0 • Campus Spark 2026'),
              trailing: const Icon(Icons.chevron_right_rounded,
                  color: AppColors.textSecondary),
              onTap: () => _showAbout(context),
            ),
            const Divider(indent: 56),
            ListTile(
              leading: const _LeadIcon(
                  icon: Icons.privacy_tip_rounded,
                  color: AppColors.textSecondary),
              title: const Text('Privacy Policy'),
              trailing: const Icon(Icons.open_in_new_rounded,
                  size: 16, color: AppColors.textSecondary),
              onTap: () {},
            ),
            const Divider(indent: 56),
            ListTile(
              leading: const _LeadIcon(
                  icon: Icons.help_rounded, color: AppColors.textSecondary),
              title: const Text('Help & Support'),
              trailing: const Icon(Icons.chevron_right_rounded,
                  color: AppColors.textSecondary),
              onTap: () {},
            ),
          ]),

          // Sign out
          if (null != null) ...[
            _SectionHeader(title: 'Account'),
            _SectionCard(children: [
              ListTile(
                leading: const _LeadIcon(
                    icon: Icons.logout_rounded, color: AppColors.error),
                title: const Text('Sign Out',
                    style: TextStyle(color: AppColors.error,
                        fontWeight: FontWeight.w600)),
                onTap: () {},  // signout disabled
              ),
            ]),
          ],
        ],
      ),
    );
  }

  void _showAbout(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          const Icon(Icons.eco_rounded, color: AppColors.primary),
          const SizedBox(width: 8),
          const Text('ShambaDoc'),
        ]),
        content: const Text(
          'AI-Powered Crop Disease Diagnosis for Kenyan Smallholder Farmers.\n\n'
          'Version 1.0.0\nCampus Spark Innovation Challenge 2026\n\n'
          'Built by Nicholas Matata & Willis Otieno.',
          style: TextStyle(height: 1.5),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _confirmSignOut(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              // await null.signOut();
              if (context.mounted) setState(() {});
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
    child: Text(title.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppColors.textSecondary,
        letterSpacing: 1.1,
      )),
  );
}

class _SectionCard extends StatelessWidget {
  final List<Widget> children;
  const _SectionCard({required this.children});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: const Border.fromBorderSide(
            BorderSide(color: AppColors.divider)),
      ),
      child: Column(children: children),
    ),
  );
}

class _LeadIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  const _LeadIcon({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    width: 34, height: 34,
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Icon(icon, color: color, size: 18),
  );
}
