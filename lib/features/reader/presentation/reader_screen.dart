import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:page_flip/page_flip.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:lumina_pdf_reader/features/home/presentation/home_providers.dart';
import 'package:lumina_pdf_reader/features/reader/presentation/reader_controller.dart';
import 'package:lumina_pdf_reader/features/annotations/data/highlight_entity.dart';
import 'package:lumina_pdf_reader/features/annotations/presentation/annotation_providers.dart';
import 'package:lumina_pdf_reader/features/annotations/widgets/annotation_toolbar.dart';
import 'package:lumina_pdf_reader/features/annotations/widgets/highlight_overlay.dart';

class ReaderScreen extends ConsumerStatefulWidget {
  final String bookId;
  const ReaderScreen({super.key, required this.bookId});

  @override
  ConsumerState<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends ConsumerState<ReaderScreen> {
  final _flipKey = GlobalKey<PageFlipWidgetState>();
  bool _showControls = true;
  int _totalPages = 0;
  int _currentPage = 0;
  bool _hasInitialized = false;
  bool _hasNavigatedToSavedPage = false;

  // Annotation state
  Offset? _selectionStart;
  Offset? _selectionEnd;
  Rect? _selectionRect;
  Size _pageSize = Size.zero;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.invalidate(bookProvider(widget.bookId));
    });
  }

  @override
  void dispose() {
    // Reset annotation mode when leaving
    ref.read(annotationModeProvider.notifier).disableAnnotationMode();
    super.dispose();
  }

  void _toggleControls() {
    final annotationMode = ref.read(annotationModeProvider);
    if (!annotationMode.isEnabled) {
      setState(() => _showControls = !_showControls);
    }
  }

  void _initializePages(int documentPages, int savedCurrentPage) {
    if (!_hasInitialized && documentPages > 0) {
      _hasInitialized = true;
      final maxPage = documentPages - 1;
      final targetPage = savedCurrentPage.clamp(0, maxPage);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _totalPages = documentPages;
            _currentPage = targetPage;
          });
        }
      });
    }

    if (!_hasNavigatedToSavedPage && _hasInitialized && savedCurrentPage > 0) {
      _hasNavigatedToSavedPage = true;
      final maxPage = documentPages - 1;
      final targetPage = savedCurrentPage.clamp(0, maxPage);

      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted && _flipKey.currentState != null) {
          _flipKey.currentState!.goToPage(targetPage);
          setState(() => _currentPage = targetPage);
        }
      });
    }
  }

  Future<void> _saveProgress() async {
    final bookId = int.tryParse(widget.bookId) ?? -1;
    if (_totalPages > 0 && bookId != -1) {
      await ref.read(bookRepositoryProvider).updateProgress(
        bookId,
        _currentPage,
        _totalPages,
      );
    }
  }

  Future<bool> _handleExit() async {
    await _saveProgress();
    ref.invalidate(recentBooksProvider);
    ref.invalidate(allBooksProvider);
    ref.invalidate(bookProvider(widget.bookId));
    return true;
  }

  void _goToPage(int page) {
    if (page < 0 || page >= _totalPages) return;
    setState(() => _currentPage = page);
    _flipKey.currentState?.goToPage(page);
    _saveProgress();
  }

  void _onPageFlipChanged(int page) {
    if (mounted && page != _currentPage) {
      setState(() => _currentPage = page);
      _saveProgress();
    }
  }

  // Annotation methods
  void _onSelectionStart(DragStartDetails details) {
    final annotationMode = ref.read(annotationModeProvider);
    if (!annotationMode.isEnabled) return;

    setState(() {
      _selectionStart = details.localPosition;
      _selectionEnd = details.localPosition;
      _selectionRect = null;
    });
    ref.read(annotationModeProvider.notifier).startSelection();
  }

  void _onSelectionUpdate(DragUpdateDetails details) {
    final annotationMode = ref.read(annotationModeProvider);
    if (!annotationMode.isEnabled || _selectionStart == null) return;

    setState(() {
      _selectionEnd = details.localPosition;
      _selectionRect = Rect.fromPoints(_selectionStart!, _selectionEnd!);
    });
    ref.read(annotationModeProvider.notifier).updateSelection(_selectionRect!);
  }

  void _onSelectionEnd(DragEndDetails details) {
    final annotationMode = ref.read(annotationModeProvider);
    if (!annotationMode.isEnabled) return;

    ref.read(annotationModeProvider.notifier).endSelection();
  }

  Future<void> _confirmHighlight() async {
    if (_selectionRect == null || _pageSize == Size.zero) return;

    final annotationState = ref.read(annotationModeProvider);
    final bookId = int.tryParse(widget.bookId) ?? -1;
    if (bookId == -1) return;

    // Convert to relative coordinates (0.0 - 1.0)
    final relativeRect = [
      _selectionRect!.left / _pageSize.width,
      _selectionRect!.top / _pageSize.height,
      _selectionRect!.right / _pageSize.width,
      _selectionRect!.bottom / _pageSize.height,
    ];

    final highlight = HighlightEntity()
      ..bookId = bookId
      ..pageNumber = _currentPage + 1 // 1-indexed
      ..selectedText = 'Selected text' // Placeholder - pdfrx doesn't support text extraction
      ..type = annotationState.selectedType
      ..color = annotationState.selectedColor
      ..relativeRect = relativeRect
      ..createdAt = DateTime.now();

    // If note type, show dialog for note content
    if (annotationState.selectedType == HighlightType.note) {
      final noteContent = await _showNoteDialog();
      if (noteContent == null) return;
      highlight.noteContent = noteContent;
    }

    await ref.read(highlightRepositoryProvider).addHighlight(highlight);

    // Refresh highlights
    ref.invalidate(pageHighlightsProvider((bookId: bookId, pageNumber: _currentPage + 1)));
    ref.invalidate(bookHighlightsProvider(bookId));

    // Clear selection
    _clearSelection();

    // Show feedback
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Highlight added!'),
          backgroundColor: Color(annotationState.selectedColor.colorValue),
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<String?> _showNoteDialog() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Add Note',
          style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        content: TextField(
          controller: controller,
          maxLines: 4,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Enter your note...',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
            filled: true,
            fillColor: Colors.white.withOpacity(0.1),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _clearSelection() {
    setState(() {
      _selectionStart = null;
      _selectionEnd = null;
      _selectionRect = null;
    });
    ref.read(annotationModeProvider.notifier).clearSelection();
  }

  @override
  Widget build(BuildContext context) {
    final bookAsync = ref.watch(bookProvider(widget.bookId));
    final annotationState = ref.watch(annotationModeProvider);
    final bookId = int.tryParse(widget.bookId) ?? -1;

    return WillPopScope(
      onWillPop: _handleExit,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: bookAsync.when(
          data: (book) {
            if (book == null) return const Center(child: Text('Book not found'));

            return Stack(
              children: [
                // PDF View with PageFlip
                GestureDetector(
                  onTap: _toggleControls,
                  onPanStart: _onSelectionStart,
                  onPanUpdate: _onSelectionUpdate,
                  onPanEnd: _onSelectionEnd,
                  child: PdfDocumentViewBuilder.file(
                    book.filePath,
                    builder: (context, document) {
                      if (document == null) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final docPages = document.pages.length;
                      _initializePages(docPages, book.currentPage);

                      final safeInitialIndex = book.currentPage.clamp(0, docPages > 0 ? docPages - 1 : 0);

                      if (docPages == 0) {
                        return const Center(
                          child: Text('No pages', style: TextStyle(color: Colors.white)),
                        );
                      }

                      return PageFlipWidget(
                        key: _flipKey,
                        backgroundColor: Colors.black,
                        initialIndex: safeInitialIndex,
                        duration: const Duration(milliseconds: 450),
                        onPageFlipped: _onPageFlipChanged,
                        lastPage: Container(
                          color: Colors.white,
                          child: const Center(
                            child: Text('The End', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        children: [
                          for (var i = 0; i < docPages; i++)
                            _PdfPageWithHighlights(
                              document: document,
                              pageNumber: i + 1,
                              bookId: bookId,
                              onSizeChanged: (size) {
                                if (i == _currentPage) {
                                  _pageSize = size;
                                }
                              },
                            ),
                        ],
                      );
                    },
                  ),
                ),

                // Selection Box (when dragging)
                if (_selectionRect != null && annotationState.isEnabled)
                  SelectionBox(
                    rect: _selectionRect!,
                    color: Color(annotationState.selectedColor.colorValue),
                  ),

                // Top Bar
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 200),
                  top: _showControls ? 0 : -120,
                  left: 0,
                  right: 0,
                  child: Container(
                    color: Colors.black.withOpacity(0.85),
                    padding: EdgeInsets.only(
                      top: MediaQuery.of(context).padding.top,
                      bottom: 10,
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
                          onPressed: () async {
                            await _handleExit();
                            if (context.mounted) context.pop();
                          },
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                book.title,
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (_totalPages > 0)
                                Text(
                                  'Page ${_currentPage + 1} of $_totalPages',
                                  style: GoogleFonts.inter(color: Colors.white60, fontSize: 12),
                                ),
                            ],
                          ),
                        ),
                        // Annotation mode toggle
                        IconButton(
                          icon: Icon(
                            annotationState.isEnabled ? LucideIcons.highlighter : LucideIcons.highlighter,
                            color: annotationState.isEnabled ? const Color(0xFFFFEB3B) : Colors.white,
                          ),
                          onPressed: () {
                            ref.read(annotationModeProvider.notifier).toggleAnnotationMode();
                            if (!annotationState.isEnabled) {
                              setState(() => _showControls = true);
                            }
                          },
                        ),
                        IconButton(
                          icon: const Icon(LucideIcons.bookmark, color: Colors.white),
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ),
                ),

                // Bottom Bar with Page Navigation
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 200),
                  bottom: _showControls ? (annotationState.isEnabled ? 140 : 0) : -100,
                  left: 0,
                  right: 0,
                  child: Container(
                    color: Colors.black.withOpacity(0.85),
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        IconButton(
                          icon: Icon(
                            LucideIcons.chevronLeft,
                            color: _currentPage > 0 ? Colors.white : Colors.white38,
                          ),
                          onPressed: _currentPage > 0 ? () => _goToPage(_currentPage - 1) : null,
                        ),
                        Text(
                          _totalPages > 0 ? '${_currentPage + 1} / $_totalPages' : '...',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            LucideIcons.chevronRight,
                            color: _currentPage < _totalPages - 1 ? Colors.white : Colors.white38,
                          ),
                          onPressed: _currentPage < _totalPages - 1 ? () => _goToPage(_currentPage + 1) : null,
                        ),
                      ],
                    ),
                  ),
                ),

                // Annotation Toolbar (bottom)
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 200),
                  bottom: annotationState.isEnabled ? MediaQuery.of(context).padding.bottom + 16 : -200,
                  left: 0,
                  right: 0,
                  child: AnnotationToolbar(
                    onHighlightConfirm: _selectionRect != null ? _confirmHighlight : null,
                    onCancel: _clearSelection,
                  ),
                ),

                // Annotation mode indicator
                if (annotationState.isEnabled)
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 60,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFEB3B).withOpacity(0.9),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Annotation Mode - Drag to select',
                          style: GoogleFonts.inter(
                            color: Colors.black87,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, s) => Center(
            child: Text('Error: $e', style: const TextStyle(color: Colors.white)),
          ),
        ),
      ),
    );
  }
}

/// PDF Page with Highlight Overlay
class _PdfPageWithHighlights extends ConsumerWidget {
  final PdfDocument document;
  final int pageNumber;
  final int bookId;
  final ValueChanged<Size>? onSizeChanged;

  const _PdfPageWithHighlights({
    required this.document,
    required this.pageNumber,
    required this.bookId,
    this.onSizeChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);

        // Report size to parent
        WidgetsBinding.instance.addPostFrameCallback((_) {
          onSizeChanged?.call(size);
        });

        return Container(
          color: Colors.white,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // PDF Page
              PdfPageView(
                document: document,
                pageNumber: pageNumber,
                alignment: Alignment.center,
              ),

              // Highlight Overlay
              if (bookId > 0)
                HighlightOverlay(
                  bookId: bookId,
                  pageNumber: pageNumber,
                  pageSize: size,
                ),

              // Gradient overlay for book effect
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Colors.black.withOpacity(0.1),
                      Colors.transparent,
                      Colors.transparent,
                      Colors.black.withOpacity(0.05),
                    ],
                    stops: const [0.0, 0.1, 0.9, 1.0],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
