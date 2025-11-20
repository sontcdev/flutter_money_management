// path: lib/src/ui/screens/onboarding_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_money_management/src/ui/widgets/app_button.dart';
import 'package:flutter_money_management/src/app_router.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class OnboardingScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.pie_chart, size: 120, color: Theme.of(context).colorScheme.primary),
              SizedBox(height: 32),
              Text(
                l10n.onboardingTitle,
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              Text(
                l10n.onboardingSubtitle,
                style: TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: AppButton(
                  text: l10n.getStarted,
                  onPressed: () {
                    Navigator.of(context).pushReplacementNamed(AppRouter.login);
                  },
                ),
              ),
              SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pushReplacementNamed(AppRouter.home);
                },
                child: Text(l10n.skip),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

