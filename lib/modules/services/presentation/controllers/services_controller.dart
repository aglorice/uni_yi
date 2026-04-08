import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/di/app_providers.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/result/result.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../domain/entities/service_card_data.dart';

final servicesControllerProvider =
    AsyncNotifierProvider<ServicesController, ServicesState>(
      ServicesController.new,
    );

class ServicesState {
  const ServicesState({
    required this.groups,
    this.loadingCategoryKeys = const {},
    this.loadedCategoryKeys = const {},
    this.categoryErrors = const {},
  });

  final List<ServiceCardGroup> groups;
  final Set<String> loadingCategoryKeys;
  final Set<String> loadedCategoryKeys;
  final Map<String, String> categoryErrors;

  static const empty = ServicesState(groups: []);

  ServicesState copyWith({
    List<ServiceCardGroup>? groups,
    Set<String>? loadingCategoryKeys,
    Set<String>? loadedCategoryKeys,
    Map<String, String>? categoryErrors,
  }) {
    return ServicesState(
      groups: groups ?? this.groups,
      loadingCategoryKeys: loadingCategoryKeys ?? this.loadingCategoryKeys,
      loadedCategoryKeys: loadedCategoryKeys ?? this.loadedCategoryKeys,
      categoryErrors: categoryErrors ?? this.categoryErrors,
    );
  }

  bool isCategoryLoading(ServiceCardGroup group, ServiceCategory category) {
    return loadingCategoryKeys.contains(_categoryKey(group, category));
  }

  bool isCategoryLoaded(ServiceCardGroup group, ServiceCategory category) {
    return loadedCategoryKeys.contains(_categoryKey(group, category));
  }

  String? categoryError(ServiceCardGroup group, ServiceCategory category) {
    return categoryErrors[_categoryKey(group, category)];
  }

  static String categoryKeyFor(String cardWid, String typeId) {
    return '$cardWid::$typeId';
  }

  static String _categoryKey(ServiceCardGroup group, ServiceCategory category) {
    return categoryKeyFor(group.cardWid, category.typeId);
  }
}

class ServicesController extends AsyncNotifier<ServicesState> {
  @override
  Future<ServicesState> build() async {
    return _load();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_load);
  }

  Future<void> ensureCategoryLoaded(
    ServiceCardGroup group,
    ServiceCategory category, {
    bool forceRefresh = false,
  }) async {
    final currentState = state.asData?.value;
    if (currentState == null) {
      return;
    }

    final key = ServicesState.categoryKeyFor(group.cardWid, category.typeId);
    final matchingGroup = _findGroup(currentState.groups, group.cardWid);
    if (matchingGroup == null) {
      return;
    }

    final hasItems = matchingGroup.itemsForCategory(category).isNotEmpty;
    final isLoaded = currentState.loadedCategoryKeys.contains(key);
    final isLoading = currentState.loadingCategoryKeys.contains(key);
    if (!forceRefresh && (hasItems || isLoaded || isLoading)) {
      return;
    }

    final nextLoadingKeys = <String>{...currentState.loadingCategoryKeys, key};
    final nextErrors = <String, String>{...currentState.categoryErrors}
      ..remove(key);
    state = AsyncData(
      currentState.copyWith(
        loadingCategoryKeys: nextLoadingKeys,
        categoryErrors: nextErrors,
      ),
    );

    final authState = await ref.read(authControllerProvider.future);
    final session = authState.session;
    if (session == null) {
      _finishCategoryLoadWithError(key, '当前未登录，无法加载服务分类。');
      return;
    }

    final result = await ref
        .read(schoolPortalGatewayProvider)
        .fetchServiceCategoryItems(
          session,
          cardWid: group.cardWid,
          category: category,
        );

    if (result case FailureResult<List<ServiceItem>>(failure: final failure)) {
      _finishCategoryLoadWithError(key, failure.message);
      return;
    }

    final latestState = state.asData?.value;
    if (latestState == null) {
      return;
    }

    final updatedGroups = latestState.groups.map((candidate) {
      if (candidate.cardWid != group.cardWid) {
        return candidate;
      }
      return candidate.replaceCategoryItems(category, result.requireValue());
    }).toList();

    final finalLoadingKeys = <String>{...latestState.loadingCategoryKeys}
      ..remove(key);
    final finalLoadedKeys = <String>{...latestState.loadedCategoryKeys, key};
    final finalErrors = <String, String>{...latestState.categoryErrors}
      ..remove(key);
    state = AsyncData(
      latestState.copyWith(
        groups: updatedGroups,
        loadingCategoryKeys: finalLoadingKeys,
        loadedCategoryKeys: finalLoadedKeys,
        categoryErrors: finalErrors,
      ),
    );
  }

  Future<ServicesState> _load() async {
    final authState = await ref.watch(authControllerProvider.future);
    final session = authState.session;
    if (session == null) {
      throw const AuthenticationFailure('当前未登录，无法加载校园服务。');
    }

    final gateway = ref.read(schoolPortalGatewayProvider);
    final result = await gateway.fetchServiceCards(session);
    if (result case FailureResult<List<ServiceCardGroup>>(
      failure: final failure,
    )) {
      throw failure;
    }
    final groups = result.requireValue();
    return ServicesState(
      groups: groups,
      loadedCategoryKeys: _collectLoadedCategoryKeys(groups),
    );
  }

  Set<String> _collectLoadedCategoryKeys(List<ServiceCardGroup> groups) {
    final keys = <String>{};
    for (final group in groups) {
      for (final category in group.categories) {
        if (group.itemsForCategory(category).isNotEmpty) {
          keys.add(
            ServicesState.categoryKeyFor(group.cardWid, category.typeId),
          );
        }
      }
    }
    return keys;
  }

  ServiceCardGroup? _findGroup(List<ServiceCardGroup> groups, String cardWid) {
    for (final group in groups) {
      if (group.cardWid == cardWid) {
        return group;
      }
    }
    return null;
  }

  void _finishCategoryLoadWithError(String key, String message) {
    final latestState = state.asData?.value;
    if (latestState == null) {
      return;
    }

    final nextLoadingKeys = <String>{...latestState.loadingCategoryKeys}
      ..remove(key);
    final nextErrors = <String, String>{
      ...latestState.categoryErrors,
      key: message,
    };
    state = AsyncData(
      latestState.copyWith(
        loadingCategoryKeys: nextLoadingKeys,
        categoryErrors: nextErrors,
      ),
    );
  }
}
