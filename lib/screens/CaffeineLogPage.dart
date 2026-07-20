import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:my_app/api/taipei_time.dart';
import 'package:my_app/gen_l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/ntu_hospital_caffeine_catalog.dart';

enum _CaffeineEntryMode { catalog, estimator }

enum _MeasureType { volume, serving, manual }

class _DrinkType {
  const _DrinkType({
    required this.id,
    required this.icon,
    required this.measureType,
    this.mgPerMl,
    this.mgPerServing,
    this.supportsStrength = false,
  });

  final String id;
  final IconData icon;
  final _MeasureType measureType;
  final double? mgPerMl;
  final int? mgPerServing;
  final bool supportsStrength;
}

class _VolumeOption {
  const _VolumeOption(this.id, this.label, this.ml);

  final String id;
  final String label;
  final int ml;
}

class _ServingOption {
  const _ServingOption(this.count, this.label);

  final int count;
  final String label;
}

class _StrengthOption {
  const _StrengthOption(this.id, this.multiplier);

  final String id;
  final double multiplier;
}

class CaffeineLogPage extends StatefulWidget {
  final String userId;
  final DateTime selectedDate;

  const CaffeineLogPage({
    super.key,
    required this.userId,
    required this.selectedDate,
  });

  @override
  State<CaffeineLogPage> createState() => _CaffeineLogPageState();
}

class _CaffeineLogPageState extends State<CaffeineLogPage> {
  final TextEditingController caffeineController = TextEditingController();
  final TextEditingController drinkNameController = TextEditingController();
  final TextEditingController takingTimeController = TextEditingController();

  final String baseUrl = 'https://wakemate-api-4-0-qtgs.onrender.com';
  static const int _maxSingleCaffeineMg = 500;

  static const List<_DrinkType> _drinkTypes = [
    _DrinkType(
      id: 'brewed_coffee',
      icon: Icons.local_cafe_outlined,
      measureType: _MeasureType.volume,
      mgPerMl: 0.50,
      supportsStrength: true,
    ),
    _DrinkType(
      id: 'instant_coffee',
      icon: Icons.coffee_maker_outlined,
      measureType: _MeasureType.volume,
      mgPerMl: 0.30,
      supportsStrength: true,
    ),
    _DrinkType(
      id: 'capsule_espresso',
      icon: Icons.coffee_outlined,
      measureType: _MeasureType.serving,
      mgPerServing: 70,
    ),
    _DrinkType(
      id: 'capsule_lungo',
      icon: Icons.coffee_outlined,
      measureType: _MeasureType.serving,
      mgPerServing: 95,
    ),
    _DrinkType(
      id: 'espresso',
      icon: Icons.local_cafe,
      measureType: _MeasureType.serving,
      mgPerServing: 70,
    ),
    _DrinkType(
      id: 'black_tea',
      icon: Icons.emoji_food_beverage_outlined,
      measureType: _MeasureType.volume,
      mgPerMl: 0.20,
    ),
    _DrinkType(
      id: 'green_tea',
      icon: Icons.emoji_food_beverage,
      measureType: _MeasureType.volume,
      mgPerMl: 0.15,
    ),
    _DrinkType(
      id: 'energy_drink',
      icon: Icons.bolt_outlined,
      measureType: _MeasureType.volume,
      mgPerMl: 0.32,
    ),
    _DrinkType(
      id: 'caffeinated_soda',
      icon: Icons.local_drink_outlined,
      measureType: _MeasureType.volume,
      mgPerMl: 0.10,
    ),
    _DrinkType(
      id: 'other',
      icon: Icons.edit_note_outlined,
      measureType: _MeasureType.manual,
    ),
  ];

  static const List<_VolumeOption> _volumeOptions = [
    _VolumeOption('small', '<150 ml', 120),
    _VolumeOption('medium', '240 ml', 240),
    _VolumeOption('large', '360 ml', 360),
    _VolumeOption('xlarge', '480+ ml', 540),
  ];

  static const List<_ServingOption> _servingOptions = [
    _ServingOption(1, '1'),
    _ServingOption(2, '2'),
    _ServingOption(3, '3+'),
  ];

