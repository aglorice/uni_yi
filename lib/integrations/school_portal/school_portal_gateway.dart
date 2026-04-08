import 'dart:math';

import '../../core/error/failure.dart';
import '../../core/logging/app_logger.dart';
import '../../core/models/data_origin.dart';
import '../../core/result/result.dart';
import '../../modules/auth/domain/entities/app_session.dart';
import '../../modules/auth/domain/entities/school_credential.dart';
import '../../modules/electricity/domain/entities/electricity_dashboard.dart';
import '../../modules/exams/domain/entities/exam_schedule_snapshot.dart';
import '../../modules/grades/domain/entities/grades_snapshot.dart';
import '../../modules/gym_booking/domain/entities/gym_booking_overview.dart';
import '../../modules/schedule/domain/entities/schedule_snapshot.dart';
import '../../modules/services/domain/entities/service_card_data.dart';
import '../../modules/services/domain/entities/service_launch_data.dart';
import 'sso/session_validator.dart';
import 'sso/sso_login_orchestrator.dart';
import 'wyu_portal_api.dart';

abstract class SchoolPortalGateway {
  Future<Result<AppSession>> login(SchoolCredential credential);
  Future<Result<AppSession>> refreshSession(SchoolCredential credential);
  Future<Result<void>> validateSession(AppSession session);
  Future<Result<ScheduleSnapshot>> fetchSchedule(
    AppSession session, {
    String? termId,
  });
  Future<Result<GradesSnapshot>> fetchGrades(AppSession session);
  Future<Result<ExamScheduleSnapshot>> fetchExamSchedule(
    AppSession session, {
    String? termId,
  });
  Future<Result<ElectricityDashboard>> fetchElectricityDashboard(
    AppSession session,
  );
  Future<Result<GymBookingOverview>> fetchGymBookingOverview(
    AppSession session, {
    required DateTime date,
  });
  Future<Result<BookingRecord>> submitGymBooking(
    AppSession session, {
    required BookingDraft draft,
  });
  Future<Result<List<ServiceCardGroup>>> fetchServiceCards(AppSession session);
  Future<Result<List<ServiceItem>>> fetchServiceCategoryItems(
    AppSession session, {
    required String cardWid,
    required ServiceCategory category,
  });
  Future<Result<ServiceLaunchData>> prepareServiceLaunch(
    AppSession session, {
    required ServiceItem item,
  });
}

class WyuSchoolPortalGateway implements SchoolPortalGateway {
  WyuSchoolPortalGateway({
    required SsoLoginOrchestrator loginOrchestrator,
    required SessionValidator sessionValidator,
    required WyuPortalApi portalApi,
    required AppLogger logger,
  }) : _loginOrchestrator = loginOrchestrator,
       _sessionValidator = sessionValidator,
       _portalApi = portalApi,
       _logger = logger;

  final SsoLoginOrchestrator _loginOrchestrator;
  final SessionValidator _sessionValidator;
  final WyuPortalApi _portalApi;
  final AppLogger _logger;
  final Random _random = Random();

  @override
  Future<Result<ScheduleSnapshot>> fetchSchedule(
    AppSession session, {
    String? termId,
  }) async {
    _logger.info('[Gateway] 开始加载课表 userId=${session.userId} termId=$termId');
    final validation = await validateSession(session);
    if (validation.isFailure) {
      _logger.warn('[Gateway] 课表加载前 session 校验失败');
      return FailureResult(validation.failureOrNull!);
    }

    final termsResult = await _portalApi.fetchYjsData(
      session,
      path: '/student/default/bindterm',
      method: 'GET',
      queryParameters: {'_': _nonce()},
    );
    if (termsResult case FailureResult<dynamic>(failure: final failure)) {
      return FailureResult(failure);
    }

    final termMaps = _collectRecordMaps(termsResult.dataOrNull)
        .where(
          (map) => _pickString(map, const ['termcode', 'termCode']) != null,
        )
        .toList();
    _logger.debug('[Gateway] 学期原始记录数=${termMaps.length}');
    if (termMaps.isEmpty) {
      return const FailureResult(ParsingFailure('未找到研究生教务学期列表。'));
    }

    final selectedTermMap = _selectScheduleTerm(
      termMaps,
      requestedTermId: termId,
    );
    final termCode = _pickString(selectedTermMap, const [
      'termcode',
      'termCode',
    ]);
    final termName =
        _pickString(selectedTermMap, const ['termname', 'termName', 'name']) ??
        termCode ??
        '当前学期';
    if (termCode == null || termCode.isEmpty) {
      return const FailureResult(ParsingFailure('学期编号解析失败。'));
    }
    _logger.info('[Gateway] 课表目标学期 termCode=$termCode termName=$termName');

    final courseResult = await _portalApi.fetchYjsData(
      session,
      path: '/student/pygl/py_kbcx_ew',
      method: 'POST',
      formFields: {'kblx': 'xs', 'termcode': termCode},
    );
    if (courseResult case FailureResult<dynamic>(failure: final failure)) {
      return FailureResult(failure);
    }

    final studentCardResult = await _portalApi.fetchYjsData(
      session,
      path: '/student/default/getxscardinfo',
      method: 'GET',
      queryParameters: {'_': _nonce()},
    );

    final snapshot = _mapSchedule(
      raw: courseResult.dataOrNull,
      termId: termCode,
      termName: termName,
      availableTerms: _mapTerms(termMaps, selectedTermId: termCode),
      isCurrentTerm: _isSelectedTermCurrent(selectedTermMap),
      currentWeekSource: studentCardResult.dataOrNull,
    );
    if (snapshot != null) {
      _logger.info(
        '[Gateway] 课表解析完成 term=${snapshot.term.name} currentWeek=${snapshot.currentWeek} '
        'courseCount=${snapshot.courses.length} entryCount=${snapshot.entries.length}',
      );
      _logger.debug(
        '[Gateway] 课表样例=${snapshot.entries.take(5).map((item) => '${item.session.weekdayLabel} ${item.session.startTime}-${item.session.endTime} ${item.course.name}@${item.session.location.fullName}').join(' | ')}',
      );
    } else {
      _logger.warn('[Gateway] 课表解析结果为空');
    }
    return snapshot == null
        ? const FailureResult(ParsingFailure('课表数据解析失败。'))
        : Success(snapshot);
  }

