import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:lumina_pdf_reader/features/home/data/book_entity.dart';
import 'package:lumina_pdf_reader/features/home/presentation/home_providers.dart';
import 'package:lumina_pdf_reader/features/home/presentation/saved_screen.dart';
import 'package:lumina_pdf_reader/features/home/presentation/search_screen.dart';
import 'package:lumina_pdf_reader/features/settings/presentation/settings_screen.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:permission_handler/permission_handler.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;

  static const List<Widget> _screens = [
    _HomeContent(),
    SearchScreen(),
    SavedScreen(),
    SettingsScreen(),
  ];

  Future<void> _importBook(WidgetRef ref) async {
    if (Platform.isAndroid) {
       var status = await Permission.storage.status;
       if (!status.isGranted) {
         await Permission.storage.request();
       }
    }

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null) {
      final file = result.files.single;
      if (file.path != null) {
        final book = BookEntity()
          ..title = file.name.replaceAll('.pdf', '')
          ..author = 'Unknown'
          ..filePath = file.path!
          ..lastRead = DateTime.now();
        
        await ref.read(bookRepositoryProvider).addBook(book);
        ref.refresh(allBooksProvider);
        ref.refresh(recentBooksProvider);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // Allow body to extend behind nav bar
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0F172A), // Deep Slate
              Color(0xFF020617), // Almost Black
            ],
          ),
        ),
        child: _screens[_selectedIndex],
      ),
      floatingActionButton: _selectedIndex == 0 ? FloatingActionButton.extended(
        onPressed: () => _importBook(ref),
        label: Text('Import PDF', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        icon: const Icon(LucideIcons.plus),
        backgroundColor: Theme.of(context).colorScheme.primary,
        elevation: 4,
      ) : null,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
          color: const Color(0xFF0F172A).withOpacity(0.9), // Semi-transparent
        ),
        child: NavigationBar(
          backgroundColor: Colors.transparent,
          indicatorColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
          elevation: 0,
          height: 70,
          labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
          destinations: const [
            NavigationDestination(
              icon: Icon(LucideIcons.home, color: Colors.white54), 
              selectedIcon: Icon(LucideIcons.home, color: Colors.white),
              label: 'Home'
            ),
            NavigationDestination(
              icon: Icon(LucideIcons.search, color: Colors.white54),
              selectedIcon: Icon(LucideIcons.search, color: Colors.white),
              label: 'Search'
            ),
            NavigationDestination(
              icon: Icon(LucideIcons.bookmark, color: Colors.white54),
              selectedIcon: Icon(LucideIcons.bookmark, color: Colors.white),
              label: 'Saved'
            ),
            NavigationDestination(
              icon: Icon(LucideIcons.settings, color: Colors.white54),
              selectedIcon: Icon(LucideIcons.settings, color: Colors.white),
              label: 'Settings'
            ),
          ],
          selectedIndex: _selectedIndex,
          onDestinationSelected: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
        ),
      ),
    );
  }
}

class _HomeContent extends ConsumerStatefulWidget {
  const _HomeContent();

  @override
  ConsumerState<_HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends ConsumerState<_HomeContent> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Refresh when app comes back to foreground
    if (state == AppLifecycleState.resumed) {
      _refreshData();
    }
  }

  void _refreshData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.invalidate(recentBooksProvider);
        ref.invalidate(allBooksProvider);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final allBooks = ref.watch(allBooksProvider);
    final recentBooks = ref.watch(recentBooksProvider);

    return SafeArea(
      bottom: false, // Let content scroll behind nav bar
      child: CustomScrollView(
        slivers: [
          // Header
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
            sliver: SliverToBoxAdapter(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Zenith PDF',
                    style: GoogleFonts.outfit(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(LucideIcons.bell, color: Colors.white),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.1),
                          shape: const CircleBorder(),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Recent Section
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Recent Reads',
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: Text(
                          'See All',
                          style: GoogleFonts.inter(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 260, // Increased height for progress bar
                  child: recentBooks.when(
                    data: (books) => books.isEmpty
                        ? Center(child: Text('No recent books', style: GoogleFonts.inter(color: Colors.white54)))
                        : ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            itemCount: books.length,
                            itemBuilder: (context, index) {
                              final book = books[index];
                              return _BookCard(book: book, isRecent: true);
                            },
                          ),
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, s) => Center(child: Text('Error: $e')),
                  ),
                ),
              ],
            ),
          ),

          // Library Section
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
            sliver: SliverToBoxAdapter(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Library',
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: Text(
                      'See All',
                      style: GoogleFonts.inter(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          allBooks.when(
            data: (books) => SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.65, // Taller cards
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 24,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final book = books[index];
                    return _BookCard(book: book);
                  },
                  childCount: books.length,
                ),
              ),
            ),
            loading: () => const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator())),
            error: (e, s) => SliverToBoxAdapter(child: Center(child: Text('Error: $e'))),
          ),
          
          const SliverToBoxAdapter(child: SizedBox(height: 120)), // Bottom padding for FAB and Nav Bar
        ],
      ),
    );
  }
}

class _BookCard extends ConsumerWidget {
  final BookEntity book;
  final bool isRecent;

  const _BookCard({required this.book, this.isRecent = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Calculate progress
    final double progress = book.progress;
    final double displayProgress = progress > 0 ? progress : 0.0;

    return GestureDetector(
      onTap: () async {
        // Navigate to reader and wait for it to complete
        await context.push('/reader/${book.id}');
        // Refresh data when returning from reader
        ref.invalidate(recentBooksProvider);
        ref.invalidate(allBooksProvider);
      },
      child: Container(
        width: isRecent ? 160 : null, // Wider for recent to fit progress
        margin: isRecent ? const EdgeInsets.only(right: 20) : null,
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFF334155),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    PdfDocumentViewBuilder.file(
                      book.filePath,
                      builder: (context, document) {
                        if (document == null) return const Center(child: CircularProgressIndicator());
                        return PdfPageView(
                          document: document,
                          pageNumber: 1,
                          alignment: Alignment.center,
                        );
                      },
                    ),
                    // Gradient Overlay for depth
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.4),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Color(0xFF1E293B),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                  if (book.author.isNotEmpty && book.author != 'Unknown') ...[
                    const SizedBox(height: 4),
                    Text(
                      book.author,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 12, 
                        color: Colors.white54,
                      ),
                    ),
                  ],
                  if (isRecent) ...[
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: displayProgress > 0 ? displayProgress : 0.1, // Show at least a little bit
                        backgroundColor: Colors.white10,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).colorScheme.primary,
                        ),
                        minHeight: 4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${(displayProgress * 100).toInt()}% Completed',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: Colors.white54,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
