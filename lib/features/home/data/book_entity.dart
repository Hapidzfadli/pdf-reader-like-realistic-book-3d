import 'package:isar/isar.dart';

part 'book_entity.g.dart';

@collection
class BookEntity {
  Id id = Isar.autoIncrement;

  late String title;
  late String author;
  late String filePath;
  String? coverPath;
  
  @Index()
  late DateTime lastRead;
  
  double progress = 0.0; // 0.0 to 1.0
  int totalPages = 0;
  int currentPage = 0;
}
