import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

/// Primary action button: azure fill, white label, soft 3D bottom edge that
/// sinks 2px on press.
class AppPrimaryButton extends StatefulWidget {
  const AppPrimaryButton({
    required this.label,
    required this.onPressed,
    this.icon,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  State<AppPrimaryButton> createState() => _AppPrimaryButtonState();
}

class _AppPrimaryButtonState extends State<AppPrimaryButton> {
  bool _down = false;

  bool get _enabled => widget.onPressed != null;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppTokens.radiusButton);
    final sink = _down ? 2.0 : 0.0;
    // Muted label/icon on the disabled (hairline) fill so it reads as inactive
    // instead of low-contrast white-on-beige.
    final contentColor = _enabled ? Colors.white : AppTokens.textHintLight;
    return Semantics(
      button: true,
      enabled: _enabled,
      label: widget.label,
      child: GestureDetector(
        onTap: widget.onPressed,
        onTapDown: _enabled ? (_) => setState(() => _down = true) : null,
        onTapUp: _enabled ? (_) => setState(() => _down = false) : null,
        onTapCancel: _enabled ? () => setState(() => _down = false) : null,
        child: AnimatedContainer(
          duration: AppTokens.fast,
          transform: Matrix4.translationValues(0, sink, 0),
          decoration: BoxDecoration(
            color: _enabled ? AppTokens.azure : AppTokens.hairline,
            borderRadius: radius,
            boxShadow: _enabled
                ? [
                    BoxShadow(
                      color: AppTokens.azurePressed,
                      offset: Offset(0, 4 - sink),
                      blurRadius: 0,
                    ),
                  ]
                : const [],
          ),
          padding: const EdgeInsets.symmetric(vertical: AppTokens.s16),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, size: 20, color: contentColor),
                const SizedBox(width: AppTokens.s8),
              ],
              Text(
                widget.label,
                style: TextStyle(
                  color: contentColor,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Secondary action: white fill, azure label, soft outline.
class AppSecondaryButton extends StatelessWidget {
  const AppSecondaryButton({
    required this.label,
    required this.onPressed,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: AppTokens.azure,
        side: const BorderSide(color: AppTokens.primarySoftText, width: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusButton),
        ),
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
    );
  }
}
