import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:page_flip/page_flip.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:lumina_pdf_reader/features/home/presentation/home_providers.dart';
import 'package:lumina_pdf_reader/features/reader/presentation/reader_controller.dart';

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

  @override
  void initState() {
    super.initState();
    // Invalidate book provider immediately to force fresh data
    Future.microtask(() {
      ref.invalidate(bookProvider(widget.bookId));
    });
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
  }

  /// Initialize page state from loaded document and book data
  void _initializePages(int documentPages, int savedCurrentPage) {
    debugPrint('📖 _initializePages: docPages=$documentPages, savedPage=$savedCurrentPage, hasInit=$_hasInitialized, hasNav=$_hasNavigatedToSavedPage');

    if (!_hasInitialized && documentPages > 0) {
      _hasInitialized = true;

      final maxPage = documentPages - 1;
      final targetPage = savedCurrentPage.clamp(0, maxPage);

      debugPrint('📖 First init - setting totalPages=$documentPages, currentPage=$targetPage');

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _totalPages = documentPages;
            _currentPage = targetPage;
          });
        }
      });
    }

    // Navigate to saved page only ONCE after PageFlipWidget is ready
    if (!_hasNavigatedToSavedPage && _hasInitialized && savedCurrentPage > 0) {
      _hasNavigatedToSavedPage = true;

      final maxPage = documentPages - 1;
      final targetPage = savedCurrentPage.clamp(0, maxPage);

      debugPrint('📖 Scheduling navigation to page $targetPage');

      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted && _flipKey.currentState != null) {
          debugPrint('📖 NOW navigating to page $targetPage');
          _flipKey.currentState!.goToPage(targetPage);
          setState(() => _currentPage = targetPage);
        } else {
          debugPrint('📖 Cannot navigate - widget not ready');
        }
      });
    }
  }

  Future<void> _saveProgress() async {
    final bookId = int.tryParse(widget.bookId) ?? -1;

    debugPrint('📖 _saveProgress: bookId=$bookId, currentPage=$_currentPage, totalPages=$_totalPages');

    if (_totalPages > 0 && bookId != -1) {
      await ref.read(bookRepositoryProvider).updateProgress(
        bookId,
        _currentPage,
        _totalPages,
      );
      debugPrint('📖 Progress saved!');
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
    debugPrint('📖 onPageFlipChanged: page=$page, current=$_currentPage');
    if (mounted && page != _currentPage) {
      setState(() => _currentPage = page);
      _saveProgress();
    }
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

            debugPrint('📖 BUILD: book.currentPage=${book.currentPage}');

            return Stack(
              children: [
                // PDF View with PageFlip
                GestureDetector(
                  onTap: _toggleControls,
                  child: PdfDocumentViewBuilder.file(
                    book.filePath,
                    builder: (context, document) {
                      if (document == null) return const Center(child: CircularProgressIndicator());

                      final docPages = document.pages.length;

                      // Initialize pages
                      _initializePages(docPages, book.currentPage);

                      // Calculate safe initial index for PageFlipWidget
                      final safeInitialIndex = book.currentPage.clamp(0, docPages > 0 ? docPages - 1 : 0);

                      if (docPages == 0) {
                        return const Center(child: Text('No pages', style: TextStyle(color: Colors.white)));
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
                            _PdfPageRenderer(document: document, pageNumber: i + 1),
                        ],
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
                                  style: GoogleFonts.inter(color: Colors.white60, fontSize: 12),
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

                // Bottom Bar
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

  const _PdfPageRenderer({required this.document, required this.pageNumber});

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
  }
}
