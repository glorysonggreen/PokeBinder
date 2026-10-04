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
