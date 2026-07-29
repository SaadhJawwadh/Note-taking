import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:intl/intl.dart';
import '../data/repositories/note_repository.dart';
import '../data/repositories/transaction_repository.dart';
import '../data/repositories/period_repository.dart';
import '../data/note_model.dart';
import '../data/transaction_model.dart';
import '../data/period_log_model.dart';
import 'home_screen.dart'; // For NoteCard
import 'note_editor_screen.dart';
import 'transaction_editor_screen.dart';
import 'period_tracker_screen.dart';
import 'category_management_screen.dart';
import 'sms_contacts_screen.dart';
import 'sms_rules_screen.dart';
import 'manage_tags_screen.dart';
import 'filtered_notes_screen.dart';
import 'settings_screen.dart';
import '../widgets/recurring_rules_sheet.dart';
import '../services/backup_service.dart';

import '../data/transaction_category.dart';
import '../utils/app_route.dart';
import '../theme/app_layout.dart';

class _SettingsSearchResult {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<String> keywords;
  final VoidCallback onTap;

  const _SettingsSearchResult({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.keywords,
    required this.onTap,
  });
}

class GlobalSearchDelegate extends SearchDelegate {
  @override
  String get searchFieldLabel => 'Search notes, finance, health...';

  @override
  ThemeData appBarTheme(BuildContext context) {
    final theme = Theme.of(context);
    return theme.copyWith(
      appBarTheme: theme.appBarTheme.copyWith(
        backgroundColor: theme.colorScheme.surfaceContainerHighest,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: InputBorder.none,
      ),
    );
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () => query = '',
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    if (query.trim().isEmpty) {
      return const Center(child: Text("Type something to search"));
    }
    return _buildSearchResults(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.trim().isEmpty) {
      return const Center(child: Text("Search across all modules..."));
    }
    return _buildSearchResults(context);
  }

