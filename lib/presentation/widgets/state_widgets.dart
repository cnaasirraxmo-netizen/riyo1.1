import 'package:flutter/material.dart';
import 'package:riyo/core/design_system.dart';
import 'package:riyo/presentation/widgets/riyo_components.dart';

class StateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final List<Widget>? bulletPoints;
  final String? primaryActionText;
  final VoidCallback? onPrimaryAction;
  final String? secondaryActionText;
  final VoidCallback? onSecondaryAction;

  const StateWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.bulletPoints,
    this.primaryActionText,
    this.onPrimaryAction,
    this.secondaryActionText,
    this.onSecondaryAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 80, color: Theme.of(context).colorScheme.primary.withAlpha(100)),
            const SizedBox(height: 32),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTypography.headlineMedium,
            ),
            const SizedBox(height: 16),
            Text(
              description,
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                color: Theme.of(context).textTheme.labelSmall?.color,
              ),
            ),
            if (bulletPoints != null && bulletPoints!.isNotEmpty) ...[
              const SizedBox(height: 24),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: bulletPoints!,
              ),
            ],
            const SizedBox(height: 40),
            if (primaryActionText != null)
              RiyoButton(
                text: primaryActionText!,
                onPressed: onPrimaryAction,
              ),
            if (secondaryActionText != null) ...[
              const SizedBox(height: 12),
              RiyoButton(
                text: secondaryActionText!,
                isPrimary: false,
                onPressed: onSecondaryAction,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class BulletPoint extends StatelessWidget {
  final String text;
  const BulletPoint({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline_rounded, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Text(text, style: AppTypography.bodyMedium),
        ],
      ),
    );
  }
}

// Pre-defined states
class NoInternetState extends StatelessWidget {
  final VoidCallback onRetry;
  final VoidCallback onGoOffline;

  const NoInternetState({super.key, required this.onRetry, required this.onGoOffline});

  @override
  Widget build(BuildContext context) {
    return StateWidget(
      icon: Icons.wifi_off_rounded,
      title: 'You are offline',
      description: "Please check your internet connection and try again.",
      primaryActionText: 'Retry Connection',
      onPrimaryAction: onRetry,
      secondaryActionText: 'Go to Downloads',
      onSecondaryAction: onGoOffline,
    );
  }
}

class NoDownloadsState extends StatelessWidget {
  final VoidCallback onBrowse;
  final VoidCallback onHowTo;

  const NoDownloadsState({super.key, required this.onBrowse, required this.onHowTo});

  @override
  Widget build(BuildContext context) {
    return StateWidget(
      icon: Icons.download_for_offline_outlined,
      title: 'No Downloads',
      description: 'Movies you download will appear here so you can watch them anywhere.',
      primaryActionText: 'Find something to watch',
      onPrimaryAction: onBrowse,
    );
  }
}

class NoHistoryState extends StatelessWidget {
  final VoidCallback onStartWatching;

  const NoHistoryState({super.key, required this.onStartWatching});

  @override
  Widget build(BuildContext context) {
    return StateWidget(
      icon: Icons.history_rounded,
      title: 'No Watch History',
      description: 'Movies and shows you watch will appear here.',
      primaryActionText: 'Start Watching',
      onPrimaryAction: onStartWatching,
    );
  }
}

class NoSearchResultsState extends StatelessWidget {
  final String query;
  final VoidCallback onBack;

  const NoSearchResultsState({super.key, required this.query, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return StateWidget(
      icon: Icons.search_off_rounded,
      title: 'No Results Found',
      description: 'We couldn\'t find any matches for "$query".',
      primaryActionText: 'Try Another Search',
      onPrimaryAction: onBack,
    );
  }
}
