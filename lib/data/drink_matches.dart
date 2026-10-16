import 'package:my_app/data/ntu_hospital_caffeine_catalog.dart';

class DrinkMatch {
  const DrinkMatch(this.item, this.fraction);
  final CaffeineCatalogItem item;
  final double fraction;
  int get caffeineMg => (item.caffeineMg * fraction).round();
}

List<DrinkMatch> matchDrinks(double targetMg, {String? brand}) {
  if (!targetMg.isFinite || targetMg <= 0 || targetMg > 500) return [];
  final candidates = <DrinkMatch>[];
  for (final item in ntuHospitalCaffeineCatalog) {
    if (item.isEstimate ||
        item.caffeineMg <= 0 ||
        (brand != null && item.brand != brand))
      continue;
    for (final fraction in [1.0, .75, .5, .25]) {
      if (item.caffeineMg * fraction <= targetMg) {
        final candidate = DrinkMatch(item, fraction);
        if (candidate.caffeineMg > 0 && candidate.caffeineMg <= targetMg)
          candidates.add(candidate);
        break;
      }
    }
  }
  candidates.sort((a, b) {
    final difference = (targetMg - a.caffeineMg).compareTo(
      targetMg - b.caffeineMg,
    );
    if (difference != 0) return difference;
    final fraction = b.fraction.compareTo(a.fraction);
    return fraction != 0 ? fraction : a.item.id.compareTo(b.item.id);
  });
  return candidates;
}
