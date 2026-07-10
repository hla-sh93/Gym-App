import 'package:flutter/widgets.dart';

const List<int> weekDayValues = <int>[0, 1, 2, 3, 4, 5, 6];

int currentAppWeekDay(DateTime date) {
  return date.weekday == DateTime.sunday ? 0 : date.weekday;
}

String weekDayName(int weekDay, Locale locale) {
  final isArabic = locale.languageCode == 'ar';
  return switch (weekDay) {
    0 => isArabic ? 'الأحد' : 'Sunday',
    1 => isArabic ? 'الإثنين' : 'Monday',
    2 => isArabic ? 'الثلاثاء' : 'Tuesday',
    3 => isArabic ? 'الأربعاء' : 'Wednesday',
    4 => isArabic ? 'الخميس' : 'Thursday',
    5 => isArabic ? 'الجمعة' : 'Friday',
    6 => isArabic ? 'السبت' : 'Saturday',
    _ => isArabic ? 'اليوم' : 'Day',
  };
}