  static const List<_StrengthOption> _strengthOptions = [
    _StrengthOption('light', 0.8),
    _StrengthOption('normal', 1.0),
    _StrengthOption('strong', 1.2),
  ];

  String _selectedDrinkId = 'brewed_coffee';
  String _selectedVolumeId = 'medium';
  int _selectedServingCount = 1;
  String _selectedStrengthId = 'normal';
  bool _isUncertain = false;
  _CaffeineEntryMode _entryMode = _CaffeineEntryMode.catalog;
  String _selectedCatalogBrand = ntuHospitalCaffeineCatalog.first.brand;
  String _selectedCatalogId = ntuHospitalCaffeineCatalog.first.id;

  @override
  void initState() {
    super.initState();
    final now = taipeiNow();
    final initialTime = DateTime(
      widget.selectedDate.year,
      widget.selectedDate.month,
      widget.selectedDate.day,
      now.hour,
      now.minute,
    );
    takingTimeController.text = DateFormat(
      'yyyy-MM-dd HH:mm',
    ).format(initialTime);
    _syncEstimatedAmountToController();
  }

  @override
  void dispose() {
    caffeineController.dispose();
    drinkNameController.dispose();
    takingTimeController.dispose();
    super.dispose();
  }

  _DrinkType get _selectedDrink =>
      _drinkTypes.firstWhere((drink) => drink.id == _selectedDrinkId);

  _VolumeOption get _selectedVolume =>
      _volumeOptions.firstWhere((option) => option.id == _selectedVolumeId);

  _ServingOption get _selectedServing => _servingOptions.firstWhere(
    (option) => option.count == _selectedServingCount,
  );

  _StrengthOption get _selectedStrength =>
      _strengthOptions.firstWhere((option) => option.id == _selectedStrengthId);

  CaffeineCatalogItem get _selectedCatalogItem => ntuHospitalCaffeineCatalog
      .firstWhere((item) => item.id == _selectedCatalogId);

  List<String> get _catalogBrands =>
      ntuHospitalCaffeineCatalog.map((item) => item.brand).toSet().toList();

  List<CaffeineCatalogItem> get _filteredCatalogItems =>
      ntuHospitalCaffeineCatalog
          .where((item) => item.brand == _selectedCatalogBrand)
          .toList();

  bool get _isZh => AppLocalizations.of(context)!.localeName.startsWith('zh');
  bool get _isId => AppLocalizations.of(context)!.localeName.startsWith('id');

  String get _caffeineOutOfRangeMessage {
    if (_isId) {
      return 'Jumlah kafein per catatan harus 1-$_maxSingleCaffeineMg mg. Jika memang lebih tinggi, pisahkan menjadi beberapa catatan atau periksa kembali input.';
    }
    if (_isZh) {
      return '單筆咖啡因含量需介於 1-$_maxSingleCaffeineMg mg；若真的超過，請拆成多筆或確認是否輸入錯誤。';
    }
    return 'Caffeine amount must be 1-$_maxSingleCaffeineMg mg per entry. If it is higher, split it into multiple records or check the input.';
  }

  String _drinkLabel(_DrinkType drink) {
    if (_isId) {
      return switch (drink.id) {
        'brewed_coffee' => 'Kopi seduh',
        'instant_coffee' => 'Kopi instan',
        'capsule_espresso' => 'Kapsul espresso',
        'capsule_lungo' => 'Kapsul lungo',
        'espresso' => 'Espresso',
        'black_tea' => 'Teh hitam',
        'green_tea' => 'Teh hijau',
        'energy_drink' => 'Minuman energi',
        'caffeinated_soda' => 'Soda berkafein',
        _ => AppLocalizations.of(context)!.otherDrink,
      };
    }

    if (_isZh) {
      return switch (drink.id) {
        'brewed_coffee' => '現煮咖啡',
        'instant_coffee' => '即溶咖啡',
        'capsule_espresso' => '膠囊咖啡 Espresso',
        'capsule_lungo' => '膠囊咖啡 Lungo',
        'espresso' => 'Espresso',
        'black_tea' => '紅茶',
        'green_tea' => '綠茶',
        'energy_drink' => '能量飲料',
        'caffeinated_soda' => '含咖啡因氣泡飲',
        _ => AppLocalizations.of(context)!.otherDrink,
      };
    }

    return switch (drink.id) {
      'brewed_coffee' => 'Brewed coffee',
      'instant_coffee' => 'Instant coffee',
      'capsule_espresso' => 'Capsule espresso',
      'capsule_lungo' => 'Capsule lungo',
      'espresso' => 'Espresso',
      'black_tea' => 'Black tea',
      'green_tea' => 'Green tea',
      'energy_drink' => 'Energy drink',
      'caffeinated_soda' => 'Caffeinated soda',
      _ => AppLocalizations.of(context)!.otherDrink,
    };
  }

