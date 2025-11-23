import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lumina_pdf_reader/features/home/data/book_entity.dart';
import 'package:lumina_pdf_reader/features/home/presentation/home_providers.dart';

final bookProvider = FutureProvider.family<BookEntity?, String>((ref, id) async {
  final repo = ref.watch(bookRepositoryProvider);
  return repo.getBook(int.parse(id));
});
