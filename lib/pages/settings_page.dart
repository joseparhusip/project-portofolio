// settings_page.dart (FULL & CORRECTED CODE)

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../models/user_model.dart';
import '../api/api_service.dart';
import 'signin_page.dart';

class SettingsPage extends StatefulWidget {
  final User user;
  const SettingsPage({super.key, required this.user});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final ApiService _apiService = ApiService();
  bool _isDeleting = false;

  Future<void> _handleDeleteAccount() async {
    Navigator.of(context).pop(); // Close the confirmation dialog
    if (_isDeleting) return;

    setState(() {
      _isDeleting = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(width: 16),
            Text('Deleting account...'),
          ],
        ),
        duration: Duration(days: 1),
      ),
    );

    final result = await _apiService.deleteAccount(
      userId: widget.user.userId,
      authToken: widget.user.authToken,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    if (result['status'] == 'success') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Account deleted successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const SignInPage()),
        (Route<dynamic> route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Failed to delete account.'),
          backgroundColor: Colors.red,
        ),
      );
    }

    if (mounted) {
      setState(() {
        _isDeleting = false;
      });
    }
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
            'Are you sure you want to delete your account permanently? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _isDeleting ? null : _handleDeleteAccount,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
            ),
            child: const Text('Yes, Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Appearance'),
            _buildSettingsCard(
              children: [
                _buildSwitchTile(
                  icon: Icons.dark_mode,
                  iconColor: Colors.purple,
                  title: 'Dark Mode',
                  subtitle: 'Enable dark theme for eye comfort',
                  value: themeProvider.isDarkMode,
                  onChanged: (value) {
                    Provider.of<ThemeProvider>(context, listen: false)
                        .toggleTheme(value);
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('Account'),
            _buildSettingsCard(
              children: [
                _buildNavigationTile(
                  icon: Icons.lock,
                  iconColor: Colors.blueAccent,
                  title: 'Change Password',
                  onTap: () => _showFeatureNotAvailable(),
                ),
                const Divider(height: 1),
                _buildNavigationTile(
                  icon: Icons.delete_forever,
                  iconColor: Colors.red.shade700,
                  title: 'Delete Account',
                  isDestructive: true,
                  onTap: _showDeleteConfirmation,
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('More'),
            _buildSettingsCard(
              children: [
                _buildNavigationTile(
                  icon: Icons.info,
                  iconColor: Colors.teal,
                  title: 'About App',
                  onTap: () => _showAboutDialog(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: Colors.grey[600],
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildSettingsCard({required List<Widget> children}) {
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withAlpha(26),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: EdgeInsets.zero,
      child: Column(children: children),
    );
  }

  Widget _buildSwitchTile(
      {required IconData icon,
      required Color iconColor,
      required String title,
      required String subtitle,
      required bool value,
      required ValueChanged<bool> onChanged}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withAlpha(26),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: iconColor),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle,
          style: TextStyle(color: Colors.grey[600], fontSize: 12)),
      trailing: CupertinoSwitch(
        value: value,
        onChanged: onChanged,
        activeTrackColor: const Color(0xFF36067e),
      ),
    );
  }

  Widget _buildNavigationTile(
      {required IconData icon,
      required Color iconColor,
      required String title,
      Widget? trailing,
      bool isDestructive = false,
      required VoidCallback onTap}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withAlpha(26),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: iconColor),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: isDestructive
              ? Colors.red.shade700
              : Theme.of(context).textTheme.bodyLarge?.color,
        ),
      ),
      trailing: trailing ?? const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }

  void _showFeatureNotAvailable() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('This feature is not available yet.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AboutDialog(
        applicationName: 'Trivo',
        applicationVersion: '1.0.0',
        applicationLegalese: '© 2025 Trivo Team',
        // [CHANGE] Image moved to applicationIcon for better layout
        applicationIcon: SizedBox(
          width: 80,
          height: 80,
          child: Image.asset('assets/trivo.jpg', fit: BoxFit.contain),
        ),
        children: const [
          SizedBox(height: 16),
          Text('Developed by:'),
          SizedBox(height: 8),
          Text('Sri Nuryani Pujiastuti'),
          Text('Jose Elio Parhusip'),
          SizedBox(height: 8),
          Text('S1 Digital Business'),
          Text('International Logistics and Business University'),
        ],
      ),
    );
  }
}
