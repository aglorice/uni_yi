import '../../../core/logging/app_logger.dart';
import '../models/portal_document.dart';
import '../models/portal_response_meta.dart';

class GymPortalClient {
  const GymPortalClient({required AppLogger logger}) : _logger = logger;

  final AppLogger _logger;

  Future<PortalDocument> fetchOverview(DateTime date) async {
    _logger.info('Fetching gym booking payload from fixture portal client.');

    final normalizedDate = DateTime(date.year, date.month, date.day);

    return PortalDocument(
      rawBody:
          '''
{
  "date": "${normalizedDate.toIso8601String()}",
  "rule": {
    "summary": "每日 20:00 放号，可提前 3 天预约，需手动确认提交。",
    "advanceWindowDays": 3,
    "supportsSameDay": false
  },
  "venues": [
    {
      "id": "badminton",
      "name": "羽毛球馆",
      "location": "体育中心二层",
      "slots": [
        {
          "id": "badminton-1900",
          "startTime": "19:00",
          "endTime": "20:00",
          "capacity": 6,
          "remaining": 2,
          "price": 12.0
        },
        {
          "id": "badminton-2000",
          "startTime": "20:00",
          "endTime": "21:00",
          "capacity": 6,
          "remaining": 0,
          "price": 12.0
        }
      ]
    },
    {
      "id": "basketball",
      "name": "半场篮球",
      "location": "田径场南侧",
      "slots": [
        {
          "id": "basketball-1800",
          "startTime": "18:00",
          "endTime": "19:00",
          "capacity": 2,
          "remaining": 1,
          "price": 18.0
        },
        {
          "id": "basketball-1900",
          "startTime": "19:00",
          "endTime": "20:00",
          "capacity": 2,
          "remaining": 1,
          "price": 18.0
        }
      ]
    }
  ],
  "records": [
    {
      "id": "BK-240406-1",
      "venueName": "羽毛球馆",
      "slotLabel": "19:00-20:00",
      "date": "${normalizedDate.toIso8601String()}",
      "status": "已预约"
    }
  ]
}
''',
      meta: PortalResponseMeta(
        endpoint: '/gym/booking/slots',
        fetchedAt: DateTime.now(),
        isFixture: true,
      ),
    );
  }
}
