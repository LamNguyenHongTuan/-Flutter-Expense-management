import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/models/transaction_model.dart';
import '../../core/theme/app_theme.dart';
import 'painters/donut_chart_painter.dart';
import 'painters/bar_chart_painter.dart';

class AnalyticsScreen extends StatefulWidget {
  final List<Transaction> transactions;
  const AnalyticsScreen({super.key, required this.transactions});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animCtrl;
  late final Animation<double> _anim;

  String? _selectedCategory;
  int? _selectedBarIndex;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _anim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeInOut);
    _animCtrl.forward();
  }

  @override
  void didUpdateWidget(AnalyticsScreen old) {
    super.didUpdateWidget(old);
    if (old.transactions.length != widget.transactions.length) {
      _selectedCategory = null;
      _selectedBarIndex = null;
      _animCtrl
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  // ── Data helpers ────────────────────────────────────────────────────────

  Map<String, double> get _categoryTotals {
    final totals = <String, double>{};
    for (final t in widget.transactions) {
      totals[t.category.displayName] =
          (totals[t.category.displayName] ?? 0) + t.amount;
    }
    return totals;
  }

  List<Map<String, dynamic>> get _weeklyData {
    final now = DateTime.now();
    return List.generate(7, (i) {
      final day = now.subtract(Duration(days: 6 - i));
      final dayStr = DateFormat('yyyy-MM-dd').format(day);
      final total = widget.transactions
          .where((t) => DateFormat('yyyy-MM-dd').format(t.date) == dayStr)
          .fold(0.0, (s, t) => s + t.amount);
      return {'day': DateFormat('EEE').format(day), 'total': total, 'date': day};
    });
  }

  void _onDonutTap(TapUpDetails details, Size chartSize, Map<String, double> cats) {
    if (cats.isEmpty) return;
    final center = Offset(chartSize.width / 2, chartSize.height / 2);
    final touch = details.localPosition;
    final distance = (touch - center).distance;
    final outerRadius = min(chartSize.width, chartSize.height) / 2 - 16;
    const strokeWidth = 46.0;

    // Check if tap fell inside the donut ring
    if (distance >= outerRadius - strokeWidth && distance <= outerRadius + 20) {
      // Calculate angle from 12 o'clock (-pi/2)
      var touchAngle = atan2(touch.dy - center.dy, touch.dx - center.dx) + (pi / 2.0);
      if (touchAngle < 0) touchAngle += 2 * pi;

      final total = cats.values.fold(0.0, (a, b) => a + b);
      var currentAngle = 0.0;
      String? foundCat;

      for (final entry in cats.entries) {
        final sweep = (entry.value / total) * 2 * pi;
        if (touchAngle >= currentAngle && touchAngle <= currentAngle + sweep) {
          foundCat = entry.key;
          break;
        }
        currentAngle += sweep;
      }

      setState(() {
        _selectedCategory = _selectedCategory == foundCat ? null : foundCat;
      });
    } else {
      // Tap outside or in center clears selection
      setState(() {
        _selectedCategory = null;
      });
    }
  }

  void _onBarTap(TapUpDetails details, Size chartSize) {
    const padLeft = 44.0;
    const padRight = 12.0;
    final chartW = chartSize.width - padLeft - padRight;
    final barSlot = chartW / 7;
    final touchX = details.localPosition.dx;

    if (touchX >= padLeft && touchX <= chartSize.width - padRight) {
      final index = ((touchX - padLeft) / barSlot).floor().clamp(0, 6);
      setState(() {
        _selectedBarIndex = _selectedBarIndex == index ? null : index;
      });
    } else {
      setState(() {
        _selectedBarIndex = null;
      });
    }
  }

  // ── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);
    final total = widget.transactions.fold(0.0, (s, t) => s + t.amount);
    final cats = _categoryTotals;
    final weekly = _weeklyData;

    return CustomScrollView(
      slivers: [
        const SliverAppBar(
          pinned: true,
          title: Text('Expense Analytics', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // ── Summary Cards ──────────────────────────────────────
              Row(
                children: [
                  _SummaryCard(
                    label: 'Total Expenses',
                    value: fmt.format(total),
                    icon: Icons.account_balance_wallet_outlined,
                  ),
                  const SizedBox(width: 12),
                  _SummaryCard(
                    label: 'Receipts Scanned',
                    value: '${widget.transactions.length}',
                    icon: Icons.receipt_long_outlined,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── Donut Chart Card ───────────────────────────────────
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Category Breakdown',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          if (_selectedCategory != null)
                            TextButton(
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                              ),
                              onPressed: () => setState(() => _selectedCategory = null),
                              child: const Text('Reset Selection'),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      widget.transactions.isEmpty
                          ? const _EmptyChart('No receipts to display')
                          : LayoutBuilder(
                              builder: (context, constraints) {
                                final chartSize = Size(constraints.maxWidth, 230);
                                return GestureDetector(
                                  onTapUp: (details) => _onDonutTap(details, chartSize, cats),
                                  child: AnimatedBuilder(
                                    animation: _anim,
                                    builder: (_, __) => CustomPaint(
                                      size: chartSize,
                                      painter: DonutChartPainter(
                                        data: cats,
                                        progress: _anim.value,
                                        categoryColors: AppTheme.categoryColors,
                                        selectedCategory: _selectedCategory,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                      if (cats.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _buildInteractiveLegend(cats, fmt),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Bar Chart Card ─────────────────────────────────────
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '7-Day Spending Trend',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          if (_selectedBarIndex != null)
                            Text(
                              fmt.format(weekly[_selectedBarIndex!]['total'] as double),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final chartSize = Size(constraints.maxWidth, 210);
                          return GestureDetector(
                            onTapUp: (details) => _onBarTap(details, chartSize),
                            child: AnimatedBuilder(
                              animation: _anim,
                              builder: (_, __) => CustomPaint(
                                size: chartSize,
                                painter: BarChartPainter(
                                  data: weekly,
                                  progress: _anim.value,
                                  barColor: AppTheme.primaryColor,
                                  selectedIndex: _selectedBarIndex,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildInteractiveLegend(Map<String, double> cats, NumberFormat fmt) {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: cats.entries.map((e) {
        final isSelected = e.key == _selectedCategory;
        final color = AppTheme.categoryColors[e.key] ?? Colors.grey;

        return InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            setState(() {
              _selectedCategory = isSelected ? null : e.key;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected ? color.withValues(alpha: 0.18) : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? color : Colors.grey.withValues(alpha: 0.3),
                width: isSelected ? 1.5 : 1.0,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${e.key} (${fmt.format(e.value)})',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? color : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: AppTheme.primaryColor, size: 24),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyChart extends StatelessWidget {
  final String message;
  const _EmptyChart(this.message);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 140,
      child: Center(
        child: Text(message, style: const TextStyle(color: Colors.grey, fontSize: 14)),
      ),
    );
  }
}