  @override
  Future<Result<GradesSnapshot>> fetchGrades(AppSession session) async {
    _logger.info('[Gateway] 开始加载成绩 userId=${session.userId}');
    final validation = await validateSession(session);
    if (validation.isFailure) {
      _logger.warn('[Gateway] 成绩加载前 session 校验失败');
      return FailureResult(validation.failureOrNull!);
    }

    var availableTerms = const <Term>[];
    final termsResult = await _portalApi.fetchYjsData(
      session,
      path: '/student/default/bindterm',
      method: 'GET',
      queryParameters: {'_': _nonce()},
    );
    if (termsResult case Success<dynamic>(data: final data)) {
      final termMaps = _collectRecordMaps(data)
          .where(
            (map) => _pickString(map, const ['termcode', 'termCode']) != null,
          )
          .toList();
      if (termMaps.isNotEmpty) {
        final selectedTermMap = _selectScheduleTerm(termMaps);
        final selectedTermId =
            _pickString(selectedTermMap, const ['termcode', 'termCode']) ?? '';
        availableTerms = _mapTerms(termMaps, selectedTermId: selectedTermId);
        _logger.debug('[Gateway] 成绩-学期原始记录数=${termMaps.length}');
      }
    } else {
      _logger.warn('[Gateway] 成绩学期列表获取失败，回退到成绩记录内的学期标签');
    }

    final result = await _portalApi.fetchYjsData(
      session,
      path: '/student/pygl/xscjcx_list',
      method: 'GET',
      queryParameters: {'_': _nonce()},
    );
    if (result case FailureResult<dynamic>(failure: final failure)) {
      return FailureResult(failure);
    }

    final records = _collectRecordMaps(
      result.dataOrNull,
    ).map(_mapGradeRecord).whereType<GradeRecord>().toList();
    _logger.debug(
      '[Gateway] 成绩原始展开记录数=${_collectRecordMaps(result.dataOrNull).length}',
    );
    if (records.isEmpty) {
      return const FailureResult(ParsingFailure('未解析到成绩记录。'));
    }

    _logger.info(
      '[Gateway] 成绩解析完成 recordCount=${records.length} '
      'terms=${records.map((item) => item.termName).toSet().join(' | ')}',
    );
    _logger.debug(
      '[Gateway] 成绩样例=${records.take(5).map((item) => '${item.termName}:${item.courseName}=${item.grade}').join(' | ')}',
    );
    return Success(
      GradesSnapshot(
        records: records,
        availableTerms: availableTerms,
        fetchedAt: DateTime.now(),
        origin: DataOrigin.remote,
      ),
    );
  }

  @override
  Future<Result<ExamScheduleSnapshot>> fetchExamSchedule(
    AppSession session, {
    String? termId,
  }) async {
    _logger.info('[Gateway] 开始加载考试安排 userId=${session.userId} termId=$termId');
    final validation = await validateSession(session);
    if (validation.isFailure) {
      _logger.warn('[Gateway] 考试安排加载前 session 校验失败');
      return FailureResult(validation.failureOrNull!);
    }

    // 1. 获取学期列表
    final termsResult = await _portalApi.fetchYjsData(
      session,
      path: '/student/default/bindterm',
      method: 'GET',
      queryParameters: {'_': _nonce()},
    );
    if (termsResult case FailureResult<dynamic>(failure: final failure)) {
      return FailureResult(failure);
    }

    final termMaps = _collectRecordMaps(termsResult.dataOrNull)
        .where(
          (map) => _pickString(map, const ['termcode', 'termCode']) != null,
        )
        .toList();
    _logger.debug('[Gateway] 考试-学期原始记录数=${termMaps.length}');
    if (termMaps.isEmpty) {
      return const FailureResult(ParsingFailure('未找到研究生教务学期列表。'));
    }

    final selectedTermMap = _selectScheduleTerm(
      termMaps,
      requestedTermId: termId,
    );
    final termCode = _pickString(selectedTermMap, const [
      'termcode',
      'termCode',
    ]);
    final termName =
        _pickString(selectedTermMap, const ['termname', 'termName', 'name']) ??
        termCode ??
        '当前学期';
    if (termCode == null || termCode.isEmpty) {
      return const FailureResult(ParsingFailure('学期编号解析失败。'));
    }
    _logger.info('[Gateway] 考试目标学期 termCode=$termCode termName=$termName');

    // 2. 获取考试安排
    final result = await _portalApi.fetchYjsData(
      session,
      path: '/student/pygl/kckccx_list',
      method: 'POST',
      formFields: {'termcode': termCode},
    );
    if (result case FailureResult<dynamic>(failure: final failure)) {
      return FailureResult(failure);
    }

    final records = _collectRecordMaps(
      result.dataOrNull,
    ).map(_mapExamRecord).whereType<ExamRecord>().toList();
    _logger.debug(
      '[Gateway] 考试原始展开记录数=${_collectRecordMaps(result.dataOrNull).length}',
    );

    final availableTerms = _mapTerms(termMaps, selectedTermId: termCode);
    _logger.info('[Gateway] 考试安排解析完成 recordCount=${records.length}');
    _logger.debug(
      '[Gateway] 考试样例=${records.take(5).map((item) => '${item.courseName}:${item.dateLabel} ${item.timeLabel} ${item.location}').join(' | ')}',
    );
    return Success(
      ExamScheduleSnapshot(
        term: availableTerms.firstWhere(
          (item) => item.id == termCode,
          orElse: () => Term(
            id: termCode,
            name: termName,
            isSelected: _isSelectedTermCurrent(selectedTermMap),
          ),
        ),
        availableTerms: availableTerms,
        records: records,
        fetchedAt: DateTime.now(),
        origin: DataOrigin.remote,
      ),
    );
  }

