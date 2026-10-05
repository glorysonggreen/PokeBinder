import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/pokebinder_theme.dart';

enum ToastKind { success, info, warning, error }

class PokeBinderToast {
  PokeBinderToast._();

  static const Duration defaultDuration = Duration(seconds: 4);
  static const Duration _entryAllowance = Duration(milliseconds: 250);

  static void show(
    BuildContext context,
    String message, {
    ToastKind kind = ToastKind.info,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = defaultDuration,
  }) {
    showOn(
      ScaffoldMessenger.of(context),
      message,
      kind: kind,
      actionLabel: actionLabel,
      onAction: onAction,
      duration: duration,
    );
  }

  static void showOn(
    ScaffoldMessengerState messenger,
    String message, {
    ToastKind kind = ToastKind.info,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = defaultDuration,
  }) {
    messenger.clearSnackBars();

    final controller = messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        padding: EdgeInsets.zero,
        margin: const EdgeInsets.fromLTRB(
          PokeBinderSpacing.sp4,
          0,
          PokeBinderSpacing.sp4,
          PokeBinderSpacing.sp3,
        ),
        duration: duration,
        persist: false,
        dismissDirection: DismissDirection.horizontal,
        content: _ToastBody(
          message: message,
          kind: kind,
          actionLabel: actionLabel,
          lifetime: duration + _entryAllowance,
          onAction: () {
            messenger.hideCurrentSnackBar(reason: SnackBarClosedReason.action);
            onAction?.call();
          },
        ),
      ),
    );

    final fallback = Timer(duration + const Duration(milliseconds: 600), () {
      controller.close();
    });
    controller.closed.whenComplete(fallback.cancel);
  }
}

class _ToastBody extends StatelessWidget {
  final String message;
  final ToastKind kind;
  final String? actionLabel;
  final Duration lifetime;
  final VoidCallback onAction;

  const _ToastBody({
    required this.message,
    required this.kind,
    required this.actionLabel,
    required this.lifetime,
    required this.onAction,
  });

  IconData get _icon {
    switch (kind) {
      case ToastKind.success:
        return Icons.check_rounded;
      case ToastKind.info:
        return Icons.info_outline_rounded;
      case ToastKind.warning:
        return Icons.priority_high_rounded;
      case ToastKind.error:
        return Icons.close_rounded;
    }
  }

  LinearGradient get _badgeGradient {
    switch (kind) {
      case ToastKind.success:
        return PokeBinderColors.goldGradient;
      case ToastKind.info:
        return PokeBinderColors.tealGradient;
      case ToastKind.warning:
        return PokeBinderColors.goldGradient;
      case ToastKind.error:
        return PokeBinderColors.redGradient;
    }
  }

  Color get _iconColor =>
      kind == ToastKind.error ? PokeBinderColors.white : PokeBinderColors.ink;

  Color get _accent {
    switch (kind) {
      case ToastKind.success:
      case ToastKind.warning:
        return PokeBinderColors.gold;
      case ToastKind.info:
        return const Color(0xFF8FD0D8);
      case ToastKind.error:
        return const Color(0xFFE0402A);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasAction = actionLabel != null;

    return Semantics(
      liveRegion: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: PokeBinderColors.white.withValues(alpha: 0.10),
          ),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF332B27), PokeBinderColors.ink],
          ),
          boxShadow: [
            BoxShadow(
              color: PokeBinderColors.ink.withValues(alpha: 0.35),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                  PokeBinderSpacing.sp3,
                  PokeBinderSpacing.sp3,
                  hasAction ? PokeBinderSpacing.sp2 : PokeBinderSpacing.sp4,
                  PokeBinderSpacing.sp3 + 3,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: _badgeGradient,
                        boxShadow: [
                          BoxShadow(
                            color: _accent.withValues(alpha: 0.35),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Icon(_icon, size: 18, color: _iconColor),
                    ),
                    const SizedBox(width: PokeBinderSpacing.sp3),
                    Expanded(
                      child: Text(
                        message,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: PokeBinderText.chakraPetch(const TextStyle(
                          fontSize: 13.5,
                          height: 1.3,
                          fontWeight: FontWeight.w600,
                          color: PokeBinderColors.white,
                        )),
                      ),
                    ),
                    if (hasAction) ...[
                      const SizedBox(width: PokeBinderSpacing.sp2),
                      _ActionPill(
                        label: actionLabel!,
                        color: _accent,
                        onTap: onAction,
                      ),
                    ],
                  ],
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 3,
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 1, end: 0),
                  duration: lifetime,
                  builder: (context, value, _) => Align(
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: value,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: _accent.withValues(alpha: 0.85),
                        ),
                        child: const SizedBox.expand(),
                      ),
                    ),
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

class _ActionPill extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionPill({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.16),
      shape: StadiumBorder(
        side: BorderSide(color: color.withValues(alpha: 0.45)),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 36, minWidth: 56),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: PokeBinderSpacing.sp4,
            ),
            child: Center(
              widthFactor: 1,
              child: Text(
                label.toUpperCase(),
                style: PokeBinderText.chakraPetch(TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                  color: color,
                )),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
