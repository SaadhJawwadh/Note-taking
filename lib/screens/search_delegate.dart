import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:intl/intl.dart';
import '../data/database_helper.dart';
import '../data/note_model.dart';
import '../data/transaction_model.dart';
import '../data/period_log_model.dart';
import 'home_screen.dart'; // For NoteCard
import 'note_editor_screen.dart';
import 'transaction_editor_screen.dart';
import 'period_tracker_screen.dart'; // We can use this or a specific detail view

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

  Widget _buildSearchResults(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: Future.wait([
        DatabaseHelper.instance.searchNotes(query),
        DatabaseHelper.instance.searchTransactions(query),
        DatabaseHelper.instance.searchPeriodLogs(query),
        DatabaseHelper.instance.getAllTagColors(),
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

        if (notes.isEmpty && transactions.isEmpty && periodLogs.isEmpty) {
          return const Center(child: Text("No results found"));
        }

        return ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
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
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => NoteEditorScreen(note: notes[index]),
                        ),
                      );
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
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: theme.colorScheme.surfaceContainerLow,
      child: ListTile(
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
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TransactionEditorScreen(transaction: t),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPeriodLogResult(BuildContext context, PeriodLog log) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: theme.colorScheme.surfaceContainerLow,
      child: ListTile(
        title: Text("Period Log: ${log.intensity}"),
        subtitle: Text(
          "Started: ${DateFormat.yMMMd().format(log.startDate)}${log.notes.isNotEmpty ? '\n${log.notes}' : ''}",
        ),
        isThreeLine: log.notes.isNotEmpty,
        onTap: () {
          // Navigating to the tracker screen for context
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const PeriodTrackerScreen(),
            ),
          );
        },
      ),
    );
  }
}
