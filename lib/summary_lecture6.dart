import 'dart:io';
import 'package:path_provider/path_provider.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter/services.dart';
import 'dart:async'; // StreamSubscription을 위해 추가
import 'dart:typed_data';
import 'database_helper.dart';
import 'home.dart';
import 'constants.dart';
import 'ad_helper.dart';
import 'ad_state.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'config.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

// 학습노트 데이터 (기존과 동일)
final Map<String, Map<String, dynamic>> studyNotes = {
  '1. 거푸집·동바리·콘크리트 작업 안전': {
    'description': ''' - 파이프서포트가 높이 3.5 m를 초과하면 2 m 이내마다 양 방향 수평연결재를 설치해 좌굴을 억제한다.
 - 동바리 침하 방지는 하중 분산용 깔목, 지반 보강용 말뚝박기, 기초 콘크리트 타설 등 ‘지지력 확보’로 접근한다. 수평연결재는 침하 대책이 아닌 ‘횡방향 안정’ 대책이다.
 - 콘크리트 타설 중에는 거푸집·동바리의 변형·변위·침하 여부를 전담 감시자가 수시 확인하고, 이상 발생 시 즉시 작업을 중지‧대피 후 보강한다.
 - 해체 순서는 연직부재(기둥·벽)→수평부재(슬래브) 순으로 진행해 상부 하중을 안전하게 전달-제거한다.
 - 시스템 거푸집(갱폼·슬립폼·클라이밍폼)은 작업발판과 거푸집을 일체화해 고층부 시공 안전과 작업성을 높이지만, 유로폼은 ‘일체형 거푸집’ 범주에 포함되지 않는다.
 - 좌굴하중 산정 시 오일러 공식 Pcr = π²EI/(KL)²를 적용하며, 힌지-힌지 기둥의 좌굴길이는 실길이와 같다(K=1).''',
    'related_questions': [
      {'date': '2022년 4월', 'question_id': 101},
      {'date': '2022년 4월', 'question_id': 119},
      {'date': '2022년 3월', 'question_id': 102},
      {'date': '2022년 3월', 'question_id': 105},
      {'date': '2021년 8월', 'question_id': 101},
      {'date': '2021년 8월', 'question_id': 102},
      {'date': '2021년 8월', 'question_id': 110},
    ],
  },
  '2. 비계 및 작업발판 설치 기준': {
    'description': ''' - 이동식 비계 작업발판 최대 적재하중: 250 kg 이하, 작업 시 이동 금지, 주행바퀴에는 제동장치 부착.
 - 강관틀비계: 높이 20 m 초과·중량 작업 시 주틀 간 간격 ≤1.8 m, 단관비계 벽이음 간격은 수직·수평 모두 5 m 이하.
 - 작업발판 폭: 40 cm 이상, 장선 위 겹침 이음은 20 cm 이상.
 - 강관비계 기둥 간 적재하중은 400 kg 이하로 제한해 국부 과부하를 방지한다.
 - 벽 연결부, 가새, 난간 등을 통해 2 m 이상 비계에는 추락방지 설비를 추가한다.''',
    'related_questions': [
      {'date': '2022년 4월', 'question_id': 109},
      {'date': '2022년 3월', 'question_id': 115},
      {'date': '2022년 3월', 'question_id': 116},
      {'date': '2021년 8월', 'question_id': 113},
      {'date': '2021년 8월', 'question_id': 117},
    ],
  },
  '3. 사다리·가설통로·승강로 구조 기준': {
    'description': ''' - 사다리식 통로 폭 ≥30 cm, 고정식 사다리 최대 기울기 90 °(수직), 길이 10 m 이상이면 9 m(수직갱은 10 m) 이내마다 계단참 설치.
 - 가설통로 경사 15 ° 초과 시 미끄럼 방지, 경사 30 ° 초과 시 계단형으로 시공.
 - 통로발판 겹침 이음은 반드시 장선 위에서 20 cm 이상, 발판·난간·발끝막이를 갖춘다.
 - 철골 고정 승강로 답단 간격 ≤30 cm, 화물차 승강설비 높이가 2 m 이상이면 난간·발판 등 안전조치를 설치한다.''',
    'related_questions': [
      {'date': '2022년 4월', 'question_id': 105},
      {'date': '2022년 4월', 'question_id': 114},
      {'date': '2022년 4월', 'question_id': 115},
      {'date': '2022년 3월', 'question_id': 103},
      {'date': '2022년 3월', 'question_id': 120},
      {'date': '2022년 3월', 'question_id': 111},
      {'date': '2021년 8월', 'question_id': 109},
      {'date': '2021년 8월', 'question_id': 118},
    ],
  },
  '4. 추락방지 설비 및 달비계 관리': {
    'description': ''' - 작업발판 설치가 곤란할 경우 추락방호망을 설치해 낙하 에너지를 흡수한다.
 - 안전난간: 상단 난간대 높이 90 ~ 120 cm, 중간 난간대, 발끝막이판 높이 ≥10 cm.
 - 매듭방망(그물코 5 cm) 신품 인장강도 ≥110 kg, 사용 중 이음·손상 여부를 주기적으로 점검.
 - 달비계 안전계수: 달기 훅 ≥5, 와이어·강선 ≥10, 체인 ≥4. 와이어로프 한 꼬임당 소선 단선이 10 % 이상이면 즉시 폐기.''',
    'related_questions': [
      {'date': '2022년 3월', 'question_id': 104},
      {'date': '2021년 8월', 'question_id': 105},
      {'date': '2021년 8월', 'question_id': 112},
      {'date': '2021년 8월', 'question_id': 119},
      {'date': '2022년 4월', 'question_id': 120},
    ],
  },
  '5. 건설기계·양중장치 안전 및 풍속 기준': {
    'description': ''' - 고소작업대 와이어·체인 안전율 ≥5, 이동 시 작업자는 승강부에서 하차 후 이동.
 - 항타기·항발기: 증기·공기 차단밸브는 ‘작업자가 쉽게 접근할 수 없는’ 위치에 설치, 권상 로프는 최저 위치 기준 드럼에 2회 이상 감기도록 여유장 확보.
 - 타워크레인 필수 안전장치: 권과방지, 과부하방지, 비상정지, 풍속계 등.
 - 옥외 주행크레인: 순간풍속 30 m/s 초과 우려 시 이탈방지조치, 건설용 리프트는 35 m/s 초과 시 받침 추가·운전 중지.
 - 차량계 건설기계 작업계획서 필수 항목: 기종·성능, 운행경로, 작업방법 등이며 유지보수 방법은 별도 관리계획으로 분리.''',
    'related_questions': [
      {'date': '2022년 4월', 'question_id': 102},
      {'date': '2022년 4월', 'question_id': 106},
      {'date': '2022년 4월', 'question_id': 108},
      {'date': '2022년 4월', 'question_id': 111},
      {'date': '2022년 3월', 'question_id': 109},
      {'date': '2021년 8월', 'question_id': 107},
      {'date': '2021년 8월', 'question_id': 113},
      {'date': '2021년 8월', 'question_id': 104},
    ],
  },
  '6. 유해·위험방지계획서 제출 요건': {
    'description': ''' - 제출 시기: 건설공사 착공 ‘전날까지’ 고용노동부장관(관할청)에 제출.
 - 대상 공사: 터널, 깊이 10 m 이상 굴착, 높이 31 m 이상 건축물, 연면적 5000 m² 이상 특정 용도 시설 등. 냉동·냉장창고(연면적 3000 m²)나 40 m 길이 교량은 비대상.
 - 첨부서류: 공정표·안전관리조직도·안전시설 배치도 등이 필수이나 ‘작업인부 배치도’는 요구되지 않는다.''',
    'related_questions': [
      {'date': '2022년 4월', 'question_id': 103},
      {'date': '2022년 4월', 'question_id': 107},
      {'date': '2022년 3월', 'question_id': 101},
      {'date': '2021년 8월', 'question_id': 108},
    ],
  },
  '7. 산업안전보건관리비 및 안전관리자': {
    'description': ''' - 적용 대상: 총 공사금액 2 천만 원 이상(전기·정보통신공사 제외).
 - 안전관리자 배치: 공사금액 800 억 원 이상 → 2명 이상, 금액·공정률에 따라 추가 배치.
 - 안전관리비 사용 범위
• 기능성 보호장구(혹한·혹서 노출 특정 근로자) 및 재해예방용 CCTV 설치 가능.
• 공사용 기계·민원대책용 가설물·감리원 보호구 등은 사용 불가.''',
    'related_questions': [
      {'date': '2022년 4월', 'question_id': 117},
      {'date': '2022년 4월', 'question_id': 118},
      {'date': '2022년 3월', 'question_id': 108},
      {'date': '2021년 8월', 'question_id': 115},
    ],
  },
  '8. 지반 굴착·흙막이·사면 안정': {
    'description': ''' - 토사붕괴 요인: 경사 증대, 성토 높이·상재하중 증가, 지하수 상승 등. ‘토사중량 감소’는 위험을 줄이는 요인.
 - 흙막이 지보공 구성: 흙막이판, 띠장, 말뚝, 버팀보 등. 턴버클은 인장 조정 부속품일 뿐 주 부재가 아니다.
 - 히빙 방지: 흙막이벽 근입 깊이 증가, 굴착 전면 잔토 남기기, 기초콘크리트 선시공 등으로 파괴면 전단저항 확보.
 - 연암 굴착 안전 기울기: 1 : 1.0(45 °) 정도가 일반 기준.
 - 사면 안전 대책: 배수로 설치로 지표·지하수 침투 차단, 안정구배 확보, 지반개량(약액·프리팩·샌드드레인) 등, 옹벽은 ‘지반개량 공법’이 아니다.
 - 사면 파괴 형태: 사면내·선단·저부 파괴가 대표적이고 ‘사면 인장파괴’는 원형활동면 파괴 범주에 포함되지 않는다.
 - 흙의 전단응력 증대 요인: 과재하, 굴착면 경사 증가, 함수비 감소로 인한 강도 증가는 있지만 ‘단위체적중량 감소’가 직접 증가 요인은 아니다.
 - 버팀보·앵커 축하중 계측에는 로드셀을 사용해 지지효과 변화를 실시간 확인한다.''',
    'related_questions': [
      {'date': '2022년 4월', 'question_id': 110},
      {'date': '2022년 4월', 'question_id': 112},
      {'date': '2022년 3월', 'question_id': 110},
      {'date': '2022년 3월', 'question_id': 112},
      {'date': '2022년 3월', 'question_id': 117},
      {'date': '2022년 3월', 'question_id': 118},
      {'date': '2021년 8월', 'question_id': 106},
      {'date': '2021년 8월', 'question_id': 116},
      {'date': '2021년 8월', 'question_id': 103},
    ],
  },
  '9. 터널 발파 및 암질 판별': {
    'description': ''' - 점화회선은 다른 동력·조명 회선과 분리하여 노출·혼선을 방지한다.
 - 암질 판별 지표: RQD(코어 절리율), 탄성파 속도, RMR(암반등급) 등을 이용하며 ‘전단강도’는 설계·안정 계산용 물성치로 판별 지표가 아니다.''',
    'related_questions': [
      {'date': '2022년 4월', 'question_id': 116},
      {'date': '2021년 8월', 'question_id': 120},
    ],
  },
  '10. 작업장 환경·출입구·하역·운반': {
    'description': ''' - 출입구는 장비용·보행용을 분리해 충돌을 예방한다.
 - 근로자 상시 작업면 조도: 초정밀 750 lx 이상, 정밀 300 lx, 보통 150 lx, 기타 75 lx 이상.
 - 화물을 인력 인양 시 등은 곧게, 다리 힘을 활용, 물체는 몸 가까이, 직선 운반이 원칙이며 화물 중간 빼내기 작업은 금지.
 - 곡선 운반·허리 90 ° 수평자세·중간 화물 빼내기는 재해위험을 높인다.''',
    'related_questions': [
      {'date': '2022년 3월', 'question_id': 106},
      {'date': '2022년 3월', 'question_id': 107},
      {'date': '2022년 3월', 'question_id': 119},
      {'date': '2021년 8월', 'question_id': 111},
      {'date': '2021년 8월', 'question_id': 114},
    ],
  },
  '11. 가설구조물의 특성 및 문제점': {
    'description': ''' - 용도는 임시·한시적이므로 경제성·시공성이 우선, 구조 해석이 단순화되기 쉬워 부재 단면이 부족하거나 연결부가 취약할 수 있다.
 - 해체‧재사용을 전제로 가볍고 조립이 간단하지만, ‘연결부가 견고하다’·‘정밀도가 높다’는 통상적 특징이 아니다.''',
    'related_questions': [
      {'date': '2022년 4월', 'question_id': 113},
      {'date': '2022년 3월', 'question_id': 114},
    ],
  },
};

