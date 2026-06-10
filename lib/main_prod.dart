import 'config/app_config.dart';
import 'main_common.dart';

Future<void> main() async {
  const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://gown.maxmar.net',
  );

  final config = AppConfig(
    apiBaseUrl: apiBaseUrl,
    environmentName: 'Production',
  );
  await mainCommon(config);
}
