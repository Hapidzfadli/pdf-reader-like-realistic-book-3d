import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Custom page curl widget that provides 3D curl effect
/// Curl starts from bottom-left corner like a physical book
class PageCurlWidget extends StatefulWidget {
  final List<Widget> pages;
  final int initialPage;
  final Function(int)? onPageChanged;
  final Color backgroundColor;

  const PageCurlWidget({
    super.key,
    required this.pages,
    this.initialPage = 0,
    this.onPageChanged,
    this.backgroundColor = Colors.black,
  });

  @override
  State<PageCurlWidget> createState() => PageCurlWidgetState();
}

class PageCurlWidgetState extends State<PageCurlWidget>
    with SingleTickerProviderStateMixin {
  late int _currentPage;
  late AnimationController _animationController;
  Offset? _dragStart;
  Offset? _dragUpdate;
  bool _isCurling = false;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage;
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onPanStart(DragStartDetails details) {
    final size = context.size;
    if (size == null) return;

    // Only allow drag from right half of screen
    if (details.localPosition.dx > size.width * 0.5) {
      setState(() {
        _dragStart = details.localPosition;
        _dragUpdate = details.localPosition;
        _isCurling = true;
      });
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!_isCurling) return;

    setState(() {
      _dragUpdate = details.localPosition;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (!_isCurling) return;

    final size = context.size;
    if (size == null) return;

    // Check if drag was significant enough to turn page
    final dragDistance = _dragUpdate!.dx - _dragStart!.dx;
    final shouldTurnPage = dragDistance.abs() > size.width * 0.3;

    if (shouldTurnPage && dragDistance < 0 && _currentPage < widget.pages.length - 1) {
      // Turn to next page
      _animatePageTurn(true);
    } else if (shouldTurnPage && dragDistance > 0 && _currentPage > 0) {
      // Turn to previous page
      _animatePageTurn(false);
    } else {
      // Snap back
      _animationController.reverse();
    }

    setState(() {
      _isCurling = false;
      _dragStart = null;
      _dragUpdate = null;
    });
  }

  void _animatePageTurn(bool forward) {
    _animationController.forward(from: 0).then((_) {
      setState(() {
        _currentPage = forward ? _currentPage + 1 : _currentPage - 1;
        widget.onPageChanged?.call(_currentPage);
      });
      _animationController.reset();
    });
  }

  /// Public method to go to specific page
  void goToPage(int page) {
    if (page >= 0 && page < widget.pages.length) {
      setState(() {
        _currentPage = page;
        widget.onPageChanged?.call(_currentPage);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: widget.backgroundColor,
      child: GestureDetector(
        onPanStart: _onPanStart,
        onPanUpdate: _onPanUpdate,
        onPanEnd: _onPanEnd,
        child: Stack(
          children: [
            // Current page
            if (_currentPage < widget.pages.length)
              Positioned.fill(
                child: widget.pages[_currentPage],
              ),

            // Next page with curl effect
            if (_isCurling && _currentPage < widget.pages.length - 1)
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return CustomPaint(
                      painter: PageCurlPainter(
                        dragPosition: _dragUpdate,
                        animationValue: _animationController.value,
                      ),
                      child: ClipPath(
                        clipper: PageCurlClipper(
                          dragPosition: _dragUpdate,
                          animationValue: _animationController.value,
                        ),
                        child: widget.pages[_currentPage + 1],
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Custom painter for curl shadow effect
class PageCurlPainter extends CustomPainter {
  final Offset? dragPosition;
  final double animationValue;

  PageCurlPainter({
    this.dragPosition,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (dragPosition == null) return;

    // Draw shadow gradient for curl effect
    final shadowPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerRight,
        end: Alignment.centerLeft,
        colors: [
          Colors.black.withOpacity(0.3),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path();
    path.moveTo(dragPosition!.dx, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(dragPosition!.dx, size.height);
    path.close();

    canvas.drawPath(path, shadowPaint);
  }

  @override
  bool shouldRepaint(PageCurlPainter oldDelegate) {
    return dragPosition != oldDelegate.dragPosition ||
        animationValue != oldDelegate.animationValue;
  }
}

/// Custom clipper for curl shape
class PageCurlClipper extends CustomClipper<Path> {
  final Offset? dragPosition;
  final double animationValue;

  PageCurlClipper({
    this.dragPosition,
    required this.animationValue,
  });

  @override
  Path getClip(Size size) {
    final path = Path();

    if (dragPosition == null) {
      return path;
    }

    // Create curl path from bottom-left
    final curlX = dragPosition!.dx;
    final curlRadius = (size.width - curlX) * 0.5;

    path.moveTo(curlX, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height);
    
    // Curl curve from bottom-right to bottom-left
    path.quadraticBezierTo(
      curlX + curlRadius,
      size.height - curlRadius,
      curlX,
      size.height,
    );
    
    path.lineTo(curlX, 0);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(PageCurlClipper oldClipper) {
    return dragPosition != oldClipper.dragPosition ||
        animationValue != oldClipper.animationValue;
  }
}