  String _servingUnit(_DrinkType drink) {
    if (drink.id.startsWith('capsule')) {
      if (_isId) return 'kapsul';
      if (_isZh) return '顆';
      return 'capsule';
    }
    return 'shot';
  }

  String _strengthLabel(_StrengthOption option) {
    final l10n = AppLocalizations.of(context)!;
    return switch (option.id) {
      'light' => l10n.light,
      'strong' => l10n.strong,
      _ => l10n.normal,
    };
  }

  int get _estimatedCaffeineAmount {
    if (_entryMode == _CaffeineEntryMode.catalog) {
      return _selectedCatalogItem.caffeineMg;
    }

    final drink = _selectedDrink;
    switch (drink.measureType) {
      case _MeasureType.volume:
        final baseMg = _selectedVolume.ml * (drink.mgPerMl ?? 0);
        final multiplier =
            drink.supportsStrength ? _selectedStrength.multiplier : 1.0;
        return (baseMg * multiplier).round();
      case _MeasureType.serving:
        return (drink.mgPerServing ?? 0) * _selectedServingCount;
      case _MeasureType.manual:
        return int.tryParse(caffeineController.text.trim()) ?? 0;
    }
  }

  String get _amountDescription {
    final drink = _selectedDrink;
    switch (drink.measureType) {
      case _MeasureType.volume:
        final strengthText =
            drink.supportsStrength
                ? ' ${_strengthLabel(_selectedStrength)}'
                : '';
        return '${_selectedVolume.label}$strengthText';
      case _MeasureType.serving:
        return '${_selectedServing.label} ${_servingUnit(drink)}';
      case _MeasureType.manual:
        return AppLocalizations.of(context)!.manualInput;
    }
  }

  String get _drinkNameForSubmit {
    final l10n = AppLocalizations.of(context)!;
    if (_entryMode == _CaffeineEntryMode.catalog) {
      final item = _selectedCatalogItem;
      final estimateTag = item.isEstimate ? ' (${l10n.manualEstimate})' : '';
      return '${item.brand} ${item.productName} ${item.sizeLabel}$estimateTag';
    }

    final drink = _selectedDrink;
    if (drink.measureType == _MeasureType.manual) {
      final name = drinkNameController.text.trim();
      return name.isEmpty ? l10n.otherDrink : name;
    }

    final uncertainty = _isUncertain ? ' (${l10n.uncertainAmount})' : '';
    return '${_drinkLabel(drink)} $_amountDescription$uncertainty';
  }

  void _syncEstimatedAmountToController() {
    if (_entryMode == _CaffeineEntryMode.catalog ||
        _selectedDrink.measureType != _MeasureType.manual) {
      caffeineController.text = _estimatedCaffeineAmount.toString();
    }
  }

  void _showSnackBar(String message, {Color color = Colors.red}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              color == Colors.green || color == const Color(0xFF8BB9A1)
                  ? Icons.check_circle_outline
                  : Icons.error_outline,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _pickDateTime(TextEditingController controller) async {
    DateTime initialDateTime;
    try {
      initialDateTime = parseTaipeiInput(controller.text);
    } catch (_) {
      initialDateTime = taipeiNow();
    }

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDateTime,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (pickedDate == null || !mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDateTime),
    );
    if (pickedTime == null) return;

    final finalDateTime = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    controller.text = DateFormat('yyyy-MM-dd HH:mm').format(finalDateTime);
  }

