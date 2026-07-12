import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../data/settings_provider.dart';
import '../theme/app_layout.dart';
import '../widgets/bouncing_widget.dart';
import 'package:package_info_plus/package_info_plus.dart';

class OnboardingSheet extends StatefulWidget {
  const OnboardingSheet({super.key});

  @override
  State<OnboardingSheet> createState() => _OnboardingSheetState();
}

class _OnboardingSheetState extends State<OnboardingSheet> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  static const int _totalPages = 5;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    HapticFeedback.lightImpact();
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: AppLayout.animDefault,
        curve: Curves.easeInOut,
      );
    } else {
      _finishOnboarding();
    }
  }

  void _finishOnboarding() async {
    final settings = context.read<SettingsProvider>();
    await HapticFeedback.mediumImpact();
    await settings.setHasSeenOnboarding(true);
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      await settings.setLastSeenVersion(packageInfo.version);
    } catch (_) {}
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppLayout.radiusMAX)),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: isDark ? 0.15 : 0.3),
          width: 1.0,
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Top Drag Handle & Skip Option
            Padding(
              padding: const EdgeInsets.fromLTRB(AppLayout.spaceXL, AppLayout.spaceM, AppLayout.spaceXL, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Minimalist center drag handle visual
                  Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  if (_currentPage < _totalPages - 1)
                    TextButton(
                      onPressed: _finishOnboarding,
                      child: Text(
                        'Skip',
                        style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  else
                    const SizedBox(height: 48), // Spacer to maintain layout alignment
                ],
              ),
            ),
            
            // Slider Pages
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                children: [
                  _buildWelcomePage(theme),
                  _buildModulesPage(theme),
                  _buildAiPage(theme),
                  _buildNavigationPage(theme),
                  _buildTipsPage(theme),
                ],
              ),
            ),

            // Indicator Dots & Navigation Actions
            Padding(
              padding: const EdgeInsets.all(AppLayout.spaceXL),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Page Indicators
                  Row(
                    children: List.generate(_totalPages, (index) {
                      final isActive = index == _currentPage;
                      return AnimatedContainer(
                        duration: AppLayout.animShort,
                        margin: const EdgeInsets.only(right: AppLayout.spaceS),
                        width: isActive ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isActive
                              ? theme.colorScheme.primary
                              : theme.colorScheme.outlineVariant,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),

                  // Action Button
                  BouncingWidget(
                    onTap: _nextPage,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppLayout.spaceXL,
                        vertical: AppLayout.spaceM,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(AppLayout.radiusL),
                        boxShadow: [
                          BoxShadow(
                            color: theme.colorScheme.primary.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _currentPage == _totalPages - 1 ? 'Get Started' : 'Next',
                            style: TextStyle(
                              color: theme.colorScheme.onPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(width: AppLayout.spaceS),
                          Icon(
                            _currentPage == _totalPages - 1
                                ? Icons.done_all_rounded
                                : Icons.arrow_forward_rounded,
                            color: theme.colorScheme.onPrimary,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomePage(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppLayout.spaceXL),
      child: Column(
        children: [
          const SizedBox(height: AppLayout.spaceXL),
          // Large Premium Welcome Graphic
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary.withValues(alpha: 0.25),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Icon(
              Icons.note_alt_rounded,
              color: theme.colorScheme.onPrimary,
              size: 48,
            ),
          ),
          const SizedBox(height: AppLayout.spaceXXL),
          Text(
            'Welcome to Everything App',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppLayout.spaceL),
          Text(
            'A minimalist, private, offline-first notes space. Write down ideas, checklist items, and customize layout feeds with clean Material 3 design.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppLayout.spaceXL),
          _buildInfoRow(
            theme,
            icon: Icons.offline_bolt_outlined,
            title: 'Fully Offline',
            desc: 'Your text and documents never leave your phone. 100% private.',
          ),
          _buildInfoRow(
            theme,
            icon: Icons.edit_note_rounded,
            title: 'Rich Editor',
            desc: 'Format text with checklists, markdown support, and bullet lists.',
          ),
        ],
      ),
    );
  }

  Widget _buildModulesPage(ThemeData theme) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppLayout.spaceXL),
          child: Column(
            children: [
              const SizedBox(height: AppLayout.spaceL),
              // Feature Icon
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.apps_rounded,
                  color: theme.colorScheme.primary,
                  size: 32,
                ),
              ),
              const SizedBox(height: AppLayout.spaceXL),
              Text(
                'Modular Powerups',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppLayout.spaceM),
              Text(
                'Everything App adapts to your life. Enable extra modules below, or customize them in Settings anytime.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppLayout.spaceXL),
              
              // Module Toggles
              _buildModuleCard(
                theme,
                icon: Icons.account_balance_wallet_outlined,
                title: 'Financial Manager',
                desc: 'Ledger tracking, trends chart, and automatic bank SMS parses.',
                value: settings.showFinancialManager,
                onChanged: settings.setShowFinancialManager,
              ),
              const SizedBox(height: AppLayout.spaceM),
              _buildModuleCard(
                theme,
                icon: Icons.water_drop_outlined,
                title: 'Period Tracker',
                desc: 'Menstrual calendar cycle predictions and discreet logs.',
                value: settings.isPeriodTrackerEnabled,
                onChanged: settings.setIsPeriodTrackerEnabled,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAiPage(ThemeData theme) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppLayout.spaceXL),
          child: Column(
            children: [
              const SizedBox(height: AppLayout.spaceL),
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.auto_awesome_outlined,
                  color: theme.colorScheme.secondary,
                  size: 32,
                ),
              ),
              const SizedBox(height: AppLayout.spaceXL),
              Text(
                'On-Device Gemini AI',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppLayout.spaceM),
              Text(
                'Unlock local AI capabilities to summarize notes, auto-suggest tags, and intelligently categorize SMS transactions.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppLayout.spaceXL),
              if (settings.isDeviceAiSupported)
                _buildModuleCard(
                  theme,
                  icon: Icons.psychology_outlined,
                  title: 'Enable Offline AI',
                  desc: 'Run model on-device (zero data leaves your phone).',
                  value: settings.useOnDeviceAi,
                  onChanged: settings.setUseOnDeviceAi,
                )
              else
                Container(
                  padding: const EdgeInsets.all(AppLayout.spaceM),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(AppLayout.radiusL),
                    border: Border.all(
                      color: theme.colorScheme.outlineVariant.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: theme.colorScheme.outline),
                      const SizedBox(width: AppLayout.spaceM),
                      Expanded(
                        child: Text(
                          'Offline AI is unsupported on this device (requires compatible NPU and Android AI Core).',
                          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNavigationPage(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppLayout.spaceXL),
      child: Column(
        children: [
          const SizedBox(height: AppLayout.spaceXL),
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.explore_rounded,
              color: theme.colorScheme.primary,
              size: 32,
            ),
          ),
          const SizedBox(height: AppLayout.spaceXL),
          Text(
            'Where to Find Features',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppLayout.spaceM),
          Text(
            'Everything is designed to stay out of your way until needed.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppLayout.spaceXXL),
          _buildInfoRow(
            theme,
            icon: Icons.navigation_outlined,
            title: 'Bottom Navigation Bar',
            desc: 'Once any modular feature is enabled, a navigation bar appears at the bottom of the home screen to switch tabs.',
          ),
          const SizedBox(height: AppLayout.spaceM),
          _buildInfoRow(
            theme,
            icon: Icons.settings_outlined,
            title: 'Main Settings Menu',
            desc: 'Tap the Settings gear at the top right of the Notes screen. That is where you lock the app, configure AI, or manage backups.',
          ),
        ],
      ),
    );
  }

  Widget _buildTipsPage(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppLayout.spaceXL),
      child: Column(
        children: [
          const SizedBox(height: AppLayout.spaceXL),
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: theme.colorScheme.secondary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.tips_and_updates_outlined,
              color: theme.colorScheme.secondary,
              size: 32,
            ),
          ),
          const SizedBox(height: AppLayout.spaceXL),
          Text(
            'Quick Pro-Tips',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppLayout.spaceL),
          
          // List of bullet tips
          _buildTipCard(
            theme,
            icon: Icons.color_lens_outlined,
            title: 'Color Tags',
            desc: 'Note backgrounds adapt to their tag color dynamically to make your notes easy to group visually.',
          ),
          const SizedBox(height: AppLayout.spaceM),
          _buildTipCard(
            theme,
            icon: Icons.select_all_rounded,
            title: 'Multi-Select Actions',
            desc: 'Long press any note card to enter selection mode. This allows you to tag, archive, or delete notes in bulk.',
          ),
          const SizedBox(height: AppLayout.spaceM),
          _buildTipCard(
            theme,
            icon: Icons.security_rounded,
            title: 'Encrypted & Safe',
            desc: 'The local database is encrypted securely with SQLCipher using a protected KeyStore key.',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(ThemeData theme, {required IconData icon, required String title, required String desc}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppLayout.spaceM),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: theme.colorScheme.primary, size: 24),
          const SizedBox(width: AppLayout.spaceM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppLayout.spaceXS),
                Text(
                  desc,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModuleCard(
    ThemeData theme, {
    required IconData icon,
    required String title,
    required String desc,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(AppLayout.radiusL),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: isDark ? 0.15 : 0.3),
        ),
      ),
      child: SwitchListTile(
        secondary: Icon(icon, color: theme.colorScheme.primary),
        title: Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          desc,
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        value: value,
        onChanged: (val) {
          HapticFeedback.lightImpact();
          onChanged(val);
        },
      ),
    );
  }

  Widget _buildTipCard(ThemeData theme, {required IconData icon, required String title, required String desc}) {
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(AppLayout.spaceM),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(AppLayout.radiusL),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: isDark ? 0.15 : 0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: theme.colorScheme.secondary, size: 20),
          const SizedBox(width: AppLayout.spaceM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: AppLayout.spaceXS),
                Text(
                  desc,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 13,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