class SummaryLecture6Page extends StatefulWidget {
  final String dbPath;

  SummaryLecture6Page({required this.dbPath});

  @override
  _SummaryLecture6PageState createState() => _SummaryLecture6PageState();
}

class _SummaryLecture6PageState extends State<SummaryLecture6Page>
    with WidgetsBindingObserver {
  late DatabaseHelper dbHelper;
  bool isLoading = false;

  // 오디오 플레이어 관련 변수
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  bool _isAudioLoading = true;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  String _errorMessage = '';
  final List<double> _speedOptions = [0.8, 1.0, 1.2, 1.5, 2.0];
  double _currentSpeed = 1.0;
  bool _isAudioInitialized = false; // 오디오 초기화 상태 추가

  // 오디오 플레이어 리스너 구독을 관리하기 위한 변수 추가
  StreamSubscription? _playerStateSubscription;
  StreamSubscription? _durationSubscription;
  StreamSubscription? _positionSubscription;
  StreamSubscription? _processingStateSubscription;

  // 테스트 모드 관련 변수 추가
  bool _isTestMode = false;
  Timer? _testModeTimer;
  static const Duration _testModeDuration = Duration(seconds: 10);

  // 광고 관련 변수 추가
  InterstitialAd? _interstitialAd;
  bool _isInterstitialAdLoaded = false;
  int _lastAdShowTime = 0;
  final int _adInterval = 240;
  bool _isAdShowing = false;
  bool _wasPlayingBeforeAd = false;
  int _adRetryCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // 테스트 모드 감지
    _isTestMode =
        const bool.fromEnvironment('DISABLE_ADS', defaultValue: false);
    print('SummaryLecture6Page: Test mode enabled: $_isTestMode');

    dbHelper = DatabaseHelper(widget.dbPath);

    // 오디오 초기화를 별도로 실행하여 UI 렌더링을 차단하지 않도록 함
    _initAudioPlayerAsync();

    // 광고 로드는 별도로 실행
    Future.microtask(() {
      if (mounted) {
        _loadInterstitialAd();
      }
    });
  }

  // 오디오 초기화를 비동기로 처리
  void _initAudioPlayerAsync() {
    // UI는 즉시 표시되도록 하고, 오디오 초기화는 백그라운드에서 처리
    Future.microtask(() async {
      if (mounted) {
        await _initAudioPlayer();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    // 테스트 모드 타이머 정리
    _cancelTestModeTimer();

    // 가장 먼저 오디오 플레이어 중지 및 구독 취소
    _audioPlayer.stop(); // 플레이를 즉시 멈춤
    _playerStateSubscription?.cancel();
    _playerStateSubscription = null;
    _durationSubscription?.cancel();
    _durationSubscription = null;
    _positionSubscription?.cancel();
    _positionSubscription = null;
    _processingStateSubscription?.cancel();
    _processingStateSubscription = null;

    _audioPlayer.dispose(); // 그 다음 플레이어 리소스 해제
    dbHelper.dispose();
    _interstitialAd?.dispose(); // 광고 리소스 해제
    super.dispose();
  }

  // 테스트 모드 타이머 시작
  void _startTestModeTimer() {
    if (!_isTestMode) return;

    _cancelTestModeTimer(); // 기존 타이머가 있다면 취소

    print(
        'SummaryLecture6Page: Starting test mode timer: ${_testModeDuration.inSeconds} seconds');
    _testModeTimer = Timer(_testModeDuration, () {
      print('SummaryLecture6Page: Test mode timer expired - stopping audio');
      if (mounted && _isPlaying) {
        _audioPlayer.pause();
      }
    });
  }

  // 테스트 모드 타이머 취소
  void _cancelTestModeTimer() {
    if (_testModeTimer != null) {
      print('SummaryLecture6Page: Cancelling test mode timer');
      _testModeTimer!.cancel();
      _testModeTimer = null;
    }
  }

  void _loadInterstitialAd() {
    if (!mounted) return; // 메서드 시작 시 mounted 확인

    print("DEBUG: 전면 광고 로드 시도 (시도 횟수: $_adRetryCount)");
    final adState = Provider.of<AdState>(context, listen: false);
    if (adState.adsRemoved || kDisableAdsForTesting) {
      print("DEBUG: 광고 제거됨 또는 테스트 모드임");
      return;
    }

    InterstitialAd.load(
      adUnitId: AdHelper.interstitialAdUnitId,
      request: AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          if (!mounted) {
            // 콜백 내에서도 mounted 확인
            ad.dispose(); // 로드되었지만 페이지가 사라졌으면 광고도 해제
            return;
          }
          print("DEBUG: 전면 광고 로드 성공");
          setState(() {
            _interstitialAd = ad;
            _isInterstitialAdLoaded = true;
            _adRetryCount = 0;
          });

          _interstitialAd!.fullScreenContentCallback =
              FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              if (!mounted) return;
              print("DEBUG: 광고 닫힘");
              ad.dispose();
              setState(() {
                _isInterstitialAdLoaded = false;
                _isAdShowing = false;
              });

              if (_wasPlayingBeforeAd) {
                _audioPlayer.play();
              }

              if (!adState.adsRemoved && !kDisableAdsForTesting) {
                if (mounted) _loadInterstitialAd();
              }
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              if (!mounted) return;
              print("DEBUG: 광고 표시 실패: $error");
              ad.dispose();
              setState(() {
                _isInterstitialAdLoaded = false;
                _isAdShowing = false;
              });

              if (_wasPlayingBeforeAd) {
                _audioPlayer.play();
              }

              if (!adState.adsRemoved && !kDisableAdsForTesting) {
                if (mounted) _loadInterstitialAd();
              }
            },
            onAdShowedFullScreenContent: (ad) {
              print("DEBUG: 광고 전체화면으로 표시됨");
            },
          );
        },
        onAdFailedToLoad: (error) {
          if (!mounted) return;
          print('DEBUG: 전면 광고 로드 실패: $error');
          setState(() => _isInterstitialAdLoaded = false);

          _adRetryCount++;
          Future.delayed(Duration(seconds: 30), () {
            if (mounted) _loadInterstitialAd();
          });

          if (_isAdShowing && _wasPlayingBeforeAd) {
            if (mounted) {
              setState(() => _isAdShowing = false);
              _audioPlayer.play();
            }
          }
        },
      ),
    );
  }

  // _initAudioPlayer 메서드를 다음과 같이 완전히 교체하세요:

  Future<void> _initAudioPlayer() async {
    try {
      print('DEBUG: 오디오 플레이어 초기화 시작');

      if (!mounted) return;

      setState(() {
        _isAudioLoading = true;
        _errorMessage = '';
      });

      // 방법 1: AssetSource 직접 사용 (가장 권장되는 방법)
      try {
        print('DEBUG: AssetSource로 오디오 로딩 시도');

        // 경로에서 'assets/' 제거하고 시도
        await _audioPlayer.setAudioSource(
          AudioSource.asset('audio/summary/lecture1.mp3'),
          preload: true,
        );
        print('DEBUG: AssetSource 오디오 로딩 성공');
      } catch (assetError) {
        print('DEBUG: AssetSource 실패: $assetError');

        // 방법 2: 다른 경로로 시도
        try {
          print('DEBUG: 전체 경로로 AssetSource 시도');
          await _audioPlayer.setAudioSource(
            AudioSource.asset('assets/audio/summary/lecture6.mp3'),
            preload: true,
          );
          print('DEBUG: 전체 경로 AssetSource 성공');
        } catch (fullPathError) {
          print('DEBUG: 전체 경로도 실패: $fullPathError');

          // 방법 3: BytesAudioSource (마지막 수단)
          try {
            print('DEBUG: BytesAudioSource로 fallback 시도');
            final ByteData data =
                await rootBundle.load('assets/audio/summary/lecture6.mp3');
            print('DEBUG: 오디오 파일 로드 성공, 크기: ${data.lengthInBytes} bytes');

            if (!mounted) return;

            final Uint8List bytes = data.buffer.asUint8List();

            // BytesAudioSource 사용 시 preload 제거
            await _audioPlayer.setAudioSource(BytesAudioSource(bytes));
            print('DEBUG: BytesAudioSource 오디오 설정 완료');
          } catch (bytesError) {
            print('DEBUG: BytesAudioSource도 실패: $bytesError');

            // 방법 4: 임시 파일로 저장 후 로드
            try {
              print('DEBUG: 임시 파일 방식 시도');
              await _loadAudioFromTempFile();
              print('DEBUG: 임시 파일 방식 성공');
            } catch (tempError) {
              print('DEBUG: 모든 방법 실패: $tempError');
              throw Exception('모든 오디오 로딩 방법이 실패했습니다: $tempError');
            }
          }
        }
      }

      if (!mounted) return;

      // 성공적으로 로드된 경우에만 리스너 설정
      await _setupAudioListeners();
      await _audioPlayer.setSpeed(_currentSpeed);

      if (!mounted) return;

      setState(() {
        _isAudioLoading = false;
        _isAudioInitialized = true;
      });

      print('DEBUG: 오디오 플레이어 초기화 완료');
    } catch (e) {
      print("DEBUG: 오디오 초기화 전체 오류: $e");
      if (mounted) {
        setState(() {
          _isAudioLoading = false;
          _errorMessage = '오디오 초기화 오류: $e';
          _isAudioInitialized = false;
        });
      }
    }
  }

