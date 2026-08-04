String formatCostInXaf(int cost) {
  final xafValue = cost * 650;
  final formatted = xafValue.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'\B(?=(\d{3})+(?!\d))'),
        (Match m) => ',',
      );
  return 'XAF $formatted/day';
}
