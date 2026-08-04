import 'package:flutter/material.dart';
import 'package:globetrotter_flutter/theme/app_theme.dart';

/// Social features (friends, shared itineraries, activity feed) have no
/// backend support yet — this screen is an honest placeholder rather than
/// fabricated friend data, ready to wire up once a social API exists.
class SocialScreen extends StatelessWidget {
  const SocialScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          color: AppColors.navyDark,
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
          child: const Text(
            'Social',
            style: TextStyle(
                color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800),
          ),
        ),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.groups_outlined,
                      size: 64,
                      color: AppColors.textMuted.withValues(alpha: 0.6)),
                  const SizedBox(height: 16),
                  const Text(
                    'Social features are coming soon',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Follow friends, share itineraries, and see where fellow travelers have been — once this is wired up on the backend.',
                    style: TextStyle(color: AppColors.textMuted),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
