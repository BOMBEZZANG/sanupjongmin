import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart'; // 추가된 import
import 'splash_screen.dart';
import 'home.dart';
import 'setting.dart';
// import 'ad_helper.dart'; // ad_helper.dart는 home.dart 등에서 사용되므로 여기서는 직접 필요 없을 수 있음
import 'ad_state.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MobileAds.instance.initialize();
  await initializeDateFormatting('ko_KR', null); // 추가된 라인: 한국어 로케일 초기화

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
      title: '산업안전기사 기출문제', // 앱 제목은 '위험물산업기사'에서 '산업안전기사'로 변경되어 있을 수 있습니다.
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