  @override
  Future<Result<ElectricityDashboard>> fetchElectricityDashboard(
    AppSession session,
  ) async {
    return const FailureResult(BusinessFailure('电费查询将在后续接入。'));
  }

  @override
  Future<Result<GymBookingOverview>> fetchGymBookingOverview(
    AppSession session, {
    required DateTime date,
  }) async {
    return const FailureResult(BusinessFailure('体育馆预约将在后续接入。'));
  }

  @override
  Future<Result<AppSession>> login(SchoolCredential credential) {
    return _loginOrchestrator.login(credential);
  }

  @override
  Future<Result<AppSession>> refreshSession(SchoolCredential credential) {
    return _loginOrchestrator.login(credential);
  }

  @override
  Future<Result<BookingRecord>> submitGymBooking(
    AppSession session, {
    required BookingDraft draft,
  }) async {
    return const FailureResult(BusinessFailure('体育馆预约将在后续接入。'));
  }

  @override
  Future<Result<void>> validateSession(AppSession session) {
    return _sessionValidator.validate(session);
  }

  @override
  Future<Result<List<ServiceCardGroup>>> fetchServiceCards(
    AppSession session,
  ) async {
    _logger.info('[Gateway] 开始加载服务卡片 userId=${session.userId}');
    final validation = await validateSession(session);
    if (validation.isFailure) {
      _logger.warn('[Gateway] 服务卡片加载前 session 校验失败');
      return FailureResult(validation.failureOrNull!);
    }

    final groups = <ServiceCardGroup>[];

    final serviceCardResult = await _portalApi.fetchServiceCardData(
      session,
      _serviceCardWid,
    );
    if (serviceCardResult case Success<Map<String, dynamic>>(
      data: final data,
    )) {
      final group = _parseServiceCardGroup('校园服务', _serviceCardWid, data);
      if (group != null) {
        groups.add(group);
      }
    } else {
      _logger.warn('[Gateway] 校园服务卡片加载失败');
    }

    final yjsCardResult = await _portalApi.fetchServiceCardData(
      session,
      _yjsServiceCardWid,
    );
    if (yjsCardResult case Success<Map<String, dynamic>>(data: final data)) {
      final group = _parseServiceCardGroup('系统直通车', _yjsServiceCardWid, data);
      if (group != null) {
        groups.add(group);
      }
    } else {
      _logger.warn('[Gateway] 系统直通车卡片加载失败');
    }

    if (groups.isEmpty) {
      return const FailureResult(ParsingFailure('未加载到任何服务数据。'));
    }

    _logger.info(
      '[Gateway] 服务卡片加载完成 groupCount=${groups.length} '
      'totalItems=${groups.fold<int>(0, (sum, g) => sum + g.items.length)}',
    );
    return Success(groups);
  }

  @override
  Future<Result<List<ServiceItem>>> fetchServiceCategoryItems(
    AppSession session, {
    required String cardWid,
    required ServiceCategory category,
  }) async {
    _logger.info(
      '[Gateway] 开始加载服务分类 cardWid=$cardWid typeId=${category.typeId} typeName=${category.typeName}',
    );
    final validation = await validateSession(session);
    if (validation.isFailure) {
      _logger.warn('[Gateway] 服务分类加载前 session 校验失败');
      return FailureResult(validation.failureOrNull!);
    }

    final result = await _portalApi.fetchServiceCardData(
      session,
      cardWid,
      typeId: category.typeId,
    );
    if (result case FailureResult<Map<String, dynamic>>(
      failure: final failure,
    )) {
      return FailureResult(failure);
    }

    final parsed = _parseServiceCardGroup(
      '分类服务',
      cardWid,
      result.requireValue(),
    );
    if (parsed == null) {
      return const FailureResult(ParsingFailure('服务分类解析失败。'));
    }

    final items = parsed.itemsForCategory(category);
    if (items.isNotEmpty) {
      return Success(items);
    }

    return Success(parsed.items);
  }

  @override
  Future<Result<ServiceLaunchData>> prepareServiceLaunch(
    AppSession session, {
    required ServiceItem item,
  }) async {
    _logger.info(
      '[Gateway] 准备进入服务 app=${item.appName} userId=${session.userId}',
    );
    final validation = await validateSession(session);
    if (validation.isFailure) {
      _logger.warn('[Gateway] 服务跳转前 session 校验失败');
      return FailureResult(validation.failureOrNull!);
    }

    return _portalApi.prepareServiceLaunch(session, item: item);
  }

