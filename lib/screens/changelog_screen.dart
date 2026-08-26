import 'package:flutter/material.dart';
import '../core/theme/app_layout.dart';
import '../widgets/frosted_glass_sliver_app_bar.dart';
import '../core/ui/app_card.dart';

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
                  version: 'v2.24.0',
                  date: 'August 26, 2026',
                  isLatest: true,
                  changes: [
                    _ChangelogGroup(
                      title: "🌟 What's New",
                      items: [
                        'Split Bills & Shared Debts: Group bill splitting with equal or custom exact splits, friend balances, and 1-tap WhatsApp breakdown reminders.',
                        '100% Offline Receipt Scanner: Instant OCR totals and merchant extraction directly on-device with zero cloud dependency.',
                        'Modular Dual-Account Toggle: Flexible switch to enable or disable the Savings Vault & Daily Operating two-bucket view anytime.',
                      ],
                    ),
                    _ChangelogGroup(
                      title: '🚀 Improvements',
                      items: [
                        'Unified Category Pickers: Color-coded category chips cloud seamlessly shared across Transactions, Split Bills, and Recurring Rules.',
                        'Accessibility & Touch Hit Targets: Enhanced TalkBack / VoiceOver semantics and enlarged interactive touch targets across all sheets.',
                        'Optimized Custom Amount Inputs: Spacious, unclipped multi-currency number entry fields.',
                      ],
                    ),
                  ],
                ),
                _buildVersionSection(
                  context,
                  version: 'v2.23.0',
                  date: 'August 25, 2026',
                  isLatest: false,
                  changes: [
                    _ChangelogGroup(
                      title: "🌟 What's New",
                      items: [
                        'Two-Bank Account Management: Manage separate Daily Operating and Savings Vault accounts with instant balance hero badges and ledger account filtering.',
                        'AI-Powered Spending Analysis Export: Export your financial ledger with an integrated, intelligent analysis prompt crafted for Claude, ChatGPT, Gemini, and NotebookLM.',
                        'Resilient Auto-Backup Storage: Sandboxed app storage ensures automatic daily/weekly backups remain active without permission revocations across OS updates.',
                      ],
                    ),
                    _ChangelogGroup(
                      title: '🚀 Improvements',
                      items: [
                        'Live Recurring Rule Sync: Editing a recurring transaction seamlessly synchronizes and updates the master recurring rule for all future billing cycles.',
                        'Widget Launch SMS Catch-Up Sync: Automatically checks and imports new bank SMS transactions when opening the app directly or through home screen widgets.',
                        'Account Ledger Tagging: Clear account bucket chips and icons across transaction rows and CSV exports.',
                      ],
                    ),
                  ],
                ),
                _buildVersionSection(
                  context,
                  version: 'v2.22.0',
                  date: 'August 24, 2026',
                  isLatest: false,
                  changes: [
                    _ChangelogGroup(
                      title: "🌟 What's New",
                      items: [
                        'SMS & Bank Automation Hub: Real-time SMS test sandbox, custom keyword rules, and verified offline bank parsing for instant ledger tracking.',
                        'Smart Recurring Subscriptions: Automated repeating bills and salaries with live keyword category detection and duplicate prevention.',
                        'Sender Controls & Diagnostics: Block unwanted senders and inspect diagnostic feedback for promotional broadcasts.',
                      ],
                    ),
                    _ChangelogGroup(
                      title: '🚀 Improvements',
                      items: [
                        'Spending Trend Analytics: Refined chart header density and projection styling for smooth 120 FPS navigation.',
                        'Hardware-Aware AI Controls: Dynamic feature gating ensures settings and menus cleanly adapt to device capabilities.',
                        'Clean Merchant Extraction: Automatic filtering of phone numbers, country codes, and payment gateway noise from transaction titles.',
                      ],
                    ),
                    _ChangelogGroup(
                      title: '🐛 Fixes',
                      items: [
                        'CEFTS Self-Transfer Categorization: Accurate zero-expense detection for bank transfers between owned accounts.',
                        'SMS Ingestion & Date Precision: Historical message timestamps strictly preserved with tombstone re-import safeguards.',
                      ],
                    ),
                  ],
                ),
                _buildVersionSection(
                  context,
                  version: 'v2.21.5',
                  date: 'August 24, 2026',
                  isLatest: false,
                  changes: [
                    _ChangelogGroup(
                      title: '🚀 Improvements',
                      items: [
                        'Play Store Release Pipeline Resiliency: Synchronized bilingual release notes with strict character limits and automated version code pacing for Google Play releases.',
                        'Android 15 Edge-to-Edge & Performance: Native system bar edge-to-edge rendering and optimized R8 bytecode shrinking for faster cold launch.',
                      ],
                    ),
                  ],
                ),
                _buildVersionSection(
                  context,
                  version: 'v2.21.4',
                  date: 'August 24, 2026',
                  isLatest: false,
                  changes: [
                    _ChangelogGroup(
                      title: '🚀 Improvements',
                      items: [
                        'Android 15 Native Edge-to-Edge: Integrated native enableEdgeToEdge() activity orchestration and transparent system insets for fluid display across Android 15 & 16 devices.',
                        'R8 Code Shrinking & Inlining: Hardened ProGuard keep rules and release build optimizations for reduced memory and zero-delay startup.',
                      ],
                    ),
                  ],
                ),
                _buildVersionSection(
                  context,
                  version: 'v2.21.3',
                  date: 'August 21, 2026',
                  isLatest: false,
                  changes: [
                    _ChangelogGroup(
                      title: '🚀 Improvements',
                      items: [
                        'Instant 0ms UI Updates: Added optimistic instant state rendering across the Financial Ledger, Notes feed, Trash Sheet, and Health Tracker—deleting, restoring, and toggling items updates the UI in 0ms with zero loading flickers or list re-animations.',
                        'Accurate SMS Message Timestamps: Past bank SMS transactions and inbox imports accurately preserve the exact date and time the message arrived instead of defaulting to the import date.',
                      ],
                    ),
                    _ChangelogGroup(
                      title: '🐛 Fixes',
                      items: [
                        'Financial Ledger Undo Restoration: Fixed transaction undo button by executing direct database restoration, preventing primary key collisions and soft-delete tombstone blocks.',
                        'Silent Background Sync: Background data refreshes and note tagging updates execute quietly without interrupting ongoing user reading or unmounting active lists.',
                      ],
                    ),
                  ],
                ),
                _buildVersionSection(
                  context,
                  version: 'v2.21.2',
                  date: 'August 21, 2026',
                  isLatest: false,
                  changes: [
                    _ChangelogGroup(
                      title: '🐛 Fixes & Improvements',
                      items: [
                        'SMS Permission & Sync Detection: Fixed SMS permission evaluation by removing undeclared phone permission requirements, restoring instant 1-tap quick sync and real-time bank SMS interception.',
                        'Tombstone Re-Import Safeguards: Enhanced transaction ingestion to check the tombstone table, preventing permanently deleted transactions from being re-imported during historical scans unless explicitly enabled.',
                        'Sync Cancellation & Progress Controls: Added an instant "Cancel" button to the SMS sync banner and batch processing chunks for seamless navigation across large inboxes.',
                      ],
                    ),
                  ],
                ),
                _buildVersionSection(
                  context,
                  version: 'v2.21.1',
                  date: 'August 21, 2026',
                  isLatest: false,
                  changes: [
                    _ChangelogGroup(
                      title: '🚀 Improvements',
                      items: [
                        'Bitmap Memory Downsampling: Added image downsampling and fallback error handling to note previews, cutting image memory usage by up to 85% and preventing Out-Of-Memory pauses on large camera photos.',
                        'R8 Full-Mode Optimization: Enabled aggressive dead-code elimination, method inlining, and bytecode optimization for faster app launch and reduced download size.',
                        'Backward-Compatible Schema Upgrades: Enhanced SQLite database migration routines with rigorous single-quote SQL syntax and multi-version upgrade validation.',
                      ],
                    ),
                  ],
                ),
                _buildVersionSection(
                  context,
                  version: 'v2.21.0',
                  date: 'August 21, 2026',
                  isLatest: false,
                  changes: [
                    _ChangelogGroup(
                      title: '🌟 What\'s New',
                      items: [
                        'Universal Morphing Action Buttons: Standardized fluid floating action buttons that dynamically morph into compact circular buttons while scrolling for distraction-free reading.',
                        'Recurring Payment Conversion: Seamlessly convert any manual or imported SMS transaction into a recurring schedule directly from the transaction editor.',
                        'Rotating Pro-Tips System: Helpful dismissible contextual tips on the Home feed and optional 3-day notifications to discover power features.',
                      ],
                    ),
                    _ChangelogGroup(
                      title: '🚀 Improvements',
                      items: [
                        'Real-Time Home Widget Budget Updates: Editing budget limits or adding transactions instantly synchronizes to the Android home screen widget.',
                        'Donut Chart Precision & Text Scaling: Dynamic downscaling for large currency totals inside donut chart center holes with guaranteed visibility for small slices.',
                        'Forecast Chart Tooltip Visibility: Tooltips now render above touch targets for crystal-clear finger navigation.',
                      ],
                    ),
                    _ChangelogGroup(
                      title: '🐛 Fixes',
                      items: [
                        'Bottom Content Overlap Safeguards: Standardized bottom clearance padding across all lists, forms, and segmented buttons to eliminate floating button overlap.',
                        'Smart Recurring Deduplication: Intelligent time and amount tolerance window avoids duplicate transactions when bank clearance schedules shift.',
                      ],
                    ),
                  ],
                ),
                _buildVersionSection(
                  context,
                  version: 'v2.20.0',
                  date: 'August 19, 2026',
                  isLatest: false,
                  changes: [
                    _ChangelogGroup(
                      title: '🌟 What\'s New',
                      items: [
                        'Interactive Expense Breakdown Donut: Centered donut chart with dynamic center total and bi-directional touch linking with ranked categories.',
                        '3-Slide Swipable Visual Intelligence Deck: Trajectory forecast spline, category breakdown donut, and budget pacing with circular gauge.',
                        'Dynamic Home Screen Widget Sparkline: Native anti-aliased canvas sparkline curve plot, gradient underfill, and glowing forecast dot.',
                      ],
                    ),
                    _ChangelogGroup(
                      title: '🚀 Improvements',
                      items: [
                        'Adaptive Month-End Run-Rate Forecast: Extrapolates current month finish with days 1–3 early-month smoothing to prevent artificial spikes.',
                        'Context-Aware Deep Linking: Tapping "Details >" on any slide routes directly to the exact corresponding sub-tab with zero guesswork.',
                        'Zero-Dead-Code Cleanup: Purged deprecated legacy widgets and unified all forecasting logic into SpendingForecastService.',
                      ],
                    ),
                    _ChangelogGroup(
                      title: '🐛 Fixes',
                      items: [
                        'Resolved Title Clipping & Whitespace: Fixed text truncation on small screens and balanced budget pacing cards with dual-column layout.',
                      ],
                    ),
                  ],
                ),
                _buildVersionSection(
                  context,
                  version: 'v2.19.0',
                  date: 'August 18, 2026',
                  isLatest: false,
                  changes: [
                    _ChangelogGroup(
                      title: '🌟 What\'s New',
                      items: [
                        'Symmetrical Precision Text Toolbar: Directional horizontal nudges, double-tap word jumping, and vertical line traversal in a frosted floating bar.',
                        'Health Cycle Regularity Insights: Real-time regularity scoring (0–100%), average flow duration analytics, moon phase guidance, and symptom tracking.',
                        'Category Spending Budgets & CSV Export: Category spending progress bars with threshold alerts, recurring subscription rules, and RFC-compliant CSV ledger export.',
                        'Tombstone Sync & Backup Protection: Permanent deletion retention prevents purged transactions from ever resurrecting across backups or P2P sync.',
                      ],
                    ),
                    _ChangelogGroup(
                      title: '🚀 Improvements',
                      items: [
                        'Fluid Spring Animations & Tactile Haptics: Smooth slide transitions and tactile click responses across formatting tools and cycle insights.',
                        'Ultra-Modular Screen Architecture: Cleaner, faster performance with decoupled state providers across Notes, Finances, and Health.',
                      ],
                    ),
                    _ChangelogGroup(
                      title: '🐛 Fixes',
                      items: [
                        'SMS Re-import & Duplication Resilience: Rock-solid P2P two-way merge resolution and deletion tombstone propagation.',
                      ],
                    ),
                  ],
                ),
                _buildVersionSection(
                  context,
                  version: 'v2.18.0',
                  date: 'August 15, 2026',
                  isLatest: false,
                  changes: [
                    _ChangelogGroup(
                      title: '🌟 What\'s New',
                      items: [
                        'Interactive SMS Test Sandbox: Test bank SMS messages live with instant amount, transaction direction, and category feedback before importing.',
                        'Global Currencies & Custom Currency: Choose from curated world currencies with authentic symbol badges or add your own custom currency code.',
                        'One-Tap Category Learning: Automatically train merchant rules into your category definitions with a single tap in the transaction editor.',
                      ],
                    ),
                    _ChangelogGroup(
                      title: '🚀 Improvements',
                      items: [
                        'Hardware-Aware AI Smart Gating: Cleanly hides AI controls on devices without on-device AI hardware for a distraction-free experience.',
                        'Precision Text Selection Toolbar: Refined text selection entry with directional arrow controls for fine-grained editing.',
                        'Silent Auto-Backup Channel: Background auto-backups now run in a quiet notification channel without disturbing your workflow.',
                        'Note Editor Heading & Indentation Tools: Visual heading level indicator badges and indentation buttons in the rich-text note editor.',
                      ],
                    ),
                    _ChangelogGroup(
                      title: '🐛 Fixes',
                      items: [
                        'Enhanced SMS Parsing & Long Merchant Support: Extended merchant recognition up to 60 characters and refined PII reference number cleaning.',
                      ],
                    ),
                  ],
                ),
                _buildVersionSection(
                  context,
                  version: 'v2.17.2',
                  date: 'August 12, 2026',
                  isLatest: false,
                  changes: [
                    _ChangelogGroup(
                      title: '🌟 What\'s New',
                      items: [
                        'Background Bank SMS Auto-Import: Automatically scan bank transactions in the background with a floating M3 progress indicator while using the app.',
                        'AI Transaction Title Refinement: Clean up cryptic bank SMS transaction descriptions into clean merchant names with single-tap or 48-hour bulk AI title refinement.',
                        'Unified Dual-Gesture Sync: Tap sync icons for fast 24-hour sync, or long-press to open advanced historical import sheets across Notes and Finances.',
                        'Friendly Device Naming & Multi-Network P2P: Automatically generate memorable paired device names and keep P2P sync connected across home and work Wi-Fi networks.',
                      ],
                    ),
                    _ChangelogGroup(
                      title: '🚀 Improvements',
                      items: [
                        '60–120 FPS Performance & WAL Mode: RepaintBoundary GPU chart isolation and SQLite Write-Ahead Logging (WAL) mode for silky smooth fling-scrolling and non-blocking background syncs.',
                        'Human-Readable P2P Diagnostics: Clear, actionable troubleshooting guidance for P2P connection failures with dynamic red error cards and instant retry options.',
                        'Interactive Wi-Fi Refresh: Instant SnackBar feedback when re-scanning Wi-Fi network interfaces and binding P2P host ports.',
                      ],
                    ),
                    _ChangelogGroup(
                      title: '🐛 Fixes',
                      items: [
                        'Android Telephony Stability: Resolved native Android channel exception crashes when SMS permissions are revoked, and handled pairing timeouts gracefully.',
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: AppLayout.spaceXL),
                _buildVersionSection(
                  context,
                  version: 'v2.17.1',
                  date: 'August 12, 2026',
                  isLatest: false,
                  changes: [
                    _ChangelogGroup(
                      title: '🌟 What\'s New',
                      items: [
                        'AI Transaction Title Refinement: Clean up cryptic bank SMS transaction descriptions into clean merchant names with single-tap or 48-hour bulk AI title refinement.',
                        'Unified Dual-Gesture Sync: Tap sync icons for fast 24-hour sync, or long-press to open advanced historical import sheets across Notes and Finances.',
                      ],
                    ),
                    _ChangelogGroup(
                      title: '🚀 Improvements',
                      items: [
                        'Human-Readable P2P Diagnostics: Clear, actionable troubleshooting guidance for P2P connection failures with dynamic red error cards and instant retry options.',
                        'Interactive Wi-Fi Refresh: Instant SnackBar feedback when re-scanning Wi-Fi network interfaces and binding P2P host ports.',
                      ],
                    ),
                    _ChangelogGroup(
                      title: '🐛 Fixes',
                      items: [
                        'Android Telephony Stability: Resolved native Android channel exception crashes when SMS permissions are revoked, and handled pairing timeouts gracefully.',
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: AppLayout.spaceXL),
                _buildVersionSection(
                  context,
                  version: 'v2.17.0',
                  date: 'August 12, 2026',
                  isLatest: false,
                  changes: [
                    _ChangelogGroup(
                      title: '🌟 What\'s New',
                      items: [
                        'Non-Blocking Background SMS Import: Automatically scan bank transactions in the background with a floating live progress indicator while you continue using the app.',
                        'Advanced SMS Range & Tombstones: Import recent or full historical bank SMS with 30-day auto-purge retention and tombstone protection to prevent re-importing deleted items.',
                        'Smart Toolbar & Precision Text Selection: Fine-tune cursor placement character-by-character or word-by-word, and enjoy intelligent toolbar layouts that adapt to your device\'s hardware AI capabilities.',
                        'Friendly Device Naming & Multi-Network P2P: Automatically generate memorable paired device names and keep P2P sync connected across home, work, and mobile Wi-Fi networks.',
                      ],
                    ),
                    _ChangelogGroup(
                      title: '🚀 Improvements',
                      items: [
                        'Hardware-Aware Onboarding: Clear status indicators differentiate Android AI Core NPU hardware from offline rule-based NLP engines during setup.',
                        'Material 3 Depth & Ink Polish: Seamless borderless top app bar, frosted glass navigation depth, and material ripple splash protections across search overlays and finance cards.',
                      ],
                    ),
                    _ChangelogGroup(
                      title: '🐛 Fixes',
                      items: [
                        'Finance Provider & Exception Guard: Resolved root provider scoping for finance screens and fixed ListTile container material assertions.',
                        'Pairing & Scanner Reliability: Reinforced QR code pairing handshakes, camera permission declarations, and multi-endpoint network fallbacks.',
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: AppLayout.spaceXL),
                _buildVersionSection(
                  context,
                  version: 'v2.16.0',
                  date: 'August 11, 2026',
                  isLatest: false,
                  changes: [
                    _ChangelogGroup(
                      title: '🌟 What\'s New',
                      items: [
                        'Smarter Device Sync: Give each paired device a name and keep it connected across home, work, and other Wi-Fi networks.',
                        'Precision Text Selection: Use the new cursor tool in the note editor to adjust selected text one character or word at a time.',
                      ],
                    ),
                    _ChangelogGroup(
                      title: '🚀 Improvements',
                      items: [
                        'Clearer Editor Tools: AI Assist and Precision Selection now have their own toolbar buttons, keeping writing tools easier to find.',
                        'Faster Navigation: Search now surfaces P2P Sync and more settings shortcuts, while long-pressing a note makes moving it to a folder quicker.',
                      ],
                    ),
                    _ChangelogGroup(
                      title: '🐛 Fixes',
                      items: [
                        'Reliable Pairing & Scanning: Pairing is confirmed before it is saved, remembers alternate Wi-Fi connections, and QR scanning now requests camera access correctly.',
                        'Editor & Data Stability: Improved selection-toolbar layout, table editing behavior, and fresh-install database setup.',
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: AppLayout.spaceXL),
                _buildVersionSection(
                  context,
                  version: 'v2.14.0',
                  date: 'August 5, 2026',
                  isLatest: false,
                  changes: [
                    _ChangelogGroup(
                      title: '🌟 What\'s New',
                      items: [
                        'Bi-Directional P2P Wi-Fi Sync: Seamlessly merge notes, financial ledgers, and settings between devices over Wi-Fi non-destructively without losing local edits.',
                        'Reliable SMS Auto-Sync Engine: Background bank transaction sync now runs reliably with 48-hour catch-up sync for offline devices, live status badges, and a 1-tap "Sync SMS Now" test action.',
                      ],
                    ),
                    _ChangelogGroup(
                      title: '🚀 Improvements',
                      items: [
                        'Ultra-Smooth Text Selection: Fixed keyboard D-Pad arrow key navigation and text selection lag in the editor for instant, stutter-free typing.',
                        'Dynamic Light & Dark Hero Cards: Hero cards dynamically adjust pastel opacities in Light Mode and deep translucent fills in Dark Mode for crisp visual contrast.',
                      ],
                    ),
                    _ChangelogGroup(
                      title: '🐛 Fixes',
                      items: [
                        'Database Subtype Options Safety: Resolved database option type casting issues for encrypted local storage.',
                        'Onboarding P2P Entry Point: Verified seamless navigation from initial onboarding tips to the P2P device sync hub.',
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: AppLayout.spaceXL),
                _buildVersionSection(
                  context,
                  version: 'v2.13.0',
                  date: 'August 5, 2026',
                  isLatest: false,
                  changes: [
                    _ChangelogGroup(
                      title: '🌟 What\'s New',
                      items: [
                        'Bi-Directional Delta Merge P2P Sync: Seamlessly merge notes, financial ledgers, and settings between devices over Wi-Fi without losing local edits or moving soft-deleted items back to the inbox.',
                        'Interactive Onboarding & What\'s New Entry Points: Pair and sync devices directly during app setup or explore new features with 1-tap action buttons in the What\'s New sheet.',
                      ],
                    ),
                    _ChangelogGroup(
                      title: '🚀 Improvements',
                      items: [
                        'Material 3 Expressive Sync Hub: Redesigned P2P control center with dynamic status cards, 1-tap IP & pair code copying, and individual device sync actions.',
                        'Robust Network & VPN Handling: Smart socket binding and local IP discovery support DHCP changes and VPN split-tunneling cleanly.',
                      ],
                    ),
                    _ChangelogGroup(
                      title: '🐛 Fixes',
                      items: [
                        'Dual-Device Pairing Detection: Fixed issue where paired devices were not displayed symmetrically on both host and scanner devices.',
                        'Trash-Moving Sync Guardrail: Soft-deleted notes remain cleanly in the Trash across devices without reappearing in active note lists.',
                      ],
                    ),
                  ],
                ),
                _buildVersionSection(
                  context,
                  version: 'v2.12.0',
                  date: 'August 5, 2026',
                  isLatest: false,
                  changes: [
                    _ChangelogGroup(
                      title: '🌟 What\'s New',
                      items: [
                        'Fast Local Master Device Sync: Transfer your complete notebook between devices instantly over your local network using direct REST connections.',
                        'Onboarding Setup Mode Choices: Choose to set up a new primary notebook or pair and import from an existing phone during initial app setup.',
                      ],
                    ),
                    _ChangelogGroup(
                      title: '🚀 Improvements',
                      items: [
                        'Permission-Lean Privacy: Removed unnecessary Bluetooth and location permission requests for a cleaner experience.',
                        'Clear Master Overwrite Warnings: Helpful warning dialogs explain Primary and Secondary device roles before replacing secondary device data.',
                        'Landscape & Tablet FAB Access: Access the "New Note" button seamlessly in portrait, landscape, and tablet modes.',
                      ],
                    ),
                    _ChangelogGroup(
                      title: '🐛 Fixes',
                      items: [
                        'Single-Device Deduplication: Prevents duplicate device entries when pairing devices.',
                        'Ultra-Fast Network Sockets: Replaced legacy Bluetooth connections with fast local REST sockets for zero-freeze syncing.',
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: AppLayout.spaceXL),
                _buildVersionSection(
                  context,
                  version: 'v2.11.1',
                  date: 'August 1, 2026',
                  isLatest: false,
                  changes: [
                    _ChangelogGroup(
                      title: '🌟 What\'s New',
                      items: [
                        'Keyboard-Aware Note Editor: Formatting tools now stay accessible directly above the soft keyboard, and the note editor auto-scrolls to keep your active typing line visible as you type long notes.',
                        'Full-Screen Setup Wizard: Customise your app theme, preferences, and local AI options right from the start.',
                      ],
                    ),
                    _ChangelogGroup(
                      title: '🚀 Improvements',
                      items: [
                        'Refreshed Material 3 Design: Enjoy modern rounded cards, fluid animations, dynamic typography scaling, and a cleaner control center.',
                        'Quick Keyboard Dismiss: Tap the new Hide Keyboard button on the note editor toolbar anytime to instantly dismiss the keyboard.',
                        'Smarter Search & Folders: Easily search across settings and notes, and organize your ideas into folders.',
                      ],
                    ),
                    _ChangelogGroup(
                      title: '🐛 Fixes',
                      items: [
                        'Note Editor Keyboard & Text Visibility: Resolved an issue where the software keyboard obscured long note text and hid formatting action bars during typing.',
                      ],
                    ),
                  ],
                ),
                _buildVersionSection(
                  context,
                  version: 'v2.11.0',
                  date: 'August 1, 2026',
                  isLatest: false,
                  changes: [
                    _ChangelogGroup(
                      title: '🌟 What\'s New',
                      items: [
                        'Full-Screen Setup Wizard: Customise your app theme, preferences, and local AI options right from the start.',
                      ],
                    ),
                    _ChangelogGroup(
                      title: '🚀 Improvements',
                      items: [
                        'Refreshed Material 3 Design: Enjoy modern rounded cards, fluid animations, and a cleaner control center.',
                        'Smarter Search & Folders: Easily search across settings and notes, and organize your ideas into folders.',
                      ],
                    ),
                    _ChangelogGroup(
                      title: '🐛 Fixes',
                      items: [
                        'Interactive Checklist Polish: Toggling checklist items in notes is now smoother and more reliable.',
                      ],
                    ),
                  ],
                ),
                _buildVersionSection(
                  context,
                  version: 'v2.10.0',
                  date: 'July 30, 2026',
                  isLatest: false,
                  changes: [
                    _ChangelogGroup(
                      title: '🌟 What\'s New',
                      items: [
                        'Full-Screen Setup Wizard: Customise your app theme, preferences, and local AI options right from the start.',
                      ],
                    ),
                    _ChangelogGroup(
                      title: '🚀 Improvements',
                      items: [
                        'Refreshed Material 3 Design: Enjoy modern rounded cards, fluid animations, and a cleaner control center.',
                        'Smarter Search & Folders: Easily search across settings and notes, and organize your ideas into folders.',
                      ],
                    ),
                    _ChangelogGroup(
                      title: '🐛 Fixes',
                      items: [
                        'Interactive Checklist Polish: Toggling checklist items in notes is now smoother and more reliable.',
                      ],
                    ),
                  ],
                ),
                _buildVersionSection(
                  context,
                  version: 'v2.9.1',
                  date: 'July 29, 2026',
                  isLatest: false,
                  changes: [
                    _ChangelogGroup(
                      title: '🚀 Improvements',
                      items: [
                        'Unified Frosted Glass Headers: Clean, symmetric top navigation bar across all app screens.',
                        'Single Action Button: Centralized action button floats comfortably above the bottom navigation bar.',
                        'Default Folder Memory: Automatically opens your preferred folder when starting the app.',
                      ],
                    ),
                    _ChangelogGroup(
                      title: '🐛 Fixes',
                      items: [
                        'Light Mode Visual Fixes: Removed double border lines and shadow artifacts for cleaner light mode viewing.',
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
                      title: '🌟 What\'s New',
                      items: [
                        'Material 3 Expressive Look: Dynamic color themes, rounded card hierarchy, and fluid spring animations.',
                        'Glassmorphic Navigation: Symmetric top and bottom frosted glass bars for immersive reading.',
                      ],
                    ),
                    _ChangelogGroup(
                      title: '🚀 Improvements',
                      items: [
                        'Tactile Button Feedback: Improved touch response and haptics across all buttons and menus.',
                        'Health Tracker Readability: High-contrast cards and illuminated cycle phase rings in dark mode.',
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
                      title: '🌟 What\'s New',
                      items: [
                        'Universal Spotlight Search: Search Notes, Settings, Tools, Finances, and Health in one single search bar.',
                        'Instant Filter Chips: Quickly filter search results by Notes, Finances, or Health with one tap.',
                      ],
                    ),
                    _ChangelogGroup(
                      title: '🐛 Fixes',
                      items: [
                        'Backup & Export Stability: Fixed file sharing fallbacks and prevented note title clipping on cards.',
                        'Handwriting Support: Smooth typing support for S-Pen and Apple Scribble.',
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
                      title: '🚀 Improvements',
                      items: [
                        'Instant Settings Search: Search options directly inside the Settings header bar.',
                        'Smarter Expense Analytics: Intelligent spending trend forecasting dampens one-off purchase spikes automatically.',
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
                      title: '🌟 What\'s New',
                      items: [
                        'Scheduled Auto-Sync: Schedule daily automatic bank SMS transaction imports at your chosen time.',
                      ],
                    ),
                    _ChangelogGroup(
                      title: '🚀 Improvements',
                      items: [
                        'Note Editor Enhancements: Auto-keyboard focus on new note creation and auto-dismiss on scroll.',
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
                height: changes.fold<double>(0.0, (acc, item) => acc + (item.items.length * 28.0) + 70.0),
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ],
          ),
          const SizedBox(width: AppLayout.spaceM),
          Expanded(
            child: AppCard(
              backgroundColor: isLatest
                  ? theme.colorScheme.primaryContainer.withValues(alpha: 0.15)
                  : theme.colorScheme.surfaceContainerLow,
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
                                          height: 1.35,
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
