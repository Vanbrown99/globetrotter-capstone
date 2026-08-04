import 'package:flutter_test/flutter_test.dart';
import 'package:globetrotter_flutter/helpers/currency_formatter.dart';

void main() {
  group('formatCostInXaf', () {
    test('formats values with the XAF currency label', () {
      expect(formatCostInXaf(15), 'XAF 9,750/day');
      expect(formatCostInXaf(0), 'XAF 0/day');
    });
  });
}