  ServiceCardGroup? _parseServiceCardGroup(
    String cardName,
    String cardWid,
    Map<String, dynamic> raw,
  ) {
    final data = raw['data'];
    if (data is! Map<String, dynamic>) return null;

    final categories = _parseServiceCategories(data);
    final items = _parseServiceItems(data);
    if (items.isEmpty && categories.isEmpty) return null;

    // If classifyData was empty, fall back to deriving categories from items
    if (categories.isEmpty && items.isNotEmpty) {
      final categoryMap = <String, ServiceCategory>{};
      final countMap = <String, int>{};
      for (final item in items) {
        countMap[item.typeId] = (countMap[item.typeId] ?? 0) + 1;
        if (!categoryMap.containsKey(item.typeId)) {
          categoryMap[item.typeId] = ServiceCategory(
            typeId: item.typeId,
            typeName: item.typeId.isEmpty ? '其他' : item.typeId,
            count: countMap[item.typeId]!,
          );
        } else {
          categoryMap[item.typeId] = categoryMap[item.typeId]!.copyWith(
            count: countMap[item.typeId],
          );
        }
      }
      categories.addAll(categoryMap.values);
    }

    return ServiceCardGroup(
      cardWid: cardWid,
      cardName: cardName,
      categories: categories,
      items: items,
    );
  }

  List<ServiceCategory> _parseServiceCategories(Map<String, dynamic> data) {
    final categories = <ServiceCategory>[];
    final classifyData = data['classifyData'];
    if (classifyData is! List) {
      return categories;
    }

    for (final cls in classifyData) {
      if (cls is! Map<String, dynamic>) continue;
      final show = cls['show'];
      if (show == false || show == 0) continue;
      final typeId = _pickString(cls, const ['typeId']);
      final typeName = _pickString(cls, const ['typeName']) ?? '其他';
      final count = _pickInt(cls, const ['count']) ?? 0;
      if (typeId != null && typeId.isNotEmpty) {
        categories.add(
          ServiceCategory(typeId: typeId, typeName: typeName, count: count),
        );
      }
    }

    return categories;
  }

  List<ServiceItem> _parseServiceItems(Map<String, dynamic> data) {
    final appData = data['appData'];
    if (appData is! List) {
      return const [];
    }

    final items = <ServiceItem>[];
    for (final svc in appData) {
      if (svc is! Map<String, dynamic>) continue;

      final appName = _pickString(svc, const [
        'appName',
        'serviceName',
        'name',
        'title',
      ]);
      if (appName == null || appName.isEmpty) continue;

      final appId =
          _pickString(svc, const ['appId', 'serviceId', 'wid', 'id']) ??
          appName;
      final iconLink = _pickString(svc, const [
        'iconLink',
        'icon',
        'iconUrl',
        'img',
        'logo',
      ]);
      final pcAccessUrl = _pickString(svc, const [
        'pcAccessUrl',
        'url',
        'pcUrl',
      ]);
      final mobileAccessUrl = _pickString(svc, const [
        'mobileAccessUrl',
        'mobileUrl',
      ]);
      final wid = _pickString(svc, const ['wid', 'serviceWid', 'appWid']);

      final typeId =
          _pickString(svc, const [
            'typeId',
            'categoryId',
            'appTypeId',
            'classifyId',
            'classifyID',
            'typeID',
          ]) ??
          '';
      final typeName = _pickString(svc, const [
        'typeName',
        'categoryName',
        'appTypeName',
        'classifyName',
      ]);

      items.add(
        ServiceItem(
          appId: appId,
          appName: appName,
          iconLink: iconLink,
          pcAccessUrl: pcAccessUrl,
          mobileAccessUrl: mobileAccessUrl,
          wid: wid,
          typeId: typeId,
          typeName: typeName,
        ),
      );
    }

    return items;
  }

  static const _serviceCardWid = '8558486040491173';
  static const _yjsServiceCardWid = '017434820995445355';

  ScheduleSnapshot? _mapSchedule({
    required dynamic raw,
    required String termId,
    required String termName,
    required List<Term> availableTerms,
    required bool isCurrentTerm,
    required dynamic currentWeekSource,
  }) {
    final grouped = <String, List<ClassSession>>{};
    final courseMeta =
        <
          String,
          ({String name, String teacher, String? courseCode, String? note})
        >{};

    final sessions = _parseScheduleSessions(raw);
    for (final session in sessions) {
      grouped.putIfAbsent(session.courseId, () => []);
      grouped[session.courseId]!.add(
        ClassSession(
          dayOfWeek: session.dayOfWeek,
          startTime: session.startTime,
          endTime: session.endTime,
          weekRange: session.weekRange,
          location: session.location,
          teacher: session.teacher,
          startSection: session.startSection,
          endSection: session.endSection,
          weekDescription: session.weekDescription,
          dayLabel: session.dayLabel,
        ),
      );
      courseMeta[session.courseId] = (
        name: session.courseName,
        teacher: session.teacher,
        courseCode: session.courseCode,
        note: session.note,
      );
    }

    if (grouped.isEmpty) {
      return null;
    }

    final courses = grouped.entries.map((entry) {
      final meta = courseMeta[entry.key]!;
      return Course(
        id: entry.key,
        name: meta.name,
        teacher: meta.teacher,
        courseCode: meta.courseCode,
        note: meta.note,
        sessions: entry.value,
      );
    }).toList();

    return ScheduleSnapshot(
      term: availableTerms.firstWhere(
        (item) => item.id == termId,
        orElse: () =>
            Term(id: termId, name: termName, isSelected: isCurrentTerm),
      ),
      availableTerms: availableTerms,
      currentWeek: isCurrentTerm
          ? _extractCurrentWeek(currentWeekSource)
          : null,
      courses: courses,
      fetchedAt: DateTime.now(),
      origin: DataOrigin.remote,
    );
  }

