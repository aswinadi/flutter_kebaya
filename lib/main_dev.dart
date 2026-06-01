import 'config/app_config.dart';
import 'main_common.dart';

void main() {
  final config = AppConfig(
    apiBaseUrl: 'https://biogeographic-raylan-interdentally.ngrok-free.dev',
    environmentName: 'Development',
  );
  mainCommon(config);
}
