import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../utils/colors.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onFinish;
  final bool isDark;

  const OnboardingScreen({
    super.key,
    required this.onFinish,
    required this.isDark,
  });

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  // Returns black or white depending on background brightness for best contrast
  Color _getTextColor(Color background) {
    // Calculate luminance (0.0 = black, 1.0 = white)
    return background.computeLuminance() > 0.5 ? Colors.white : Colors.white;
  }

  final List<_OnboardPage> _pages = [
    _OnboardPage(
      imagePath: 'assets/onboarding/todo_list.svg',
      title: 'Task Management',
      desc: 'View all your current to-dos, add new, and track completion.',
      backgroundColor: AppColors.primaryBlue,
    ),
    _OnboardPage(
      imagePath: 'assets/onboarding/prioritise_task.svg',
      title: 'Priorities Your Important Task',
      desc: 'Assign low, medium, or high priority badges to your tasks.',
      backgroundColor: AppColors.mintGreen,
    ),
    _OnboardPage(
      imagePath: 'assets/onboarding/reminder.svg',
      title: 'Get Notify On Time',
      desc: 'Set deadlines and get reminders for important tasks.',
      backgroundColor: AppColors.teal,
    ),
    _OnboardPage(
      imagePath: 'assets/onboarding/swipe_options.svg',
      title: 'Swipe Gestures',
      desc: 'Swipe left to delete or edit, right to complete tasks quickly.',
      backgroundColor: AppColors.softLavender,
    ),
  ];
  int _pageIndex = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final page = _pages[_pageIndex];
    final textColor = _getTextColor(page.backgroundColor);
    
    return Scaffold(
      backgroundColor: page.backgroundColor,
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 24),
                // Main content
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SvgPicture.asset(
                          page.imagePath,
                          height: 180,
                          width: 180,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: 32),
                        Text(
                          page.title,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          page.desc,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.normal,
                            color: textColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                // Bottom controls
                Column(
                  children: [
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: _pageIndex == 0
                              ? null
                              : () {
                                  setState(() => _pageIndex--);
                                },
                          child: const Text('Previous'),
                        ),
                        Expanded(
                          child: Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: List.generate(
                                _pages.length,
                                (i) => Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 3),
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: i == _pageIndex
                                        ? textColor
                                        : textColor.withOpacity(0.3),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: _pageIndex == _pages.length - 1
                              ? widget.onFinish
                              : () {
                                  setState(() => _pageIndex++);
                                },
                          child: Text(
                            _pageIndex == _pages.length - 1 ? 'Get Started' : 'Next',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ],
            ),
          ),
          // Skip button in top-right corner
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 16,
            child: TextButton(
              onPressed: widget.onFinish,
              style: TextButton.styleFrom(
                foregroundColor: textColor,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: textColor.withOpacity(0.3),
                    width: 1,
                  ),
                ),
              ),
              child: const Text(
                'Skip',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardPage {
  final String imagePath;
  final String title;
  final String desc;
  final Color backgroundColor;

  const _OnboardPage({
    required this.imagePath,
    required this.title,
    required this.desc,
    required this.backgroundColor,
  });
}
