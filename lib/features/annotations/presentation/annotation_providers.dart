import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lumina_pdf_reader/core/providers/database_provider.dart';
import 'package:lumina_pdf_reader/features/annotations/data/highlight_entity.dart';
import 'package:lumina_pdf_reader/features/annotations/data/highlight_repository.dart';

/// Provider untuk HighlightRepository
final highlightRepositoryProvider = Provider<HighlightRepository>((ref) {
  final isar = ref.watch(isarProvider);
  return HighlightRepository(isar);
});

/// Provider untuk semua highlights dalam satu buku
final bookHighlightsProvider = FutureProvider.family<List<HighlightEntity>, int>((ref, bookId) async {
  final repo = ref.watch(highlightRepositoryProvider);
  return repo.getHighlightsByBook(bookId);
});

/// Provider untuk highlights di halaman tertentu
final pageHighlightsProvider = FutureProvider.family<List<HighlightEntity>, ({int bookId, int pageNumber})>((ref, params) async {
  final repo = ref.watch(highlightRepositoryProvider);
  return repo.getHighlightsByPage(params.bookId, params.pageNumber);
});

/// State untuk mode annotation (selection mode)
class AnnotationModeState {
  final bool isEnabled;
  final HighlightColor selectedColor;
  final HighlightType selectedType;
  final Rect? selectionRect;
  final bool isSelecting;

  const AnnotationModeState({
    this.isEnabled = false,
    this.selectedColor = HighlightColor.yellow,
    this.selectedType = HighlightType.highlight,
    this.selectionRect,
    this.isSelecting = false,
  });

  AnnotationModeState copyWith({
    bool? isEnabled,
    HighlightColor? selectedColor,
    HighlightType? selectedType,
    Rect? selectionRect,
    bool? isSelecting,
    bool clearSelection = false,
  }) {
    return AnnotationModeState(
      isEnabled: isEnabled ?? this.isEnabled,
      selectedColor: selectedColor ?? this.selectedColor,
      selectedType: selectedType ?? this.selectedType,
      selectionRect: clearSelection ? null : (selectionRect ?? this.selectionRect),
      isSelecting: isSelecting ?? this.isSelecting,
    );
  }
}

/// Notifier untuk annotation mode
class AnnotationModeNotifier extends StateNotifier<AnnotationModeState> {
  AnnotationModeNotifier() : super(const AnnotationModeState());

  void toggleAnnotationMode() {
    state = state.copyWith(
      isEnabled: !state.isEnabled,
      clearSelection: true,
      isSelecting: false,
    );
  }

  void enableAnnotationMode() {
    state = state.copyWith(isEnabled: true);
  }

  void disableAnnotationMode() {
    state = state.copyWith(
      isEnabled: false,
      clearSelection: true,
      isSelecting: false,
    );
  }

  void setSelectedColor(HighlightColor color) {
    state = state.copyWith(selectedColor: color);
  }

  void setSelectedType(HighlightType type) {
    state = state.copyWith(selectedType: type);
  }

  void startSelection() {
    state = state.copyWith(isSelecting: true);
  }

  void updateSelection(Rect rect) {
    state = state.copyWith(selectionRect: rect);
  }

  void clearSelection() {
    state = state.copyWith(clearSelection: true, isSelecting: false);
  }

  void endSelection() {
    state = state.copyWith(isSelecting: false);
  }
}

/// Provider untuk annotation mode state
final annotationModeProvider = StateNotifierProvider<AnnotationModeNotifier, AnnotationModeState>((ref) {
  return AnnotationModeNotifier();
});

/// Provider untuk selected highlight (untuk edit/delete)
final selectedHighlightProvider = StateProvider<HighlightEntity?>((ref) => null);

/// Provider untuk jumlah highlights per buku
final highlightCountProvider = FutureProvider.family<int, int>((ref, bookId) async {
  final repo = ref.watch(highlightRepositoryProvider);
  return repo.countHighlightsByBook(bookId);
});
