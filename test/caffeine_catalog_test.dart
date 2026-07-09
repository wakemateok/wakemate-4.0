import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/data/ntu_hospital_caffeine_catalog.dart';

void main() {
  test('catalog contains only source-backed exact caffeine values', () {
    expect(ntuHospitalCaffeineCatalog, isNotEmpty);
    expect(ntuHospitalCaffeineCatalog.any((item) => item.isEstimate), isFalse);
    expect(
      ntuHospitalCaffeineCatalog.any(
        (item) =>
            item.brand.contains('瓶罐') ||
            item.productName.contains('Red Bull') ||
            item.productName.contains('Monster'),
      ),
      isFalse,
    );
  });

  test('Starbucks values match the Taiwan official nutrition table', () {
    final byId = {
      for (final item in ntuHospitalCaffeineCatalog) item.id: item.caffeineMg,
    };

    expect(byId['starbucks_americano_hot_tall'], 195);
    expect(byId['starbucks_americano_hot_grande'], 293);
    expect(byId['starbucks_latte_hot_grande'], 182);
    expect(byId['starbucks_latte_iced_grande'], 183);
  });
}