  List<_ParsedScheduleSession> _parseScheduleSessions(dynamic raw) {
    final flatSessions = _parseFlatScheduleSessions(raw);
    if (flatSessions.isNotEmpty) {
      _logger.debug(
        '[Gateway] 课表解析命中扁平记录结构 sessionCount=${flatSessions.length}',
      );
      return flatSessions;
    }

    final gridSessions = _parseYjsGridScheduleSessions(raw);
    if (gridSessions.isNotEmpty) {
      _logger.debug('[Gateway] 课表解析命中矩阵结构 sessionCount=${gridSessions.length}');
    }
    return gridSessions;
  }

  List<_ParsedScheduleSession> _parseFlatScheduleSessions(dynamic raw) {
    final sessions = <_ParsedScheduleSession>[];

    for (final map in _collectRecordMaps(raw)) {
      final courseName = _pickString(map, const ['kcmc', 'courseName', 'name']);
      final teacher = _pickString(map, const ['jsmc', 'teacher', 'jsxm']) ?? '';
      final courseCode = _pickString(map, const ['kcdm', 'kcbh', 'courseCode']);
      final dayOfWeek = _resolveDayOfWeek(map);
      if (courseName == null || dayOfWeek == null) {
        continue;
      }

      final courseId =
          courseCode ??
          _pickString(map, const ['courseId']) ??
          '$courseName-${teacher.isEmpty ? 'unknown' : teacher}';
      final sectionRange = _resolveSectionRange(map);
      final timeRange = _resolveTimeRange(map, sectionRange);
      final weekRange = _resolveWeekRange(map);

      sessions.add(
        _ParsedScheduleSession(
          courseId: courseId,
          courseName: courseName,
          teacher: teacher,
          courseCode: courseCode,
          note: _pickString(map, const ['bz', 'remark', 'memo']),
          dayOfWeek: dayOfWeek,
          startTime: timeRange.$1,
          endTime: timeRange.$2,
          weekRange: weekRange,
          location: TeachingLocation(
            campus: _pickString(map, const ['xqmc', 'campusName', 'xq']) ?? '',
            building:
                _pickString(map, const ['jxlmc', 'buildingName', 'jxl']) ?? '',
            room: _pickString(map, const ['cdmc', 'roomName', 'jxcdmc']) ?? '',
          ),
          startSection: sectionRange?.$1,
          endSection: sectionRange?.$2,
          weekDescription: _pickString(map, const ['zc', 'weekRange', 'zcsm']),
          dayLabel: _pickString(map, const ['weekdayLabel', 'dayLabel']),
        ),
      );
    }

    return sessions;
  }

  List<_ParsedScheduleSession> _parseYjsGridScheduleSessions(dynamic raw) {
    final rows = switch (raw) {
      {'rows': final List<dynamic> value} =>
        value
            .whereType<Map>()
            .map(
              (item) =>
                  Map<String, dynamic>.from(item.cast<dynamic, dynamic>()),
            )
            .toList(),
      _ => const <Map<String, dynamic>>[],
    };
    if (rows.isEmpty) {
      return const <_ParsedScheduleSession>[];
    }

    final sessions = <_MutableParsedScheduleSession>[];
    for (final row in rows) {
      final section = _pickInt(row, const ['jcid', 'mc']);
      if (section == null) {
        continue;
      }

      for (var dayOfWeek = 1; dayOfWeek <= 7; dayOfWeek++) {
        final cellValue = row['z$dayOfWeek'];
        final rawCell = cellValue?.toString().trim() ?? '';
        if (rawCell.isEmpty) {
          continue;
        }

        final cellCourses = _parseYjsGridCell(rawCell);
        for (final cellCourse in cellCourses) {
          _MutableParsedScheduleSession? matched;
          for (var index = sessions.length - 1; index >= 0; index--) {
            final candidate = sessions[index];
            if (candidate.dayOfWeek == dayOfWeek &&
                candidate.endSection == section - 1 &&
                candidate.courseName == cellCourse.courseName &&
                candidate.teacher == cellCourse.teacher &&
                candidate.location.room == cellCourse.location.room &&
                candidate.weekDescription == cellCourse.weekDescription &&
                candidate.note == cellCourse.note) {
              matched = candidate;
              break;
            }
          }

          if (matched != null) {
            matched.endSection = section;
            matched.endTime = _sectionLabel(section);
            continue;
          }

          sessions.add(
            _MutableParsedScheduleSession(
              courseId:
                  '${cellCourse.courseName}-${cellCourse.teacher.isEmpty ? 'unknown' : cellCourse.teacher}',
              courseName: cellCourse.courseName,
              teacher: cellCourse.teacher,
              courseCode: null,
              note: cellCourse.note,
              dayOfWeek: dayOfWeek,
              startTime: _sectionLabel(section),
              endTime: _sectionLabel(section),
              weekRange: cellCourse.weekRange,
              location: cellCourse.location,
              startSection: section,
              endSection: section,
              weekDescription: cellCourse.weekDescription,
              dayLabel: null,
            ),
          );
        }
      }
    }

    return sessions.map((item) => item.toImmutable()).toList()
      ..sort((left, right) {
        final byDay = left.dayOfWeek.compareTo(right.dayOfWeek);
        if (byDay != 0) {
          return byDay;
        }
        final leftSection = left.startSection ?? 0;
        final rightSection = right.startSection ?? 0;
        return leftSection.compareTo(rightSection);
      });
  }

