import 'package:flutter_test/flutter_test.dart';
import 'package:receipt_scanner/core/services/receipt_parser.dart';

void main() {
  group('ReceiptParser Tests', () {
    test('extracts Vietnamese VND total amounts correctly', () {
      const ocrSample1 = '''
        HIGHLANDS COFFEE
        Dia chi: 123 Nguyen Thi Minh Khai, Q1
        Ngay: 24/10/2026 10:15
        1 Cà phê sữa đá       39.000
        1 Trà thanh đào       55.000
        Tong cong: 150.000 đ
        Tien mat: 200.000 đ
      ''';

      final parsed1 = ReceiptParser.parse(ocrSample1);
      expect(parsed1.totalAmount, equals(150000.0));
      expect(parsed1.date, equals(DateTime(2026, 10, 24)));
      expect(parsed1.merchantName?.toLowerCase(), contains('highlands'));

      const ocrSample2 = '''
        SIEU THI CO.OPMART
        Hoa don ban hang
        Ngay 15/09/2026
        Tong tien: 150,000 VND
      ''';

      final parsed2 = ReceiptParser.parse(ocrSample2);
      expect(parsed2.totalAmount, equals(150000.0));
      expect(parsed2.date, equals(DateTime(2026, 9, 15)));
      expect(parsed2.merchantName?.toLowerCase(), contains('co.opmart'));
    });

    test('extracts international amounts and formats', () {
      const ocrSampleUsd = '''
        STARBUCKS COFFEE
        Store #1234
        Date: 2026-08-20
        Caramel Macchiato    5.50
        Croissant            4.00
        Subtotal             9.50
        Tax                  0.76
        Total Amount: \$10.26
      ''';

      final parsed = ReceiptParser.parse(ocrSampleUsd);
      expect(parsed.totalAmount, equals(10.26));
      expect(parsed.date, equals(DateTime(2026, 8, 20)));
      expect(parsed.merchantName?.toLowerCase(), contains('starbucks'));
    });

    test('extracts Vietnamese textual date', () {
      const ocrDateSample = '''
        Nha Sach Fahasa
        Ngay 25 thang 10 nam 2026
        Thanh toan: 85.000 VND
      ''';

      final parsed = ReceiptParser.parse(ocrDateSample);
      expect(parsed.totalAmount, equals(85000.0));
      expect(parsed.date, equals(DateTime(2026, 10, 25)));
      expect(parsed.merchantName?.toLowerCase(), contains('fahasa'));
    });
  });
}
