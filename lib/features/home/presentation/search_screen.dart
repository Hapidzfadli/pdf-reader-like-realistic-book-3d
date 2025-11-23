import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:lumina_pdf_reader/features/home/presentation/home_providers.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final allBooksAsync = ref.watch(allBooksProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _query = value),
                style: GoogleFonts.inter(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search books...',
                  hintStyle: GoogleFonts.inter(color: Colors.white54),
                  prefixIcon: const Icon(LucideIcons.search, color: Colors.white54),
                  filled: true,
                  fillColor: const Color(0xFF1E293B),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            Expanded(
              child: allBooksAsync.when(
                data: (books) {
                  final filteredBooks = books.where((book) {
                    return book.title.toLowerCase().contains(_query.toLowerCase()) ||
                        book.author.toLowerCase().contains(_query.toLowerCase());
                  }).toList();

                  if (filteredBooks.isEmpty) {
                    return Center(
                      child: Text(
                        _query.isEmpty ? 'Start typing to search' : 'No books found',
                        style: GoogleFonts.inter(color: Colors.white54),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: filteredBooks.length,
                    itemBuilder: (context, index) {
                      final book = filteredBooks[index];
                      return ListTile(
                        leading: const Icon(LucideIcons.book, color: Colors.white),
                        title: Text(book.title, style: GoogleFonts.inter(color: Colors.white)),
                        subtitle: Text(book.author, style: GoogleFonts.inter(color: Colors.white54)),
                        onTap: () => context.push('/reader/${book.id}'),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, s) => Center(child: Text('Error: $e')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