  List<_ParsedYjsGridCellCourse> _parseYjsGridCell(String rawCell) {
    final normalized = rawCell
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'<[^>]+>'), '\n')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('\r', '');
    final lines = normalized
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty && line.toLowerCase() != 'null')
        .toList();
    if (lines.isEmpty) {
      return const <_ParsedYjsGridCellCourse>[];
    }

    final courses = <_ParsedYjsGridCellCourse>[];
    var index = 0;
    while (index < lines.length) {
      final courseName = lines[index++].trim();
      if (courseName.isEmpty || _looksLikeWeekLine(courseName)) {
        continue;
      }

      String? note;
      if (index < lines.length && !_looksLikeWeekLine(lines[index])) {
        note = lines[index++].trim();
      }

      if (index >= lines.length || !_looksLikeWeekLine(lines[index])) {
        continue;
      }
      final weekDescription = lines[index++].trim();
      final weekRange = _weekRangeFromText(weekDescription);
      if (weekRange == null) {
        continue;
      }

      final teacherAndLocation = index < lines.length
          ? lines[index++].trim()
          : '';
      final parsedTeacherAndLocation = _parseTeacherAndLocation(
        teacherAndLocation,
      );

      courses.add(
        _ParsedYjsGridCellCourse(
          courseName: courseName,
          teacher: parsedTeacherAndLocation.teacher,
          location: parsedTeacherAndLocation.location,
          weekRange: weekRange,
          weekDescription: weekDescription
              .replaceAll('[', '')
              .replaceAll(']', ''),
          note: note,
        ),
      );
    }

    return courses;
  }

  bool _looksLikeWeekLine(String value) {
    return value.contains('周');
  }

  WeekRange? _weekRangeFromText(String? raw) {
    if (raw == null) {
      return null;
    }
    final normalized = raw.replaceAll('[', '').replaceAll(']', '').trim();
    final rangeMatch = RegExp(r'(\d+)\D+(\d+)\s*周?').firstMatch(normalized);
    if (rangeMatch != null) {
      return WeekRange(
        startWeek: int.parse(rangeMatch.group(1)!),
        endWeek: int.parse(rangeMatch.group(2)!),
      );
    }

    final singleMatch = RegExp(r'(\d+)\s*周?').firstMatch(normalized);
    if (singleMatch != null) {
      final week = int.parse(singleMatch.group(1)!);
      return WeekRange(startWeek: week, endWeek: week);
    }

    return null;
  }

  ({String teacher, TeachingLocation location}) _parseTeacherAndLocation(
    String raw,
  ) {
    final match = RegExp(r'^(.+?)\[(.+?)\]$').firstMatch(raw.trim());
    if (match == null) {
      return (
        teacher: raw.trim(),
        location: const TeachingLocation(campus: '', building: '', room: ''),
      );
    }

    return (
      teacher: match.group(1)!.trim(),
      location: TeachingLocation(
        campus: '',
        building: '',
        room: match.group(2)!.trim(),
      ),
    );
  }

  String _sectionLabel(int section) => '第$section节';

  GradeRecord? _mapGradeRecord(Map<String, dynamic> map) {
    final courseName = _pickString(map, const ['kcmc', 'courseName', 'name']);
    final grade = _pickString(map, const [
      'cj',
      'zpcj',
      'score',
      'grade',
      'cjmsz',
    ]);
    if (courseName == null || grade == null) {
      return null;
    }

    return GradeRecord(
      courseName: courseName,
      termName:
          _pickString(map, const [
            'kkxq',
            'termname',
            'xqmc',
            'xnxqmc',
            'termName',
          ]) ??
          '未分学期',
      grade: grade,
      courseCode: _pickString(map, const ['kcbh', 'kcdm', 'courseCode']),
      credit: _pickDouble(map, const ['kcxf', 'xf', 'credit']),
      gradePoint: _pickDouble(map, const ['jd', 'gradePoint']),
      assessmentMethod: _pickString(map, const [
        'khfs',
        'ksxz',
        'khfsmc',
        'assessment',
      ]),
      teacher: _pickString(map, const ['rkjs', 'jsmc', 'teacher']),
      classHours: _pickString(map, const ['xs', 'classHours']),
    );
  }

  ExamRecord? _mapExamRecord(Map<String, dynamic> map) {
    final courseName = _pickString(map, const ['kcmc', 'courseName', 'name']);
    if (courseName == null) {
      return null;
    }

    final dateLabel =
        _pickString(map, const ['ksrq', 'date', 'examDate']) ?? '日期待定';
    final startTime = _pickString(map, const ['kssj', 'startTime']);
    final endTime = _pickString(map, const ['jssj', 'endTime']);
    final timeLabel = switch ((startTime, endTime)) {
      (final String start?, final String end?) => '$start-$end',
      (final String start?, _) => start,
      _ => _pickString(map, const ['sjdmc', 'timeLabel']) ?? '时间待定',
    };
    final locationParts = <String>[];
    for (final value in [
      _pickString(map, const ['dz', 'ksdd', 'location', 'address']),
      _pickString(map, const ['jsmc', 'roomName']),
    ]) {
      if (value == null || value.isEmpty || locationParts.contains(value)) {
        continue;
      }
      locationParts.add(value);
    }
    final location = locationParts.join(' ');

    return ExamRecord(
      courseName: courseName,
      dateLabel: dateLabel,
      timeLabel: timeLabel,
      location: location.isEmpty ? '地点待定' : location,
      courseCode: _pickString(map, const ['kcbh', 'courseCode']),
      className: _pickString(map, const ['bjmc', 'className']),
      examMethod: _pickString(map, const ['khxs', 'examMethod', 'examType']),
      primaryTeacher: _pickString(map, const ['zjjs', 'teacher']),
      assistantTeacher: _pickString(map, const ['fjjs', 'assistantTeacher']),
      candidateCount: _pickString(map, const ['ksrs', 'candidateCount']),
      seatNumber: _pickString(map, const ['zwh', 'seatNo', 'seatNumber']),
      remark: _pickString(map, const ['bz', 'remark', 'memo']),
    );
  }

  Map<String, dynamic> _selectScheduleTerm(
    List<Map<String, dynamic>> terms, {
    String? requestedTermId,
  }) {
    if (requestedTermId != null && requestedTermId.isNotEmpty) {
      for (final term in terms) {
        if (_pickString(term, const ['termcode', 'termCode']) ==
            requestedTermId) {
          return term;
        }
      }
    }

    for (final term in terms) {
      if (_isSelectedTermCurrent(term)) {
        return term;
      }
    }
    return terms.first;
  }

  List<Term> _mapTerms(
    List<Map<String, dynamic>> termMaps, {
    required String selectedTermId,
  }) {
    return termMaps.map((map) {
      final id = _pickString(map, const ['termcode', 'termCode']) ?? '';
      final name =
          _pickString(map, const ['termname', 'termName', 'name']) ?? id;
      return Term(id: id, name: name, isSelected: id == selectedTermId);
    }).toList();
  }

  bool _isSelectedTermCurrent(Map<String, dynamic> termMap) {
    final value = _pickString(termMap, const [
      'selected',
      'dqxnq',
      'isCurrent',
      'currentFlag',
      'sfmr',
    ]);
    return value == '1' || value?.toLowerCase() == 'true';
  }

  List<Map<String, dynamic>> _collectRecordMaps(dynamic value) {
    final items = <Map<String, dynamic>>[];

    void visit(dynamic node) {
      if (node is List) {
        for (final item in node) {
          visit(item);
        }
        return;
      }

      if (node is! Map) {
        return;
      }

      final map = Map<String, dynamic>.from(node.cast<dynamic, dynamic>());
      items.add(map);
      for (final child in map.values) {
        visit(child);
      }
    }

    visit(value);
    return items;
  }

  int? _extractCurrentWeek(dynamic raw) {
    for (final map in _collectRecordMaps(raw)) {
      final week = _pickInt(map, const [
        'dqzc',
        'dqszc',
        'week',
        'currentWeek',
      ]);
      if (week != null) {
        return week;
      }
    }
    return null;
  }

  int? _resolveDayOfWeek(Map<String, dynamic> map) {
    final raw = _pickString(map, const ['xq', 'skxq', 'dayOfWeek', 'weekday']);
    if (raw == null) {
      return null;
    }

    final number = int.tryParse(raw);
    if (number != null && number >= 1 && number <= 7) {
      return number;
    }

    const labels = {
      '一': 1,
      '二': 2,
      '三': 3,
      '四': 4,
      '五': 5,
      '六': 6,
      '日': 7,
      '天': 7,
    };
    for (final entry in labels.entries) {
      if (raw.contains(entry.key)) {
        return entry.value;
      }
    }
    return null;
  }

  (int, int)? _resolveSectionRange(Map<String, dynamic> map) {
    final start = _pickInt(map, const ['ksjc', 'startSection']);
    final end = _pickInt(map, const ['jsjc', 'endSection']);
    if (start != null && end != null) {
      return (start, end);
    }

    final raw = _pickString(map, const ['jcs', 'jc', 'sectionRange']);
    if (raw == null) {
      return null;
    }

    final match = RegExp(r'(\d+)\D+(\d+)').firstMatch(raw);
    if (match != null) {
      return (int.parse(match.group(1)!), int.parse(match.group(2)!));
    }

    final single = int.tryParse(raw);
    return single == null ? null : (single, single);
  }

  (String, String) _resolveTimeRange(
    Map<String, dynamic> map,
    (int, int)? sectionRange,
  ) {
    final startTime = _pickString(map, const ['kssj', 'startTime']);
    final endTime = _pickString(map, const ['jssj', 'endTime']);
    if (startTime != null && endTime != null) {
      return (startTime, endTime);
    }

    if (sectionRange != null) {
      return ('第${sectionRange.$1}节', '第${sectionRange.$2}节');
    }

    return ('待定', '待定');
  }

  WeekRange _resolveWeekRange(Map<String, dynamic> map) {
    final start = _pickInt(map, const ['ksz', 'startWeek']);
    final end = _pickInt(map, const ['jsz', 'endWeek']);
    if (start != null && end != null) {
      return WeekRange(startWeek: start, endWeek: end);
    }

    final raw = _pickString(map, const ['zc', 'weekRange', 'zcsm']);
    if (raw != null) {
      final match = RegExp(r'(\d+)\D+(\d+)').firstMatch(raw);
      if (match != null) {
        return WeekRange(
          startWeek: int.parse(match.group(1)!),
          endWeek: int.parse(match.group(2)!),
        );
      }
      final single = int.tryParse(raw);
      if (single != null) {
        return WeekRange(startWeek: single, endWeek: single);
      }
    }

    return const WeekRange(startWeek: 1, endWeek: 20);
  }

  int _nonce() => _random.nextInt(100000);

  String? _pickString(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value == null) {
        continue;
      }
      final text = value.toString().trim();
      if (text.isNotEmpty) {
        return text;
      }
    }
    return null;
  }

  int? _pickInt(Map<String, dynamic> map, List<String> keys) {
    final value = _pickString(map, keys);
    if (value == null) {
      return null;
    }
    return int.tryParse(value);
  }

  double? _pickDouble(Map<String, dynamic> map, List<String> keys) {
    final value = _pickString(map, keys);
    if (value == null) {
      return null;
    }
    return double.tryParse(value);
  }
}

