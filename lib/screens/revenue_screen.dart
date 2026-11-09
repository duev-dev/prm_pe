import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/models.dart';
import '../providers/providers.dart';
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

    return Scaffold(
      appBar: AppBar(title: const Text('Thống kê doanh thu')),
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
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 12),
                color: Theme.of(context).colorScheme.primaryContainer,
                child: ListTile(
                  leading: const Icon(Icons.attach_money, size: 40),
                  title: const Text('Tổng doanh thu'),
                  subtitle: Text('${list.length} đơn hàng'),
                  trailing: Text(money(revenue), style: Theme.of(context).textTheme.headlineSmall),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: list.isEmpty
                    ? const Center(child: Text('Chưa có đơn hàng'))
                    : ListView.builder(
                        itemCount: list.length,
                        itemBuilder: (_, i) => ListTile(
                          leading: const Icon(Icons.receipt_long),
                          title: Text('Đơn #${list[i].id}'),
                          subtitle: Text(_fmt(list[i].createdAt)),
                          trailing: Text(money(list[i].total)),
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
