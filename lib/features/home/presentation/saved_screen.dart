import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

class SavedScreen extends StatelessWidget {
  const SavedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Saved Books', style: GoogleFonts.outfit()),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(LucideIcons.bookmark, size: 64, color: Colors.white24),
            const SizedBox(height: 16),
            Text(
              'No saved books yet',
              style: GoogleFonts.inter(color: Colors.white54),
            ),
          ],
        ),
      ),
    );
  }
}
