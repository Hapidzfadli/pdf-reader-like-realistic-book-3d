import 'package:isar/isar.dart';
import 'package:lumina_pdf_reader/features/annotations/data/highlight_entity.dart';

class HighlightRepository {
  final Isar _isar;

  HighlightRepository(this._isar);

  /// Ambil semua highlights untuk satu buku
  Future<List<HighlightEntity>> getHighlightsByBook(int bookId) async {
    return _isar.highlightEntitys
        .where()
        .bookIdEqualTo(bookId)
        .sortByPageNumber()
        .findAll();
  }

  /// Ambil highlights untuk halaman tertentu
  Future<List<HighlightEntity>> getHighlightsByPage(int bookId, int pageNumber) async {
    return _isar.highlightEntitys
        .where()
        .bookIdEqualTo(bookId)
        .filter()
        .pageNumberEqualTo(pageNumber)
        .findAll();
  }

  /// Tambah highlight baru
  Future<int> addHighlight(HighlightEntity highlight) async {
    return _isar.writeTxn(() async {
      return _isar.highlightEntitys.put(highlight);
    });
  }

  /// Update highlight
  Future<void> updateHighlight(HighlightEntity highlight) async {
    highlight.updatedAt = DateTime.now();
    await _isar.writeTxn(() async {
      await _isar.highlightEntitys.put(highlight);
    });
  }

  /// Hapus highlight
  Future<bool> deleteHighlight(int id) async {
    return _isar.writeTxn(() async {
      return _isar.highlightEntitys.delete(id);
    });
  }

  /// Hapus semua highlights untuk satu buku
  Future<int> deleteAllHighlightsByBook(int bookId) async {
    return _isar.writeTxn(() async {
      return _isar.highlightEntitys
          .where()
          .bookIdEqualTo(bookId)
          .deleteAll();
    });
  }

  /// Cari highlights berdasarkan teks
  Future<List<HighlightEntity>> searchHighlights(int bookId, String query) async {
    return _isar.highlightEntitys
        .where()
        .bookIdEqualTo(bookId)
        .filter()
        .selectedTextContains(query, caseSensitive: false)
        .findAll();
  }

  /// Hitung jumlah highlights per buku
  Future<int> countHighlightsByBook(int bookId) async {
    return _isar.highlightEntitys
        .where()
        .bookIdEqualTo(bookId)
        .count();
  }

  /// Ambil highlight berdasarkan ID
  Future<HighlightEntity?> getHighlightById(int id) async {
    return _isar.highlightEntitys.get(id);
  }

  /// Update warna highlight
  Future<void> updateHighlightColor(int id, HighlightColor color) async {
    await _isar.writeTxn(() async {
      final highlight = await _isar.highlightEntitys.get(id);
      if (highlight != null) {
        highlight.color = color;
        highlight.updatedAt = DateTime.now();
        await _isar.highlightEntitys.put(highlight);
      }
    });
  }

  /// Update note content
  Future<void> updateNoteContent(int id, String? noteContent) async {
    await _isar.writeTxn(() async {
      final highlight = await _isar.highlightEntitys.get(id);
      if (highlight != null) {
        highlight.noteContent = noteContent;
        highlight.updatedAt = DateTime.now();
        await _isar.highlightEntitys.put(highlight);
      }
    });
  }
}
