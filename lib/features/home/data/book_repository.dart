import 'package:isar/isar.dart';
import 'package:lumina_pdf_reader/features/home/data/book_entity.dart';

class BookRepository {
  final Isar _isar;

  BookRepository(this._isar);

  Future<List<BookEntity>> getAllBooks() async {
    return _isar.bookEntitys.where().findAll();
  }

  Future<List<BookEntity>> getRecentBooks() async {
    return _isar.bookEntitys.where().sortByLastReadDesc().limit(5).findAll();
  }

  Future<void> addBook(BookEntity book) async {
    await _isar.writeTxn(() async {
      await _isar.bookEntitys.put(book);
    });
  }
  
  Future<BookEntity?> getBook(int id) async {
    return _isar.bookEntitys.get(id);
  }

  Future<void> updateProgress(int id, int currentPage, int totalPages) async {
    await _isar.writeTxn(() async {
      final book = await _isar.bookEntitys.get(id);
      if (book != null) {
        book.currentPage = currentPage;
        book.totalPages = totalPages;
        book.progress = totalPages > 0 ? currentPage / totalPages : 0.0;
        book.lastRead = DateTime.now();
        await _isar.bookEntitys.put(book);
      }
    });
  }
}
