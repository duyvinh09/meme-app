import 'package:flutter/material.dart';

enum RewindStoryType {
  overview,
  categories,
  streak,
  topExpenses,
  biggestDay,
  moments,
  highlight,
  comparison,
  summary,
  empty,
}

class RewindStory {
  final String id;
  final RewindStoryType type;
  final Duration duration;
  final List<Color> backgroundGradient;

  const RewindStory({
    required this.id,
    required this.type,
    this.duration = const Duration(milliseconds: 5000),
    required this.backgroundGradient,
  });

  static const defaultGradient = [
    Color(0xFF0F172A),
    Color(0xFF020617),
  ];

  static const overviewGradient = [
    Color(0xFF1E1B4B),
    Color(0xFF0F172A),
    Color(0xFF090D16),
  ];

  static const categoryGradient = [
    Color(0xFF0C4A6E),
    Color(0xFF082F49),
    Color(0xFF030712),
  ];

  static const streakGradient = [
    Color(0xFF431407),
    Color(0xFF2E1065),
    Color(0xFF090D16),
  ];

  static const topExpensesGradient = [
    Color(0xFF3B0764),
    Color(0xFF1E1B4B),
    Color(0xFF090D16),
  ];

  static const biggestDayGradient = [
    Color(0xFF14532D),
    Color(0xFF064E3B),
    Color(0xFF022C22),
  ];

  static const momentsGradient = [
    Color(0xFF18181B),
    Color(0xFF09090B),
    Color(0xFF000000),
  ];

  static const highlightGradient = [
    Color(0xFF701A75),
    Color(0xFF4A044E),
    Color(0xFF18021A),
  ];

  static const comparisonGradient = [
    Color(0xFF172554),
    Color(0xFF1E1B4B),
    Color(0xFF020617),
  ];

  static const summaryGradient = [
    Color(0xFF312E81),
    Color(0xFF1E1B4B),
    Color(0xFF090D16),
  ];
}
