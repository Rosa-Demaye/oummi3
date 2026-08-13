import 'package:flutter/material.dart';
import 'package:oummi3/data/onboarding_config.dart';

class OnboardingPage extends StatelessWidget {
  final OnboardingPageData page;
  final int index;
  final int total;
  final VoidCallback onNext;
  final VoidCallback onSkip;
  final OumiRole role;

  const OnboardingPage({
    super.key,
    required this.page,
    required this.index,
    required this.total,
    required this.onNext,
    required this.onSkip,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    // Get palette based on the role
    final RolePalette palette = OnboardingConfig.getPaletteForRole(role);

    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Illustration
              Expanded(
                flex: 3,
                child: page.illustration.isNotEmpty
                    ? Image.asset(
                        page.illustration,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => Container(
                          decoration: BoxDecoration(
                            color: palette.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.image_outlined,
                              size: 100,
                              color: palette.primary,
                            ),
                          ),
                        ),
                      )
                    : Container(
                        decoration: BoxDecoration(
                          color: palette.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.image_outlined,
                            size: 100,
                            color: palette.primary,
                          ),
                        ),
                      ),
              ),
              const SizedBox(height: 24),
              // Title
              Text(
                page.title,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: palette.primary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              // Body
              Text(
                page.body,
                style: const TextStyle(fontSize: 16, color: Colors.black87),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              // Progress dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  total,
                  (i) => Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i == index
                          ? palette.primary
                          : palette.primary.withOpacity(0.3),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              // Buttons
              if (page.buttonText != null)
                ElevatedButton(
                  onPressed: onNext,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: palette.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28)),
                  ),
                  child: Text(
                    page.buttonText!,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                )
              else
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(
                      onPressed: onSkip,
                      child: const Text('Passer',
                          style: TextStyle(color: Colors.grey)),
                    ),
                    ElevatedButton(
                      onPressed: onNext,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: palette.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28)),
                      ),
                      child: const Text('Commencer'),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
