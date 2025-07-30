import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:dhgc_flutter_google_map/src/core/utils/configs/api_configs.dart';
import 'package:dhgc_flutter_google_map/src/core/utils/constants/env_variables.dart';
import 'package:dhgc_flutter_google_map/src/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load keys from .env
  await dotenv.load().then((_) {
    // Initialize API configurations
    ApiConfigs.apiKeyGoogleMaps = dotenv.get(EnvVariables.apiKeyGoogleMaps);
  });

  runApp(const MyApp());
}
