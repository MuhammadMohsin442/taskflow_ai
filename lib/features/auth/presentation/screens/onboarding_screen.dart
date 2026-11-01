import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import 'login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();

  int _currentPage = 0;

  final List<_OnboardingItem> _pages = const [
    _OnboardingItem(
      icon: Icons.task_alt_rounded,
      title: 'Organize Your Tasks',
      description:
          'Create tasks, set priorities, and stay on top '
          'of everything that matters.',
    ),
    _OnboardingItem(
      icon: Icons.insights_rounded,
      title: 'Track Your Progress',
      description:
          'Monitor your productivity, manage projects, '
          'and celebrate your achievements.',
    ),
    _OnboardingItem(
      icon: Icons.auto_awesome_rounded,
      title: 'Work Smarter With AI',
      description:
          'Get intelligent suggestions to plan your day '
          'and make better use of your time.',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _finishOnboarding();
    }
  }

  void _finishOnboarding() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
    // Temporary navigation.
    // We will connect the real login screen
    // in Lesson 4.
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Login screen coming next!')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              // Skip button
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _finishOnboarding,
                  child: const Text('Skip'),
                ),
              ),

              // Swipeable pages
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _pages.length,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    final page = _pages[index];

                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE0E7FF),
                            borderRadius: BorderRadius.circular(40),
                          ),
                          child: Icon(
                            page.icon,
                            size: 96,
                            color: AppTheme.primary,
                          ),
                        ),

                        const SizedBox(height: 48),

                        Text(
                          page.title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary,
                          ),
                        ),

                        const SizedBox(height: 16),

                        Text(
                          page.description,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            height: 1.6,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),

              // Page indicators
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_pages.length, (index) {
                  final selected = index == _currentPage;

                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: selected ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: selected
                          ? AppTheme.primary
                          : const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  );
                }),
              ),

              const SizedBox(height: 32),

              // Continue button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _nextPage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    _currentPage == _pages.length - 1
                        ? 'Get Started'
                        : 'Continue',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingItem {
  final IconData icon;
  final String title;
  final String description;

  const _OnboardingItem({
    required this.icon,
    required this.title,
    required this.description,
  });
}