// 임시 파일을 사용한 오디오 로딩 메서드 추가
  Future<void> _loadAudioFromTempFile() async {
    final ByteData data =
        await rootBundle.load('assets/audio/summary/lecture6.mp3');
    final Uint8List bytes = data.buffer.asUint8List();

    // 임시 디렉토리에 파일 저장
    final Directory tempDir = await getTemporaryDirectory();
    final File tempFile = File('${tempDir.path}/temp_lecture1.mp3');
    await tempFile.writeAsBytes(bytes);

    // 임시 파일로부터 오디오 로드
    await _audioPlayer.setAudioSource(AudioSource.file(tempFile.path));

    print('DEBUG: 임시 파일에서 오디오 로드 완료: ${tempFile.path}');
  }

// 오디오 리스너 설정을 별도 메서드로 분리
  Future<void> _setupAudioListeners() async {
    // 기존 구독이 있다면 취소
    await _cancelAudioSubscriptions();

    _playerStateSubscription = _audioPlayer.playerStateStream.listen((state) {
      if (!mounted) return;
      if (state.playing != _isPlaying) {
        setState(() {
          _isPlaying = state.playing;
        });
      }
    });

    _durationSubscription = _audioPlayer.durationStream.listen((d) {
      if (!mounted) return;
      if (d != null) {
        setState(() => _duration = d);
        print('DEBUG: 오디오 길이 설정: ${d.inMinutes}:${d.inSeconds % 60}');
      }
    });

    _positionSubscription = _audioPlayer.positionStream.listen((p) {
      if (!mounted) return;
      setState(() => _position = p);

      int currentPositionInSeconds = p.inSeconds;
      if (_isPlaying &&
          _isInterstitialAdLoaded &&
          !_isAdShowing &&
          currentPositionInSeconds > 0 &&
          currentPositionInSeconds - _lastAdShowTime >= _adInterval) {
        print(
            "DEBUG: 광고 표시 조건 충족. 현재 시간: $currentPositionInSeconds, 마지막 광고 시간: $_lastAdShowTime");
        if (mounted) {
          setState(() {
            _isAdShowing = true;
            _wasPlayingBeforeAd = _isPlaying;
          });
        }
        _audioPlayer.pause();
        _lastAdShowTime = currentPositionInSeconds;
        if (mounted) _showInterstitialAd();
      }
    });

    _processingStateSubscription =
        _audioPlayer.processingStateStream.listen((state) {
      if (!mounted) return;
      if (state == ProcessingState.completed) {
        _cancelTestModeTimer();
        setState(() {
          _isPlaying = false;
          _position = _duration;
        });
      }
    });
  }

