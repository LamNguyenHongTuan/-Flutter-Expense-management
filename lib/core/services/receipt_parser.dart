/// Parsed result from a receipt image.
class ParsedReceipt {
  final double? totalAmount;
  final DateTime? date;
  final String? merchantName;
  final List<LineItem> lineItems;

  const ParsedReceipt({
    this.totalAmount,
    this.date,
    this.merchantName,
    this.lineItems = const [],
  });
}

/// A single line-item detected on a receipt.
class LineItem {
  final String description;
  final double? amount;
  const LineItem({required this.description, this.amount});
}

/// Heuristic regex-based parser for OCR text from receipts.
///
/// Supports:
/// - Vietnamese VND formats: 150.000đ, 150,000 VND, TỔNG: 150,000
/// - International USD/generic: $12.50, Total: 12.50
/// - Dates: DD/MM/YYYY, YYYY-MM-DD, "24 Oct 2026"
/// - Merchant names: first plausible title-cased line
class ReceiptParser {
  static final _totalPatterns = [
    // Explicit total keywords in Vietnamese and English
    RegExp(
      r'(?:t[oô]ng\s*c[oộ]ng|t[oô]ng\s*ti[eề]n|thanh\s*to[aá]n|ti[eề]n\s*thanh\s*to[aá]n|c[aầ]n\s*thanh\s*to[aá]n|ph[aả]i\s*thanh\s*to[aá]n|th[aà]nh\s*ti[eề]n|grand\s*total|amount\s*due|total\s*due|subtotal|total|t[oô]ng)[^\d\n\r]*(\d{1,3}(?:[.,\s]\d{3})*(?:[.,]\d{1,2})?|\d+)\s*(?:vnd|vnđ|đ|d|\$|usd)?',
      caseSensitive: false,
    ),
    // Fallback: any monetary value with currency indicator
    RegExp(
      r'(\d{1,3}(?:[.,\s]\d{3})*(?:[.,]\d{1,2})?|\d+)\s*(?:vnd|vnđ|đ|\$|usd)',
      caseSensitive: false,
    ),
    // Fallback: large numbers separated by thousand separators
    RegExp(
      r'(\d{1,3}(?:[.,]\d{3})+)',
      caseSensitive: false,
    ),
  ];

  static final _lineItemPattern = RegExp(
    r'^(.{3,40}?)\s{2,}(\d{1,3}(?:[.,]\d{3})*(?:[.,]\d{1,2})?)$',
    multiLine: true,
  );

  /// Main entry point. Parse [rawText] into a [ParsedReceipt].
  static ParsedReceipt parse(String rawText) {
    final lines = rawText
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    return ParsedReceipt(
      totalAmount: _extractTotal(rawText),
      date: _extractDate(rawText),
      merchantName: _extractMerchant(lines),
      lineItems: _extractLineItems(rawText),
    );
  }

  // ─── Amount ──────────────────────────────────────────────────────────────

  static double? _extractTotal(String text) {
    for (final pattern in _totalPatterns) {
      final matches = pattern.allMatches(text).toList();
      if (matches.isNotEmpty) {
        final raw = matches.last.group(1) ?? '';
        final parsed = _parseAmount(raw);
        if (parsed != null && parsed > 0) return parsed;
      }
    }
    return null;
  }

  /// Normalize ambiguous decimal/thousands separators.
  static double? _parseAmount(String raw) {
    String cleaned = raw.trim().replaceAll(RegExp(r'[^0-9.,]'), '');
    if (cleaned.isEmpty) return null;

    if (cleaned.contains(',') && cleaned.contains('.')) {
      final lastComma = cleaned.lastIndexOf(',');
      final lastDot = cleaned.lastIndexOf('.');
      if (lastComma > lastDot) {
        // European: 1.234,56
        cleaned = cleaned.replaceAll('.', '').replaceAll(',', '.');
      } else {
        // US: 1,234.56
        cleaned = cleaned.replaceAll(',', '');
      }
    } else if (cleaned.contains(',')) {
      final parts = cleaned.split(',');
      if (parts.length == 2 && parts.last.length <= 2) {
        // Decimal comma: 12,50
        cleaned = cleaned.replaceAll(',', '.');
      } else {
        // Thousands comma: 1,000 or 1,500,000
        cleaned = cleaned.replaceAll(',', '');
      }
    } else if (cleaned.contains('.')) {
      final parts = cleaned.split('.');
      if (parts.length > 2 || (parts.length == 2 && parts.last.length == 3)) {
        // Vietnamese thousands dot: 150.000 or 1.500.000
        cleaned = cleaned.replaceAll('.', '');
      }
    }

    return double.tryParse(cleaned);
  }

  // ─── Date ────────────────────────────────────────────────────────────────

