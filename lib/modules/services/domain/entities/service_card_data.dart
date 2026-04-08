class ServiceCategory {
  const ServiceCategory({
    required this.typeId,
    required this.typeName,
    this.count = 0,
  });

  final String typeId;
  final String typeName;
  final int count;

  ServiceCategory copyWith({String? typeId, String? typeName, int? count}) {
    return ServiceCategory(
      typeId: typeId ?? this.typeId,
      typeName: typeName ?? this.typeName,
      count: count ?? this.count,
    );
  }
}

class ServiceItem {
  const ServiceItem({
    required this.appId,
    required this.appName,
    this.iconLink,
    this.pcAccessUrl,
    this.mobileAccessUrl,
    this.wid,
    this.typeId = '',
    this.typeName,
  });

  final String appId;
  final String appName;
  final String? iconLink;
  final String? pcAccessUrl;
  final String? mobileAccessUrl;
  final String? wid;
  final String typeId;
  final String? typeName;

  String get accessUrl => mobileAccessUrl?.isNotEmpty == true
      ? mobileAccessUrl!
      : pcAccessUrl ?? '';

  List<String> get launchCandidates {
    final candidates = <String>[];

    void add(String? value) {
      final text = value?.trim() ?? '';
      if (text.isEmpty || text.startsWith('javascript:')) {
        return;
      }
      if (!candidates.contains(text)) {
        candidates.add(text);
      }
    }

    add(pcAccessUrl);
    add(mobileAccessUrl);
    if (wid != null && wid!.isNotEmpty) {
      add(
        'https://ehall.wyu.edu.cn/default/index.html#/ServiceShow?isMobile=0&wid=$wid',
      );
    }
    return candidates;
  }

  Map<String, dynamic> toJson() => {
    'appId': appId,
    'appName': appName,
    'iconLink': iconLink,
    'pcAccessUrl': pcAccessUrl,
    'mobileAccessUrl': mobileAccessUrl,
    'wid': wid,
    'typeId': typeId,
    'typeName': typeName,
  };

  factory ServiceItem.fromJson(Map<String, dynamic> json) {
    return ServiceItem(
      appId: json['appId'] as String,
      appName: json['appName'] as String,
      iconLink: json['iconLink'] as String?,
      pcAccessUrl: json['pcAccessUrl'] as String?,
      mobileAccessUrl: json['mobileAccessUrl'] as String?,
      wid: json['wid'] as String?,
      typeId: json['typeId'] as String? ?? '',
      typeName: json['typeName'] as String?,
    );
  }
}

class ServiceCardGroup {
  const ServiceCardGroup({
    required this.cardWid,
    required this.cardName,
    required this.categories,
    required this.items,
  });

  final String cardWid;
  final String cardName;
  final List<ServiceCategory> categories;
  final List<ServiceItem> items;

  ServiceCardGroup copyWith({
    String? cardWid,
    String? cardName,
    List<ServiceCategory>? categories,
    List<ServiceItem>? items,
  }) {
    return ServiceCardGroup(
      cardWid: cardWid ?? this.cardWid,
      cardName: cardName ?? this.cardName,
      categories: categories ?? this.categories,
      items: items ?? this.items,
    );
  }

  ServiceCardGroup replaceCategoryItems(
    ServiceCategory category,
    List<ServiceItem> categoryItems,
  ) {
    final normalizedTypeId = category.typeId.trim();
    final nextItems = items.where((item) {
      return item.typeId.trim() != normalizedTypeId;
    }).toList();
    nextItems.addAll(categoryItems);
    return copyWith(items: nextItems);
  }

  Map<String, List<ServiceItem>> get itemsByCategory {
    final result = <String, List<ServiceItem>>{};
    for (final item in items) {
      result.putIfAbsent(item.typeId, () => []).add(item);
    }
    return result;
  }

  List<ServiceItem> itemsForCategory(ServiceCategory category) {
    final direct = items
        .where((item) => item.typeId == category.typeId)
        .toList();
    if (direct.isNotEmpty) {
      return direct;
    }

    final normalizedName = _normalizeCategoryName(category.typeName);
    if (normalizedName.isEmpty) {
      return const [];
    }

    return items.where((item) {
      return _normalizeCategoryName(item.typeName) == normalizedName;
    }).toList();
  }

  int categoryCount(ServiceCategory category) {
    final actual = itemsForCategory(category).length;
    return actual > 0 ? actual : category.count;
  }

  static String _normalizeCategoryName(String? value) {
    return (value ?? '').replaceAll(RegExp(r'\s+'), '').trim();
  }
}
