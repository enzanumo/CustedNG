import 'dart:convert';

import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';
import 'package:collection/collection.dart';
import 'package:custed2/core/user/cust_user.dart';
import 'package:custed2/core/user/user.dart';
import 'package:custed2/core/utils.dart';
import 'package:custed2/data/models/grade.dart';
import 'package:custed2/data/models/grade_detail.dart';
import 'package:custed2/data/models/grade_term.dart';
import 'package:custed2/data/models/jw_grade_data.dart';
import 'package:custed2/data/models/jw_schedule.dart';
import 'package:custed2/data/models/kbpro_schedule.dart';
import 'package:custed2/data/models/schedule.dart';
import 'package:custed2/data/models/schedule_lesson.dart';
import 'package:custed2/data/providers/app_provider.dart';
import 'package:custed2/locator.dart';
import 'package:custed2/res/build_data.dart';
import 'package:custed2/service/jw_service.dart';
import 'package:flutter/foundation.dart';

class UndergraduateUser with CustUser implements User {
  final _jw = locator<JwService>();

  @override
  Future<Schedule> getSchedule() async {
    if (locator<AppProvider>().useKBPro) {
      final raw = await _jw.getSelfScheduleFromKBPro();
      return normalizeScheduleKBPro(raw);
    }
    final rawSchedule = await _jw.getSchedule();
    return normalizeSchedule(rawSchedule);
  }

  @override
  Future<Grade> getGrade() async {
    final rawGrade = await _jw.getGrade();
    return normalizeGrade(rawGrade);
  }

  static Future<Schedule> getScheduleByStudentUUID(String uuid) async {
    final jwService = locator<JwService>();
    final rawSchedule = await jwService.getSchedule(uuid);
    return normalizeSchedule(rawSchedule);
  }

  static Future<Schedule> normalizeScheduleKBPro(
      List<KBProSchedule> raw) async {
    final result = Schedule()
      ..createdAt = DateTime.now()
      ..versionHash = await computeJsonHashAsync(raw)
      ..startDate = getScheduleStartTime()
      ..lessons = [];

    for (var rawLesson in raw) {
      final lesson = ScheduleLesson()
        ..weeks = rawLesson.sKZC.parseWeeks(rawLesson.sKZCTYPE)
        ..name = rawLesson.kCMC
        ..classes = [rawLesson.jXBMC]
        ..startTime = rawLesson.kSJC.startTime
        ..endTime = rawLesson.jSJC.endTime
        ..type = ScheduleLessonType.general
        ..weekday = int.parse(rawLesson.wEEK)
        ..classRaw = rawLesson.jXBMC
        ..startSection = int.parse(rawLesson.kSJC)
        ..endSection = int.parse(rawLesson.jSJC)
        ..roomRaw = rawLesson.jSMC
        ..teacherName = rawLesson.jSXM
        ..classRaw = rawLesson.jXBMC;

      result.lessons.add(lesson);
    }

    for (var idx1 = 0; idx1 < result.lessons.length - 1; idx1++) {
      for (var idx2 = idx1 + 1; idx2 < result.lessons.length; idx2++) {
        final l1 = result.lessons[idx1];
        final l2 = result.lessons[idx2];
        if (l1.name == l2.name &&
            listEq(l1.weeks, l2.weeks) &&
            l1.startSection == l2.startSection &&
            l1.endSection == l2.endSection &&
            l1.roomRaw == l2.roomRaw &&
            l1.weekday == l2.weekday) {
          result.lessons[idx1].teacherName += ' ${l2.teacherName}';
          result.lessons.removeAt(idx2);
        }
      }
    }

    return result;
  }

