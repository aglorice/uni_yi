import '../../../core/error/failure.dart';
import '../../../core/result/result.dart';
import '../dto/schedule_dto.dart';

class ScheduleParser {
  const ScheduleParser();

  Result<ScheduleDto> parse(String rawBody) {
    final tableMatch = RegExp(
      r'<table[^>]*data-term-id="([^"]+)"[^>]*data-term-name="([^"]+)"[^>]*data-current-week="([^"]+)"[^>]*>',
    ).firstMatch(rawBody);

    if (tableMatch == null) {
      return const FailureResult(
        ParsingFailure(
          'Unable to locate the term metadata in schedule payload.',
        ),
      );
    }

    final rowMatches = RegExp(
      r'<tr\s+data-course-id="([^"]+)"\s+data-course="([^"]+)"\s+data-teacher="([^"]+)"\s+data-day="([^"]+)"\s+data-start="([^"]+)"\s+data-end="([^"]+)"\s+data-start-week="([^"]+)"\s+data-end-week="([^"]+)"\s+data-campus="([^"]+)"\s+data-building="([^"]+)"\s+data-room="([^"]+)"\s*></tr>',
    ).allMatches(rawBody);

    final sessions = rowMatches
        .map(
          (match) => ScheduleSessionDto(
            courseId: match.group(1)!,
            courseName: match.group(2)!,
            teacher: match.group(3)!,
            dayOfWeek: int.parse(match.group(4)!),
            startTime: match.group(5)!,
            endTime: match.group(6)!,
            startWeek: int.parse(match.group(7)!),
            endWeek: int.parse(match.group(8)!),
            campus: match.group(9)!,
            building: match.group(10)!,
            room: match.group(11)!,
          ),
        )
        .toList();

    if (sessions.isEmpty) {
      return const FailureResult(
        ParsingFailure('Schedule payload did not contain any course rows.'),
      );
    }

    return Success(
      ScheduleDto(
        termId: tableMatch.group(1)!,
        termName: tableMatch.group(2)!,
        currentWeek: int.parse(tableMatch.group(3)!),
        sessions: sessions,
      ),
    );
  }
}
