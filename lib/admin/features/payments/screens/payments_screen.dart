import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/app_providers.dart';
import '../../../models/app_models.dart';

class PaymentsScreen extends ConsumerWidget {
  const PaymentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final payments = ref.watch(paymentsProvider);
    final isTamil = ref.watch(languageProvider) == 'ta';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final totalReceived = payments.where((p) => p.isPaid).fold<double>(0, (sum, p) => sum + p.amount);
    final totalPending = payments.where((p) => !p.isPaid).fold<double>(0, (sum, p) => sum + p.amount);

    return Scaffold(
      appBar: AppBar(
        title: Text(isTamil ? 'கட்டணங்கள்' : 'Payments & Invoicing'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Financial Summary Cards
          Row(
            children: [
              Expanded(
                child: Card(
                  color: isDark ? const Color(0xFF162E25) : const Color(0xFFECFDF5),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Collected', style: TextStyle(color: AppColors.success, fontSize: 12, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        Text(
                          'LKR ${totalReceived.toStringAsFixed(0)}',
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.success),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Card(
                  color: isDark ? const Color(0xFF3B1E1E) : const Color(0xFFFEF2F2),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Pending / Due', style: TextStyle(color: AppColors.danger, fontSize: 12, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        Text(
                          'LKR ${totalPending.toStringAsFixed(0)}',
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.danger),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          Text(
            isTamil ? 'மாணவர் கட்டணப் பதிவுகள்' : 'Student Payment Schedules',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),

          ...payments.map((pay) {
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: (pay.isPaid ? AppColors.success : AppColors.warning).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        pay.isPaid ? Icons.check_circle_outline : Icons.pending_outlined,
                        color: pay.isPaid ? AppColors.success : AppColors.warning,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(pay.memberName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(height: 2),
                          Text('${pay.groupName} • ${pay.scheduleType}', style: TextStyle(fontSize: 12, color: isDark ? AppColors.mutedDark : AppColors.mutedLight)),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${pay.currency} ${pay.amount.toStringAsFixed(0)}',
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                        ),
                        const SizedBox(height: 4),
                        if (!pay.isPaid)
                          InkWell(
                            onTap: () {
                              ref.read(paymentsProvider.notifier).update((list) {
                                return list.map((item) {
                                  if (item.id == pay.id) {
                                    return PaymentModel(
                                      id: item.id,
                                      memberName: item.memberName,
                                      groupName: item.groupName,
                                      amount: item.amount,
                                      currency: item.currency,
                                      scheduleType: item.scheduleType,
                                      dueDate: item.dueDate,
                                      isPaid: true,
                                      paidAt: DateTime.now(),
                                    );
                                  }
                                  return item;
                                }).toList();
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Marked payment for ${pay.memberName} as PAID!')),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.accent,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text('Mark Paid', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                            ),
                          )
                        else
                          const Text('Paid', style: TextStyle(color: AppColors.success, fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
