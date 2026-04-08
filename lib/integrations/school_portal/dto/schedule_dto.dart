class ScheduleDto {
  const ScheduleDto({
    required this.termId,
    required this.termName,
    required this.currentWeek,
    required this.sessions,
  });

  final String termId;
  final String termName;
  final int currentWeek;
  final List<ScheduleSessionDto> sessions;
}

class ScheduleSessionDto {
  const ScheduleSessionDto({
    required this.courseId,
    required this.courseName,
    required this.teacher,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.startWeek,
    required this.endWeek,
    required this.campus,
    required this.building,
    required this.room,
  });

  final String courseId;
  final String courseName;
  final String teacher;
  final int dayOfWeek;
  final String startTime;
  final String endTime;
  final int startWeek;
  final int endWeek;
  final String campus;
  final String building;
  final String room;
}