  List<_SettingsSearchResult> _searchSettings(BuildContext context, String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return [];

    final allItems = <_SettingsSearchResult>[
      _SettingsSearchResult(
        title: 'App Lock & Security',
        subtitle: 'Configure PIN & biometric protection',
        icon: Icons.lock_outlined,
        keywords: ['app lock', 'security', 'pin', 'biometrics', 'password', 'timeout', 'lock'],
        onTap: () => AppRoute.push(context, const SettingsScreen()),
      ),
      _SettingsSearchResult(
        title: 'Manage Categories',
        subtitle: 'Customise transaction categories & keywords',
        icon: Icons.category_outlined,
        keywords: ['category', 'categories', 'manage categories', 'icons', 'keywords', 'ledger'],
        onTap: () => AppRoute.push(context, const CategoryManagementScreen()),
      ),
      _SettingsSearchResult(
        title: 'SMS Contacts',
        subtitle: 'Manage recognized bank senders for auto-import',
        icon: Icons.contacts_outlined,
        keywords: ['sms contacts', 'contacts', 'senders', 'bank', 'phone'],
        onTap: () => AppRoute.push(context, const SmsContactsScreen()),
      ),
      _SettingsSearchResult(
        title: 'Recurring Transactions',
        subtitle: 'Manage automatically repeating ledger entries',
        icon: Icons.event_repeat_outlined,
        keywords: ['recurring', 'rules', 'repeating', 'subscription', 'auto transaction'],
        onTap: () => showModalBottomSheet(context: context, isScrollControlled: true, showDragHandle: true, builder: (_) => const RecurringRulesSheet()),
      ),
      _SettingsSearchResult(
        title: 'SMS Import Rules',
        subtitle: 'Auto-categorization & transaction type rules',
        icon: Icons.rule_folder_outlined,
        keywords: ['sms rules', 'auto categorize', 'income rules', 'expense rules'],
        onTap: () => AppRoute.push(context, const SmsRulesScreen()),
      ),
      _SettingsSearchResult(
        title: 'Import Transactions (CSV)',
        subtitle: 'Import transaction records from CSV file',
        icon: Icons.file_upload_outlined,
        keywords: ['import csv', 'csv', 'import transactions', 'excel', 'ledger csv'],
        onTap: () => BackupService.importTransactionsFromCsv(context),
      ),
      _SettingsSearchResult(
        title: 'Export & Import Backup',
        subtitle: 'Save or restore all notes and settings to JSON file',
        icon: Icons.backup_outlined,
        keywords: ['backup', 'export backup', 'import backup', 'restore', 'json'],
        onTap: () => AppRoute.push(context, const SettingsScreen()),
      ),
      _SettingsSearchResult(
        title: 'Period Tracker',
        subtitle: 'Optional cycle tracking and symptom logs',
        icon: Icons.calendar_month_outlined,
        keywords: ['period', 'tracker', 'cycle', 'health', 'symptoms', 'ovulation', 'menstrual'],
        onTap: () => AppRoute.push(context, const PeriodTrackerScreen()),
      ),
      _SettingsSearchResult(
        title: 'Gemini Nano AI',
        subtitle: 'Enable offline summaries, tag suggestions & smart SMS parsing',
        icon: Icons.auto_awesome_outlined,
        keywords: ['ai', 'gemini', 'nano', 'summaries', 'tag suggestions', 'smart sms'],
        onTap: () => AppRoute.push(context, const SettingsScreen()),
      ),
      _SettingsSearchResult(
        title: 'Manage Tags',
        subtitle: 'View, edit, and organize all note tags',
        icon: Icons.label_outlined,
        keywords: ['tags', 'manage tags', 'labels', 'tag colors'],
        onTap: () => AppRoute.push(context, const ManageTagsScreen()),
      ),
      _SettingsSearchResult(
        title: 'Archive',
        subtitle: 'View archived notes',
        icon: Icons.archive_outlined,
        keywords: ['archive', 'archived', 'hidden notes'],
        onTap: () => AppRoute.push(context, const FilteredNotesScreen(filterType: FilterType.archived)),
      ),
      _SettingsSearchResult(
        title: 'Trash',
        subtitle: 'View deleted notes',
        icon: Icons.delete_outline,
        keywords: ['trash', 'deleted', 'restore deleted'],
        onTap: () => AppRoute.push(context, const FilteredNotesScreen(filterType: FilterType.trash)),
      ),
      _SettingsSearchResult(
        title: 'Currency',
        subtitle: 'Select currency symbol (LKR, USD, EUR, GBP...)',
        icon: Icons.currency_exchange_outlined,
        keywords: ['currency', 'symbol', 'usd', 'lkr', 'eur', 'gbp', 'money'],
        onTap: () => AppRoute.push(context, const SettingsScreen()),
      ),
      _SettingsSearchResult(
        title: 'SMS Auto-Sync',
        subtitle: 'Daily SMS background transaction import',
        icon: Icons.sync_outlined,
        keywords: ['auto sync', 'sms sync', 'daily sync', 'background sync'],
        onTap: () => AppRoute.push(context, const SettingsScreen()),
      ),
    ];

    return allItems.where((item) {
      return item.title.toLowerCase().contains(q) ||
          item.subtitle.toLowerCase().contains(q) ||
          item.keywords.any((k) => k.contains(q));
    }).toList();
  }

