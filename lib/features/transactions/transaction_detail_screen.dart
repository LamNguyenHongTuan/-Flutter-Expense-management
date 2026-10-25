import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/models/transaction_model.dart';
import 'add_transaction_screen.dart';

class TransactionDetailScreen extends StatelessWidget {
  final Transaction transaction;
  const TransactionDetailScreen({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(
        locale: 'vi_VN', symbol: '₫', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Receipt Detail'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Edit',
            onPressed: () async {
              final updated = await Navigator.push<Transaction>(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      AddTransactionScreen(existing: transaction),
                ),
              );
              if (updated != null && context.mounted) {
                Navigator.pop(context, updated);
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Receipt image ─────────────────────────────────────────
            if (transaction.receiptImagePath != null)
              SizedBox(
                height: 220,
                width: double.infinity,
                child: Image.file(
                  File(transaction.receiptImagePath!),
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.broken_image,
                        size: 64, color: Colors.grey),
                  ),
                ),
              )
            else
              Container(
                height: 120,
                width: double.infinity,
                color: transaction.category.color.withValues(alpha: 0.15),
                child: Icon(transaction.category.icon,
                    size: 52, color: transaction.category.color),
              ),

            // ── Details ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DetailRow(
                      icon: Icons.store,
                      label: 'Merchant',
                      value: transaction.merchantName),
                  _DetailRow(
                    icon: Icons.attach_money,
                    label: 'Amount',
                    value: fmt.format(transaction.amount),
                    valueStyle: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: transaction.category.color),
                  ),
                  _DetailRow(
                      icon: transaction.category.icon,
                      label: 'Category',
                      value: transaction.category.displayName),
                  _DetailRow(
                      icon: Icons.calendar_today,
                      label: 'Date',
                      value: DateFormat('EEEE, dd MMMM yyyy')
                          .format(transaction.date)),
                  if (transaction.notes != null &&
                      transaction.notes!.isNotEmpty)
                    _DetailRow(
                        icon: Icons.note_alt_outlined,
                        label: 'Notes',
                        value: transaction.notes!),

                  // ── Raw OCR ─────────────────────────────────────────
                  if (transaction.rawOcrText != null) ...[
                    const Divider(height: 32),
                    const Text('OCR Raw Text',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: Colors.grey.withValues(alpha: 0.2)),
                      ),
                      child: SelectableText(transaction.rawOcrText!,
                          style: const TextStyle(
                              fontFamily: 'monospace', fontSize: 12)),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final TextStyle? valueStyle;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 2),
                Text(value,
                    style: valueStyle ??
                        const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
