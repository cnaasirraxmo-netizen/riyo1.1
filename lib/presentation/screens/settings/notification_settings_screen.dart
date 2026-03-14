import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:riyo/providers/settings_provider.dart';
import 'package:riyo/presentation/screens/settings/settings_widgets.dart';

class NotificationSettingsScreen extends StatelessWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body: ListView(
        children: [
          const SettingsHeader(title: 'General Notifications'),
          SettingsToggle(
            icon: Icons.movie_outlined,
            title: 'New Movie Alerts',
            value: settings.newMovieAlerts,
            onChanged: (val) => settings.setNewMovieAlerts(val),
          ),
          SettingsToggle(
            icon: Icons.video_library_outlined,
            title: 'Trailer Alerts',
            value: settings.trailerAlerts,
            onChanged: (val) => settings.setTrailerAlerts(val),
          ),
          SettingsToggle(
            icon: Icons.notifications_active_outlined,
            title: 'Coming Soon Reminders',
            value: settings.comingSoonReminders,
            onChanged: (val) => settings.setComingSoonReminders(val),
          ),

          const SettingsHeader(title: 'Personal Notifications'),
          SettingsToggle(
            icon: Icons.bookmark_outline,
            title: 'My List Updates',
            subtitle: 'Notify me when movie I saved is released',
            value: settings.notifyOnSavedReleased,
            onChanged: (val) => settings.setNotifyOnSavedReleased(val),
          ),

          const SettingsHeader(title: 'System'),
          SettingsToggle(
            icon: Icons.volume_up_outlined,
            title: 'Enable Sound',
            value: settings.enableNotificationSound,
            onChanged: (val) => settings.setEnableNotificationSound(val),
          ),
          SettingsToggle(
            icon: Icons.vibration,
            title: 'Enable Vibration',
            value: settings.enableNotificationVibration,
            onChanged: (val) => settings.setEnableNotificationVibration(val),
          ),

          const SettingsHeader(title: 'Quiet Mode'),
          SettingsToggle(
            icon: Icons.do_not_disturb_on_outlined,
            title: 'Quiet Mode',
            subtitle: 'Mute notifications during specific time',
            value: settings.quietMode,
            onChanged: (val) => settings.setQuietMode(val),
          ),
          if (settings.quietMode) ...[
             SettingsItem(
               icon: Icons.access_time,
               title: 'Start Time',
               subtitle: settings.quietModeStart.format(context),
               onTap: () => _selectTime(context, settings, true),
             ),
             SettingsItem(
               icon: Icons.access_time,
               title: 'End Time',
               subtitle: settings.quietModeEnd.format(context),
               onTap: () => _selectTime(context, settings, false),
             ),
          ]
        ],
      ),
    );
  }

  Future<void> _selectTime(BuildContext context, SettingsProvider settings, bool isStart) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStart ? settings.quietModeStart : settings.quietModeEnd,
    );
    if (picked != null) {
      if (isStart) {
        settings.setQuietModeStart(picked);
      } else {
        settings.setQuietModeEnd(picked);
      }
    }
  }
}
