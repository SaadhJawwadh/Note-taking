import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/note_provider.dart';
import 'package:flutter/services.dart';

class TagFilterBar extends StatelessWidget {
  final Function(String) onTagLongPress;

  const TagFilterBar({super.key, required this.onTagLongPress});

  @override
  Widget build(BuildContext context) {
    return Consumer<NoteProvider>(
      builder: (context, noteProvider, child) {
        final allTags = noteProvider.allTags;
        final selectedTag = noteProvider.selectedTag;
        final tagColors = noteProvider.tagColors;

        return Container(
          height: 50,
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: allTags.length,
            itemBuilder: (context, index) {
              final tag = allTags[index];
              final isSelected = tag == selectedTag;
              final tagColorValue = tagColors[tag];

              Color? chipBg;
              Color? chipFg;
              BorderSide? chipSide;

              if (isSelected) {
                if (tagColorValue != null && tagColorValue != 0) {
                  final scheme = ColorScheme.fromSeed(
                      seedColor: Color(tagColorValue),
                      brightness: Theme.of(context).brightness);
                  chipBg = scheme.primary;
                  chipFg = scheme.onPrimary;
                } else {
                  chipBg = Theme.of(context).colorScheme.primary;
                  chipFg = Theme.of(context).colorScheme.onPrimary;
                }
                chipSide = BorderSide.none;
              } else {
                if (tagColorValue != null && tagColorValue != 0) {
                  final scheme = ColorScheme.fromSeed(
                      seedColor: Color(tagColorValue),
                      brightness: Theme.of(context).brightness);
                  chipBg = Colors.transparent;
                  chipFg = scheme.primary;
                  chipSide = BorderSide(color: scheme.primary);
                } else {
                  chipBg = Colors.transparent;
                  chipFg = Theme.of(context).colorScheme.onSurfaceVariant;
                  chipSide = BorderSide(
                    color: Theme.of(context).colorScheme.outline,
                  );
                }
              }

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onLongPress: () {
                    HapticFeedback.mediumImpact();
                    onTagLongPress(tag);
                  },
                  child: FilterChip(
                    label: Text(tag),
                    selected: isSelected,
                    onSelected: (selected) {
                      HapticFeedback.lightImpact();
                      if (selected) noteProvider.setTag(tag);
                    },
                    backgroundColor: chipBg,
                    selectedColor: chipBg,
                    labelStyle: TextStyle(
                      color: chipFg,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    side: chipSide,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    showCheckmark: false,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