// 구독 취소 메서드
  Future<void> _cancelAudioSubscriptions() async {
    _playerStateSubscription?.cancel();
    _playerStateSubscription = null;
    _durationSubscription?.cancel();
    _durationSubscription = null;
    _positionSubscription?.cancel();
    _positionSubscription = null;
    _processingStateSubscription?.cancel();
    _processingStateSubscription = null;
  }

  void _showInterstitialAd() {
    if (!mounted) return; // 메서드 시작 시 mounted 확인

    final adState = Provider.of<AdState>(context, listen: false);
    if (adState.adsRemoved || kDisableAdsForTesting) {
      print("DEBUG: 광고 표시 스킵 - 광고 제거됨 또는 테스트 모드");
      if (mounted) setState(() => _isAdShowing = false);
      if (_wasPlayingBeforeAd) {
        _audioPlayer.play();
      }
      return;
    }

    if (!_isInterstitialAdLoaded || _interstitialAd == null) {
      print("DEBUG: 광고 표시 실패 - 광고가 로드되지 않음");
      if (mounted) setState(() => _isAdShowing = false);
      if (_wasPlayingBeforeAd) {
        _audioPlayer.play();
      }
      if (mounted) _loadInterstitialAd();
      return;
    }

    print("DEBUG: 전면 광고 표시 시도");
    _interstitialAd!.show().catchError((error) {
      print("DEBUG: 광고 표시 중 오류 발생: $error");
      if (mounted) {
        setState(() => _isAdShowing = false);
        if (_wasPlayingBeforeAd) {
          _audioPlayer.play();
        }
        _loadInterstitialAd();
      }
    });
  }

  void _playPause() {
    if (!mounted || !_isAudioInitialized) return;

    if (_audioPlayer.playing) {
      // 일시정지 시 타이머 취소
      _cancelTestModeTimer();
      _audioPlayer.pause();
    } else {
      // 재생 시 테스트 모드에서 타이머 시작
      _audioPlayer.play();
      if (_isTestMode) {
        _startTestModeTimer();
      }
    }
  }

  void _changePlaybackSpeed(double speed) {
    if (!mounted || !_isAudioInitialized) return;
    setState(() {
      _currentSpeed = speed;
    });
    _audioPlayer.setSpeed(speed);
  }

