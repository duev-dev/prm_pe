import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/models.dart';
import '../providers/providers.dart';
import '../ui.dart';
import 'product_list_screen.dart';

enum RevenuePeriod { all, day, month, year }

/// Orders in the same day / month / year as [now].
List<Order> ordersInPeriod(List<Order> orders, RevenuePeriod period, DateTime now) => orders.where((o) {
  final d = o.createdAt;
  return switch (period) {
    RevenuePeriod.all => true,
    RevenuePeriod.year => d.year == now.year,
    RevenuePeriod.month => d.year == now.year && d.month == now.month,
    RevenuePeriod.day => d.year == now.year && d.month == now.month && d.day == now.day,
  };
}).toList();

class RevenueScreen extends ConsumerStatefulWidget {
  const RevenueScreen({super.key});

  @override
  ConsumerState<RevenueScreen> createState() => _RevenueScreenState();
}

class _RevenueScreenState extends ConsumerState<RevenueScreen> {
  RevenuePeriod _period = RevenuePeriod.all;

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} '
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final orders = ref.watch(ordersProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Thống kê doanh thu', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
      ),
      body: orders.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Lỗi: $e')),
        data: (all) {
          final list = ordersInPeriod(all, _period, DateTime.now());
          final revenue = list.fold<double>(0, (s, o) => s + o.total);
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: SegmentedButton<RevenuePeriod>(
                  segments: const [
                    ButtonSegment(value: RevenuePeriod.all, label: Text('Tất cả')),
                    ButtonSegment(value: RevenuePeriod.day, label: Text('Hôm nay')),
                    ButtonSegment(value: RevenuePeriod.month, label: Text('Tháng')),
                    ButtonSegment(value: RevenuePeriod.year, label: Text('Năm')),
                  ],
                  selected: {_period},
                  onSelectionChanged: (s) => setState(() => _period = s.first),
                ),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 12),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: brandGradient,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF7B2FF7).withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Tổng doanh thu', style: TextStyle(color: Colors.white.withValues(alpha: 0.85))),
                          const SizedBox(height: 4),
                          // Counts up from 0 whenever the total changes.
                          TweenAnimationBuilder<double>(
                            key: ValueKey(revenue),
                            tween: Tween(begin: 0, end: revenue),
                            duration: const Duration(milliseconds: 900),
                            curve: Curves.easeOutCubic,
                            builder: (_, v, _) => Text(
                              money(v),
                              style: theme.textTheme.headlineMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text('${list.length} đơn hàng', style: const TextStyle(color: Colors.white)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.2)),
                      child: const Icon(Icons.trending_up_rounded, color: Colors.white, size: 36),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: list.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.receipt_long_outlined,
                              size: 64,
                              color: theme.colorScheme.primary.withValues(alpha: 0.4),
                            ),
                            const SizedBox(height: 8),
                            const Text('Chưa có đơn hàng'),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                        itemCount: list.length,
                        itemBuilder: (_, i) => FadeSlideIn(
                          key: ValueKey(list[i].id),
                          index: i,
                          child: Card(
                            margin: const EdgeInsets.symmetric(vertical: 5),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: theme.colorScheme.primaryContainer,
                                child: Icon(Icons.receipt_long, color: theme.colorScheme.primary),
                              ),
                              title: Text('Đơn #${list[i].id}', style: const TextStyle(fontWeight: FontWeight.w600)),
                              subtitle: Text(_fmt(list[i].createdAt)),
                              trailing: Text(
                                money(list[i].total),
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
