import 'package:isar/isar.dart';

part 'highlight_entity.g.dart';

/// Enum untuk tipe highlight
enum HighlightType {
  highlight,
  underline,
  strikethrough,
  note,
}

/// Enum untuk warna highlight
enum HighlightColor {
  yellow,
  red,
  green,
  blue,
  purple,
  orange,
}

extension HighlightColorExtension on HighlightColor {
  int get colorValue {
    switch (this) {
      case HighlightColor.yellow:
        return 0xFFFFEB3B;
      case HighlightColor.red:
        return 0xFFEF5350;
      case HighlightColor.green:
        return 0xFF66BB6A;
      case HighlightColor.blue:
        return 0xFF42A5F5;
      case HighlightColor.purple:
        return 0xFFAB47BC;
      case HighlightColor.orange:
        return 0xFFFF7043;
    }
  }

  double get opacity {
    switch (this) {
      case HighlightColor.yellow:
      case HighlightColor.green:
      case HighlightColor.orange:
        return 0.4;
      case HighlightColor.red:
      case HighlightColor.blue:
      case HighlightColor.purple:
        return 0.35;
    }
  }
}

@collection
class HighlightEntity {
  Id id = Isar.autoIncrement;

  /// ID buku yang di-highlight
  @Index()
  late int bookId;

  /// Halaman PDF (1-indexed)
  @Index()
  late int pageNumber;

  /// Teks yang di-highlight (untuk display/search)
  late String selectedText;

  /// Tipe highlight (highlight, underline, strikethrough, note)
  @Enumerated(EnumType.name)
  late HighlightType type;

  /// Warna highlight
  @Enumerated(EnumType.name)
  late HighlightColor color;

  /// Koordinat relatif (0.0 - 1.0) untuk posisi highlight
  /// Format: [x1, y1, x2, y2] sebagai persentase dari ukuran halaman
  late List<double> relativeRect;

  /// Catatan opsional untuk tipe 'note'
  String? noteContent;

  /// Timestamp
  late DateTime createdAt;
  DateTime? updatedAt;

  /// Helper untuk mendapatkan Rect dari relativeRect
  /// Perlu dikali dengan ukuran halaman aktual saat render
  List<double> get rectValues => relativeRect;

  /// Composite index untuk query cepat per buku dan halaman
  @Index(composite: [CompositeIndex('pageNumber')])
  int get bookPageIndex => bookId;
}
