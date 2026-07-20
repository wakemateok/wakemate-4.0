import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:my_app/gen_l10n/app_localizations.dart';

class SettingsPage extends StatefulWidget {
  final String userId;
  const SettingsPage({super.key, required this.userId});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _formKey = GlobalKey<FormState>();
  String? _gender;
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _bmiController = TextEditingController();

  bool _isLoading = false;
  final String baseUrl = 'https://wakemate-api-4-0-qtgs.onrender.com';
  String? _existingRecordId;

  // 定義顏色和樣式
  final Color _primaryColor = const Color(0xFF1F3D5B); // 深藍色
  final Color _accentColor = const Color(0xFF5E91B3); // 淺藍色
  final Color _backgroundColor = const Color(0xFFF0F2F5); // 淺灰色背景
  final Color _cardColor = Colors.white; // 卡片白色背景
  final Color _textColor = const Color(0xFF424242); // 深灰色文字

  @override
  void initState() {
    super.initState();
    _loadUserSettings();
    _heightController.addListener(_calculateBMI);
    _weightController.addListener(_calculateBMI);
  }

  void _calculateBMI() {
    final double? height = double.tryParse(_heightController.text);
    final double? weight = double.tryParse(_weightController.text);

    if (height != null && weight != null && height > 0) {
      final double bmi = weight / ((height / 100) * (height / 100));
      _bmiController.text = bmi.toStringAsFixed(2);
    } else {
      _bmiController.text = '';
    }
  }

  Future<void> _loadUserSettings() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isLoading = true);
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/users_body_info/?user_id=${widget.userId}'),
        headers: {'Content-Type': 'application/json'},
      );

      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        if (data.isNotEmpty) {
          final userData = data[0];
          _existingRecordId = userData['id']?.toString();
          setState(() {
            _gender = userData['gender'] ?? null;
            _ageController.text = userData['age']?.toString() ?? '';
            _heightController.text = userData['height']?.toString() ?? '';
            _weightController.text = userData['weight']?.toString() ?? '';
            _bmiController.text = userData['bmi']?.toString() ?? '';
          });
        } else {
          print("尚未有資料，第一次使用");
        }
      } else {
        print("讀取資料失敗：${res.body}");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("${l10n.settingsLoadFailed}: ${res.statusCode}"),
            ),
          );
        }
      }
    } catch (e) {
      print("讀取資料錯誤：$e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("${l10n.settingsLoadError}: $e")),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSettings() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate() || _gender == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.completeRequiredFieldsAndGender)),
      );
      return;
    }

    setState(() => _isLoading = true);

    final body = {
      "user_id": widget.userId,
      "gender": _gender,
      "age": int.tryParse(_ageController.text) ?? 0,
      "height": double.tryParse(_heightController.text) ?? 0,
      "weight": double.tryParse(_weightController.text) ?? 0,
      "bmi": double.tryParse(_bmiController.text) ?? 0,
    };

    try {
      http.Response res;

      if (_existingRecordId != null) {
        res = await http.put(
          Uri.parse('$baseUrl/users_body_info/${_existingRecordId!}/'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        );
      } else {
        res = await http.post(
          Uri.parse('$baseUrl/users_body_info/'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        );

        if (res.statusCode == 200 || res.statusCode == 201) {
          final savedData = jsonDecode(res.body);
          _existingRecordId = savedData['id']?.toString();
        }
      }

      if (res.statusCode == 200 || res.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.settingsSaved)));
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("${l10n.settingsSaveFailed}: ${res.body}")),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("${l10n.settingsSaveFailed}: $e")),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _bmiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: Text(
          l10n.bodySettingsTitle,
          style: TextStyle(fontWeight: FontWeight.bold, color: _primaryColor),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: _primaryColor),
      ),
      body:
          _isLoading && _existingRecordId == null
              ? Center(child: CircularProgressIndicator(color: _accentColor))
              : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),
                      Text(
                        l10n.genderLabel,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _textColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: _cardColor,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.2),
                              spreadRadius: 1,
                              blurRadius: 5,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: RadioListTile<String>(
                                title: Text(
                                  l10n.maleLabel,
                                  style: TextStyle(color: _textColor),
                                ),
                                value: "M",
                                groupValue: _gender,
                                onChanged: (value) {
                                  setState(() {
                                    _gender = value;
                                  });
                                },
                                activeColor: _accentColor,
                              ),
                            ),
                            Expanded(
                              child: RadioListTile<String>(
                                title: Text(
                                  l10n.femaleLabel,
                                  style: TextStyle(color: _textColor),
                                ),
                                value: "F",
                                groupValue: _gender,
                                onChanged: (value) {
                                  setState(() {
                                    _gender = value;
                                  });
                                },
                                activeColor: _accentColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildTextFormField(
                        controller: _ageController,
                        labelText: l10n.ageLabel,
                        hintText: l10n.ageHint,
                        keyboardType: TextInputType.number,
                        prefixIcon: Icons.cake_outlined,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return l10n.ageRequired;
                          }
                          if (int.tryParse(value) == null ||
                              int.parse(value) <= 0) {
                            return l10n.invalidAge;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildTextFormField(
                        controller: _heightController,
                        labelText: l10n.heightLabel,
                        hintText: l10n.heightHint,
                        keyboardType: TextInputType.number,
                        prefixIcon: Icons.height,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return l10n.heightRequired;
                          }
                          if (double.tryParse(value) == null ||
                              double.parse(value) <= 0) {
                            return l10n.invalidHeight;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildTextFormField(
                        controller: _weightController,
                        labelText: l10n.weightLabel,
                        hintText: l10n.weightHint,
                        keyboardType: TextInputType.number,
                        prefixIcon: Icons.scale,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return l10n.weightRequired;
                          }
                          if (double.tryParse(value) == null ||
                              double.parse(value) <= 0) {
                            return l10n.invalidWeight;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildTextFormField(
                        controller: _bmiController,
                        labelText: "BMI",
                        hintText: l10n.bmiHint,
                        keyboardType: TextInputType.number,
                        prefixIcon: Icons.calculate,
                        readOnly: true,
                        fillColor: Colors.grey[200],
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _saveSettings,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 5,
                          ),
                          icon:
                              _isLoading
                                  ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                  : const Icon(Icons.save),
                          label: Text(
                            _isLoading ? l10n.saving : l10n.saveSettings,
                            style: const TextStyle(fontSize: 18),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }

  // 輔助函式，用於建立統一風格的 TextFormField
  Widget _buildTextFormField({
    required TextEditingController controller,
    required String labelText,
    String? hintText,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    IconData? prefixIcon,
    bool readOnly = false,
    Color? fillColor,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        labelStyle: TextStyle(color: _textColor),
        hintStyle: TextStyle(color: _textColor.withOpacity(0.5)),
        prefixIcon:
            prefixIcon != null ? Icon(prefixIcon, color: _primaryColor) : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade400),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade400),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _primaryColor, width: 2),
        ),
        filled: true,
        fillColor: fillColor ?? _cardColor,
      ),
      keyboardType: keyboardType,
      validator: validator,
      readOnly: readOnly,
      style: TextStyle(color: _textColor),
    );
  }
}
