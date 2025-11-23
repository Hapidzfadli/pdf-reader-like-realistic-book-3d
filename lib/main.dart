import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lumina_pdf_reader/config/router.dart';
import 'package:lumina_pdf_reader/core/theme/app_theme.dart';

void main() {
  runApp(const ProviderScope(child: LuminaApp()));
}

class LuminaApp extends StatelessWidget {
  const LuminaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Zenith PDF',
      theme: AppTheme.darkTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
