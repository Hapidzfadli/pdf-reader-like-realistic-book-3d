import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:lumina_pdf_reader/features/home/data/book_entity.dart';
import 'package:lumina_pdf_reader/features/annotations/data/highlight_entity.dart';

final databaseProvider = FutureProvider<Isar>((ref) async {
  final dir = await getApplicationDocumentsDirectory();
  return Isar.open(
    [BookEntitySchema, HighlightEntitySchema],
    directory: dir.path,
  );
});

/// Direct access to Isar instance (throws if not initialized)
final isarProvider = Provider<Isar>((ref) {
  final asyncValue = ref.watch(databaseProvider);
  return asyncValue.maybeWhen(
    data: (isar) => isar,
    orElse: () => throw Exception('Database not initialized'),
  );
});
