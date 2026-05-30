import 'package:flutter/material.dart';

class SwipeActionCard extends StatefulWidget {
  const SwipeActionCard({
    super.key,
    required this.child,
    required this.actions,
    this.enabled = true,
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
  });

  final Widget child;
  final List<SwipeCardAction> actions;
  final bool enabled;
  final BorderRadius borderRadius;

  @override
  State<SwipeActionCard> createState() => _SwipeActionCardState();
}

class _SwipeActionCardState extends State<SwipeActionCard> {
  static const double _actionWidth = 88;
  double _offset = 0;

  double get _maxReveal => widget.actions.length * _actionWidth;

  bool get _isOpen => _offset != 0;

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled || widget.actions.isEmpty) {
      return widget.child;
    }
    final showActions = _isOpen;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        if (showActions)
          Positioned(
            top: 0,
            right: 0,
            bottom: 0,
            width: _maxReveal,
            child: ClipRRect(
              borderRadius: widget.borderRadius,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: widget.actions.map(_buildActionButton).toList(),
              ),
            ),
          ),
        ClipRect(
          child: GestureDetector(
            behavior: showActions
                ? HitTestBehavior.deferToChild
                : HitTestBehavior.translucent,
            onHorizontalDragUpdate: (details) {
              setState(() {
                _offset = (_offset + details.primaryDelta!).clamp(
                  -_maxReveal,
                  0.0,
                );
              });
            },
            onHorizontalDragEnd: (_) {
              setState(() {
                _offset = _offset.abs() > _maxReveal / 2 ? -_maxReveal : 0;
              });
            },
            onTap: _isOpen
                ? () {
                    setState(() {
                      _offset = 0;
                    });
                  }
                : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              transform: Matrix4.translationValues(_offset, 0, 0),
              child: widget.child,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(SwipeCardAction action) {
    return SizedBox(
      key: ValueKey('swipe-action-${action.label}'),
      width: _actionWidth,
      child: ColoredBox(
        color: action.backgroundColor,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            setState(() {
              _offset = 0;
            });
            action.onPressed();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(action.icon, color: action.foregroundColor),
                const SizedBox(height: 2),
                Text(
                  action.label,
                  textAlign: TextAlign.center,
                  softWrap: false,
                  overflow: TextOverflow.fade,
                  style: TextStyle(
                    color: action.foregroundColor,
                    height: 1,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SwipeCardAction {
  const SwipeCardAction({
    required this.label,
    required this.icon,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final Color backgroundColor;
  final Color foregroundColor;
  final VoidCallback onPressed;
}
