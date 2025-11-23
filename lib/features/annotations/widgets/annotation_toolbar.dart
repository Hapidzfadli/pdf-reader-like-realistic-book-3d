import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:lumina_pdf_reader/features/annotations/data/highlight_entity.dart';
import 'package:lumina_pdf_reader/features/annotations/presentation/annotation_providers.dart';

/// Floating toolbar yang muncul saat annotation mode aktif
class AnnotationToolbar extends ConsumerWidget {
  final VoidCallback? onHighlightConfirm;
  final VoidCallback? onCancel;

  const AnnotationToolbar({
    super.key,
    this.onHighlightConfirm,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final annotationState = ref.watch(annotationModeProvider);

    return AnimatedSlide(
      duration: const Duration(milliseconds: 200),
      offset: annotationState.isEnabled ? Offset.zero : const Offset(0, 2),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: annotationState.isEnabled ? 1.0 : 0.0,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B).withOpacity(0.95),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Color picker row
              _ColorPickerRow(
                selectedColor: annotationState.selectedColor,
                onColorSelected: (color) {
                  ref.read(annotationModeProvider.notifier).setSelectedColor(color);
                },
              ),
              const SizedBox(height: 8),
              // Tools row
              _ToolsRow(
                selectedType: annotationState.selectedType,
                hasSelection: annotationState.selectionRect != null,
                onTypeSelected: (type) {
                  ref.read(annotationModeProvider.notifier).setSelectedType(type);
                },
                onConfirm: onHighlightConfirm,
                onCancel: () {
                  ref.read(annotationModeProvider.notifier).clearSelection();
                  onCancel?.call();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ColorPickerRow extends StatelessWidget {
  final HighlightColor selectedColor;
  final ValueChanged<HighlightColor> onColorSelected;

  const _ColorPickerRow({
    required this.selectedColor,
    required this.onColorSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: HighlightColor.values.map((color) {
        final isSelected = color == selectedColor;
        return GestureDetector(
          onTap: () => onColorSelected(color),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: isSelected ? 36 : 28,
            height: isSelected ? 36 : 28,
            decoration: BoxDecoration(
              color: Color(color.colorValue),
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? Colors.white : Colors.transparent,
                width: 2,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: Color(color.colorValue).withOpacity(0.5),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _ToolsRow extends StatelessWidget {
  final HighlightType selectedType;
  final bool hasSelection;
  final ValueChanged<HighlightType> onTypeSelected;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;

  const _ToolsRow({
    required this.selectedType,
    required this.hasSelection,
    required this.onTypeSelected,
    this.onConfirm,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Highlight tool
        _ToolButton(
          icon: LucideIcons.highlighter,
          label: 'Highlight',
          isSelected: selectedType == HighlightType.highlight,
          onTap: () => onTypeSelected(HighlightType.highlight),
        ),
        // Underline tool
        _ToolButton(
          icon: LucideIcons.underline,
          label: 'Underline',
          isSelected: selectedType == HighlightType.underline,
          onTap: () => onTypeSelected(HighlightType.underline),
        ),
        // Strikethrough tool
        _ToolButton(
          icon: LucideIcons.strikethrough,
          label: 'Strike',
          isSelected: selectedType == HighlightType.strikethrough,
          onTap: () => onTypeSelected(HighlightType.strikethrough),
        ),
        // Note tool
        _ToolButton(
          icon: LucideIcons.stickyNote,
          label: 'Note',
          isSelected: selectedType == HighlightType.note,
          onTap: () => onTypeSelected(HighlightType.note),
        ),
        // Divider
        Container(
          width: 1,
          height: 32,
          color: Colors.white24,
          margin: const EdgeInsets.symmetric(horizontal: 8),
        ),
        // Confirm button (only if selection exists)
        if (hasSelection) ...[
          _ActionButton(
            icon: LucideIcons.check,
            color: Colors.green,
            onTap: onConfirm,
          ),
          const SizedBox(width: 8),
        ],
        // Cancel/Clear button
        _ActionButton(
          icon: hasSelection ? LucideIcons.x : LucideIcons.eraser,
          color: hasSelection ? Colors.red : Colors.white54,
          onTap: onCancel,
        ),
      ],
    );
  }
}

class _ToolButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ToolButton({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.white60,
              size: 20,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                color: isSelected ? Colors.white : Colors.white60,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }
}

/// Mini floating toolbar yang muncul saat ada selection
class SelectionToolbar extends ConsumerWidget {
  final Offset position;
  final VoidCallback onHighlight;
  final VoidCallback onNote;
  final VoidCallback onCopy;
  final VoidCallback onDismiss;

  const SelectionToolbar({
    super.key,
    required this.position,
    required this.onHighlight,
    required this.onNote,
    required this.onCopy,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedColor = ref.watch(annotationModeProvider).selectedColor;

    return Positioned(
      left: position.dx - 100,
      top: position.dy - 60,
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _MiniToolButton(
                icon: LucideIcons.highlighter,
                color: Color(selectedColor.colorValue),
                onTap: onHighlight,
              ),
              _MiniToolButton(
                icon: LucideIcons.stickyNote,
                color: Colors.amber,
                onTap: onNote,
              ),
              _MiniToolButton(
                icon: LucideIcons.copy,
                color: Colors.white70,
                onTap: onCopy,
              ),
              _MiniToolButton(
                icon: LucideIcons.x,
                color: Colors.white38,
                onTap: onDismiss,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniToolButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _MiniToolButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }
}
