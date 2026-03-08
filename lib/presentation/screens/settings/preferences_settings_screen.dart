import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:riyo/providers/settings_provider.dart';
import 'package:riyo/presentation/screens/settings/settings_widgets.dart';

class PreferencesSettingsScreen extends StatelessWidget {
  const PreferencesSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F0F),
        title: const Text('Preferences', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        children: [
          const SettingsHeader(title: 'Content Discovery'),
          SettingsItem(
            icon: Icons.favorite_border,
            title: 'Favorite Genres',
            subtitle: settings.favoriteGenres.isEmpty ? 'None selected' : settings.favoriteGenres.join(', '),
            onTap: () => _showGenreSelection(context, settings),
          ),

          const SettingsHeader(title: 'Content Filtering'),
          SettingsToggle(
            icon: Icons.explicit_outlined,
            title: 'Hide Adult Content',
            value: settings.hideAdultContent,
            onChanged: (val) => settings.setHideAdultContent(val),
          ),
          SettingsToggle(
            icon: Icons.warning_amber_outlined,
            title: 'Hide Horror Movies',
            value: settings.hideHorrorMovies,
            onChanged: (val) => settings.setHideHorrorMovies(val),
          ),
          SettingsToggle(
            icon: Icons.visibility_off_outlined,
            title: 'Hide Spoilers',
            value: settings.hideSpoilers,
            onChanged: (val) => settings.setHideSpoilers(val),
          ),

          const SettingsHeader(title: 'Recommendations'),
          SettingsToggle(
            icon: Icons.recommend_outlined,
            title: 'Personalized Recommendations',
            subtitle: 'Based on your watch history',
            value: settings.personalRecommendations,
            onChanged: (val) => settings.setPersonalRecommendations(val),
          ),
        ],
      ),
    );
  }

  void _showGenreSelection(BuildContext context, SettingsProvider settings) {
    final genres = ['Action', 'Drama', 'Comedy', 'Horror', 'Documentary', 'Sci-Fi', 'Thriller'];
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final current = List<String>.from(settings.favoriteGenres);
          return AlertDialog(
            backgroundColor: const Color(0xFF1C1C1C),
            title: const Text('Favorite Genres', style: TextStyle(color: Colors.white)),
            content: SingleChildScrollView(
              child: Column(
                children: genres.map((g) => CheckboxListTile(
                  title: Text(g, style: const TextStyle(color: Colors.white)),
                  value: current.contains(g),
                  onChanged: (val) {
                    if (val!) {
                      current.add(g);
                    } else {
                      current.remove(g);
                    }
                    settings.setFavoriteGenres(current);
                    setState(() {});
                  },
                  activeColor: Theme.of(context).primaryColor,
                )).toList(),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('DONE')),
            ],
          );
        }
      ),
    );
  }
}
