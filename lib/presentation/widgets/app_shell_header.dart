import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// The app's consistent top bar used across Home, Check-In, Check-Out,
/// Attendance and Settings: optional back button, logo, title/subtitle,
/// a printer-status pill, and a settings-gear button.
///
/// This replaces the stock [AppBar] on shell pages — the design's hairline
/// bottom border and pill-shaped status chip aren't expressible via
/// [AppBarTheme], so each page places this widget at the top of its body
/// [Column] instead of using the `appBar:` slot.
class AppShellHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool showBackButton;
  final VoidCallback? onBack;
  final VoidCallback onSettings;
  final bool printerConnected;

  const AppShellHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.showBackButton = false,
    this.onBack,
    required this.onSettings,
    required this.printerConnected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(bottom: BorderSide(color: AppTheme.hairline)),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            if (showBackButton) ...[
              _CircleIconButton(
                onTap: onBack ?? () => Navigator.of(context).maybePop(),
                child: const Icon(Icons.arrow_back, size: 20),
              ),
              const SizedBox(width: 12),
            ],
            Image.asset(
              'assets/images/kids_church_logo.png',
              height: 34,
              width: 34,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  if (subtitle != null && subtitle!.isNotEmpty)
                    Text(
                      subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _PrinterPill(connected: printerConnected),
            const SizedBox(width: 8),
            _CircleIconButton(
              onTap: onSettings,
              child: const Icon(Icons.settings_outlined, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrinterPill extends StatelessWidget {
  final bool connected;

  const _PrinterPill({required this.connected});

  @override
  Widget build(BuildContext context) {
    final bg = connected ? const Color(0xFFE6F5EA) : AppTheme.errorBg;
    final border = connected ? const Color(0xFFC7E6D0) : AppTheme.errorBorder;
    final fg = connected ? const Color(0xFF1F6E39) : const Color(0xFF8E2A1F);
    final dot = connected ? AppTheme.green : AppTheme.error;
    final label = connected ? 'Printer ready' : 'No printer';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final VoidCallback onTap;
  final Widget child;

  const _CircleIconButton({required this.onTap, required this.child});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppTheme.inputBorder, width: 1.5),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: SizedBox(width: 44, height: 44, child: Center(child: child)),
      ),
    );
  }
}
