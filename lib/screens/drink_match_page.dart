import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_app/data/drink_matches.dart';
import 'package:my_app/data/ntu_hospital_caffeine_catalog.dart';
import 'package:my_app/utils/catalog_labels.dart';
import 'package:my_app/utils/review_text.dart';
import 'package:my_app/screens/CaffeineLogPage.dart';

class DrinkMatchPage extends StatefulWidget {
  const DrinkMatchPage({
    super.key,
    required this.userId,
    required this.targetMg,
    required this.recommendedAt,
  });
  final String userId;
  final double targetMg;
  final DateTime recommendedAt;
  @override
  State<DrinkMatchPage> createState() => _DrinkMatchPageState();
}

class _DrinkMatchPageState extends State<DrinkMatchPage> {
  String? _brand;
  @override
  Widget build(BuildContext context) {
    final language = Localizations.localeOf(context).languageCode;
    String text(String key) => reviewText(key, language);
    final matches = matchDrinks(widget.targetMg, brand: _brand);
    final brands =
        ntuHospitalCaffeineCatalog.map((item) => item.brand).toSet().toList();
    return Scaffold(
      appBar: AppBar(title: Text(text('drinkOptions'))),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              '${DateFormat('yyyy/MM/dd HH:mm').format(widget.recommendedAt)} · ${widget.targetMg.toStringAsFixed(0)} mg',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Text(text('doseReference')),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _brand ?? '',
              isExpanded: true,
              items: [
                DropdownMenuItem(value: '', child: Text(text('allBrands'))),
                ...brands.map(
                  (brand) => DropdownMenuItem(value: brand, child: Text(brand)),
                ),
              ],
              onChanged:
                  (value) =>
                      setState(() => _brand = value == '' ? null : value),
            ),
            const SizedBox(height: 16),
            if (matches.isEmpty) Text(text('noDrinkMatch')),
            for (final match in matches) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      '${match.item.brand} · ${catalogProductName(match.item, language)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(catalogSizeLabel(match.item, language)),
                    Text(
                      '${portionText(match.fraction, language)} · ${match.caffeineMg} mg',
                    ),
                    Text(
                      '${text('perCup')}: ${match.item.caffeineLabel}',
                      style: const TextStyle(color: Color(0xFF52636D)),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: OutlinedButton.icon(
                        key: ValueKey('drink-log-${match.item.id}'),
                        icon: const Icon(Icons.edit_note),
                        label: Text(text('recordActual')),
                        onPressed: () async {
                          final saved = await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder:
                                  (_) => CaffeineLogPage(
                                    userId: widget.userId,
                                    selectedDate: widget.recommendedAt,
                                    initialCatalogId: match.item.id,
                                    initialPortion: match.fraction,
                                    initialTimestamp: widget.recommendedAt,
                                  ),
                            ),
                          );
                          if (saved == true && context.mounted)
                            Navigator.pop(context, true);
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
            ],
          ],
        ),
      ),
    );
  }
}
