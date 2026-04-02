import 'package:flutter/material.dart';
import '../services/notification_service.dart';
import '../theme/quotesy_theme.dart';

class DebugNotificationsSheet extends StatelessWidget {
  const DebugNotificationsSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const DebugNotificationsSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: QColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Debug Notifications',
                style: TextStyle(
                  fontFamily: 'Playfair Display',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: QColors.textPrimary,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: QColors.textGhost),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _DebugButton(
            label: 'Test Daily Wisdom',
            subtitle: 'Quiet, 9:00 AM style',
            icon: Icons.lightbulb_outline,
            onTap: () => NotificationService().testDailyQuote(),
          ),
          const SizedBox(height: 12),
          _DebugButton(
            label: 'Test Streak Reminder',
            subtitle: 'Loud, 8:00 PM style',
            icon: Icons.fireplace_outlined,
            onTap: () => NotificationService().testStreakReminder(),
          ),
          const SizedBox(height: 12),
          _DebugButton(
            label: 'Test Streak Broken',
            subtitle: 'Loud, 9:00 AM break alert',
            icon: Icons.error_outline,
            onTap: () => NotificationService().testStreakBreak(),
          ),
          const SizedBox(height: 12),
          _DebugButton(
            label: 'Test Streak Restored',
            subtitle: 'Loud, success confirmation',
            icon: Icons.check_circle_outline,
            onTap: () => NotificationService().testStreakRestored(),
          ),
          const SizedBox(height: 12),
          _DebugButton(
            label: 'Notification Diagnostics',
            subtitle: 'Permission, exact alarm, pending queue',
            icon: Icons.health_and_safety_outlined,
            onTap: () => _showDiagnostics(context),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Future<void> _showDiagnostics(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (_) => const _DiagnosticsDialog(),
    );
  }
}

class _DiagnosticsDialog extends StatelessWidget {
  const _DiagnosticsDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: QColors.surface,
      title: const Text(
        'Notification Diagnostics',
        style: TextStyle(
          fontFamily: 'Playfair Display',
          color: QColors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
      content: SizedBox(
        width: 420,
        child: FutureBuilder<NotificationDiagnostics>(
          future: NotificationService().getDiagnostics(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              if (snapshot.hasError) {
                return Text(
                  'Failed to load diagnostics: ${snapshot.error}',
                  style: const TextStyle(color: QColors.textGhost),
                );
              }
              return const SizedBox(
                height: 72,
                child: Center(
                  child: CircularProgressIndicator(color: QColors.amberGlow),
                ),
              );
            }

            final data = snapshot.data!;
            final lines = <String>[
              'Notifications enabled: ${data.notificationsEnabled ?? 'unknown'}',
              'Can schedule exact alarms: ${data.canScheduleExact ?? 'unknown'}',
              'Selected schedule mode: ${data.scheduleMode.name}',
              'Total pending notifications: ${data.pendingCount}',
              'Daily quote pending (IDs 100-106): ${data.dailyQuotePendingCount}',
            ];

            if (data.pendingSummary.isNotEmpty) {
              lines.add('');
              lines.add('Pending IDs:');
              lines.addAll(data.pendingSummary.take(12));
              if (data.pendingSummary.length > 12) {
                lines.add('... ${data.pendingSummary.length - 12} more');
              }
            }

            return SingleChildScrollView(
              child: SelectableText(
                lines.join('\n'),
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  height: 1.4,
                  color: QColors.textPrimary,
                ),
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            'Close',
            style: TextStyle(color: QColors.amberGlow),
          ),
        ),
      ],
    );
  }
}

class _DebugButton extends StatelessWidget {
  const _DebugButton({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          backgroundColor: QColors.obsidian,
          padding: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: QColors.borderMid, width: 0.5),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: QColors.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: QColors.amberGlow, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: QColors.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: QColors.textGhost,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: QColors.textGhost,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
