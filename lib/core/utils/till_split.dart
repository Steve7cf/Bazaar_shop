/// Which physical cash drawer a product's category routes sales to.
enum Till { general, drinks }

extension TillValue on Till {
  String get value => switch (this) {
    Till.general => 'general',
    Till.drinks => 'drinks',
  };

  static Till fromValue(String? v) => v == 'drinks' ? Till.drinks : Till.general;

  String get label => switch (this) {
    Till.general => 'General',
    Till.drinks => 'Drinks',
  };
}

const _drinksCategoryAliases = [
  'vinywaji',
  'drinks',
  'drink',
  'vinywaji (drinks)',
];

/// Routes a product's category to its till. Case-insensitive, trimmed
/// comparison against the fixed alias list — anything not recognized as a
/// drinks category routes to General.
Till tillForCategory(String category) {
  final normalized = category.trim().toLowerCase();
  return _drinksCategoryAliases.contains(normalized) ? Till.drinks : Till.general;
}

/// One till-group's share of a pool being split (e.g. discount or payment),
/// weighted by that group's own subtotal.
class SplitShare {
  final Till till;
  final double weight;
  final double share;

  const SplitShare({required this.till, required this.weight, required this.share});
}

/// Splits [pool] proportionally across [weights] (keyed by till), giving
/// every group except the last `round(pool * (groupWeight / totalWeight))`,
/// with the **last group absorbing the exact remainder** so the parts
/// always sum exactly to [pool] — no rounding drift, regardless of how many
/// groups are involved (in practice always exactly 2: general + drinks).
///
/// [weights] must be provided in the order groups should be processed;
/// the last entry in that order gets the remainder. Zero-weight groups are
/// dropped, since a till with no items in the cart doesn't participate.
List<SplitShare> proportionalSplit(
  double pool,
  List<MapEntry<Till, double>> weights,
) {
  final active = weights.where((e) => e.value > 0).toList();
  if (active.isEmpty) return const [];
  if (active.length == 1) {
    return [SplitShare(till: active.first.key, weight: active.first.value, share: pool)];
  }

  final totalWeight = active.fold<double>(0, (sum, e) => sum + e.value);
  final shares = <SplitShare>[];
  double assigned = 0;

  for (var i = 0; i < active.length; i++) {
    final entry = active[i];
    final isLast = i == active.length - 1;
    final share = isLast
        ? pool - assigned
        : _roundHalfUp(pool * (entry.value / totalWeight));
    assigned += share;
    shares.add(SplitShare(till: entry.key, weight: entry.value, share: share));
  }

  return shares;
}

/// Standard round-half-up to the nearest whole shilling — this app never
/// deals in cents, and Dart's `.round()` already does round-half-up for
/// positive values, but this makes the intent explicit at call sites.
double _roundHalfUp(double value) => value.roundToDouble();
