import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:oummi3/data/onboarding_config.dart';
import 'onboarding_page.dart';

class OnboardingScreen extends StatefulWidget {
  final OumiRole role;

  const OnboardingScreen({super.key, required this.role});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();

  @override
  Widget build(BuildContext context) {
    final pages = OnboardingConfig.getPagesForRole(widget.role);

    return Scaffold(
      body: PageView.builder(
        controller: _pageController,
        itemCount: pages.length,
        itemBuilder: (context, index) {
          return OnboardingPage(
            page: pages[index],
            index: index,
            total: pages.length,
            role: widget.role,
            onNext: () {
              if (index < pages.length - 1) {
                _pageController.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              } else {
                // Finish onboarding
                context.go('/home/${widget.role.name}');
              }
            },
            onSkip: () {
              context.go('/home/${widget.role.name}');
            },
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}