// summary_lecture1.dart 파일

void _showQuestionDialog(BuildContext context, String date, int questionId) async {
  if (!mounted) return;

  // --- 제안해주신 로직 시작 ---

  // 1. 날짜 문자열 정규화 (예: '2022년 04월' -> '2022년 4월')
  // '04월'과 '4월'의 불일치 가능성을 처리합니다.
  final normalizedDate = date.replaceAll(' 0', ' ');

  // 2. 맵핑(constants.dart)을 통해 DB 파일 번호(examSession) 찾기
  int? examSession;
  // reverseRoundMapping은 constants.dart에 정의되어 있다고 가정합니다.
  // 이 파일이 import 되어 있는지 확인하세요. 예: import 'constants.dart';
  reverseRoundMapping.forEach((key, value) {
    if (value == normalizedDate) {
      examSession = key;
    }
  });

  // 맵핑되는 DB가 없으면 사용자에게 알림
  if (examSession == null) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('오류: "$date"에 해당하는 시험 회차 정보를 찾을 수 없습니다.')),
    );
    return;
  }

  try {
    if (mounted) {
      setState(() {
        isLoading = true;
      });
    }

    // 3. 해당 DB 파일 경로 지정 (예: question1.db)
    String dbPath = 'assets/question$examSession.db';
    DatabaseHelper questionDb = DatabaseHelper.getInstance(dbPath);

    // 4. 새로 추가한 getQuestion 메서드 호출 (Question_id만 사용)
    final question = await questionDb.getQuestion(questionId);
    
    // --- 로직 종료 ---

    if (!mounted) {
      // questionDb.dispose(); // 개별 인스턴스 dispose는 필요시 사용
      return;
    }

    setState(() {
      isLoading = false;
    });

    if (question != null) {
      // 다이얼로그를 보여주는 코드는 기존과 동일하게 작동합니다.
      // ... (기존 다이얼로그 코드) ...
       final correctOption = question['Correct_Option'] != null
            ? int.tryParse(question['Correct_Option'].toString())
            : null;

      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey[800]
              : Colors.white,
          title: Row(
            children: [
              Icon(Icons.play_circle_fill, color: Colors.blue),
              SizedBox(width: 8),
              Flexible(
                child: Text(
                  '$date - Question $questionId',
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black,
                    fontSize: 18,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (question['Big_Question'] != null &&
                    question['Big_Question'].toString().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: _buildContent(
                      question['Big_Question'],
                      context,
                      isBold: true,
                    ),
                  ),
                if (question['Question'] != null &&
                    question['Question'].toString().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: _buildContent(
                      question['Question'],
                      context,
                    ),
                  ),
                if (question['Image'] != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: _buildContent(
                      question['Image'],
                      context,
                      isImage: true,
                    ),
                  ),
                ...List.generate(4, (index) {
                  final optionKey = 'Option${index + 1}';
                  final optionData = question[optionKey];
                  if (optionData == null ||
                      (optionData is String && optionData.isEmpty)) {
                    return SizedBox.shrink();
                  }
                  final isCorrect = correctOption == index + 1;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${['➀', '➁', '➂', '➃'][index]} ',
                          style: TextStyle(
                            fontSize: 16,
                            color: isCorrect
                                ? Colors.blue
                                : (Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.white
                                    : Colors.black),
                            fontWeight: isCorrect
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        Expanded(
                          child: _buildContent(
                            optionData,
                            context,
                            isCorrect: isCorrect,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                Divider(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[600]
                      : Colors.grey[300],
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 12.0),
                  child: Text(
                    '정답 설명',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.blue
                          : Colors.blue[700],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    question['Answer_description']?.toString() ?? '설명 없음',
                    style: TextStyle(
                      fontSize: 15,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white70
                          : Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                '닫기',
                style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white70
                        : Colors.grey[600]),
              ),
            ),
          ],
        ),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('question$examSession.db에서 Question_id $questionId에 해당하는 문제를 찾을 수 없습니다.'),
          backgroundColor: Colors.red,
        ),
      );
    }
    // 데이터베이스 인스턴스는 앱 전체에서 관리되므로 여기서 개별적으로 닫지 않는 것이 좋습니다.
    // DatabaseHelper.disposeInstance(dbPath); 
  } catch (e) {
    if (mounted) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('문제 데이터를 로드하는 중 오류가 발생했습니다: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

  Widget _buildContent(dynamic data, BuildContext context,
      {bool isBold = false, bool isCorrect = false, bool isImage = false}) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    Uint8List? imageBytes;

    try {
      if (data is Uint8List) {
        imageBytes = data;
      } else if (data is List<dynamic>) {
        try {
          imageBytes = Uint8List.fromList(data.cast<int>());
        } catch (e) {
          // 변환 실패 시 아무것도 하지 않음
        }
      }
    } catch (e) {
      // 데이터 변환 중 오류 발생 시 아무것도 하지 않음
    }

    if (imageBytes != null && imageBytes.length > 100) {
      bool isValidImage = false;
      if (imageBytes.length > 4) {
        if (imageBytes[0] == 0xFF &&
            imageBytes[1] == 0xD8 &&
            imageBytes[2] == 0xFF) {
          // JPEG
          isValidImage = true;
        } else if (imageBytes[0] == 0x89 &&
            imageBytes[1] == 0x50 &&
            imageBytes[2] == 0x4E &&
            imageBytes[3] == 0x47) {
          // PNG
          isValidImage = true;
        } else if (imageBytes[0] == 0x47 &&
            imageBytes[1] == 0x49 &&
            imageBytes[2] == 0x46) {
          // GIF
          isValidImage = true;
        }
      }

      if (isValidImage) {
        return Container(
          constraints: BoxConstraints(maxWidth: 280, maxHeight: 400),
          child: Image.memory(
            imageBytes,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Text('이미지를 표시할 수 없습니다.',
                  style: TextStyle(color: Colors.red, fontSize: 14));
            },
          ),
        );
      } else {
        return Text('[이미지 데이터 - 표시할 수 없음]',
            style: TextStyle(
                fontSize: 15,
                fontStyle: FontStyle.italic,
                color: isDarkMode ? Colors.grey : Colors.grey[700]));
      }
    } else {
      String text = data?.toString() ?? '';
      if (text.length > 100 && RegExp(r'^\d+$').hasMatch(text)) {
        return Text('[이미지 데이터로 추정됨]',
            style: TextStyle(
                fontSize: 15,
                fontStyle: FontStyle.italic,
                color: isDarkMode ? Colors.grey : Colors.grey[700]));
      }
      return Text(
        text,
        style: TextStyle(
          fontSize: 16,
          color: isCorrect
              ? Colors.blue
              : (isDarkMode ? Colors.white : Colors.black),
          fontWeight: isBold
              ? FontWeight.bold
              : (isCorrect ? FontWeight.bold : FontWeight.normal),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '비법노트',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: isDarkMode ? Color(0xFF3A4A68) : Color(0xFF4A90E2),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.home, color: Colors.white),
            onPressed: () {
              if (!mounted) return; // 네비게이션 전 mounted 확인
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => HomePage()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      backgroundColor: isDarkMode ? Color(0xFF1C1C28) : Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            // 테스트 모드 표시 배너 추가
            if (_isTestMode)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8.0),
                color: Colors.orange.withOpacity(0.8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.info, color: Colors.white, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      '테스트 모드: 10초 자동 정지',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            // 오디오 플레이어 UI - 항상 표시
            Container(
              color: isDarkMode ? Color(0xFF252535) : Colors.grey[100],
              padding: EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // 타이틀
                  Text(
                    "강의 듣기",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  SizedBox(height: 12),

                  // 오디오 상태에 따른 UI 표시
                  if (_isAudioLoading)
                    // 로딩 중
                    Column(
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isDarkMode ? Colors.blue[300]! : Colors.blue,
                          ),
                        ),
                        SizedBox(height: 12),
                        Text(
                          '오디오를 준비하고 있습니다...',
                          style: TextStyle(
                            fontSize: 14,
                            color:
                                isDarkMode ? Colors.white70 : Colors.grey[600],
                          ),
                        ),
                      ],
                    )
                  else if (_errorMessage.isNotEmpty)
                    // 오류 발생
                    Column(
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Colors.red,
                        ),
                        SizedBox(height: 12),
                        Text(
                          _errorMessage,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.red,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _errorMessage = '';
                              _isAudioLoading = true;
                            });
                            _initAudioPlayer();
                          },
                          child: Text('다시 시도'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    )
                  else
                    // 정상 오디오 플레이어 UI
                    Column(
                      children: [
                        // 재생/일시정지 버튼
                        ElevatedButton(
                          onPressed: _isAudioInitialized ? _playPause : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDarkMode
                                ? Colors.blueGrey[700]
                                : Color(0xFF4A90E2),
                            minimumSize: Size(double.infinity, 45),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _isPlaying ? Icons.pause : Icons.play_arrow,
                                color: Colors.white,
                              ),
                              SizedBox(width: 8),
                              Text(
                                _isPlaying ? '일시정지' : '강의 재생',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 12),

                        // 컨트롤
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${_position.inMinutes}:${(_position.inSeconds % 60).toString().padLeft(2, '0')}',
                              style: TextStyle(
                                fontSize: 14,
                                color: isDarkMode
                                    ? Colors.white70
                                    : Colors.grey[800],
                              ),
                            ),
                            Row(
                              children: [
                                Text(
                                  '재생 속도: ',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isDarkMode
                                        ? Colors.white70
                                        : Colors.grey[800],
                                  ),
                                ),
                                DropdownButton<double>(
                                  value: _currentSpeed,
                                  isDense: true,
                                  underline: Container(),
                                  icon: Icon(
                                    Icons.arrow_drop_down,
                                    color: isDarkMode
                                        ? Colors.white70
                                        : Colors.grey[800],
                                  ),
                                  dropdownColor: isDarkMode
                                      ? Colors.grey[800]
                                      : Colors.white,
                                  onChanged: _isAudioInitialized
                                      ? (double? newValue) {
                                          if (newValue != null) {
                                            _changePlaybackSpeed(newValue);
                                          }
                                        }
                                      : null,
                                  items: _speedOptions
                                      .map<DropdownMenuItem<double>>(
                                          (double value) {
                                    return DropdownMenuItem<double>(
                                      value: value,
                                      child: Text(
                                        '${value}x',
                                        style: TextStyle(
                                          color: isDarkMode
                                              ? Colors.white
                                              : Colors.black,
                                          fontSize: 14,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                            Text(
                              '${_duration.inMinutes}:${(_duration.inSeconds % 60).toString().padLeft(2, '0')}',
                              style: TextStyle(
                                fontSize: 14,
                                color: isDarkMode
                                    ? Colors.white70
                                    : Colors.grey[800],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),

                        // 슬라이더
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor:
                                isDarkMode ? Colors.blue[300] : Colors.blue,
                            inactiveTrackColor: isDarkMode
                                ? Colors.grey[700]
                                : Colors.grey[300],
                            thumbColor:
                                isDarkMode ? Colors.blue[300] : Colors.blue,
                            overlayColor: isDarkMode
                                ? Colors.blue.withAlpha(32)
                                : Colors.blue.withAlpha(32),
                            thumbShape:
                                RoundSliderThumbShape(enabledThumbRadius: 8),
                            overlayShape:
                                RoundSliderOverlayShape(overlayRadius: 16),
                          ),
                          child: Slider(
                            value: _position.inSeconds.toDouble(),
                            max: _duration.inSeconds.toDouble() > 0
                                ? _duration.inSeconds.toDouble()
                                : 1.0,
                            onChanged: _isAudioInitialized
                                ? (value) async {
                                    if (!mounted) return; // seek 전 mounted 확인
                                    await _audioPlayer
                                        .seek(Duration(seconds: value.toInt()));
                                  }
                                : null,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),

            // 노트 내용
            Expanded(
              child: Stack(
                children: [
                  SingleChildScrollView(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: studyNotes.entries.map((mainTopicEntry) {
                        final mainTopic = mainTopicEntry.key;
                        final mainValue = mainTopicEntry.value;
                        final mainDesc = mainValue['description'] as String;
                        List<Map<String, dynamic>> relatedQuestions = [];
                        if (mainValue.containsKey('related_questions') &&
                            mainValue['related_questions'] != null) {
                          final rawQuestions =
                              mainValue['related_questions'] as List<dynamic>;
                          if (rawQuestions.isNotEmpty) {
                            relatedQuestions = rawQuestions
                                .map((q) => q as Map<String, dynamic>)
                                .toList();
                          }
                        }
                        return Card(
                          margin: EdgeInsets.only(bottom: 24),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          color: isDarkMode ? Color(0xFF2A2A3C) : Colors.white,
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: _getTopicColor(mainTopic),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Center(
                                        child: Text(
                                          mainTopic.split('.').first,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        mainTopic.split('. ').last,
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: isDarkMode
                                              ? Colors.white
                                              : Colors.black87,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Divider(
                                    height: 24,
                                    color: isDarkMode
                                        ? Colors.grey[700]
                                        : Colors.grey[300]),
                                Padding(
                                  padding: EdgeInsets.only(bottom: 16),
                                  child: Text(
                                    mainDesc,
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: isDarkMode
                                          ? Colors.white70
                                          : Colors.grey[800],
                                    ),
                                  ),
                                ),
                                if (relatedQuestions.isNotEmpty)
                                  Container(
                                    width: double.infinity,
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: isDarkMode
                                          ? Color(0xFF22222E)
                                          : Colors.grey[100],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.play_circle_fill,
                                              size: 16,
                                              color: isDarkMode
                                                  ? Colors.blue[300]
                                                  : Colors.blue[700],
                                            ),
                                            SizedBox(width: 6),
                                            Text(
                                              '관련 문제',
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                                color: isDarkMode
                                                    ? Colors.blue[300]
                                                    : Colors.blue[700],
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 8),
                                        Wrap(
                                          spacing: 8.0,
                                          runSpacing: 8.0,
                                          children:
                                              relatedQuestions.map((question) {
                                            final date = question['date'];
                                            final questionId =
                                                question['question_id'];
                                            final shortDate = date
                                                .toString()
                                                .replaceAll('년 ', '.')
                                                .replaceAll('월', '');
                                            return InkWell(
                                              onTap: () => _showQuestionDialog(
                                                  context, date, questionId),
                                              child: Container(
                                                padding: EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 6),
                                                decoration: BoxDecoration(
                                                  color: isDarkMode
                                                      ? Colors.blueGrey[800]
                                                      : Colors.blue[50],
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                ),
                                                child: Text(
                                                  '$shortDate (#$questionId)',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    color: isDarkMode
                                                        ? Colors.blue[200]
                                                        : Colors.blue[700],
                                                  ),
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  if (isLoading)
                    Container(
                      color: Colors.black.withOpacity(0.3),
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getTopicColor(String topic) {
    int topicNumber = int.tryParse(topic.split('.').first) ?? 0;
    switch (topicNumber) {
      case 1:
        return Colors.blue;
      case 2:
        return Colors.green;
      case 3:
        return Colors.purple;
      case 4:
        return Colors.orange;
      case 5:
        return Colors.pink;
      case 6:
        return Colors.teal;
      default:
        return Colors.blue;
    }
  }
}

class BytesAudioSource extends StreamAudioSource {
  final Uint8List _buffer;

  BytesAudioSource(this._buffer);

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    start = start ?? 0;
    end = end ?? _buffer.length;
    return StreamAudioResponse(
      sourceLength: _buffer.length,
      contentLength: end - start,
      offset: start,
      stream: Stream.value(_buffer.sublist(start, end)),
      contentType: 'audio/mpeg',
    );
  }
}
