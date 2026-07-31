import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/note_provider.dart';
import 'package:flutter/services.dart';
import '../core/ui/app_chip.dart';

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
          height: 40,
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: allTags.length,
            itemBuilder: (context, index) {
              final tag = allTags[index];
              final isSelected = tag == selectedTag;
              final tagColorValue = tagColors[tag];
              final chipColors = AppChip.getTagColors(context, tagColorValue, isSelected: isSelected);

              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: GestureDetector(
                  onLongPress: () {
                    HapticFeedback.mediumImpact();
                    onTagLongPress(tag);
                  },
                  child: AppChip(
                    label: (noteProvider.tagCounts[tag] ?? 0) > 0
                        ? '$tag · ${noteProvider.tagCounts[tag]}'
                        : tag,
                    isSelected: isSelected,
                    isCompact: true,
                    backgroundColor: chipColors.bg,
                    selectedBackgroundColor: chipColors.bg,
                    textColor: chipColors.fg,
                    border: chipColors.border,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      noteProvider.setTag(tag);
                    },
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