  String formatToISO8601(String time) => taipeiInputToUtcIso(time);

  Future<void> _saveToLocal(
    double caffeineAmount,
    String takingTimeString,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final takingDateTime = parseTaipeiInput(takingTimeString);
    final dateKey = DateFormat('yyyy-MM-dd').format(takingDateTime);
    final prefsKey = 'caffeine_$dateKey';

    final currentTotal = prefs.getDouble(prefsKey) ?? 0;
    await prefs.setDouble(prefsKey, currentTotal + caffeineAmount);
  }

  Future<void> _submitData() async {
    final l10n = AppLocalizations.of(context)!;
    final takingTime = takingTimeController.text.trim();
    final caffeineAmount = _estimatedCaffeineAmount;
    final drinkName = _drinkNameForSubmit;

    if (takingTime.isEmpty) {
      _showSnackBar(l10n.enterDrinkingTime);
      return;
    }

    try {
      parseTaipeiInput(takingTime);
    } catch (_) {
      _showSnackBar(l10n.invalidDateTimeFormat);
      return;
    }

    if (caffeineAmount <= 0) {
      _showSnackBar(l10n.enterPositiveCaffeine);
      return;
    }

    if (caffeineAmount > _maxSingleCaffeineMg) {
      _showSnackBar(_caffeineOutOfRangeMessage);
      return;
    }

    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/users_intake/'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'user_id': widget.userId,
              'caffeine_amount': caffeineAmount,
              'drink_name': drinkName,
              'taking_timestamp': formatToISO8601(takingTime),
            }),
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        await _saveToLocal(caffeineAmount.toDouble(), takingTime);
        _showSnackBar(l10n.caffeineSaveSuccess, color: const Color(0xFF8BB9A1));
        if (mounted) Navigator.of(context).pop(true);
      } else {
        final body =
            response.body.isEmpty ? '' : '\n${utf8.decode(response.bodyBytes)}';
        _showSnackBar(
          '${l10n.caffeineSaveFailed}: ${response.statusCode}$body',
        );
      }
    } catch (e) {
      _showSnackBar('${l10n.networkError}: $e');
    }
  }

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _buildEntryModeSelector(Color primaryColor) {
    final l10n = AppLocalizations.of(context)!;
    return SegmentedButton<_CaffeineEntryMode>(
      segments: [
        ButtonSegment(
          value: _CaffeineEntryMode.catalog,
          icon: const Icon(Icons.storefront_outlined),
          label: Text(l10n.productCatalog),
        ),
        ButtonSegment(
          value: _CaffeineEntryMode.estimator,
          icon: const Icon(Icons.tune_outlined),
          label: Text(l10n.manualEstimate),
        ),
      ],
      selected: {_entryMode},
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected) ? primaryColor : null;
        }),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected) ? Colors.white : null;
        }),
      ),
      onSelectionChanged: (selection) {
        setState(() {
          _entryMode = selection.first;
          _syncEstimatedAmountToController();
        });
      },
    );
  }

  Widget _buildCatalogSelector(Color primaryColor, Color accentColor) {
    final l10n = AppLocalizations.of(context)!;
    final selectedItem = _selectedCatalogItem;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('1. ${l10n.chooseStore}'),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: _selectedCatalogBrand,
          isExpanded: true,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            prefixIcon: Icon(Icons.store_outlined, color: primaryColor),
          ),
          items:
              _catalogBrands
                  .map(
                    (brand) =>
                        DropdownMenuItem(value: brand, child: Text(brand)),
                  )
                  .toList(),
          onChanged: (brand) {
            if (brand == null) return;
            setState(() {
              _selectedCatalogBrand = brand;
              _selectedCatalogId =
                  ntuHospitalCaffeineCatalog
                      .firstWhere((item) => item.brand == brand)
                      .id;
              _syncEstimatedAmountToController();
            });
          },
        ),
        const SizedBox(height: 22),
        _buildSectionTitle('2. ${l10n.chooseProduct}'),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          key: ValueKey('product_$_selectedCatalogBrand'),
          initialValue: _selectedCatalogId,
          isExpanded: true,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            prefixIcon: Icon(Icons.local_cafe_outlined, color: primaryColor),
          ),
          items:
              _filteredCatalogItems.map((item) {
                return DropdownMenuItem(
                  value: item.id,
                  child: Text(
                    '${item.productName} ${item.sizeLabel} - ${item.caffeineLabel}',
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
          onChanged: (id) {
            if (id == null) return;
            setState(() {
              _selectedCatalogId = id;
              _syncEstimatedAmountToController();
            });
          },
        ),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.13),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                selectedItem.locationHint,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              Text(
                '${l10n.source}: ${selectedItem.sourceName}',
                style: const TextStyle(color: Colors.black54),
              ),
              if (selectedItem.note.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  selectedItem.note,
                  style: const TextStyle(color: Colors.black54),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildManualEstimator(Color primaryColor, Color accentColor) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('1. ${l10n.chooseDrinkType}'),
        const SizedBox(height: 12),
        _buildDrinkSelector(primaryColor),
        const SizedBox(height: 24),
        _buildSectionTitle('2. ${l10n.chooseAmount}'),
        const SizedBox(height: 12),
        _buildAmountSelector(primaryColor),
        _buildStrengthSelector(primaryColor),
        const SizedBox(height: 18),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            l10n.uncertainAmount,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(l10n.uncertainAmountHelp),
          value: _isUncertain,
          activeThumbColor: accentColor,
          onChanged: (value) => setState(() => _isUncertain = value),
        ),
      ],
    );
  }

  Widget _buildDrinkSelector(Color primaryColor) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children:
          _drinkTypes.map((drink) {
            final isSelected = drink.id == _selectedDrinkId;
            return ChoiceChip(
              selected: isSelected,
              avatar: Icon(
                drink.icon,
                size: 18,
                color: isSelected ? Colors.white : primaryColor,
              ),
              label: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_drinkLabel(drink)),
                  if (drink.measureType != _MeasureType.manual)
                    Text(
                      drink.measureType == _MeasureType.volume
                          ? '${drink.mgPerMl?.toStringAsFixed(2)} mg/ml'
                          : '${drink.mgPerServing} mg/${_servingUnit(drink)}',
                      style: TextStyle(
                        fontSize: 11,
                        color:
                            isSelected
                                ? Colors.white.withValues(alpha: 0.88)
                                : Colors.black54,
                      ),
                    ),
                ],
              ),
              selectedColor: primaryColor,
              backgroundColor: Colors.white,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w600,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(
                  color: isSelected ? primaryColor : Colors.grey.shade300,
                ),
              ),
              onSelected: (_) {
                setState(() {
                  _selectedDrinkId = drink.id;
                  _syncEstimatedAmountToController();
                });
              },
            );
          }).toList(),
    );
  }

  Widget _buildAmountSelector(Color primaryColor) {
    final l10n = AppLocalizations.of(context)!;
    final drink = _selectedDrink;

    if (drink.measureType == _MeasureType.manual) {
      return Column(
        children: [
          TextField(
            controller: drinkNameController,
            decoration: InputDecoration(
              labelText: l10n.drinkName,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              hintText: l10n.otherDrink,
              prefixIcon: Icon(Icons.local_drink_outlined, color: primaryColor),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: caffeineController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: l10n.caffeineAmountMg,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              hintText: '150',
              prefixIcon: Icon(Icons.local_cafe_outlined, color: primaryColor),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ],
      );
    }

    if (drink.measureType == _MeasureType.serving) {
      return Wrap(
        spacing: 10,
        children:
            _servingOptions.map((option) {
              return ChoiceChip(
                selected: option.count == _selectedServingCount,
                label: Text('${option.label} ${_servingUnit(drink)}'),
                selectedColor: primaryColor,
                backgroundColor: Colors.white,
                labelStyle: TextStyle(
                  color:
                      option.count == _selectedServingCount
                          ? Colors.white
                          : Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
                onSelected: (_) {
                  setState(() {
                    _selectedServingCount = option.count;
                    _syncEstimatedAmountToController();
                  });
                },
              );
            }).toList(),
      );
    }

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children:
          _volumeOptions.map((option) {
            return ChoiceChip(
              selected: option.id == _selectedVolumeId,
              label: Text(option.label),
              selectedColor: primaryColor,
              backgroundColor: Colors.white,
              labelStyle: TextStyle(
                color:
                    option.id == _selectedVolumeId
                        ? Colors.white
                        : Colors.black87,
                fontWeight: FontWeight.w600,
              ),
              onSelected: (_) {
                setState(() {
                  _selectedVolumeId = option.id;
                  _syncEstimatedAmountToController();
                });
              },
            );
          }).toList(),
    );
  }

  Widget _buildStrengthSelector(Color primaryColor) {
    final l10n = AppLocalizations.of(context)!;
    if (!_selectedDrink.supportsStrength) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 22),
        _buildSectionTitle('3. ${l10n.strength}'),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          children:
              _strengthOptions.map((option) {
                final isSelected = option.id == _selectedStrengthId;
                return ChoiceChip(
                  selected: isSelected,
                  label: Text(
                    '${_strengthLabel(option)} x${option.multiplier}',
                  ),
                  selectedColor: primaryColor,
                  backgroundColor: Colors.white,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                  onSelected: (_) {
                    setState(() {
                      _selectedStrengthId = option.id;
                      _syncEstimatedAmountToController();
                    });
                  },
                );
              }).toList(),
        ),
      ],
    );
  }

  Widget _buildEstimateBox(Color primaryColor, Color accentColor) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accentColor.withValues(alpha: 0.7)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(26),
            ),
            child: Icon(Icons.science_outlined, color: primaryColor, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.estimateCaffeine,
                  style: TextStyle(color: primaryColor.withValues(alpha: 0.78)),
                ),
                const SizedBox(height: 3),
                Text(
                  '$_estimatedCaffeineAmount mg',
                  style: TextStyle(
                    color: primaryColor,
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  _entryMode == _CaffeineEntryMode.catalog
                      ? '${_selectedCatalogItem.caffeineLabel} - ${_selectedCatalogItem.sourceName}'
                      : _drinkNameForSubmit,
                  style: const TextStyle(color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    const primaryColor = Color(0xFF4B6B7A);
    const accentColor = Color(0xFF8BB9A1);
    const bgLight = Color(0xFFF9F9F7);

    return Scaffold(
      backgroundColor: bgLight,
      appBar: AppBar(
        title: Text(
          l10n.addCaffeineRecord,
          style: const TextStyle(
            color: primaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white.withValues(alpha: 0.9),
        elevation: 1,
        shadowColor: Colors.black12,
        iconTheme: const IconThemeData(color: primaryColor),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.caffeineIntro,
                style: const TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Center(child: _buildEntryModeSelector(primaryColor)),
              const SizedBox(height: 26),
              if (_entryMode == _CaffeineEntryMode.catalog)
                _buildCatalogSelector(primaryColor, accentColor)
              else
                _buildManualEstimator(primaryColor, accentColor),
              const SizedBox(height: 12),
              _buildEstimateBox(primaryColor, accentColor),
              const SizedBox(height: 20),
              TextField(
                controller: takingTimeController,
                keyboardType: TextInputType.datetime,
                decoration: InputDecoration(
                  labelText: l10n.drinkingTime,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(
                    Icons.access_time_rounded,
                    color: primaryColor,
                  ),
                  helperText: l10n.dateTimeHelper,
                  suffixIcon: IconButton(
                    tooltip: l10n.chooseDateTime,
                    icon: const Icon(Icons.calendar_month_outlined),
                    onPressed: () => _pickDateTime(takingTimeController),
                  ),
                ),
              ),
              const SizedBox(height: 34),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _submitData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 5,
                  ),
                  icon: const Icon(Icons.save),
                  label: Text(
                    l10n.saveCaffeine,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
