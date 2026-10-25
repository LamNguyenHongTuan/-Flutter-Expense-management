import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../core/models/transaction_model.dart';
import '../../core/services/receipt_parser.dart';
import '../../core/theme/app_theme.dart';

class ReviewScreen extends StatefulWidget {
  final String imagePath;
  final ParsedReceipt parsedReceipt;
  final String rawOcrText;

  const ReviewScreen({
    super.key,
    required this.imagePath,
    required this.parsedReceipt,
    required this.rawOcrText,
  });

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  late final TextEditingController _merchantCtrl;
  late final TextEditingController _amountCtrl;
  late final TextEditingController _notesCtrl;
  late DateTime _selectedDate;
  late ExpenseCategory _selectedCategory;
  bool _showRawText = false;

  @override
  void initState() {
    super.initState();
    _merchantCtrl = TextEditingController(
        text: widget.parsedReceipt.merchantName ?? '');
    _amountCtrl = TextEditingController(
        text: widget.parsedReceipt.totalAmount?.toStringAsFixed(0) ?? '');
    _notesCtrl = TextEditingController();
    _selectedDate = widget.parsedReceipt.date ?? DateTime.now();
    _selectedCategory = ExpenseCategory.other;
  }

  @override
  void dispose() {
    _merchantCtrl.dispose();
    _amountCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  void _save() {
    final amountStr = _amountCtrl.text.trim().replaceAll(',', '');
    final amount = double.tryParse(amountStr);

    if (_merchantCtrl.text.trim().isEmpty) {
      _showError('Please enter a merchant name.');
      return;
    }
    if (amount == null || amount <= 0) {
      _showError('Please enter a valid amount greater than 0.');
      return;
    }

    Navigator.pop(
      context,
      Transaction(
        id: const Uuid().v4(),
        merchantName: _merchantCtrl.text.trim(),
        amount: amount,
        date: _selectedDate,
        category: _selectedCategory,
        receiptImagePath: widget.imagePath,
        rawOcrText: widget.rawOcrText,
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      ),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final ocrLines = widget.rawOcrText.split('\n').length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Receipt'),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('Save',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Receipt image preview ───────────────────────────────────
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                height: 180,
                width: double.infinity,
                child: Image.file(File(widget.imagePath),
                    fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 12),

            // ── OCR status banner ───────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle,
                      color: Colors.green, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'ML Kit extracted $ocrLines lines. Review & edit below.',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  TextButton(
                    style: TextButton.styleFrom(
                        minimumSize: Size.zero, padding: EdgeInsets.zero),
                    onPressed: () =>
                        setState(() => _showRawText = !_showRawText),
                    child:
                        Text(_showRawText ? 'Hide' : 'Raw text'),
                  ),
                ],
              ),
            ),

            // ── Raw OCR text (collapsible) ──────────────────────────────
            if (_showRawText) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                ),
                child: SelectableText(widget.rawOcrText,
                    style: const TextStyle(
                        fontFamily: 'monospace', fontSize: 12)),
              ),
            ],

            const SizedBox(height: 20),
            const Text('Transaction Details',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            // ── Fields ─────────────────────────────────────────────────
            TextField(
              controller: _merchantCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                  labelText: 'Merchant Name *',
                  prefixIcon: Icon(Icons.store),
                  border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amountCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  labelText: 'Amount (VND) *',
                  prefixIcon: Icon(Icons.attach_money),
                  border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _pickDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                    labelText: 'Date',
                    prefixIcon: Icon(Icons.calendar_today),
                    border: OutlineInputBorder()),
                child: Text(DateFormat('dd MMM yyyy').format(_selectedDate)),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<ExpenseCategory>(
              initialValue: _selectedCategory,
              decoration: const InputDecoration(
                  labelText: 'Category',
                  prefixIcon: Icon(Icons.category),
                  border: OutlineInputBorder()),
              items: ExpenseCategory.values
                  .map((c) => DropdownMenuItem(
                        value: c,
                        child: Row(children: [
                          Icon(c.icon, color: c.color, size: 20),
                          const SizedBox(width: 8),
                          Text(c.displayName),
                        ]),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _selectedCategory = v!),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  prefixIcon: Icon(Icons.note_alt_outlined),
                  border: OutlineInputBorder()),
            ),

            // ── Detected line items ─────────────────────────────────────
            if (widget.parsedReceipt.lineItems.isNotEmpty) ...[
              const SizedBox(height: 20),
              const Text('Detected Line Items',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...widget.parsedReceipt.lineItems.map((item) => ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(item.description,
                        style: const TextStyle(fontSize: 13)),
                    trailing: item.amount != null
                        ? Text(
                            NumberFormat.currency(
                                    symbol: '₫', decimalDigits: 0)
                                .format(item.amount))
                        : null,
                  )),
            ],

            const SizedBox(height: 90),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _save,
        icon: const Icon(Icons.save),
        label: const Text('Save Receipt'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
    );
  }
}
