import 'package:flutter/material.dart';

const Color primaryColor = Color(0xFF4A90E2);
const Color secondaryColor = Color(0xFF8E9AAF);
const Color favoriteColor = Color(0xFFEC4899);

Color getPrimaryColor(bool isDarkMode) {
  return isDarkMode ? Color(0xFF8E9AAF) : Color(0xFF4A90E2);
}

final Map<int, String> reverseRoundMapping = {
  1: '2022년 4월',
  2: '2022년 3월',
  3: '2021년 8월',
  4: '2021년 5월',
  5: '2021년 3월',
  6: '2020년 9월',
  7: '2020년 8월',
  8: '2020년 6월',
  9: '2019년 8월',
  10: '2019년 4월',
  11: '2019년 3월',
  12: '2018년 8월',
  13: '2018년 4월',
  14: '2018년 3월',
  15: '2017년 8월',
  16: '2017년 5월',
  17: '2016년 8월',
  18: '2016년 5월',
  19: '2016년 3월',
};


String examSessionToRoundName(dynamic examVal) {
  int? intVal = (examVal is int) ? examVal : int.tryParse(examVal.toString());
  return reverseRoundMapping[intVal] ?? '기타';
}


final List<String> categories = [
  '안전관리론',
  '인간공학 및 시스템안전공학',
  '기계위험방지기술',
  '전기위험방지기술',
  '화학설비위험방지기술',
  '건설안전기술'
];