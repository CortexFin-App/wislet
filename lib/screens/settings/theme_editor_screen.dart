import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:provider/provider.dart';
import 'package:wislet/models/theme_profile.dart';
import 'package:wislet/providers/theme_provider.dart';

class ThemeEditorScreen extends StatefulWidget {
  const ThemeEditorScreen({super.key, this.initialProfile});
  final ThemeProfile? initialProfile;

  @override
  State<ThemeEditorScreen> createState() => _ThemeEditorScreenState();
}

class _ThemeEditorScreenState extends State<ThemeEditorScreen> {
  late ThemeProfile _editedProfile;
  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _editedProfile =
        widget.initialProfile ?? context.read<ThemeProvider>().currentProfile;
    _nameController = TextEditingController(
      text: widget.initialProfile != null ? _editedProfile.name : '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _showColorPicker() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('РћР±РµСЂС–С‚СЊ РєРѕР»С–СЂ'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: _editedProfile.seedColor,
            onColorChanged: (color) {
              setState(() {
                _editedProfile = ThemeProfile(
                  name: _editedProfile.name,
                  seedColor: color,
                  borderRadius: _editedProfile.borderRadius,
                  fontFamily: _editedProfile.fontFamily,
                );
              });
            },
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('Р“РѕС‚РѕРІРѕ'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final originalTheme = Theme.of(context);

    return Theme(
      data: originalTheme.copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: _editedProfile.seedColor,
          brightness: originalTheme.brightness,
        ),
        cardTheme: CardThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_editedProfile.borderRadius),
          ),
        ),
        textTheme: originalTheme.textTheme.apply(
          fontFamily: _editedProfile.fontFamily,
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.initialProfile == null
                ? 'РќРѕРІР° РўРµРјР°'
                : 'Р РµРґР°РєС‚РѕСЂ РўРµРјРё',
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.save_outlined),
              onPressed: () {
                final newName = _nameController.text.trim();
                if (newName.isEmpty) return;

                final finalProfile = ThemeProfile(
                  name: newName,
                  seedColor: _editedProfile.seedColor,
                  borderRadius: _editedProfile.borderRadius,
                  fontFamily: _editedProfile.fontFamily,
                );

                context.read<ThemeProvider>().saveCustomTheme(finalProfile);
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'РќР°Р·РІР° С‚РµРјРё',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('РћСЃРЅРѕРІРЅРёР№ РєРѕР»С–СЂ'),
              trailing: CircleAvatar(backgroundColor: _editedProfile.seedColor),
              onTap: _showColorPicker,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Р Р°РґС–СѓСЃ Р·Р°РѕРєСЂСѓРіР»РµРЅРЅСЏ: ${_editedProfile.borderRadius.toStringAsFixed(1)}',
            ),
            Slider(
              value: _editedProfile.borderRadius,
              max: 24,
              divisions: 12,
              label: _editedProfile.borderRadius.toStringAsFixed(1),
              onChanged: (value) {
                setState(() {
                  _editedProfile = ThemeProfile(
                    name: _editedProfile.name,
                    seedColor: _editedProfile.seedColor,
                    borderRadius: value,
                    fontFamily: _editedProfile.fontFamily,
                  );
                });
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _editedProfile.fontFamily,
              decoration: const InputDecoration(
                labelText: 'РЁСЂРёС„С‚',
                border: OutlineInputBorder(),
              ),
              items: ['NotoSans', 'Roboto', 'Inter', 'SourceCodePro']
                  .map(
                    (value) => DropdownMenuItem<String>(
                      value: value,
                      child: Text(value, style: TextStyle(fontFamily: value)),
                    ),
                  )
                  .toList(),
              onChanged: (newValue) {
                if (newValue != null) {
                  setState(() {
                    _editedProfile = ThemeProfile(
                      name: _editedProfile.name,
                      seedColor: _editedProfile.seedColor,
                      borderRadius: _editedProfile.borderRadius,
                      fontFamily: newValue,
                    );
                  });
                }
              },
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  children: [
                    const Text('РџСЂРёРєР»Р°Рґ РєР°СЂС‚РєРё'),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () {},
                      child: const Text('РџСЂРёРєР»Р°Рґ РєРЅРѕРїРєРё'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
