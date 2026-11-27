import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image.asset(
                  'assets/images/logo.png',
                  width: 96,
                  height: 96,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => DecoratedBox(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Icon(
                        Icons.shield_outlined,
                        size: 38,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text('SmogShield AI', style: theme.textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text(
                'Preparing your clean-air companion',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              Semantics(
                label: 'Loading SmogShield AI',
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
