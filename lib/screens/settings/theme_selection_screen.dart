import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/scaffold/patterned_scaffold.dart';
import 'theme_editor_screen.dart';
import '../../utils/app_palette.dart';

class ThemeSelectionScreen extends StatelessWidget {
  const ThemeSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    
    return PatternedScaffold(
      appBar: AppBar(
        title: const Text('Вибір теми'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 80),
        itemCount: themeProvider.allProfiles.length,
        itemBuilder: (context, index) {
          final profile = themeProvider.allProfiles[index];
          final bool isSelected = profile.name == themeProvider.currentProfile.name;
          final bool isDefault = index < 3;

          return Card(
            elevation: isSelected ? 4 : 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(profile.borderRadius),
              side: BorderSide(
                color: isSelected ? AppPalette.darkAccent : Colors.transparent,
                width: 2,
              ),
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: profile.seedColor,
              ),
              title: Text(profile.name),
              trailing: isDefault 
                ? (isSelected ? const Icon(Icons.check_circle, color: AppPalette.darkPositive) : null) 
                : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if(isSelected) const Icon(Icons.check_circle, color: AppPalette.darkPositive),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 20),
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => ThemeEditorScreen(initialProfile: profile)));
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error, size: 20),
                      onPressed: () {
                        context.read<ThemeProvider>().deleteCustomTheme(profile);
                      },
                    ),
                  ],
                ),
              onTap: () {
                themeProvider.setThemeProfile(profile);
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Створити свою тему'),
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const ThemeEditorScreen()));
        },
      ),
    );
  }
}