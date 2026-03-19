class TimeRange {

  final String start;

  final String end;

  TimeRange({
    required this.start,
    required this.end,
  });

  Map<String, dynamic> toMap() {
    return {
      "start": start,
      "end": end,
    };
  }

  factory TimeRange.fromMap(Map<String, dynamic> map) {
    return TimeRange(
      start: map["start"],
      end: map["end"],
    );
  }
}