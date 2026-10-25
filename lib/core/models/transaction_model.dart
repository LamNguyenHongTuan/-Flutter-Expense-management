import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

enum ExpenseCategory { food, study, travel, gear, entertainment, other }

extension ExpenseCategoryExtension on ExpenseCategory {
  String get displayName {
    switch (this) {
      case ExpenseCategory.food:
        return 'Food';
      case ExpenseCategory.study:
        return 'Study';
      case ExpenseCategory.travel:
        return 'Travel';
      case ExpenseCategory.gear:
        return 'Gear';
      case ExpenseCategory.entertainment:
        return 'Entertainment';
      case ExpenseCategory.other:
        return 'Other';
    }
  }

  IconData get icon {
    switch (this) {
      case ExpenseCategory.food:
        return Icons.restaurant;
      case ExpenseCategory.study:
        return Icons.school;
      case ExpenseCategory.travel:
        return Icons.flight;
      case ExpenseCategory.gear:
        return Icons.devices;
      case ExpenseCategory.entertainment:
        return Icons.movie;
      case ExpenseCategory.other:
        return Icons.category;
    }
  }

  Color get color =>
      AppTheme.categoryColors[displayName] ?? Colors.grey;

  static ExpenseCategory fromString(String value) {
    return ExpenseCategory.values.firstWhere(
      (e) => e.displayName.toLowerCase() == value.toLowerCase(),
      orElse: () => ExpenseCategory.other,
    );
  }
}

class Transaction {
  final String id;
  final String merchantName;
  final double amount;
  final DateTime date;
  final ExpenseCategory category;
  final String? receiptImagePath;
  final String? rawOcrText;
  final String? notes;

  const Transaction({
    required this.id,
    required this.merchantName,
    required this.amount,
    required this.date,
    required this.category,
    this.receiptImagePath,
    this.rawOcrText,
    this.notes,
  });

  Transaction copyWith({
    String? id,
    String? merchantName,
    double? amount,
    DateTime? date,
    ExpenseCategory? category,
    String? receiptImagePath,
    String? rawOcrText,
    String? notes,
  }) {
    return Transaction(
      id: id ?? this.id,
      merchantName: merchantName ?? this.merchantName,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      category: category ?? this.category,
      receiptImagePath: receiptImagePath ?? this.receiptImagePath,
      rawOcrText: rawOcrText ?? this.rawOcrText,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'merchant_name': merchantName,
      'amount': amount,
      'date': date.toIso8601String(),
      'category': category.displayName,
      'receipt_image_path': receiptImagePath,
      'raw_ocr_text': rawOcrText,
      'notes': notes,
    };
  }

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'] as String,
      merchantName: map['merchant_name'] as String,
      amount: (map['amount'] as num).toDouble(),
      date: DateTime.parse(map['date'] as String),
      category:
          ExpenseCategoryExtension.fromString(map['category'] as String),
      receiptImagePath: map['receipt_image_path'] as String?,
      rawOcrText: map['raw_ocr_text'] as String?,
      notes: map['notes'] as String?,
    );
  }
}
