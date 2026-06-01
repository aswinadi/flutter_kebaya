import 'config/app_config.dart';
import 'main_common.dart';

void main() {
  // Default fallback entry point for standard IDE run configurations.
  // Routes to Development environment settings.
  final config = AppConfig(
    apiBaseUrl: 'https://biogeographic-raylan-interdentally.ngrok-free.dev', // Default development Ngrok host
    environmentName: 'Development',
  );
  mainCommon(config);
}
