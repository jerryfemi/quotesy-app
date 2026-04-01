import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../../services/notification_service.dart';
import '../../models/streak_model.dart';
import '../../theme/quotesy_theme.dart';
import 'streak_reusables.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Restore section — shown only when canRestore is true
// ─────────────────────────────────────────────────────────────────────────────
class StreakRestoreSection extends ConsumerStatefulWidget {
  const StreakRestoreSection({super.key, required this.streak});
  final StreakData streak;

  @override
  ConsumerState<StreakRestoreSection> createState() =>
      _StreakRestoreSectionState();
}

class _StreakRestoreSectionState extends ConsumerState<StreakRestoreSection> {
  bool _isProcessing = false;
  bool _showSuccess = false;

  @override
  Widget build(BuildContext context) {
    // previousStreak + all gap days + today
    final brokenFrom = StreakData.dateOnly(widget.streak.brokenFromDate!);
    final today = StreakData.dateOnly(DateTime.now());
    final restoredCount =
        widget.streak.previousStreak + today.difference(brokenFrom).inDays;
    final gapDays = today.difference(brokenFrom).inDays - 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const StreakSectionLabel(label: 'Restore streak'),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: QColors.amberSubtle.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: QColors.amber.withValues(alpha: 0.25),
              width: 1,
            ),
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _showSuccess
                ? _buildSuccessState(restoredCount)
                : Column(
                    key: const ValueKey('restore_ui'),
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Before → after preview row with spark
                      Row(
                        children: [
                          const StreakPreviewPill(
                            label: '1 day',
                            isAfter: false,
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 10),
                            child: Icon(
                              Icons.arrow_forward_rounded,
                              size: 14,
                              color: QColors.textSubtle,
                            ),
                          ),
                          StreakPreviewPill(
                            label: '$restoredCount days',
                            isAfter: true,
                          ),
                          const SizedBox(width: 8),
                          const Text('✨', style: TextStyle(fontSize: 14)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Reclaim your ${widget.streak.previousStreak}-day streak. '
                        "We'll bridge the $gapDays-day gap so you "
                        'continue from Day $restoredCount today.',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          color: QColors.textSubtle,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ── RevenueCat Payment Flow ──
                      SizedBox(
                        width: double.infinity,
                        child: TextButton(
                          onPressed: _isProcessing
                              ? null
                              : () async {
                                  setState(() => _isProcessing = true);
                                  try {
                                    // Initiate purchase of the streak repair consumable
                                    final products =
                                        await Purchases.getProducts(
                                          ['streak_repair_99'],
                                          productCategory:
                                              ProductCategory.nonSubscription,
                                        );
                                    if (products.isEmpty) {
                                      throw Exception('Product not found');
                                    }
                                    await Purchases.purchase(
                                      PurchaseParams.storeProduct(
                                        products.first,
                                      ),
                                    );

                                    // If execution reaches here, purchase was successful
                                    if (mounted) {
                                      HapticFeedback.heavyImpact();
                                      setState(() {
                                        _showSuccess = true;
                                        _isProcessing = false;
                                      });

                                      // Wait to allow the success animation to play
                                      await Future.delayed(
                                        const Duration(milliseconds: 2000),
                                      );

                                      if (mounted) {
                                        ref
                                            .read(streakProvider.notifier)
                                            .restoreStreak();

                                        // Final confirmation notification
                                        NotificationService().showInstantAlert(
                                          'Streak Restored!',
                                          'You are back to a $restoredCount-day streak.',
                                        );
                                      }
                                    }
                                  } on PlatformException catch (e) {
                                    var errorCode =
                                        PurchasesErrorHelper.getErrorCode(e);
                                    if (errorCode !=
                                        PurchasesErrorCode
                                            .purchaseCancelledError) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Purchase failed. Please try again.',
                                            ),
                                            backgroundColor: QColors.danger,
                                            behavior: SnackBarBehavior.floating,
                                          ),
                                        );
                                      }
                                    }
                                  } finally {
                                    if (mounted && !_showSuccess) {
                                      setState(() => _isProcessing = false);
                                    }
                                  }
                                },
                          style: TextButton.styleFrom(
                            backgroundColor: QColors.amber,
                            disabledBackgroundColor: QColors.amber.withValues(
                              alpha: 0.5,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isProcessing
                              ? const SizedBox(
                                  height: 16,
                                  width: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      QColors.obsidian,
                                    ),
                                  ),
                                )
                              : const Text(
                                  'Restore streak · \$0.99',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: QColors.obsidian,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 6),

                      // "Start fresh" — real action with confirmation
                      Center(
                        child: TextButton(
                          onPressed: () => _confirmDismiss(context, ref),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            'No thanks, start fresh',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              color: QColors.textSubtle,
                              decoration: TextDecoration.underline,
                              decorationColor: QColors.textGhost,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessState(int restoredCount) {
    return Container(
      key: const ValueKey('success_state'),
      padding: const EdgeInsets.symmetric(vertical: 24),
      width: double.infinity,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: QColors.amber.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              color: QColors.amber,
              size: 32,
            ),
          ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
          const SizedBox(height: 16),
          const Text(
                'Streak Restored!',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: QColors.amber,
                ),
              )
              .animate()
              .fadeIn(delay: 200.ms)
              .slideY(begin: 0.2, end: 0, duration: 400.ms),
          const SizedBox(height: 8),
          Text(
            'You are back to a $restoredCount-day streak.',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: QColors.textSubtle,
            ),
          ).animate().fadeIn(delay: 400.ms),
        ],
      ),
    );
  }

  Future<void> _confirmDismiss(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: QColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: QColors.borderMid, width: 0.5),
        ),
        title: const Text(
          'Start fresh?',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: QColors.textPrimary,
          ),
        ),
        content: Text(
          'Your ${widget.streak.previousStreak}-day streak will be gone forever. '
          'This can\'t be undone.',
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            color: QColors.textSubtle,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(false),
            child: const Text(
              'Keep it',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: QColors.textMuted,
              ),
            ),
          ),
          TextButton(
            onPressed: () => context.pop(true),
            child: const Text(
              'Start fresh',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: QColors.danger,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      ref.read(streakProvider.notifier).dismissRestore();
    }
  }
}
