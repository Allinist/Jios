import 'dart:convert';

import 'rules/monthWeekRule.dart';
import 'rules/timeRange.dart';

class RepeatRule {

  int? id;

  String? repeatType;

  int? interval;

  List<int>? weekDays;

  List<int>? monthDays;

  List<MonthWeekRule>? monthWeeks;

  List<String>? yearDays;

  bool? workDays;

  List<TimeRange>? timeRanges;

  RepeatRule({

    this.id,

    this.repeatType,

    this.interval,

    this.weekDays,

    this.monthDays,

    this.monthWeeks,

    this.yearDays,

    this.workDays,

    this.timeRanges,

  });

  Map<String, dynamic> toMap() {

    return {

      "id": id,

      "repeat_type": repeatType,

      "interval": interval,

      "week_days": weekDays == null
          ? null
          : jsonEncode(weekDays),

      "month_days": monthDays == null
          ? null
          : jsonEncode(monthDays),

      "month_week": monthWeeks == null
          ? null
          : jsonEncode(
              monthWeeks!.map((e) => e.toMap()).toList()),

      "year_days": yearDays == null
          ? null
          : jsonEncode(yearDays),

      "work_days": workDays == null
          ? null
          : (workDays! ? 1 : 0),

      "time_ranges": timeRanges == null
          ? null
          : jsonEncode(
              timeRanges!.map((e) => e.toMap()).toList()),

    };

  }

  factory RepeatRule.fromMap(Map<String, dynamic> map) {

    return RepeatRule(

      id: map["id"],

      repeatType: map["repeat_type"],

      interval: map["interval"],

      weekDays: map["week_days"] == null
          ? null
          : List<int>.from(
              jsonDecode(map["week_days"])),

      monthDays: map["month_days"] == null
          ? null
          : List<int>.from(
              jsonDecode(map["month_days"])),

      monthWeeks: map["month_week"] == null
          ? null
          : (jsonDecode(map["month_week"]) as List)
              .map((e) => MonthWeekRule.fromMap(e))
              .toList(),

      yearDays: map["year_days"] == null
          ? null
          : List<String>.from(
              jsonDecode(map["year_days"])),

      workDays: map["work_days"] == null
          ? null
          : map["work_days"] == 1,

      timeRanges: map["time_ranges"] == null
          ? null
          : (jsonDecode(map["time_ranges"]) as List)
              .map((e) => TimeRange.fromMap(e))
              .toList(),

    );

  }

}