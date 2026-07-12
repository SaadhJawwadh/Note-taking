import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// A prefilled starting point for a new note (title + Quill Delta JSON).
class NoteTemplate {
  final String name;
  final String description;
  final IconData icon;
  final String title;
  final String contentDeltaJson;

  const NoteTemplate({
    required this.name,
    required this.description,
    required this.icon,
    required this.title,
    required this.contentDeltaJson,
  });

  static List<NoteTemplate> all() {
    final today = DateFormat('EEE, d MMM').format(DateTime.now());
    return [
      NoteTemplate(
        name: 'Meeting Notes',
        description: 'Agenda, discussion, and action items',
        icon: Icons.groups_outlined,
        title: 'Meeting · $today',
        contentDeltaJson: jsonEncode([
          {'insert': 'Agenda'},
          {
            'insert': '\n',
            'attributes': {'header': 2}
          },
          {
            'insert': '\n',
            'attributes': {'list': 'bullet'}
          },
          {'insert': 'Discussion'},
          {
            'insert': '\n',
            'attributes': {'header': 2}
          },
          {'insert': '\n'},
          {'insert': 'Action Items'},
          {
            'insert': '\n',
            'attributes': {'header': 2}
          },
          {
            'insert': '\n',
            'attributes': {'list': 'unchecked'}
          },
        ]),
      ),
      NoteTemplate(
        name: 'Shopping List',
        description: 'A ready-to-tick checklist',
        icon: Icons.shopping_cart_outlined,
        title: 'Shopping List',
        contentDeltaJson: jsonEncode([
          {
            'insert': '\n',
            'attributes': {'list': 'unchecked'}
          },
          {
            'insert': '\n',
            'attributes': {'list': 'unchecked'}
          },
          {
            'insert': '\n',
            'attributes': {'list': 'unchecked'}
          },
        ]),
      ),
      NoteTemplate(
        name: 'Journal',
        description: 'Daily reflection prompts',
        icon: Icons.auto_stories_outlined,
        title: 'Journal · $today',
        contentDeltaJson: jsonEncode([
          {'insert': 'How was today?'},
          {
            'insert': '\n',
            'attributes': {'header': 2}
          },
          {'insert': '\n'},
          {'insert': 'Grateful for'},
          {
            'insert': '\n',
            'attributes': {'header': 2}
          },
          {
            'insert': '\n',
            'attributes': {'list': 'bullet'}
          },
        ]),
      ),
    ];
  }
}
