import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:page_flip/page_flip.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:lumina_pdf_reader/features/home/presentation/home_providers.dart';
import 'package:lumina_pdf_reader/features/home/data/book_repository.dart';
import 'package:lumina_pdf_reader/features/reader/presentation/reader_controller.dart';

class ReaderScreen extends ConsumerStatefulWidget {
  final String bookId;
  const ReaderScreen({super.key, required this.bookId});

  @override
  ConsumerState<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends ConsumerState<ReaderScreen> {
  final _controller = GlobalKey<PageFlipWidgetState>();
  bool _showControls = true;
  int _totalPages = 0;
  int _currentPage = 0;
  bool _isInitialized = false;

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
  }

  /// Initialize page state from loaded document and book data
  void _initializePages(int documentPages, int savedCurrentPage) {
    if (!_isInitialized) {
      _isInitialized = true;
      // Use post frame callback to avoid setState during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _totalPages = documentPages;
            // Validate saved page is within bounds
            _currentPage = savedCurrentPage.clamp(0, documentPages - 1);
          });
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
    // Save progress first
    await _saveProgress();
    // Invalidate providers BEFORE navigation completes
    ref.invalidate(recentBooksProvider);
    ref.invalidate(allBooksProvider);
    return true;
  }

  void _goToPage(int page) {
    if (page < 0 || page >= _totalPages) return;

    setState(() => _currentPage = page);
    _controller.currentState?.goToPage(page);
    // Save progress on every page change
    _saveProgress();
  }

  @override
  Widget build(BuildContext context) {
    final bookAsync = ref.watch(bookProvider(widget.bookId));

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
                  child: PdfDocumentViewBuilder.file(
                    book.filePath,
                    builder: (context, document) {
                      if (document == null) return const Center(child: CircularProgressIndicator());

                      // Initialize pages with setState via post frame callback
                      _initializePages(document.pages.length, book.currentPage);

                      // Use local values for initial render, state values after init
                      final effectiveTotalPages = _isInitialized ? _totalPages : document.pages.length;
                      final effectiveCurrentPage = _isInitialized
                          ? _currentPage
                          : book.currentPage.clamp(0, document.pages.length - 1);

                      return GestureDetector(
                        onHorizontalDragEnd: (details) {
                          // Detect swipe direction and update page
                          if (details.primaryVelocity != null && _isInitialized) {
                            if (details.primaryVelocity! < -100 && _currentPage < _totalPages - 1) {
                              // Swipe left = next page
                              _goToPage(_currentPage + 1);
                            } else if (details.primaryVelocity! > 100 && _currentPage > 0) {
                              // Swipe right = previous page
                              _goToPage(_currentPage - 1);
                            }
                          }
                        },
                        child: PageFlipWidget(
                          key: _controller,
                          backgroundColor: Colors.black,
                          initialIndex: effectiveCurrentPage,
                          duration: const Duration(milliseconds: 800),
                          lastPage: Container(
                            color: Colors.white,
                            child: const Center(child: Text('The End')),
                          ),
                          children: [
                            for (var i = 0; i < effectiveTotalPages; i++)
                              _PdfPageRenderer(
                                document: document,
                                pageNumber: i + 1,
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                // Top Bar
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 200),
                  top: _showControls ? 0 : -100,
                  left: 0,
                  right: 0,
                  child: Container(
                    color: Colors.black.withOpacity(0.8),
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
                                  style: GoogleFonts.inter(
                                    color: Colors.white60,
                                    fontSize: 12,
                                  ),
                                ),
                            ],
                          ),
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
                  bottom: _showControls ? 0 : -100,
                  left: 0,
                  right: 0,
                  child: Container(
                    color: Colors.black.withOpacity(0.8),
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        // Previous Page Button
                        IconButton(
                          icon: Icon(
                            LucideIcons.chevronLeft,
                            color: (_isInitialized && _currentPage > 0)
                                ? Colors.white
                                : Colors.white38,
                          ),
                          onPressed: (_isInitialized && _currentPage > 0)
                              ? () => _goToPage(_currentPage - 1)
                              : null,
                        ),
                        // Page Counter
                        Text(
                          _isInitialized
                              ? '${_currentPage + 1} / $_totalPages'
                              : '1 / 0',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        // Next Page Button
                        IconButton(
                          icon: Icon(
                            LucideIcons.chevronRight,
                            color: (_isInitialized && _currentPage < _totalPages - 1)
                                ? Colors.white
                                : Colors.white38,
                          ),
                          onPressed: (_isInitialized && _currentPage < _totalPages - 1)
                              ? () => _goToPage(_currentPage + 1)
                              : null,
                        ),
                      ],
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

class _PdfPageRenderer extends StatelessWidget {
  final PdfDocument document;
  final int pageNumber;

  const _PdfPageRenderer({
    required this.document,
    required this.pageNumber,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Stack(
        fit: StackFit.expand,
        children: [
          PdfPageView(
            document: document,
            pageNumber: pageNumber,
            alignment: Alignment.center,
          ),
          // Gradient overlay for spine/depth effect
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Colors.black.withOpacity(0.1), // Spine shadow
                  Colors.transparent,
                  Colors.transparent,
                  Colors.black.withOpacity(0.05), // Page edge shadow
                ],
                stops: const [0.0, 0.1, 0.9, 1.0],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
