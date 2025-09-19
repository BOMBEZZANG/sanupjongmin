import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'splash_screen.dart';
import 'home.dart';
import 'setting.dart';
import 'ad_state.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // AdMob 초기화 및 어댑터 상태 확인
  final initializationStatus = await MobileAds.instance.initialize();
    MobileAds.instance.updateRequestConfiguration(
    RequestConfiguration(
      testDeviceIds: ['090C3965-9B2E-425C-9DB4-BE0474175434'], // testDeviceIds가 맞습니다!
    ),
  );

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
);

  // 디버그용: 어댑터 로드 상태 출력
  print("=== ADAPTER INITIALIZATION STATUS ===");
  initializationStatus.adapterStatuses.forEach((key, value) {
    print("$key: ${value.state.name}");
    if (key.toLowerCase().contains('unity')) {
      print(">>> Unity Ads 어댑터 발견!");
    }
  });
  print("=====================================");
  
  await initializeDateFormatting('ko_KR', null);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AdState>(create: (_) => AdState()),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '산업안전기사 기출문제',
      theme: ThemeData(
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
        scaffoldBackgroundColor: Color(0xFFf2f4f8),
      ),
      themeMode: ThemeMode.light,
      home: SplashScreen(
        onThemeChanged: (_) {},
      ),
    );
  }
}