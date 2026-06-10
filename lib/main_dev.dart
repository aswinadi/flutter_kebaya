import 'config/app_config.dart';
import 'main_common.dart';

Future<void> main() async {
  final config = AppConfig(
    apiBaseUrl: 'https://biogeographic-raylan-interdentally.ngrok-free.dev',
    environmentName: 'Development',
  );
  await mainCommon(config);
}
