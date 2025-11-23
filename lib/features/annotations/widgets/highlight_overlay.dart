import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lumina_pdf_reader/features/annotations/data/highlight_entity.dart';
import 'package:lumina_pdf_reader/features/annotations/presentation/annotation_providers.dart';

/// Overlay widget untuk render highlights di atas PDF page
class HighlightOverlay extends ConsumerWidget {
  final int bookId;
  final int pageNumber;
  final Size pageSize;

  const HighlightOverlay({
    super.key,
    required this.bookId,
    required this.pageNumber,
    required this.pageSize,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final highlightsAsync = ref.watch(
      pageHighlightsProvider((bookId: bookId, pageNumber: pageNumber)),
    );

    return highlightsAsync.when(
      data: (highlights) {
        if (highlights.isEmpty) return const SizedBox.shrink();

        return Stack(
          children: highlights.map((highlight) {
            return _HighlightBox(
              highlight: highlight,
              pageSize: pageSize,
              onTap: () {
                ref.read(selectedHighlightProvider.notifier).state = highlight;
              },
              onLongPress: () {
                // Show edit/delete options
                _showHighlightOptions(context, ref, highlight);
              },
            );
          }).toList(),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  void _showHighlightOptions(BuildContext context, WidgetRef ref, HighlightEntity highlight) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _HighlightOptionsSheet(
        highlight: highlight,
        onDelete: () async {
          await ref.read(highlightRepositoryProvider).deleteHighlight(highlight.id);
          ref.invalidate(pageHighlightsProvider((bookId: bookId, pageNumber: pageNumber)));
          ref.invalidate(bookHighlightsProvider(bookId));
          if (context.mounted) Navigator.pop(context);
        },
        onChangeColor: (color) async {
          await ref.read(highlightRepositoryProvider).updateHighlightColor(highlight.id, color);
          ref.invalidate(pageHighlightsProvider((bookId: bookId, pageNumber: pageNumber)));
          if (context.mounted) Navigator.pop(context);
        },
      ),
    );
  }
}

class _HighlightBox extends StatelessWidget {
  final HighlightEntity highlight;
  final Size pageSize;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const _HighlightBox({
    required this.highlight,
    required this.pageSize,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    // Convert relative rect to actual pixels
    final rect = highlight.rectValues;
    if (rect.length < 4) return const SizedBox.shrink();

    final left = rect[0] * pageSize.width;
    final top = rect[1] * pageSize.height;
    final width = (rect[2] - rect[0]) * pageSize.width;
    final height = (rect[3] - rect[1]) * pageSize.height;

    final color = Color(highlight.color.colorValue);
    final opacity = highlight.color.opacity;

    Widget highlightWidget;

    switch (highlight.type) {
      case HighlightType.highlight:
        highlightWidget = Container(
          decoration: BoxDecoration(
            color: color.withOpacity(opacity),
            borderRadius: BorderRadius.circular(2),
          ),
        );
        break;

      case HighlightType.underline:
        highlightWidget = Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: color,
                width: 2,
              ),
            ),
          ),
        );
        break;

      case HighlightType.strikethrough:
        highlightWidget = Center(
          child: Container(
            height: 2,
            color: color,
          ),
        );
        break;

      case HighlightType.note:
        highlightWidget = Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
                border: Border.all(color: color, width: 1),
              ),
            ),
            Positioned(
              right: -8,
              top: -8,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.5),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.sticky_note_2,
                  size: 12,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
        break;
    }

    return Positioned(
      left: left,
      top: top,
      width: width,
      height: height,
      child: GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        child: highlightWidget,
      ),
    );
  }
}

class _HighlightOptionsSheet extends StatelessWidget {
  final HighlightEntity highlight;
  final VoidCallback onDelete;
  final ValueChanged<HighlightColor> onChangeColor;

  const _HighlightOptionsSheet({
    required this.highlight,
    required this.onDelete,
    required this.onChangeColor,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Selected text preview
            if (highlight.selectedText.isNotEmpty) ...[
              Text(
                '"${highlight.selectedText}"',
                style: const TextStyle(
                  color: Colors.white70,
                  fontStyle: FontStyle.italic,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),
            ],

            // Color options
            const Text(
              'Change Color',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: HighlightColor.values.map((color) {
                final isSelected = color == highlight.color;
                return GestureDetector(
                  onTap: () => onChangeColor(color),
                  child: Container(
                    width: isSelected ? 40 : 32,
                    height: isSelected ? 40 : 32,
                    decoration: BoxDecoration(
                      color: Color(color.colorValue),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? Colors.white : Colors.transparent,
                        width: 2,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Note content (if note type)
            if (highlight.type == HighlightType.note && highlight.noteContent != null) ...[
              const Text(
                'Note',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  highlight.noteContent!,
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Delete button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline),
                label: const Text('Delete Highlight'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.withOpacity(0.2),
                  foregroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget untuk selection box saat user drag
class SelectionBox extends StatelessWidget {
  final Rect rect;
  final Color color;

  const SelectionBox({
    super.key,
    required this.rect,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: rect.left,
      top: rect.top,
      width: rect.width,
      height: rect.height,
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.3),
          border: Border.all(
            color: color,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Start handle
            Positioned(
              left: -8,
              top: -8,
              child: _SelectionHandle(color: color),
            ),
            // End handle
            Positioned(
              right: -8,
              bottom: -8,
              child: _SelectionHandle(color: color),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectionHandle extends StatelessWidget {
  final Color color;

  const _SelectionHandle({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.5),
            blurRadius: 4,
          ),
        ],
      ),
    );
  }
}
