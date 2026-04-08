import '../../../core/models/data_origin.dart';
import '../../../modules/schedule/domain/entities/schedule_snapshot.dart';
import '../dto/schedule_dto.dart';

class ScheduleMapper {
  const ScheduleMapper();

  ScheduleSnapshot map(ScheduleDto dto, DateTime fetchedAt) {
    final grouped = <String, List<ScheduleSessionDto>>{};
    for (final session in dto.sessions) {
      grouped.putIfAbsent(session.courseId, () => []).add(session);
    }

    final courses = grouped.entries.map((entry) {
      final first = entry.value.first;
      return Course(
        id: first.courseId,
        name: first.courseName,
        teacher: first.teacher,
        sessions: entry.value
            .map(
              (session) => ClassSession(
                dayOfWeek: session.dayOfWeek,
                startTime: session.startTime,
                endTime: session.endTime,
                weekRange: WeekRange(
                  startWeek: session.startWeek,
                  endWeek: session.endWeek,
                ),
                location: TeachingLocation(
                  campus: session.campus,
                  building: session.building,
                  room: session.room,
                ),
                teacher: session.teacher,
              ),
            )
            .toList(),
      );
    }).toList();

    return ScheduleSnapshot(
      term: Term(id: dto.termId, name: dto.termName, isSelected: true),
      availableTerms: [
        Term(id: dto.termId, name: dto.termName, isSelected: true),
      ],
      currentWeek: dto.currentWeek,
      courses: courses,
      fetchedAt: fetchedAt,
      origin: DataOrigin.remote,
    );
  }
}
