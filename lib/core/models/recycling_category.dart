import 'package:flutter/material.dart';

class RecyclingCategory {
  final String id;
  final String name;
  final String imageAsset;
  final Color color;
  final Color lightColor;
  final String description;
  final List<String> whatGoesIn;
  final List<String> whatStaysOut;
  final List<String> preparationTips;
  final String funFact;
  final String recycleSymbol;

  const RecyclingCategory({
    required this.id,
    required this.name,
    required this.imageAsset,
    required this.color,
    required this.lightColor,
    required this.description,
    required this.whatGoesIn,
    required this.whatStaysOut,
    required this.preparationTips,
    required this.funFact,
    required this.recycleSymbol,
  });
}
