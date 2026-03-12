import 'package:flutter/material.dart';
import 'package:riyo/core/design_system.dart';

class SettingsItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const SettingsItem({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$title setting',
      hint: subtitle ?? '',
      button: true,
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(title, style: AppTypography.titleMedium),
        subtitle: subtitle != null
            ? Text(subtitle!, style: AppTypography.labelSmall)
            : null,
        trailing: trailing ??
            (onTap != null
                ? const Icon(Icons.chevron_right_rounded, size: 24)
                : null),
        onTap: onTap,
      ),
    );
  }
}

class SettingsToggle extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const SettingsToggle({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$title toggle',
      value: value ? 'enabled' : 'disabled',
      child: SwitchListTile(
        secondary: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(title, style: AppTypography.titleMedium),
        subtitle: subtitle != null
            ? Text(subtitle!, style: AppTypography.labelSmall)
            : null,
        value: value,
        onChanged: onChanged,
        activeColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}

class SettingsHeader extends StatelessWidget {
  final String title;
  const SettingsHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: AppTypography.labelSmall.copyWith(
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
