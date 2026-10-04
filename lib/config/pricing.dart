/// Catalog prices are stored in US dollars (that is what the price source
/// reports). The app shows pesos, so prices are multiplied by this rate.
///
/// This is a fixed number, not a live exchange rate — update it now and then.
/// It only affects the *suggested* value filled into the Add Card form; the
/// person can always overwrite it, and the value saved with their card is a
/// plain peso amount that never changes when this constant does.
const double kUsdToPhpRate = 58.0;

/// Rounds a peso amount to something sensible to show and store.
double roundPeso(double value) => value.roundToDouble();

/// What a copy is worth compared with the Near Mint market price, keyed by the
/// condition codes in [kConditionOptions]. Edit the numbers here to tune the
/// automatic price; a condition missing from the map counts as full price.
const Map<String, double> kConditionPriceFactor = {
  'NM': 1.0,
  'LP': 0.85,
  'MP': 0.65,
  'DMG': 0.40,
};

/// The Near Mint price scaled for [conditionCode].
double priceForCondition(double nearMintPrice, String conditionCode) =>
    roundPeso(nearMintPrice * (kConditionPriceFactor[conditionCode] ?? 1.0));
