const double kUsdToPhpRate = 58.0;

double roundPeso(double value) => value.roundToDouble();

String formatPeso(double value) {
  final digits = value
      .round()
      .toString()
      .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');
  return '₱$digits';
}

const Map<String, double> kConditionPriceFactor = {
  'NM': 1.0,
  'LP': 0.85,
  'MP': 0.65,
  'DMG': 0.40,
};

double priceForCondition(double nearMintPrice, String conditionCode) =>
    roundPeso(nearMintPrice * (kConditionPriceFactor[conditionCode] ?? 1.0));