  static Future<Schedule> normalizeSchedule(JwSchedule raw) async {
    final result = Schedule()
      ..createdAt = DateTime.now()
      ..versionHash = await computeJsonHashAsync(raw)
      ..startDate = getScheduleStartTime()
      ..lessons = [];

    for (var day in raw.AdjustDays) {
      for (var section in day.allSections()) {
        for (var rawLesson in section.Dtos) {
          final lesson = ScheduleLesson()
            ..weeks = rawLesson.parseWeeks()
            ..name = rawLesson.getName()
            ..classes = rawLesson?.Classs?.map((c) => c.Name)?.toList()
            ..startTime = section.StartTime
            ..endTime = section.EndTime
            ..type = ScheduleLessonType.general
            ..weekday = day.WIndex
            ..classRaw = ''
            ..startSection = section.StartSection
            ..endSection = section.EndSection
            ..roomRaw = rawLesson.getRoom()
            ..teacherName = rawLesson.getTeacher()
            ..classRaw = rawLesson.LessonObjName;
          result.lessons.add(lesson);
        }
      }
    }

    if (result.lessons.isEmpty) {
      showSnackBar(locator<AppProvider>().ctx, '当前课表为空，若不正常\n请在设置页面开启新数据源');
    }

    return result;
  }

  static bool isElectiveCourse(GradeDetail grade) {
    return grade.lessonType != '选修';
  }

  static Future<Grade> normalizeGrade(JwGradeData raw) async {
    final termSet = raw.GradeList.map((e) => e.KSXNXQ).toSet();
    final terms = termSet.map((term) {
      final grades = <GradeDetail>[];
      final rawGrades = raw.GradeList.where((g) => g.KSXNXQ == term);
      final effectiveGrades = <String, GradeDetail>{};

      for (var rawGrade in rawGrades) {
        final grade = GradeDetail()
          ..year = rawGrade.KSXNXQ
          ..testStatus = rawGrade.KSZT
          ..lessonType = rawGrade.KCXZ
          ..schoolHour = rawGrade.XS
          ..credit = rawGrade.XF
          ..mark = rawGrade.YXCJ ?? 0
          ..rawMark = rawGrade.ShowYXCJ
          ..lessonName = rawGrade.LessonInfo.KCMC
          ..testType = rawGrade.KSXZ
          ..lessonCategory = rawGrade.LessonClass.FLMC;

        final key = '${grade.year}:'
            '${grade.lessonName}:'
            '${grade.lessonType}:'
            '${grade.lessonCategory}'
            '${grade.credit}:'
            '${grade.schoolHour}';

        final shouldOverride = effectiveGrades[key] == null ||
            effectiveGrades[key].mark == null ||
            effectiveGrades[key].mark < (grade.mark ?? 0.0);

        if (shouldOverride) {
          effectiveGrades[key] = grade;
        }

        grades.add(grade);
      }

      double weightedGradePointSum = 0.0;
      double creditTotal = 0.0;
      double creditEarned = 0.0;
      int subjectCount = 0;
      int subjectPassed = 0;

      double weightedGradePointSumNoElectiveCourse = 0.0;
      double creditTotalNoElectiveCourse = 0.0;

      for (var grade in effectiveGrades.values) {
        final passed = grade.testStatus == '正常' && grade.mark >= 60;
        final gradePoint = markToGradePoint(grade.mark);
        creditTotal += grade.credit;
        subjectCount += 1;
        if (passed) {
          creditEarned += grade.credit;
          subjectPassed += 1;
        }
        weightedGradePointSum += gradePoint * grade.credit;

        if (isElectiveCourse(grade)) {
          weightedGradePointSumNoElectiveCourse += gradePoint * grade.credit;
          creditTotalNoElectiveCourse += grade.credit;
        }
      }

      final averageGradePoint = weightedGradePointSum / creditTotal;
      final averageGradePointNoElectiveCourse =
          weightedGradePointSumNoElectiveCourse / creditTotalNoElectiveCourse;
      return GradeTerm()
        ..averageGradePoint = averageGradePoint
        ..averageGradePointNoElectiveCourse = averageGradePointNoElectiveCourse
        ..creditTotal = creditTotal
        ..creditEarned = creditEarned
        ..subjectCount = subjectCount
        ..subjectPassed = subjectPassed
        ..grades = grades
        ..termName = term;
    }).toList();

    terms.sort((t1, t2) => t1.termName.compareTo(t2.termName));

    final result = Grade()
      ..createdAt = DateTime.now()
      ..versionHash = await computeJsonHashAsync(raw)
      ..averageGradePoint = raw.GradeStatistics.PJJD
      ..creditEarned = raw.GradeStatistics.SDXF
      ..creditUnattained = raw.GradeStatistics.WTGXF
      ..subjectCount = raw.GradeStatistics.SXMS
      ..subjectPassed = raw.GradeStatistics.TGMS
      ..subjectNotPassed = raw.GradeStatistics.WTGMS
      ..resitCount = raw.GradeStatistics.BKCS
      ..retakeCount = raw.GradeStatistics.CXCS
      ..terms = terms;

    if (result.terms.last.grades.last.rawMark == '未评教') {
      showSnackBar(locator<AppProvider>().ctx, '当前未评教\n未评教无法正常显示成绩');
    }

    return result;
  }

