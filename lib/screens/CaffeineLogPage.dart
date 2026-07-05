import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/ntu_hospital_caffeine_catalog.dart';

enum _CaffeineEntryMode { catalog, estimator }

enum _MeasureType { volume, serving, manual }

class _DrinkType {
  const _DrinkType({
    required this.id,
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.measureType,
    this.mgPerMl,
    this.mgPerServing,
    this.servingUnit = '份',
    this.supportsStrength = false,
  });

  final String id;
  final String label;
  final String subtitle;
  final IconData icon;
  final _MeasureType measureType;
  final double? mgPerMl;
  final int? mgPerServing;
  final String servingUnit;
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
  const _StrengthOption(this.id, this.label, this.multiplier);

  final String id;
  final String label;
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
  final TextEditingController drinkNameController = TextEditingController(
    text: '其他飲品',
  );
  final TextEditingController takingTimeController = TextEditingController();

  final String baseUrl = 'https://wakemate-api-4-0-qtgs.onrender.com';

  static const List<_DrinkType> _drinkTypes = [
    _DrinkType(
      id: 'brewed_coffee',
      label: '現煮咖啡',
      subtitle: '約 0.50 mg/ml',
      icon: Icons.local_cafe_outlined,
      measureType: _MeasureType.volume,
      mgPerMl: 0.50,
      supportsStrength: true,
    ),
    _DrinkType(
      id: 'instant_coffee',
      label: '即溶咖啡',
      subtitle: '約 0.30 mg/ml',
      icon: Icons.coffee_maker_outlined,
      measureType: _MeasureType.volume,
      mgPerMl: 0.30,
      supportsStrength: true,
    ),
    _DrinkType(
      id: 'capsule_espresso',
      label: '膠囊咖啡',
      subtitle: '濃縮型約 70 mg/顆',
      icon: Icons.coffee_outlined,
      measureType: _MeasureType.serving,
      mgPerServing: 70,
      servingUnit: '顆',
    ),
    _DrinkType(
      id: 'capsule_lungo',
      label: '膠囊大杯',
      subtitle: 'lungo 約 95 mg/顆',
      icon: Icons.coffee_outlined,
      measureType: _MeasureType.serving,
      mgPerServing: 95,
      servingUnit: '顆',
    ),
    _DrinkType(
      id: 'espresso',
      label: 'Espresso',
      subtitle: '約 70 mg/shot',
      icon: Icons.local_cafe,
      measureType: _MeasureType.serving,
      mgPerServing: 70,
      servingUnit: 'shot',
    ),
    _DrinkType(
      id: 'black_tea',
      label: '紅茶',
      subtitle: '約 0.20 mg/ml',
      icon: Icons.emoji_food_beverage_outlined,
      measureType: _MeasureType.volume,
      mgPerMl: 0.20,
    ),
    _DrinkType(
      id: 'green_tea',
      label: '綠茶',
      subtitle: '約 0.15 mg/ml',
      icon: Icons.emoji_food_beverage,
      measureType: _MeasureType.volume,
      mgPerMl: 0.15,
    ),
    _DrinkType(
      id: 'energy_drink',
      label: '能量飲料',
      subtitle: '約 0.32 mg/ml',
      icon: Icons.bolt_outlined,
      measureType: _MeasureType.volume,
      mgPerMl: 0.32,
    ),
    _DrinkType(
      id: 'caffeinated_soda',
      label: '氣泡飲料',
      subtitle: '約 0.10 mg/ml',
      icon: Icons.local_drink_outlined,
      measureType: _MeasureType.volume,
      mgPerMl: 0.10,
    ),
    _DrinkType(
      id: 'other',
      label: '其他',
      subtitle: '自行輸入 mg',
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
    _StrengthOption('light', '淡', 0.8),
    _StrengthOption('normal', '正常', 1.0),
    _StrengthOption('strong', '濃', 1.2),
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
    final initialTime = DateTime(
      widget.selectedDate.year,
      widget.selectedDate.month,
      widget.selectedDate.day,
      DateTime.now().hour,
      DateTime.now().minute,
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
            drink.supportsStrength ? '，${_selectedStrength.label}' : '';
        return '${_selectedVolume.label}$strengthText';
      case _MeasureType.serving:
        return '${_selectedServing.label} ${drink.servingUnit}';
      case _MeasureType.manual:
        return '自行輸入';
    }
  }

  String get _drinkNameForSubmit {
    if (_entryMode == _CaffeineEntryMode.catalog) {
      return _selectedCatalogItem.submitName;
    }

    final drink = _selectedDrink;
    if (drink.measureType == _MeasureType.manual) {
      final name = drinkNameController.text.trim();
      return name.isEmpty ? '其他飲品' : name;
    }

    final uncertainty = _isUncertain ? '（不確定）' : '';
    return '${drink.label} $_amountDescription$uncertainty';
  }

  void _syncEstimatedAmountToController() {
    if (_entryMode == _CaffeineEntryMode.catalog) {
      caffeineController.text = _estimatedCaffeineAmount.toString();
      return;
    }

    if (_selectedDrink.measureType != _MeasureType.manual) {
      caffeineController.text = _estimatedCaffeineAmount.toString();
    }
  }

  void _showSnackBar(String message, {Color color = Colors.red}) {
    final snackBar = SnackBar(
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
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  Future<void> _pickDateTime(TextEditingController controller) async {
    DateTime initialDateTime;
    try {
      initialDateTime = DateFormat('yyyy-MM-dd HH:mm').parse(controller.text);
    } catch (e) {
      initialDateTime = DateTime.now();
    }

    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDateTime,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (pickedDate == null) return;
    if (!mounted) return;

    TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDateTime),
    );
    if (pickedTime == null) return;

    DateTime finalDateTime = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    controller.text = DateFormat('yyyy-MM-dd HH:mm').format(finalDateTime);
  }

  String formatToISO8601(String time) {
    try {
      final dt = DateFormat('yyyy-MM-dd HH:mm').parse(time);
      return dt.toIso8601String();
    } catch (e) {
      return DateTime.now().toIso8601String();
    }
  }

  Future<void> _saveToLocal(
    double caffeineAmount,
    String takingTimeString,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final DateTime takingDateTime = DateFormat(
        'yyyy-MM-dd HH:mm',
      ).parse(takingTimeString);
      final String dateKey = DateFormat('yyyy-MM-dd').format(takingDateTime);
      final String prefsKey = 'caffeine_$dateKey';

      double currentTotal = prefs.getDouble(prefsKey) ?? 0;
      double newTotal = currentTotal + caffeineAmount;

      await prefs.setDouble(prefsKey, newTotal);
      debugPrint('[$prefsKey] 儲存成功：$newTotal mg');
    } catch (e) {
      debugPrint('儲存到 SharedPreferences 失敗：$e');
    }
  }

