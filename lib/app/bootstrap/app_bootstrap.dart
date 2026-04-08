import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../integrations/school_portal/school_portal_gateway.dart';
import '../../modules/auth/data/credential_vault.dart';
import '../di/app_providers.dart';

class AppBootstrap {
  const AppBootstrap._(this.overrides);

  final List<Object> overrides;

  static Future<AppBootstrap> initialize() async {
    await initializeDateFormatting('zh_CN');
    final preferences = await SharedPreferences.getInstance();

    return AppBootstrap._([
      sharedPreferencesProvider.overrideWithValue(preferences),
    ]);
  }

  static Future<AppBootstrap> testing() async {
    await initializeDateFormatting('zh_CN');
    final preferences = await SharedPreferences.getInstance();

    return AppBootstrap._([
      sharedPreferencesProvider.overrideWithValue(preferences),
      credentialVaultProvider.overrideWithValue(InMemoryCredentialVault()),
      schoolPortalGatewayProvider.overrideWithValue(
        TestingSchoolPortalGateway(),
      ),
    ]);
  }
}
