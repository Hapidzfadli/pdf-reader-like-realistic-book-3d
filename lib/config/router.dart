import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:lumina_pdf_reader/features/home/presentation/home_screen.dart';
import 'package:lumina_pdf_reader/features/reader/presentation/reader_screen.dart';
import 'package:lumina_pdf_reader/features/settings/presentation/settings_screen.dart';

import 'package:lumina_pdf_reader/features/splash/presentation/splash_screen.dart';

final router = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/reader/:bookId',
      builder: (context, state) {
        final bookId = state.pathParameters['bookId']!;
        return ReaderScreen(bookId: bookId);
      },
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
  ],
);