class _ParsedScheduleSession {
  const _ParsedScheduleSession({
    required this.courseId,
    required this.courseName,
    required this.teacher,
    required this.courseCode,
    required this.note,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.weekRange,
    required this.location,
    required this.startSection,
    required this.endSection,
    required this.weekDescription,
    required this.dayLabel,
  });

  final String courseId;
  final String courseName;
  final String teacher;
  final String? courseCode;
  final String? note;
  final int dayOfWeek;
  final String startTime;
  final String endTime;
  final WeekRange weekRange;
  final TeachingLocation location;
  final int? startSection;
  final int? endSection;
  final String? weekDescription;
  final String? dayLabel;
}

class _MutableParsedScheduleSession {
  _MutableParsedScheduleSession({
    required this.courseId,
    required this.courseName,
    required this.teacher,
    required this.courseCode,
    required this.note,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.weekRange,
    required this.location,
    required this.startSection,
    required this.endSection,
    required this.weekDescription,
    required this.dayLabel,
  });

  final String courseId;
  final String courseName;
  final String teacher;
  final String? courseCode;
  final String? note;
  final int dayOfWeek;
  String startTime;
  String endTime;
  final WeekRange weekRange;
  final TeachingLocation location;
  final int startSection;
  int endSection;
  final String? weekDescription;
  final String? dayLabel;

