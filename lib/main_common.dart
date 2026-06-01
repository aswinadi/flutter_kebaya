import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/app_config.dart';
import 'providers/auth_provider.dart';
import 'providers/inventory_provider.dart';
import 'providers/rental_provider.dart';
import 'providers/job_order_provider.dart';
import 'screens/login_screen.dart';
import 'services/api_service.dart';

void mainCommon(AppConfig config) {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set default API baseUrl based on the environment configuration
  ApiService().updateBaseUrl(config.apiBaseUrl);

  runApp(MyApp(config: config));
}

class MyApp extends StatelessWidget {
  final AppConfig config;

  const MyApp({super.key, required this.config});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AppConfig>.value(value: config),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => InventoryProvider()),
        ChangeNotifierProvider(create: (_) => RentalProvider()),
        ChangeNotifierProvider(create: (_) => JobOrderProvider()),
      ],
      child: MaterialApp(
        title: 'Caroline Lauda Portal',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.purple[900]!,
            primary: Colors.purple[900]!,
            secondary: const Color(0xFFD4AF37),
          ),
          useMaterial3: true,
          scaffoldBackgroundColor: Colors.grey[50],
          appBarTheme: const AppBarTheme(
            elevation: 0.5,
            centerTitle: false,
          ),
        ),
        builder: (context, child) {
          // If we are in Development, wrap with a banner showing environment status (Premium touch!)
          if (config.environmentName.toLowerCase() == 'development') {
            return Banner(
              message: 'DEV',
              location: BannerLocation.topEnd,
              color: Colors.redAccent,
              child: child!,
            );
          }
          return child!;
        },
        home: const LoginScreen(),
      ),
    );
  }
}
