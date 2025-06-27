import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:provider/provider.dart';
import '../../models/theme_profile.dart';
import '../../providers/theme_provider.dart';

class ThemeEditorScreen extends StatefulWidget {
  final ThemeProfile? initialProfile;

  const ThemeEditorScreen({super.key, this.initialProfile});

  @override
  State<ThemeEditorScreen> createState() => _ThemeEditorScreenState();
}

class _ThemeEditorScreenState extends State<ThemeEditorScreen> {
  late ThemeProfile _editedProfile;
  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _editedProfile = widget.initialProfile ??
        context.read<ThemeProvider>().currentProfile;
    _nameController = TextEditingController(text: widget.initialProfile != null ? _editedProfile.name : '');
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _showColorPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Оберіть колір'),
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
            child: const Text('Готово'),
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
          title: Text(widget.initialProfile == null ? 'Нова Тема' : 'Редактор Теми'),
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
                labelText: 'Назва теми',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Основний колір'),
              trailing: CircleAvatar(backgroundColor: _editedProfile.seedColor),
              onTap: _showColorPicker,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            const SizedBox(height: 16),
            Text('Радіус заокруглення: ${_editedProfile.borderRadius.toStringAsFixed(1)}'),
            Slider(
              value: _editedProfile.borderRadius,
              min: 0.0,
              max: 24.0,
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
                labelText: 'Шрифт',
                border: OutlineInputBorder(),
              ),
              items: ['NotoSans', 'Roboto', 'Inter', 'SourceCodePro'].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value, style: TextStyle(fontFamily: value)),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if(newValue != null) {
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
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    const Text('Приклад картки'),
                    const SizedBox(height: 8),
                    ElevatedButton(onPressed: () {}, child: const Text('Приклад кнопки')),
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