  _ParsedScheduleSession toImmutable() {
    return _ParsedScheduleSession(
      courseId: courseId,
      courseName: courseName,
      teacher: teacher,
      courseCode: courseCode,
      note: note,
      dayOfWeek: dayOfWeek,
      startTime: startTime,
      endTime: endTime,
      weekRange: weekRange,
      location: location,
      startSection: startSection,
      endSection: endSection,
      weekDescription: weekDescription,
      dayLabel: dayLabel,
    );
  }
}

class _ParsedYjsGridCellCourse {
  const _ParsedYjsGridCellCourse({
    required this.courseName,
    required this.teacher,
    required this.location,
    required this.weekRange,
    required this.weekDescription,
    required this.note,
  });

  final String courseName;
  final String teacher;
  final TeachingLocation location;
  final WeekRange weekRange;
  final String weekDescription;
  final String? note;
}

class TestingSchoolPortalGateway implements SchoolPortalGateway {
  const TestingSchoolPortalGateway();

  @override
  Future<Result<List<ServiceCardGroup>>> fetchServiceCards(
    AppSession session,
  ) async {
    return const FailureResult(BusinessFailure('测试环境未接入校园服务。'));
  }

  @override
  Future<Result<List<ServiceItem>>> fetchServiceCategoryItems(
    AppSession session, {
    required String cardWid,
    required ServiceCategory category,
  }) async {
    return const FailureResult(BusinessFailure('测试环境未接入校园服务分类。'));
  }

  @override
  Future<Result<ServiceLaunchData>> prepareServiceLaunch(
    AppSession session, {
    required ServiceItem item,
  }) async {
    final url = item.launchCandidates.isNotEmpty
        ? item.launchCandidates.first
        : '';
    if (url.isEmpty) {
      return const FailureResult(BusinessFailure('测试环境未接入服务跳转。'));
    }
    return Success(
      ServiceLaunchData(
        initialUrl: url,
        resolvedUrl: url,
        cookies: session.cookies,
      ),
    );
  }

  @override
  Future<Result<ElectricityDashboard>> fetchElectricityDashboard(
    AppSession session,
  ) async {
    return const FailureResult(BusinessFailure('测试环境未接入电费。'));
  }

  @override
  Future<Result<ExamScheduleSnapshot>> fetchExamSchedule(
    AppSession session, {
    String? termId,
  }) async {
    return const FailureResult(BusinessFailure('测试环境未接入考试安排。'));
  }

  @override
  Future<Result<GradesSnapshot>> fetchGrades(AppSession session) async {
    return const FailureResult(BusinessFailure('测试环境未接入成绩查询。'));
  }

  @override
  Future<Result<GymBookingOverview>> fetchGymBookingOverview(
    AppSession session, {
    required DateTime date,
  }) async {
    return const FailureResult(BusinessFailure('测试环境未接入体育馆预约。'));
  }

  @override
  Future<Result<ScheduleSnapshot>> fetchSchedule(
    AppSession session, {
    String? termId,
  }) async {
    return const FailureResult(BusinessFailure('测试环境未接入课表查询。'));
  }

  @override
  Future<Result<AppSession>> login(SchoolCredential credential) async {
    return Success(
      AppSession(
        userId: credential.username,
        displayName: credential.username,
        cookies: const [
          PortalCookie(
            name: 'CASTGC',
            value: 'testing',
            domain: 'authserver.wyu.edu.cn',
          ),
        ],
        issuedAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(hours: 8)),
        profile: PortalUserProfile(
          userName: credential.username,
          userAccount: credential.username,
        ),
      ),
    );
  }

  @override
  Future<Result<AppSession>> refreshSession(SchoolCredential credential) {
    return login(credential);
  }

  @override
  Future<Result<BookingRecord>> submitGymBooking(
    AppSession session, {
    required BookingDraft draft,
  }) async {
    return const FailureResult(BusinessFailure('测试环境未接入体育馆预约。'));
  }

  @override
  Future<Result<void>> validateSession(AppSession session) async {
    return const Success(null);
  }
}
