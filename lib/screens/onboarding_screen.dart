import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/lyris_theme.dart';
import '../widgets/lyris_icons.dart';

/// Onboarding — choose role: Tracker or Partner
class OnboardingScreen extends StatefulWidget {
  final VoidCallback onComplete;

  OnboardingScreen({super.key, required this.onComplete});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _page = 0;
  final PageController _controller = PageController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (i) => setState(() => _page = i),
                children: [
                  _WelcomePage(),
                  _RolePage(onSelect: (role) async {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setString('user_role', role);
                    if (role == 'partner') {
                      await prefs.setString('partner_mode', 'partner');
                    } else {
                      await prefs.setString('partner_mode', 'owner');
                    }
                    await prefs.setBool('onboarding_done', true);
                    widget.onComplete();
                  }),
                ],
              ),
            ),

            // Page indicator
            Padding(
              padding: const EdgeInsets.only(bottom: 32),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(2, (i) => AnimatedContainer(
                  duration: Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _page == i ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _page == i ? LyrisTheme.primary : Theme.of(context).dividerColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                )),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WelcomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          LyrisLogoAnimated(size: 72, color: LyrisTheme.primary),
          SizedBox(height: 24),
          Text(
            'Lyris',
            style: TextStyle(
              fontSize: 42,
              fontWeight: FontWeight.w800,
              color: LyrisTheme.primary,
            ),
          ),
          SizedBox(height: 12),
          Text(
            'Your cycle, your data.\n100% offline. 100% private.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
          SizedBox(height: 48),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                final state = context.findAncestorStateOfType<_OnboardingScreenState>();
                state?._controller.nextPage(
                  duration: Duration(milliseconds: 400),
                  curve: Curves.easeOutCubic,
                );
              },
              child: Text('Get Started'),
            ),
          ),
        ],
      ),
    );
  }
}

class _RolePage extends StatelessWidget {
  final void Function(String role) onSelect;

  const _RolePage({required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'How will you use Lyris?',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 32),

          // Tracker option
          _RoleCard(
            icon: Icons.favorite_rounded,
            title: 'I want to track my cycle',
            subtitle: 'Log periods, symptoms, and get predictions',
            color: LyrisTheme.primary,
            onTap: () => onSelect('tracker'),
          ),

          SizedBox(height: 16),

          // Partner option
          _RoleCard(
            icon: Icons.visibility_rounded,
            title: 'I\'m the partner',
            subtitle: 'Get a read-only view via QR code — no tracking needed',
            color: LyrisTheme.info,
            onTap: () => onSelect('partner'),
          ),

          SizedBox(height: 24),
          Text(
            'You can change this later in Settings',
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.08),
              blurRadius: 16,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(child: Icon(icon, size: 28, color: color)),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 16, color: color),
          ],
        ),
      ),
    );
  }
}