  static double markToGradePoint(double mark) {
    return mark >= 60 ? (mark - 50) / 10 : 0;
  }

  static String computeJsonHash(dynamic raw) {
    final hash = sha1.convert(utf8.encode(json.encode(raw))).bytes;
    return 'b${BuildData.build}/' + hex.encode(hash);
  }

  static Future<String> computeJsonHashAsync(dynamic raw) {
    return compute(computeJsonHash, raw);
  }

  static DateTime getScheduleStartTime() {
    // This is hardcoded, don't forget to update this :)
    final table = {
      '20201': DateTime(2020, 2, 24),
      '20202': DateTime(2020, 8, 31),
      '20211': DateTime(2021, 3, 1),
      '20212': DateTime(2021, 8, 30),
      '20221': DateTime(2022, 2, 28),
    };

    final year = DateTime.now().year.toString();
    final nth = DateTime.now().month >= 8 ? 2 : 1;

    return table['$year$nth'] ?? table.values.last;
  }
}

class SectionTime {
  String startTime;
  String endTime;

  SectionTime(this.startTime, this.endTime);
}

extension Section2Time on String {
  String get startTime {
    switch (this) {
      case '01':
        return '8:00';
      case '02':
        return '8:50';
      case '03':
        return '10:05';
      case '04':
        return '10:50';
      case '05':
        return '13:30';
      case '06':
        return '14:20';
      case '07':
        return '15:35';
      case '08':
        return '16:25';
      case '09':
        return '18:00';
      case '10':
        return '18:50';
      case '11':
        return '19:45';
      case '12':
        return '20:35';
      default:
        return '';
    }
  }

  String get endTime {
    switch (this) {
      case '01':
        return '8:45';
      case '02':
        return '9:35';
      case '03':
        return '10:50';
      case '04':
        return '11:40';
      case '05':
        return '14:15';
      case '06':
        return '15:05';
      case '07':
        return '16:20';
      case '08':
        return '17:10';
      case '09':
        return '18:45';
      case '10':
        return '19:35';
      case '11':
        return '20:25';
      case '12':
        return '21:20';
      default:
        return '';
    }
  }

  List<int> parseWeeks(String type) {
    if (this.length == 2) {
      return [int.parse(this)];
    }
    List<int> weeks = [];
    for (var i = 0; i < this.length; i++) {
      if (this[i] == '1') {
        weeks.add(i + 1);
      }
    }
    if (type == '1') {
      weeks.removeWhere((ele) => ele % 2 == 0);
    }
    if (type == '2') {
      weeks.removeWhere((ele) => ele % 2 == 1);
    }
    return weeks;
  }
}

Function listEq = const ListEquality().equals;
