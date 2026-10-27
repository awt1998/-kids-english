import 'package:flutter/material.dart';
import 'package:kids_english/content/models.dart';

Word word(String id) => Word(id: id, en: id, ar: id);

Unit unit(String id, List<String> words) => Unit(
  id: id,
  titleAr: id,
  titleEn: id,
  icon: 'unit_$id',
  color: Colors.red,
  words: words.map(word).toList(),
);