  Widget _buildSearchResults(BuildContext context) {
    final settingsResults = _searchSettings(context, query);

    return FutureBuilder<List<dynamic>>(
      future: Future.wait([
        NoteRepository.instance.searchNotes(query),
        TransactionRepository.instance.searchTransactions(query),
        PeriodRepository.instance.searchPeriodLogs(query),
        NoteRepository.instance.getAllTagColors(),
      ]),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }

        final notes = snapshot.data?[0] as List<Note>? ?? [];
        final transactions = snapshot.data?[1] as List<TransactionModel>? ?? [];
        final periodLogs = snapshot.data?[2] as List<PeriodLog>? ?? [];
        final tagColors = snapshot.data?[3] as Map<String, int>? ?? {};

        if (settingsResults.isEmpty && notes.isEmpty && transactions.isEmpty && periodLogs.isEmpty) {
          return const Center(child: Text("No results found"));
        }

        return ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            if (settingsResults.isNotEmpty) ...[
              _buildSectionHeader(context, "Settings & Tools", Icons.settings_outlined),
              const SizedBox(height: 8),
              ...settingsResults.map((s) => _buildSettingsResult(context, s)),
              const SizedBox(height: 24),
            ],
            if (notes.isNotEmpty) ...[
              _buildSectionHeader(context, "Notes", Icons.note_alt_outlined),
              const SizedBox(height: 8),
              MasonryGridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                itemCount: notes.length,
                itemBuilder: (context, index) {
                  return NoteCard(
                    note: notes[index],
                    tagColors: tagColors,
                    onTap: () {
                      AppRoute.push(context, NoteEditorScreen(note: notes[index]));
                    },
                  );
                },
              ),
              const SizedBox(height: 24),
            ],
            if (transactions.isNotEmpty) ...[
              _buildSectionHeader(context, "Financial Transactions", Icons.account_balance_wallet_outlined),
              const SizedBox(height: 8),
              ...transactions.map((t) => _buildTransactionResult(context, t)),
              const SizedBox(height: 24),
            ],
            if (periodLogs.isNotEmpty) ...[
              _buildSectionHeader(context, "Health Logs", Icons.health_and_safety_outlined),
              const SizedBox(height: 8),
              ...periodLogs.map((log) => _buildPeriodLogResult(context, log)),
            ],
          ],
        );
      },
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionResult(BuildContext context, TransactionModel t) {
    final theme = Theme.of(context);
    final catColor = TransactionCategory.colorFor(t.category);
    final catIcon = TransactionCategory.iconFor(t.category);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppLayout.radiusL),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
          width: 1.0,
        ),
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: catColor.withValues(alpha: 0.15),
            shape: BoxShape.circle,
            border: Border.all(
              color: catColor.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Icon(
            catIcon,
            color: catColor,
            size: 20,
          ),
        ),
        title: Text(t.description),
        subtitle: Text("${t.category} • ${DateFormat.yMMMd().format(t.date)}"),
        trailing: Text(
          "${t.isExpense ? '-' : '+'}${t.amount.toStringAsFixed(2)}",
          style: TextStyle(
            color: t.isExpense ? theme.colorScheme.error : Colors.green,
            fontWeight: FontWeight.bold,
          ),
        ),
        onTap: () {
          AppRoute.push(context, TransactionEditorScreen(transaction: t));
        },
      ),
    );
  }

  Widget _buildPeriodLogResult(BuildContext context, PeriodLog log) {
    final theme = Theme.of(context);
    final healthColor = theme.colorScheme.error;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppLayout.radiusL),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
          width: 1.0,
        ),
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: healthColor.withValues(alpha: 0.15),
            shape: BoxShape.circle,
            border: Border.all(
              color: healthColor.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Icon(
            Icons.water_drop_outlined,
            color: healthColor,
            size: 20,
          ),
        ),
        title: Text("Period Log: ${log.intensity}"),
        subtitle: Text(
          "Started: ${DateFormat.yMMMd().format(log.startDate)}${log.notes.isNotEmpty ? '\n${log.notes}' : ''}",
        ),
        isThreeLine: log.notes.isNotEmpty,
        onTap: () {
          AppRoute.push(context, const PeriodTrackerScreen());
        },
      ),
    );
  }

  Widget _buildSettingsResult(BuildContext context, _SettingsSearchResult s) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppLayout.radiusL),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
          width: 1.0,
        ),
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: primaryColor.withValues(alpha: 0.15),
            shape: BoxShape.circle,
            border: Border.all(
              color: primaryColor.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Icon(
            s.icon,
            color: primaryColor,
            size: 20,
          ),
        ),
        title: Text(s.title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(s.subtitle),
        trailing: Icon(Icons.arrow_forward_ios, size: 14, color: theme.colorScheme.onSurfaceVariant),
        onTap: () {
          s.onTap();
        },
      ),
    );
  }
}
