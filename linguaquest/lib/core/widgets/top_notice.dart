import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

/// Shows a top-anchored, auto-dismissing passive notice.
///
/// The notice drops from the top, sits just below the status bar and never
/// covers the bottom action area (unlike a [SnackBar]). It does not block
/// touches to the rest of the screen. If no [Overlay] is available this is a
/// safe no-op.
///
/// Callers pass a pre-localized [message] (e.g.
/// `AppLocalizations.of(context).xxx`).
void showTopNotice(
  BuildContext context,
  String message, {
  IconData? icon,
  Duration duration = const Duration(milliseconds: 1800),
}) {
  final overlay = Overlay.maybeOf(context);
  if (overlay == null) return;

  final topInset = MediaQuery.paddingOf(context).top + AppTokens.s12;

  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => Positioned(
      top: topInset,
      left: AppTokens.s16,
      right: AppTokens.s16,
      // Passive notice: must not intercept touches to the screen below.
      child: IgnorePointer(
        child: _TopNoticeCard(
          message: message,
          icon: icon,
          duration: duration,
          onDismissed: () {
            if (entry.mounted) entry.remove();
          },
        ),
      ),
    ),
  );

  overlay.insert(entry);
}

/// Animated card body: slide-down + fade in, then auto-removes after
/// [duration]. Guards against double-removal via the parent's [onDismissed]
/// (which itself checks [OverlayEntry.mounted]).
class _TopNoticeCard extends StatefulWidget {
  const _TopNoticeCard({
    required this.message,
    required this.icon,
    required this.duration,
    required this.onDismissed,
  });

  final String message;
  final IconData? icon;
  final Duration duration;
  final VoidCallback onDismissed;

  @override
  State<_TopNoticeCard> createState() => _TopNoticeCardState();
}

class _TopNoticeCardState extends State<_TopNoticeCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: AppTokens.fast);
  bool _dismissed = false;

  @override
  void initState() {
    super.initState();
    _controller.forward();
    Future.delayed(widget.duration, _dismiss);
  }

  void _dismiss() {
    if (_dismissed || !mounted) return;
    _dismissed = true;
    // Play the exit animation, but remove the entry once the duration has
    // elapsed so the notice is gone promptly (the reverse just softens it).
    _controller.reverse();
    widget.onDismissed();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final curved = CurvedAnimation(parent: _controller, curve: Curves.easeOut);

    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, -0.25),
          end: Offset.zero,
        ).animate(curved),
        child: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(AppTokens.radiusCard),
            border: Border.all(color: AppTokens.hairline),
            boxShadow: AppTokens.cardShadow(context),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppTokens.s16,
            vertical: AppTokens.s12,
          ),
          child: Row(
            children: [
              if (widget.icon != null) ...[
                Icon(
                  widget.icon,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: AppTokens.s8),
              ],
              Expanded(
                child: Text(
                  widget.message,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
