import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart' show DateFormat, NumberFormat;

class AppLocalizations {
  const AppLocalizations(this.locale);

  final Locale locale;

  static const supportedLocales = <Locale>[Locale('en'), Locale('ar')];

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  TextDirection get textDirection {
    return locale.languageCode == 'ar' ? TextDirection.rtl : TextDirection.ltr;
  }

  String t(String key) {
    return _values[locale.languageCode]?[key] ?? _values['en']![key] ?? key;
  }

  String date(DateTime value) {
    return DateFormat.yMMMd(locale.languageCode).format(value);
  }

  String month(DateTime value) {
    return DateFormat.yMMMM(locale.languageCode).format(value);
  }

  String number(num value) {
    return NumberFormat.decimalPattern(locale.languageCode).format(value);
  }
}

extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return AppLocalizations.supportedLocales
        .map((supported) => supported.languageCode)
        .contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(AppLocalizations(locale));
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

const Map<String, Map<String, String>> _values = <String, Map<String, String>>{
  'en': <String, String>{
    'appTitle': 'Gym Notebook',
    'chooseLanguage': 'Choose your language',
    'displayNameOptional': 'Display name (optional)',
    'continue': 'Continue',
    'english': 'English',
    'arabic': 'Arabic',
    'home': 'Home',
    'program': 'Program',
    'workout': 'Workout',
    'progress': 'Progress',
    'settings': 'Settings',
    'today': 'Today',
    'createProgram': 'Create Program',
    'createFirstProgram':
        'Create your first workout program to start tracking progress.',
    'noProgram': 'No active program',
    'programName': 'Program name',
    'trainingDays': 'Training days',
    'selectTrainingDays': 'Select training days',
    'atLeastOneDay': 'Select at least one day.',
    'nameRequired': 'Enter a valid name.',
    'save': 'Save',
    'cancel': 'Cancel',
    'edit': 'Edit',
    'delete': 'Delete',
    'archive': 'Archive',
    'archiveProgram': 'Archive program',
    'archiveProgramConfirm':
        'Archive this program? Workout history will remain available.',
    'currentProgram': 'Current program',
    'workoutDays': 'Workout days',
    'addWorkoutDay': 'Add Workout Day',
    'workoutDayName': 'Workout day name',
    'weekDay': 'Week day',
    'noExercises': 'Add exercises to this workout day.',
    'exercises': 'Exercises',
    'addExercise': 'Add Exercise',
    'exerciseName': 'Exercise name',
    'exerciseType': 'Exercise type',
    'weighted': 'Weighted',
    'repsOnly': 'Reps-only',
    'targetMuscle': 'Target muscle',
    'defaultSets': 'Default sets',
    'optional': 'Optional',
    'startWorkout': 'Start Workout',
    'chooseWorkout': 'Choose a workout day',
    'noWorkoutToday': 'No scheduled workout today.',
    'workoutInProgress': 'Workout in progress',
    'continueWorkout': 'Continue',
    'discard': 'Discard',
    'discardWorkoutConfirm':
        'Discard this in-progress workout? Completed history will not be affected.',
    'finishLater': 'Finish later',
    'previous': 'Previous',
    'best': 'Best',
    'todaySets': 'Today',
    'noPreviousData': 'No previous data yet.',
    'startFirstLog': 'Start your first log.',
    'addSet': 'Add Set',
    'set': 'Set',
    'reps': 'Reps',
    'completed': 'Completed',
    'finishWorkout': 'Finish Workout',
    'emptyWorkoutWarning': 'Log at least one completed set before finishing.',
    'workoutSummary': 'Workout Summary',
    'completedSets': 'Completed sets',
    'newBests': 'New bests',
    'done': 'Done',
    'noProgress': 'Complete your first workout to see progress.',
    'bests': 'Bests',
    'recentWorkouts': 'Recent workouts',
    'history': 'History',
    'noHistory': 'No history yet.',
    'privacyNote': 'Your workout data is stored locally on this device.',
    'language': 'Language',
    'displayName': 'Display name',
    'kg': 'kg',
    'confirmDelete': 'Confirm delete',
    'deleteExerciseConfirm':
        'Delete this exercise from the program? Past workout history will remain.',
    'deleteDayConfirm':
        'Delete this workout day? Past workout history will remain.',
    'yesDelete': 'Delete',
    'moveUp': 'Move up',
    'moveDown': 'Move down',
    'editProgram': 'Edit Program',
    'editWorkoutDay': 'Edit Workout Day',
    'editExercise': 'Edit Exercise',
    'exerciseSaved': 'Exercise saved',
    'programSaved': 'Program saved',
    'addAtLeastOneExercise': 'Add at least one exercise before starting.',
    'chest': 'Chest',
    'back': 'Back',
    'legs': 'Legs',
    'shoulders': 'Shoulders',
    'arms': 'Arms',
    'biceps': 'Biceps',
    'triceps': 'Triceps',
    'forearms': 'Forearms',
    'quads': 'Quads',
    'hamstrings': 'Hamstrings',
    'glutes': 'Glutes',
    'calves': 'Calves',
    'core': 'Core',
    'fullBody': 'Full body',
    'unknownError': 'Something went wrong.',
    'lb': 'lb',
    'weight': 'Weight',
    'weightUnit': 'Weight unit',
    'archivedPrograms': 'Archived programs',
    'restore': 'Restore',
    'editSession': 'Edit session',
    'saved': 'Saved',
    'workoutDayNotFound': 'Workout day was not found.',
    'sessionNotFound': 'Workout session was not found.',
    'hi': 'Hi',
    'setsCountHint':
        'Only the number of sets is planned here. You record the actual weight and reps during the workout.',
    'monthlyReport': 'Monthly report',
    'noWorkoutsThisMonth': 'No workouts this month.',
    'workoutsCount': 'Workouts',
    'highestWeight': 'Highest weight',
    'bestReps': 'Best reps',
    'lastAchieved': 'Last achieved',
    'reminders': 'Workout reminders',
    'remindersHint':
        'Get a daily notification on your training days. On some phones (e.g. Xiaomi) you must allow notifications and autostart for the app.',
    'reminderTime': 'Reminder time',
    'weeklySchedule': 'Weekly schedule',
    'restDay': 'Rest day',
    'progressChart': 'Top weight over time',
    'noPlanYet': 'No targets set',
  },
  'ar': <String, String>{
    'appTitle': 'دفتر التمرين',
    'chooseLanguage': 'اختر اللغة',
    'displayNameOptional': 'اسم العرض (اختياري)',
    'continue': 'متابعة',
    'english': 'الإنجليزية',
    'arabic': 'العربية',
    'home': 'الرئيسية',
    'program': 'البرنامج',
    'workout': 'التمرين',
    'progress': 'التقدم',
    'settings': 'الإعدادات',
    'today': 'اليوم',
    'createProgram': 'إنشاء برنامج',
    'createFirstProgram': 'أنشئ برنامجك التدريبي الأول لتبدأ بتسجيل تقدمك.',
    'noProgram': 'لا يوجد برنامج نشط',
    'programName': 'اسم البرنامج',
    'trainingDays': 'أيام التمرين',
    'selectTrainingDays': 'اختر أيام التمرين',
    'atLeastOneDay': 'اختر يوماً واحداً على الأقل.',
    'nameRequired': 'أدخل اسماً صالحاً.',
    'save': 'حفظ',
    'cancel': 'إلغاء',
    'edit': 'تعديل',
    'delete': 'حذف',
    'archive': 'أرشفة',
    'archiveProgram': 'أرشفة البرنامج',
    'archiveProgramConfirm':
        'هل تريد أرشفة هذا البرنامج؟ سيبقى سجل التمارين متاحاً.',
    'currentProgram': 'البرنامج الحالي',
    'workoutDays': 'أيام التمرين',
    'addWorkoutDay': 'إضافة يوم تمرين',
    'workoutDayName': 'اسم يوم التمرين',
    'weekDay': 'اليوم',
    'noExercises': 'أضف تمارين إلى هذا اليوم.',
    'exercises': 'التمارين',
    'addExercise': 'إضافة تمرين',
    'exerciseName': 'اسم التمرين',
    'exerciseType': 'نوع التمرين',
    'weighted': 'بأوزان',
    'repsOnly': 'عدات فقط',
    'targetMuscle': 'العضلة المستهدفة',
    'defaultSets': 'عدد الدفعات',
    'optional': 'اختياري',
    'startWorkout': 'بدء التمرين',
    'chooseWorkout': 'اختر يوم تمرين',
    'noWorkoutToday': 'لا يوجد تمرين مجدول اليوم.',
    'workoutInProgress': 'تمرين قيد التنفيذ',
    'continueWorkout': 'متابعة',
    'discard': 'تجاهل',
    'discardWorkoutConfirm':
        'هل تريد تجاهل هذا التمرين الجاري؟ لن يتأثر السجل المكتمل.',
    'finishLater': 'لاحقاً',
    'previous': 'السابق',
    'best': 'الأفضل',
    'todaySets': 'اليوم',
    'noPreviousData': 'لا توجد بيانات سابقة بعد.',
    'startFirstLog': 'ابدأ أول تسجيل.',
    'addSet': 'إضافة دفعة',
    'set': 'دفعة',
    'reps': 'العدات',
    'completed': 'مكتملة',
    'finishWorkout': 'إنهاء التمرين',
    'emptyWorkoutWarning': 'سجل دفعة مكتملة واحدة على الأقل قبل الإنهاء.',
    'workoutSummary': 'ملخص التمرين',
    'completedSets': 'الدفعات المكتملة',
    'newBests': 'أرقام جديدة',
    'done': 'تم',
    'noProgress': 'أكمل أول تمرين لعرض التقدم.',
    'bests': 'الأفضل',
    'recentWorkouts': 'آخر التمارين',
    'history': 'السجل',
    'noHistory': 'لا يوجد سجل بعد.',
    'privacyNote': 'يتم حفظ بيانات التمرين محلياً على هذا الجهاز.',
    'language': 'اللغة',
    'displayName': 'اسم العرض',
    'kg': 'كجم',
    'confirmDelete': 'تأكيد الحذف',
    'deleteExerciseConfirm':
        'حذف هذا التمرين من البرنامج؟ سيبقى سجل التمارين السابق.',
    'deleteDayConfirm': 'حذف يوم التمرين؟ سيبقى سجل التمارين السابق.',
    'yesDelete': 'حذف',
    'moveUp': 'تحريك للأعلى',
    'moveDown': 'تحريك للأسفل',
    'editProgram': 'تعديل البرنامج',
    'editWorkoutDay': 'تعديل يوم التمرين',
    'editExercise': 'تعديل التمرين',
    'exerciseSaved': 'تم حفظ التمرين',
    'programSaved': 'تم حفظ البرنامج',
    'addAtLeastOneExercise': 'أضف تمريناً واحداً على الأقل قبل البدء.',
    'chest': 'الصدر',
    'back': 'الظهر',
    'legs': 'الأرجل',
    'shoulders': 'الأكتاف',
    'arms': 'الذراعان',
    'biceps': 'باي',
    'triceps': 'تراي',
    'forearms': 'الساعد',
    'quads': 'الفخذ الأمامي',
    'hamstrings': 'الفخذ الخلفي',
    'glutes': 'الأرداف',
    'calves': 'السمانة',
    'core': 'البطن',
    'fullBody': 'الجسم كامل',
    'unknownError': 'حدث خطأ.',
    'lb': 'رطل',
    'weight': 'الوزن',
    'weightUnit': 'وحدة الوزن',
    'archivedPrograms': 'البرامج المؤرشفة',
    'restore': 'استعادة',
    'editSession': 'تعديل الجلسة',
    'saved': 'تم الحفظ',
    'workoutDayNotFound': 'لم يتم العثور على يوم التمرين.',
    'sessionNotFound': 'لم يتم العثور على جلسة التمرين.',
    'hi': 'أهلاً',
    'setsCountHint':
        'هون بتحدد عدد الدفعات فقط. الوزن والعدّات الفعلية بتسجّلها أثناء التمرين.',
    'monthlyReport': 'التقرير الشهري',
    'noWorkoutsThisMonth': 'لا يوجد تمارين هذا الشهر.',
    'workoutsCount': 'عدد التمارين',
    'highestWeight': 'أعلى وزن',
    'bestReps': 'أفضل عدّات',
    'lastAchieved': 'آخر مرة',
    'reminders': 'تذكير التمرين',
    'remindersHint':
        'إشعار يومي بأيام تمرينك. على بعض الأجهزة (مثل شاومي) لازم تسمح بالإشعارات والتشغيل التلقائي للتطبيق.',
    'reminderTime': 'وقت التذكير',
    'weeklySchedule': 'الجدول الأسبوعي',
    'restDay': 'يوم راحة',
    'progressChart': 'أعلى وزن عبر الوقت',
    'noPlanYet': 'ما في أهداف محددة',
  },
};
