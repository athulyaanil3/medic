
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';

import 'providers/calorie_journal.dart';
import 'providers/medicine_catalog.dart';

import 'screens/app_shell.dart';

import 'services/local_store.dart';
import 'services/notification_service.dart';
import 'services/voice_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await LocalStore.init();

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    await initNotifications();
  } catch (e) {
    debugPrint("Initialization Error: $e");
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => MedicineCatalog(),
        ),

        ChangeNotifierProvider(
          create: (_) => VoiceService(),
        ),

        ChangeNotifierProvider(
          create: (_) => CalorieJournal(),
        ),
      ],

      child: MaterialApp(
        debugShowCheckedModeBanner: false,

        title: 'MediVoice AI',

        theme: ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: const Color(0xFFAED9D5),
        ),

        home: const AppShell(),
      ),
    );
  }
}