  static DateTime? _extractDate(String text) {
    // 1. YYYY-MM-DD or YYYY/MM/DD (ISO format)
    final pIso = RegExp(r'\b(\d{4})[/\-.](\d{1,2})[/\-.](\d{1,2})\b');
    final mIso = pIso.firstMatch(text);
    if (mIso != null) {
      final y = int.tryParse(mIso.group(1)!);
      final mo = int.tryParse(mIso.group(2)!);
      final d = int.tryParse(mIso.group(3)!);
      if (d != null && mo != null && y != null && mo >= 1 && mo <= 12 && d >= 1 && d <= 31) {
        try {
          return DateTime(y, mo, d);
        } catch (_) {}
      }
    }

    // 2. DD/MM/YYYY or DD-MM-YYYY or DD.MM.YYYY
    final pDmY = RegExp(r'\b(\d{1,2})[/\-.](\d{1,2})[/\-.](\d{2,4})\b');
    final mDmY = pDmY.firstMatch(text);
    if (mDmY != null) {
      final d = int.tryParse(mDmY.group(1)!);
      final mo = int.tryParse(mDmY.group(2)!);
      var y = int.tryParse(mDmY.group(3)!);
      if (y != null && y < 100) y += 2000;
      if (d != null && mo != null && y != null && mo >= 1 && mo <= 12 && d >= 1 && d <= 31) {
        try {
          return DateTime(y, mo, d);
        } catch (_) {}
      }
    }

    // Vietnamese format: Ngày DD tháng MM năm YYYY
    final pVn = RegExp(
      r'ng[aà]y\s+(\d{1,2})\s+th[aá]ng\s+(\d{1,2})(?:\s+n[aă]m\s+(\d{4}))?',
      caseSensitive: false,
    );
    final mVn = pVn.firstMatch(text);
    if (mVn != null) {
      final d = int.tryParse(mVn.group(1)!);
      final mo = int.tryParse(mVn.group(2)!);
      final y = int.tryParse(mVn.group(3) ?? '') ?? DateTime.now().year;
      if (d != null && mo != null) {
        try {
          return DateTime(y, mo, d);
        } catch (_) {}
      }
    }

    // "24 Oct 2026" / "Oct 24, 2026"
    final monthMap = {
      'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'may': 5, 'jun': 6,
      'jul': 7, 'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12,
    };
    final p3 = RegExp(
      r'(\d{1,2})\s+(jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)\w*[\s,]+(\d{4})',
      caseSensitive: false,
    );
    final m3 = p3.firstMatch(text);
    if (m3 != null) {
      final d = int.tryParse(m3.group(1)!);
      final mo = monthMap[m3.group(2)!.toLowerCase().substring(0, 3)];
      final y = int.tryParse(m3.group(3)!);
      if (d != null && mo != null && y != null) {
        try {
          return DateTime(y, mo, d);
        } catch (_) {}
      }
    }

    return null;
  }

  // ─── Merchant ────────────────────────────────────────────────────────────

  static final _noiseHeaderPatterns = RegExp(
    r'(h[oó]a\s*đ[oơ]n|phi[eế]u\s*(?:thanh\s*to[aá]n|thu|b[aá]n\s*h[aà]ng)|tax\s*invoice|receipt|vat|li[eê]n\s*\d|c[oộ]ng\s*h[oò]a|s[oố]\s*h[đd]|mst|m[aã]\s*s[oố]\s*thu[eế]|thu\s*ng[aâ]n|nh[aâ]n\s*vi[eê]n|kh[aá]ch\s*h[aà]ng|b[aà]n\s*\d|gi[oờ]\s*v[aà]o|gi[oờ]\s*ra|tel|hotline|s[đd]t|đ[iị]a\s*ch[iỉ]|address)',
    caseSensitive: false,
  );

  static String? _extractMerchant(List<String> lines) {
    // Look through the first 8 lines
    for (final line in lines.take(8)) {
      final trimmed = line.trim();
      if (trimmed.length < 3 || trimmed.length > 55) continue;
      // Skip if contains common noise headers or looks like an address
      if (_noiseHeaderPatterns.hasMatch(trimmed) || _looksLikeAddress(trimmed)) {
        continue;
      }
      // Must contain alphabetic characters
      if (RegExp(r'[a-zA-Z\u00C0-\u1EF9]').hasMatch(trimmed)) {
        return _toTitleCase(trimmed);
      }
    }
    return lines.isNotEmpty ? lines.first : null;
  }

  static bool _looksLikeAddress(String line) {
    return RegExp(
      r'(\d{2,}\s*/\s*\d+|street|st\.|ave|road|rd\.|đ[uư][oờ]ng|ph[uư][oờ]ng|qu[aậ]n|huy[eệ]n|tp\.|t[iỉ]nh|th[aà]nh\s*ph[oố]|t[oò]a\s*nh[aà]|t[aầ]ng\s*\d|khu\s*ph[oố]|t[oổ]\s*\d)',
      caseSensitive: false,
    ).hasMatch(line);
  }

  static String _toTitleCase(String s) {
    return s.split(' ').map((w) {
      if (w.isEmpty) return w;
      return w[0].toUpperCase() + w.substring(1).toLowerCase();
    }).join(' ');
  }

  // ─── Line Items ──────────────────────────────────────────────────────────

  static List<LineItem> _extractLineItems(String text) {
    final items = <LineItem>[];
    final matches = _lineItemPattern.allMatches(text);
    for (final m in matches) {
      final desc = m.group(1)?.trim() ?? '';
      final amtStr = m.group(2)?.trim() ?? '';
      if (desc.isNotEmpty) {
        items.add(LineItem(description: desc, amount: _parseAmount(amtStr)));
      }
    }
    return items;
  }
}
