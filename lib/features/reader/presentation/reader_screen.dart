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

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
  }

  Future<void> _saveProgressBeforeExit() async {
    final bookId = int.tryParse(widget.bookId) ?? -1;
    
    if (_totalPages > 0 && bookId != -1) {
      await ref.read(bookRepositoryProvider).updateProgress(
        bookId,
        _currentPage,
        _totalPages,
      );
      
      // Force refresh providers
      await Future.delayed(const Duration(milliseconds: 200));
      ref.invalidate(recentBooksProvider);
      ref.invalidate(allBooksProvider);
    }
  }

  Future<bool> _handleExit() async {
    await _saveProgressBeforeExit();
    return true; // Allow navigation
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
                      
                      if (_totalPages == 0) {
                        _totalPages = document.pages.length;
                        _currentPage = book.currentPage;
                      }
                      
                      return NotificationListener<ScrollNotification>(
                        onNotification: (notification) {
                          if (notification is ScrollUpdateNotification) {
                            final page = (notification.metrics as PageMetrics).page?.round() ?? _currentPage;
                            if (page != _currentPage) {
                              setState(() => _currentPage = page);
                              _saveProgressBeforeExit();
                            }
                          }
                          return false;
                        },
                        child: PageFlipWidget(
                          key: _controller,
                          backgroundColor: Colors.black,
                          initialIndex: book.currentPage,
                          duration: const Duration(milliseconds: 800),
                          lastPage: Container(
                            color: Colors.white,
                            child: const Center(child: Text('The End')),
                          ),
                          children: [
                            for (var i = 0; i < document.pages.length; i++)
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
                          onPressed: _handleExit,
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
                          icon: const Icon(LucideIcons.chevronLeft, color: Colors.white),
                          onPressed: _currentPage > 0
                              ? () {
                                  setState(() => _currentPage--);
                                  // Navigate PageFlipWidget to previous page
                                  _controller.currentState?.goToPage(_currentPage);
                                }
                              : null,
                        ),
                        // Page Counter
                        Text(
                          '${_currentPage + 1} / $_totalPages',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        // Next Page Button
                        IconButton(
                          icon: const Icon(LucideIcons.chevronRight, color: Colors.white),
                          onPressed: _currentPage < _totalPages - 1
                              ? () {
                                  setState(() => _currentPage++);
                                  // Navigate PageFlipWidget to next page
                                  _controller.currentState?.goToPage(_currentPage);
                                }
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
