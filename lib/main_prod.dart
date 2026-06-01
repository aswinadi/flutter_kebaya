import 'config/app_config.dart';
import 'main_common.dart';

void main() {
  const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://gown.maxmar.net',
  );

  final config = AppConfig(
    apiBaseUrl: apiBaseUrl,
    environmentName: 'Production',
  );
  mainCommon(config);
}
