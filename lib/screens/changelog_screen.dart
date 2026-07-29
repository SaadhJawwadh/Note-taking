import 'package:flutter/material.dart';
import '../theme/app_layout.dart';
import '../widgets/frosted_glass_sliver_app_bar.dart';

class ChangelogScreen extends StatelessWidget {
  const ChangelogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          const FrostedGlassSliverAppBar(
            titleText: 'Changelog',
            showBackButton: true,
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppLayout.spaceXL,
              vertical: AppLayout.spaceL,
            ),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildVersionSection(
                  context,
                  version: 'v2.9.1',
                  date: 'July 29, 2026',
                  isLatest: true,
                  changes: [
                    _ChangelogGroup(
                      title: '🏛️ Unified Frosted Glass Headers & Single-Scaffold Architecture',
                      items: [
                        'Reusable FrostedGlassSliverAppBar Component: Modularized top header architecture across all 7+ sub-screens for 100% visual symmetry, 20px title alignment, and zero-border light/dark mode glassmorphism.',
                        'Single Outer Scaffold FAB Architecture: Centralized floating action bar delegate floating 16dp above the bottom navigation bar across all tabs without clipping or double-padding.',
                        'Default Launch Folder Persistence: Persists user default folder selection (settings.defaultFolder) on app launch.',
                      ],
                    ),
                    _ChangelogGroup(
                      title: '🎨 Pixel-Aligned Header Layout & Light Mode Fixes',
                      items: [
                        'Borderless Glassmorphism: Removed hard horizontal border strokes and double-container inner pills to resolve light-mode shadow artifacts.',
                        'Standardized Side Padding: Aligned left title margins to 20px and normalized right action buttons to standard 48x48dp Material touch targets.',
                      ],
                    ),
                  ],
                ),
                _buildVersionSection(
                  context,
                  version: 'v2.9.0',
                  date: 'July 29, 2026',
                  isLatest: false,
                  changes: [
                    _ChangelogGroup(
                      title: '🎨 Material 3 Expressive UI & Tactile Motion System',
                      items: [
                        'App-Wide M3 Expressive Overhaul: Modern Material 3 Expressive tokens, surface elevation hierarchy, and fluid spring motion physics.',
                        'Frosted Glass Navigation Bars: Symmetric top and bottom frosted glassmorphic navigation bars (16px blur) with edge-to-edge content depth.',
                        'M3 Expressive Floating Action Bars: Stadium-pill FABs with quick shortcuts across Home, Period Tracker, Financial Manager, and Category Management.',
                      ],
                    ),
                    _ChangelogGroup(
                      title: '🐞 Button Haptics & Contrast Enhancements',
                      items: [
                        'Header Action Button Fix: Resolved gesture arena conflict on top app bar buttons, restoring instant button clicks and spring bounce haptics.',
                        'Period Log Readability & Illumination: High-contrast card fills, clear M3 flow tiles, and illuminated outer stroke ring for dark-mode moon painter.',
                        'Floating Surface Popups: Upgraded sorting and tools context menus to M3 elevated floating surface popovers with leading icons and active checkmarks.',
                      ],
                    ),
                  ],
                ),
                _buildVersionSection(
                  context,
                  version: 'v2.8.1',
                  date: 'July 25, 2026',
                  isLatest: false,
                  changes: [
                    _ChangelogGroup(
                      title: '🔍 Universal Spotlight Search & Scope Filters',
                      items: [
                        'Universal Search: Search Notes, Settings & Tools, Financial Transactions, and Health Logs in-place directly on the home screen.',
                        'Category Scope Chips: Filter search results down to Settings, Notes, Finances, or Health with a single tap.',
                        'Inline Quick Actions: Toggle App Lock, run SMS sync, or import CSV files directly inside search cards.',
                      ],
                    ),
                    _ChangelogGroup(
                      title: '🛠️ Export Engine & UI Card Truncation Fixes',
                      items: [
                        'Backup & Ledger Export Fix: Resolved database primary key query error during JSON backup export and added graceful native file share fallbacks.',
                        'Note Card Layout Clamp: Restored multi-line maxLines and ellipsis truncation on home screen note card previews.',
                        'Handwriting Keyboard Support: Full IME compatibility for Samsung S-Pen Direct Writing, GBoard Handwriting, and Apple Scribble.',
                      ],
                    ),
                  ],
                ),
                _buildVersionSection(
                  context,
                  version: 'v2.7.0',
                  date: 'July 24, 2026',
                  isLatest: false,
                  changes: [
                    _ChangelogGroup(
                      title: '🔍 Real-Time Settings Search',
                      items: [
                        'Instant Option Filtering: Search across all 29 app settings, features, and preferences directly from the Settings top header bar.',
                      ],
                    ),
                    _ChangelogGroup(
                      title: '📈 Robust Trend Forecasting & Local Self-Tuning',
                      items: [
                        'Robust Outlier Filtering: Automatically detects and dampens one-off purchase spikes by 75% for accurate baseline trend predictions.',
                        'On-Device Self-Tuning Model: Dynamically tunes recency decay parameters (gamma) via Leave-One-Out validation on local transaction history.',
                      ],
                    ),
                    _ChangelogGroup(
                      title: '🎨 Material 3 Pixel Alignment & Dynamic Palette Control',
                      items: [
                        'Dynamic Theme Switch: Toggle Monet dynamic wallpaper color extraction ON or OFF under Appearance & UI.',
                        'Pixel-Aligned Chart Overlays: Unified Y-axis margins (52px) and multi-line WCAG AAA contrast tooltips across line and bar charts.',
                      ],
                    ),
                  ],
                ),
                _buildVersionSection(
                  context,
                  version: 'v2.6.0',
                  date: 'July 23, 2026',
                  isLatest: false,
                  changes: [
                    _ChangelogGroup(
                      title: '🔄 Flexible Duration & Scheduled SMS Auto-Sync',
                      items: [
                        'Periodic Interval Sync: Configure background SMS auto-sync at your chosen daily time.',
                        'Conditional Auto-Sync Time: Specify exact target sync time when 24-hour daily frequency is selected.',
                      ],
                    ),
                    _ChangelogGroup(
                      title: '📝 Note Editor Quality of Life & Link Previews',
                      items: [
                        'Auto Keyboard Focus: Automatically focuses the text editor on brand new note creation.',
                        'Auto Unfocus on Scroll: Smoothly dismisses the soft keyboard when dragging down long notes.',
                        'Dismissed Link Preview Protection: Link previews dismissed via X stay permanently hidden when typing.',
                        'Fixed Image Removal: Long-press Remove Image targets exact document offset for reliable image deletion.',
                      ],
                    ),
                  ],
                ),
                _buildVersionSection(
                  context,
                  version: 'v2.5.0',
                  date: 'July 22, 2026',
                  isLatest: false,
                  changes: [
                    _ChangelogGroup(
                      title: '🔤 Offline Google Sans Text & Inter Typography',
                      items: [
                        'Embedded Asset Fonts: Google Sans Text and Inter typography embedded into app assets and Android res/font/ resources.',
                        'Zero Network Fetching: Enforced 100% offline font rendering across all app screens and Android Home Widgets.',
                      ],
                    ),
                    _ChangelogGroup(
                      title: '💳 Ledger Engine & SMS Auto-Discovery',
                      items: [
                        '1-Tap Ledger Deduplication: Purge duplicate transaction entries within 120-second import windows.',
                        'Smart Bank Sender Auto-Discovery: Discover new bank senders and whitelist them with one tap.',
                      ],
                    ),
                    _ChangelogGroup(
                      title: '⚙️ Streamlined UI & SMS Import Rules',
                      items: [
                        'Single-View SMS Rules: Streamlined rules page focusing on transaction types with direct link to Category Management.',
                        'Render Overflow & Layout Fixes: Fixed top bar status padding calculations and cleaned Settings About section.',
                      ],
                    ),
                    _ChangelogGroup(
                      title: '🔒 Security & CI/CD Automation',
                      items: [
                        'Backup Rule Safety: Resolved Android FullBackupContent lint rules for encrypted database backups.',
                        'Automated Play Console Deployment: Configured GitHub Actions release workflow with Google Play API automation.',
                      ],
                    ),
                  ],
                ),
                _buildVersionSection(
                  context,
                  version: 'v2.4.0',
                  date: 'July 20, 2026',
                  isLatest: false,
                  changes: [
                    _ChangelogGroup(
                      title: '🔍 In-Note Search & Text Navigation',
                      items: [
                        'Real-Time Search Bar: Search inside any note with instant query highlighting, case-sensitivity toggle, and match navigation.',
                        'Match Count Indicator: Live match position badge (e.g. 1/5) updates dynamically.',
                      ],
                    ),
                    _ChangelogGroup(
                      title: '🧠 Dual-Engine On-Device AI',
                      items: [
                        'Universal Device Support: Powered by Android AI Core NPU on supported hardware, with zero-latency offline fallback.',
                        'Floating AI Assist Toolbar: Highlight text to trigger an instant floating AI assist toolbar over the keyboard.',
                        'Smart Tag Suggestions: Whole-word boundary precision with dynamic topic detection.',
                      ],
                    ),
                    _ChangelogGroup(
                      title: '💳 Ledger Engine & SMS Auto-Discovery',
                      items: [
                        '1-Tap Ledger Deduplication: Purge duplicate transaction entries within 120-second windows.',
                        'Smart Bank Sender Auto-Discovery: Discover new bank senders and whitelist them with one tap.',
                      ],
                    ),
                    _ChangelogGroup(
                      title: '🎨 Universal UI/UX Consistency Pass',
                      items: [
                        'Floating Pill App Bars: Standardized top app bars across all sub-screens and settings.',
                        'Aligned Action Buttons: Unified floating action buttons (FAB) with stadium border styling across modules.',
                      ],
                    ),
                  ],
                ),
                _buildVersionSection(
                  context,
                  version: 'v2.3.0',
                  date: 'July 20, 2026',
                  isLatest: false,
                  changes: [
                _ChangelogGroup(
                  title: '🏷️ Category Management & Custom Icons',
                  items: [
                    'Category Renaming: Edit category names with automatic SQLite migration across past transactions.',
                    'Custom Category Icons: Pick from 24 Material icons for any category.',
                    'Safe Category Deletion: Delete categories with automatic transaction reassignment to "Other".',
                  ],
                ),
                _ChangelogGroup(
                  title: '📝 Note Editor & Canvas Polish',
                  items: [
                    'Slash Commands (/): Type "/" to quickly insert checklists, tables, code blocks, or headings.',
                    'Floating Island Toolbar: Glassmorphism formatting bar with backdrop blur.',
                    'Note Details & Stats: View word count, character count, read time, and creation dates.',
                    'Share & Export: Share notes as Plain Text, Markdown, or copy to clipboard.',
                  ],
                ),
                _ChangelogGroup(
                  title: '🌙 Period Tracker — Full Redesign',
                  items: [
                    'Moon Phase Animation: Live moon widget reflecting current cycle phase.',
                    'Logging-First Layout: Quick logging card at top of screen.',
                    'Icon-Based Flow Intensity: Spotting, Light, Medium, and Heavy visual tiles.',
                    'Collapsible Symptoms: Animated collapsible symptoms card with active count badge.',
                  ],
                ),
                _ChangelogGroup(
                  title: '🔧 Dark Mode & Visibility Fixes',
                  items: [
                    'Unified Chip Palette: Symptom chips use onPeriodColor palette for dark mode visibility.',
                    'Visible Delete Action: Fixed log deletion icon visibility in dark mode.',
                  ],
                ),
              ],
            ),
            _buildVersionSection(
              context,
              version: 'v2.2.0',
              date: 'July 18, 2026',
              changes: [
                _ChangelogGroup(
                  title: '📊 Live Interactive Tables',
                  items: [
                    'Inline Table Widget: Rendered tables directly as beautiful interactive widgets within the Note Editor.',
                    'Dynamic Cell Editing: Added custom text inputs inside cells, managing focus and updating the note automatically.',
                    'Row/Column Management: Touch-optimized action buttons for adding and deleting rows/columns dynamically.',
                    'Automatic Focus Dismissal: Clear cell focus and collapse keyboard when tapping outside the table.',
                  ],
                ),
                _ChangelogGroup(
                  title: '📝 Textual Table Previews',
                  items: [
                    'Clean Note Card Snippets: Note list cards on the home screen display a clean preview of table rows using column separators.',
                  ],
                ),
                _ChangelogGroup(
                  title: '⚙️ Settings Redesign & Feedback',
                  items: [
                    'Modern Static Card Layout: Redesigned settings into clean card groupings for instant access.',
                    'Play Store Feedback Option: Added a direct Play Store Rating and Feedback button inside settings.',
                  ],
                ),
              ],
            ),
            _buildVersionSection(
              context,
              version: 'v2.1.0',
              date: 'July 15, 2026',
              changes: [
                _ChangelogGroup(
                  title: '📁 Folder & Selection Enhancements',
                  items: [
                    'Folder Card Selector: Replaced the dynamic greeting text on the home screen with an interactive Folder Selector showing the active folder name, notes count, and a inline dropdown arrow.',
                    'Memory-Persistent Folder Creation: Added the ability to create folders inline inside the selector sheet, which remain in memory even if they contain no notes.',
                    'Automatic Folder Assignment: Creating new notes or using templates inside a folder context automatically inherits and pre-selects that folder.',
                  ],
                ),
                _ChangelogGroup(
                  title: '📝 Templates & Creation Flow',
                  items: [
                    'Accessible Options Bottom Sheet: Changed the FAB single tap action to present a clean options sheet with direct entry paths for Blank Notes and pre-built templates, replacing the hidden long-press gesture.',
                    'Redundancy & UX Cleanup: Removed duplicate checkmark buttons and redundant checklist tools from the editor header and formatting toolbar.',
                  ],
                ),
                _ChangelogGroup(
                  title: '📱 Responsive Tablet Layouts',
                  items: [
                    'Side Navigation Rail: Tablet and foldable screens (width >= 600dp) display a sleek side NavigationRail instead of a bottom bar.',
                    'Two-Column Dashboard: The Budgets & Analytics dashboard displays side-by-side card layouts for maximized spatial usage.',
                  ],
                ),
                _ChangelogGroup(
                  title: '💰 Financial Ledger Updates',
                  items: [
                    'CSV Transaction Export: Added an export button in the financial screen app bar to export transactions as an RFC 4180 compliant CSV spreadsheet file.',
                  ],
                ),
                _ChangelogGroup(
                  title: '⚡ UI & Performance Polish',
                  items: [
                    'Snappy Snackbars: Swipe-to-trash/archive and delete alerts clear existing overlays instantly and dismiss automatically in 3 seconds.',
                  ],
                ),
              ],
            ),
            _buildVersionSection(
              context,
              version: 'v2.0.0',
              date: 'July 12, 2026',
              changes: [
                _ChangelogGroup(
                  title: '📝 Note-Taking Upgrades',
                  items: [
                    'Voice Dictation: Record voice directly at your cursor from the editor toolbar.',
                    'On-the-Fly Markdown: Headers, bullet lists, bold, and italic text auto-formats as you type.',
                    'Locked Notes: Lock private notes securely behind fingerprint or passcode verification.',
                    'Note Reminders: Schedule localized notifications to deep-link straight to note tasks.',
                    'Find-in-Note & Outlines: Search note text and navigate heading structures quickly.',
                  ],
                ),
                _ChangelogGroup(
                  title: '🩸 Period Tracker Refinements',
                  items: [
                    'Semantic Phase Colors:预测周期和经期显示色彩来自系统主题 Token，取代写死的调色板。',
                    'Skeleton Loading: Added responsive shimmer cards matching the core feeds during load.',
                  ],
                ),
                _ChangelogGroup(
                  title: '✨ Smart Features & Widgets',
                  items: [
                    'Gemini Nano Offline AI: Locally summarize notes, suggest tags, and auto-parse transaction SMS on compatible NPUs.',
                    'Recurring Transactions: Schedule daily, weekly, or monthly automatic expense logging.',
                    'Notes Quick-Capture Widget: Desktop shortcut to search and create notes instantly.',
                  ],
                ),
                _ChangelogGroup(
                  title: '🎨 Material Expressive Design',
                  items: [
                    'Font Pairing: Google Sans Display paired with Inter body text.',
                    'Predictive Back Motion: Integrated shared-axis navigation transitions.',
                    'Tamil Language: Full localization infrastructure for Tamil text support.',
                  ],
                ),
              ],
            ),
            _buildVersionSection(
              context,
              version: 'v1.39.0',
              date: 'July 11, 2026',
              changes: [
                _ChangelogGroup(
                  title: '💰 Transactions & SMS Fetching',
                  items: [
                    'Scheduled Ingestion: Added background scheduler for importing transaction logs from bank SMS.',
                    'Offline Categories: Fully offline transaction categorization engine.',
                  ],
                ),
              ],
            ),
          ]),
        ),
      ),
    ],
  ),
);
  }

  Widget _buildVersionSection(
    BuildContext context, {
    required String version,
    required String date,
    bool isLatest = false,
    required List<_ChangelogGroup> changes,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppLayout.spaceXL),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: isLatest ? theme.colorScheme.primary : theme.colorScheme.outlineVariant,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: theme.colorScheme.surface,
                    width: 3,
                  ),
                  boxShadow: isLatest
                      ? [
                          BoxShadow(
                            color: theme.colorScheme.primary.withValues(alpha: 0.4),
                            blurRadius: 6,
                            spreadRadius: 2,
                          )
                        ]
                      : null,
                ),
              ),
              Container(
                width: 2,
                height: changes.fold<double>(0.0, (acc, item) => acc + (item.items.length * 28.0) + 90.0),
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ],
          ),
          const SizedBox(width: AppLayout.spaceM),
          Expanded(
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppLayout.radiusL),
                side: BorderSide(
                  color: theme.colorScheme.outlineVariant.withValues(alpha: isDark ? 0.15 : 0.3),
                ),
              ),
              color: isLatest
                  ? theme.colorScheme.primaryContainer.withValues(alpha: 0.1)
                  : theme.colorScheme.surfaceContainerLow,
              child: Padding(
                padding: const EdgeInsets.all(AppLayout.spaceL),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(
                              version,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: isLatest ? theme.colorScheme.primary : null,
                              ),
                            ),
                            if (isLatest) ...[
                              const SizedBox(width: AppLayout.spaceS),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  'LATEST',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.onPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        Text(
                          date,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: AppLayout.spaceXL),
                    ...changes.map((group) => Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              group.title,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: AppLayout.spaceS),
                            ...group.items.map((item) => Padding(
                                  padding: const EdgeInsets.only(
                                    left: AppLayout.spaceS,
                                    bottom: AppLayout.spaceS,
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '• ',
                                        style: TextStyle(
                                          color: theme.colorScheme.primary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          item,
                                          style: theme.textTheme.bodyMedium?.copyWith(
                                            color: theme.colorScheme.onSurfaceVariant,
                                            height: 1.3,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                )),
                            const SizedBox(height: AppLayout.spaceM),
                          ],
                        )),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChangelogGroup {
  final String title;
  final List<String> items;

  _ChangelogGroup({
    required this.title,
    required this.items,
  });
}
