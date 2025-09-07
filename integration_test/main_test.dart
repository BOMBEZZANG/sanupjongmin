import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sanupjongmin/home.dart';
import 'package:sanupjongmin/ad_state.dart';
import 'package:sanupjongmin/ad_config.dart' as ad_config;

// 테스트용 더미 AdState 클래스
class TestAdState extends AdState {
  TestAdState({bool adsRemoved = true}) {
    // 테스트 환경에서는 광고를 기본적으로 제거된 상태로 설정
    _adsRemoved = adsRemoved;
    _isInitialized = true; // 초기화 완료로 즉시 설정
    print('TestAdState initialized with adsRemoved: $_adsRemoved');
  }

  bool _adsRemoved = true;
  bool _isInitialized = true;

  @override
  bool get adsRemoved => _adsRemoved;

  @override
  Future<bool> get isInitialized async => _isInitialized;

  // 테스트 환경에서는 실제 초기화 로직을 건너뜀
  @override
  void _initializeAdState() {
    // 아무것도 하지 않음 - SharedPreferences 접근 등을 건너뜀
    print('TestAdState: Skipping real initialization');
  }

  // 다른 메서드들도 필요시 오버라이드
  @override
  void removeAds() {
    _adsRemoved = true;
    notifyListeners();
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 테스트 환경 감지
  const bool isTestMode = bool.fromEnvironment('DISABLE_ADS', defaultValue: false);
  
  late AdState adState;
  
  if (isTestMode) {
    // 테스트 모드: 더미 AdState 사용
    print('main_test.dart: Running in test mode - using TestAdState');
    adState = TestAdState(adsRemoved: true);
    
    // 글로벌 변수 즉시 설정 (초기화 대기 불필요)
    ad_config.adsRemovedGlobal = true;
    print('main_test.dart: adsRemovedGlobal set to: true (test mode)');
  } else {
    // 일반 모드: 실제 AdState 사용
    print('main_test.dart: Running in normal mode - using real AdState');
    adState = AdState();
    
    // 실제 AdState 초기화 대기
    await adState.isInitialized;
    ad_config.adsRemovedGlobal = adState.adsRemoved;
    print('main_test.dart: adsRemovedGlobal set to: ${ad_config.adsRemovedGlobal} (normal mode)');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AdState>.value(
          value: adState,
        ),
      ],
      child: MyTestApp(),
    ),
  );
}

class MyTestApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo - Test',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: HomePage(),
    );
  }
}