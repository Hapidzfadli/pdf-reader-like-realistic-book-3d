import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings', style: GoogleFonts.outfit()),
      ),
      body: ListView(
        children: [
          _SectionHeader(title: 'Appearance'),
          ListTile(
            leading: const Icon(LucideIcons.moon),
            title: const Text('Dark Mode'),
            trailing: Switch(value: true, onChanged: (val) {}),
          ),
          ListTile(
            leading: const Icon(LucideIcons.type),
            title: const Text('Font Size'),
            subtitle: const Text('Medium'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          
          _SectionHeader(title: 'Reading'),
          ListTile(
            leading: const Icon(LucideIcons.moveHorizontal),
            title: const Text('Page Transition'),
            subtitle: const Text('Flip Effect'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          
          _SectionHeader(title: 'About'),
          ListTile(
            leading: const Icon(LucideIcons.info),
            title: const Text('Version'),
            trailing: const Text('1.0.0'),
          ),
          ListTile(
            leading: const Icon(LucideIcons.github),
            title: const Text('Open Source License'),
            onTap: () {
              showLicensePage(context: context);
            },
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
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: GoogleFonts.inter(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
    );
  }
}
