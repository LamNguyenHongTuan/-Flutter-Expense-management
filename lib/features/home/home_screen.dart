import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/database/database_helper.dart';
import '../../core/models/transaction_model.dart';
import '../../core/theme/app_theme.dart';
import '../analytics/analytics_screen.dart';
import '../camera/camera_screen.dart';
import '../transactions/transaction_detail_screen.dart';
import '../transactions/add_transaction_screen.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;
  const HomeScreen({super.key, required this.onToggleTheme});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin {
  List<Transaction> _transactions = [];
  bool _isLoading = true;
  int _currentIndex = 0;
  late AnimationController _fabController;
  late Animation<double> _fabAnimation;

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _fabAnimation =
        CurvedAnimation(parent: _fabController, curve: Curves.elasticOut);
    _fabController.forward();
    _loadTransactions();
  }

  @override
  void dispose() {
    _fabController.dispose();
    super.dispose();
  }

  Future<void> _loadTransactions() async {
    setState(() => _isLoading = true);
    final txns = await DatabaseHelper.instance.getAllTransactions();
    setState(() {
      _transactions = txns;
      _isLoading = false;
    });
  }

  double get _thisMonthSpending {
    final now = DateTime.now();
    return _transactions
        .where(
            (t) => t.date.year == now.year && t.date.month == now.month)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double get _totalSpending =>
      _transactions.fold(0.0, (sum, t) => sum + t.amount);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildHomeTab(),
          AnalyticsScreen(transactions: _transactions),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Home'),
          NavigationDestination(
              icon: Icon(Icons.pie_chart_outline),
              selectedIcon: Icon(Icons.pie_chart),
              label: 'Analytics'),
        ],
      ),
      floatingActionButton: ScaleTransition(
        scale: _fabAnimation,
        child: FloatingActionButton.extended(
          onPressed: _showScanOptions,
          icon: const Icon(Icons.camera_alt),
          label: const Text('Scan Receipt'),
        ),
      ),
    );
  }

  Widget _buildHomeTab() {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 200,
          floating: false,
          pinned: true,
          title: const Text('Receipt Scanner',
              style: TextStyle(fontWeight: FontWeight.bold)),
          actions: [
            IconButton(
                icon: const Icon(Icons.brightness_6),
                onPressed: widget.onToggleTheme),
            IconButton(
                icon: const Icon(Icons.add),
                onPressed: _navigateToAddTransaction),
          ],
          flexibleSpace:
              FlexibleSpaceBar(background: _buildSpendingHeader()),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: _isLoading
              ? const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()))
              : _transactions.isEmpty
                  ? SliverFillRemaining(child: _buildEmptyState())
                  : SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (ctx, i) => _TransactionCard(
                          transaction: _transactions[i],
                          onTap: () =>
                              _navigateToDetail(_transactions[i]),
                          onDelete: () =>
                              _deleteTransaction(_transactions[i]),
                        ),
                        childCount: _transactions.length,
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildSpendingHeader() {
    final fmt = NumberFormat.currency(
        locale: 'vi_VN', symbol: '₫', decimalDigits: 0);
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.primaryColor, Color(0xFF9C8FFF)],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 56, 24, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('This Month',
                  style: TextStyle(color: Colors.white70, fontSize: 14)),
              Text(
                fmt.format(_thisMonthSpending),
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Total: ${fmt.format(_totalSpending)}  •  ${_transactions.length} receipts',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined,
              size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text('No receipts yet!',
              style: TextStyle(
                  fontSize: 20,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Tap the camera button to scan your first receipt',
              style: TextStyle(color: Colors.grey.shade500),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  void _showScanOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 24),
            const Text('Add Receipt',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ListTile(
              leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.camera_alt,
                      color: AppTheme.primaryColor)),
              title: const Text('Scan with Camera'),
              subtitle: const Text('Use ML Kit OCR (offline)'),
              onTap: () {
                Navigator.pop(ctx);
                _navigateToCamera();
              },
            ),
            ListTile(
              leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: AppTheme.secondaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.add_circle_outline,
                      color: AppTheme.secondaryColor)),
              title: const Text('Add Manually'),
              subtitle: const Text('Enter expense details'),
              onTap: () {
                Navigator.pop(ctx);
                _navigateToAddTransaction();
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _navigateToCamera() async {
    final result = await Navigator.push<Transaction>(
      context,
      MaterialPageRoute(builder: (_) => const CameraScreen()),
    );
    if (result != null) {
      await DatabaseHelper.instance.insertTransaction(result);
      _loadTransactions();
    }
  }

  Future<void> _navigateToAddTransaction() async {
    final result = await Navigator.push<Transaction>(
      context,
      MaterialPageRoute(builder: (_) => const AddTransactionScreen()),
    );
    if (result != null) {
      await DatabaseHelper.instance.insertTransaction(result);
      _loadTransactions();
    }
  }

  Future<void> _navigateToDetail(Transaction t) async {
    final updated = await Navigator.push<Transaction>(
      context,
      MaterialPageRoute(
          builder: (_) => TransactionDetailScreen(transaction: t)),
    );
    if (updated != null) {
      await DatabaseHelper.instance.updateTransaction(updated);
      _loadTransactions();
    }
  }

  Future<void> _deleteTransaction(Transaction t) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Receipt'),
        content:
            const Text('Are you sure you want to delete this receipt?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (confirm == true) {
      await DatabaseHelper.instance.deleteTransaction(t.id);
      _loadTransactions();
    }
  }
}

// ─── Transaction Card ─────────────────────────────────────────────────────

class _TransactionCard extends StatelessWidget {
  final Transaction transaction;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _TransactionCard(
      {required this.transaction,
      required this.onTap,
      required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(
        locale: 'vi_VN', symbol: '₫', decimalDigits: 0);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Dismissible(
        key: Key(transaction.id),
        direction: DismissDirection.endToStart,
        onDismissed: (_) => onDelete(),
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
              color: Colors.red, borderRadius: BorderRadius.circular(16)),
          child: const Icon(Icons.delete, color: Colors.white),
        ),
        child: Card(
          child: ListTile(
            onTap: onTap,
            leading: transaction.receiptImagePath != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(
                      File(transaction.receiptImagePath!),
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => CircleAvatar(
                        backgroundColor: transaction.category.color.withValues(alpha: 0.2),
                        child: Icon(transaction.category.icon, color: transaction.category.color),
                      ),
                    ),
                  )
                : CircleAvatar(
                    backgroundColor: transaction.category.color.withValues(alpha: 0.2),
                    child: Icon(transaction.category.icon, color: transaction.category.color),
                  ),
            title: Text(transaction.merchantName,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(
                '${transaction.category.displayName} • ${DateFormat('dd MMM yyyy').format(transaction.date)}'),
            trailing: Text(
              fmt.format(transaction.amount),
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                  fontSize: 15),
            ),
          ),
        ),
      ),
    );
  }
}