  Future<void> _submitData() async {
    final uuid = widget.userId;
    final takingTime = takingTimeController.text.trim();
    final caffeineAmount = _estimatedCaffeineAmount;
    final drinkName = _drinkNameForSubmit;

    if (takingTime.isEmpty) {
      _showSnackBar('請選擇飲用時間');
      return;
    }

    if (caffeineAmount <= 0) {
      _showSnackBar('咖啡因含量必須是有效的正整數。');
      return;
    }

    final headers = {'Content-Type': 'application/json'};

    try {
      final intakeRes = await http.post(
        Uri.parse('$baseUrl/users_intake/'),
        headers: headers,
        body: jsonEncode({
          'user_id': uuid,
          'caffeine_amount': caffeineAmount,
          'drink_name': drinkName,
          'taking_timestamp': formatToISO8601(takingTime),
        }),
      );

      if (intakeRes.statusCode == 200) {
        await _saveToLocal(caffeineAmount.toDouble(), takingTime);

        _showSnackBar('咖啡因攝取記錄儲存成功！', color: const Color(0xFF8BB9A1));
        if (mounted) {
          Navigator.of(context).pop();
        }
      } else {
        String intakeBody =
            intakeRes.body.isNotEmpty ? intakeRes.body : '無回應內容';
        _showSnackBar('咖啡因記錄儲存失敗：${intakeRes.statusCode}\n回應：$intakeBody');
      }
    } catch (e) {
      _showSnackBar('發生錯誤：$e');
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
    return SegmentedButton<_CaffeineEntryMode>(
      segments: const [
        ButtonSegment(
          value: _CaffeineEntryMode.catalog,
          icon: Icon(Icons.storefront_outlined),
          label: Text('常見商品'),
        ),
        ButtonSegment(
          value: _CaffeineEntryMode.estimator,
          icon: Icon(Icons.tune_outlined),
          label: Text('手動估算'),
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
    final selectedItem = _selectedCatalogItem;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('1. 選擇品牌'),
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
        _buildSectionTitle('2. 選擇商品'),
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
                    '${item.productName} ${item.sizeLabel} · ${item.caffeineLabel}',
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
                '資料來源：${selectedItem.sourceName}',
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('1. 選擇飲品類型'),
        const SizedBox(height: 12),
        _buildDrinkSelector(primaryColor, accentColor),
        const SizedBox(height: 24),
        _buildSectionTitle('2. 選擇份量'),
        const SizedBox(height: 12),
        _buildAmountSelector(primaryColor),
        _buildStrengthSelector(primaryColor),
        const SizedBox(height: 18),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text(
            '我不確定份量或濃度',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: const Text('仍可完成記錄，後續分析會知道這筆是估算值。'),
          value: _isUncertain,
          activeThumbColor: accentColor,
          onChanged: (value) => setState(() => _isUncertain = value),
        ),
      ],
    );
  }

  Widget _buildDrinkSelector(Color primaryColor, Color accentColor) {
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
                  Text(drink.label),
                  Text(
                    drink.subtitle,
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
    final drink = _selectedDrink;

    if (drink.measureType == _MeasureType.manual) {
      return Column(
        children: [
          TextField(
            controller: drinkNameController,
            decoration: InputDecoration(
              labelText: '飲料名稱',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              hintText: '例如：拿鐵、提神飲、其他',
              prefixIcon: Icon(Icons.local_drink_outlined, color: primaryColor),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: caffeineController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: '咖啡因含量 (毫克)',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              hintText: '例如：150',
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
                label: Text('${option.label} ${drink.servingUnit}'),
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
    if (!_selectedDrink.supportsStrength) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 22),
        _buildSectionTitle('3. 沖泡濃淡'),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          children:
              _strengthOptions.map((option) {
                final isSelected = option.id == _selectedStrengthId;
                return ChoiceChip(
                  selected: isSelected,
                  label: Text('${option.label} x${option.multiplier}'),
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
                  '估算咖啡因',
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
                      ? '${_selectedCatalogItem.caffeineLabel} · ${_selectedCatalogItem.sourceName}'
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
  Widget build(BuildContext buildContext) {
    final Color primaryColor = const Color(0xFF4B6B7A);
    final Color accentColor = const Color(0xFF8BB9A1);
    final Color bgLight = const Color(0xFFF9F9F7);

    return Scaffold(
      backgroundColor: bgLight,
      appBar: AppBar(
        title: Text(
          '新增咖啡因紀錄',
          style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white.withValues(alpha: 0.9),
        elevation: 1,
        shadowColor: Colors.black12,
        iconTheme: IconThemeData(color: primaryColor),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '可直接選擇台大醫院附近常見商品，WakeMate 會自動帶入咖啡因；找不到品項時也可切換手動估算。',
              style: TextStyle(fontSize: 16, color: Colors.grey),
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
              readOnly: true,
              decoration: InputDecoration(
                labelText: '飲用時間（點擊選擇）',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: Icon(
                  Icons.access_time_rounded,
                  color: primaryColor,
                ),
              ),
              onTap: () => _pickDateTime(takingTimeController),
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
                label: const Text(
                  '儲存咖啡因記錄',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
