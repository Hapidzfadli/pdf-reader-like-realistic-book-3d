import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:lumina_pdf_reader/features/home/data/book_entity.dart';

final databaseProvider = FutureProvider<Isar>((ref) async {
  final dir = await getApplicationDocumentsDirectory();
  return Isar.open(
    [BookEntitySchema],
    directory: dir.path,
  );
});
