import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lumina_pdf_reader/core/providers/database_provider.dart';
import 'package:lumina_pdf_reader/features/home/data/book_entity.dart';
import 'package:lumina_pdf_reader/features/home/data/book_repository.dart';

final bookRepositoryProvider = Provider<BookRepository>((ref) {
  final isar = ref.watch(databaseProvider).valueOrNull;
  if (isar == null) throw UnimplementedError('Database not initialized');
  return BookRepository(isar);
});

final allBooksProvider = FutureProvider<List<BookEntity>>((ref) async {
  final db = ref.watch(databaseProvider);
  if (db.isLoading) return [];
  final repo = ref.watch(bookRepositoryProvider);
  return repo.getAllBooks();
});

final recentBooksProvider = FutureProvider<List<BookEntity>>((ref) async {
  final db = ref.watch(databaseProvider);
  if (db.isLoading) return [];
  final repo = ref.watch(bookRepositoryProvider);
  return repo.getRecentBooks();
});
