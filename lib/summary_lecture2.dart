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
  '1. 위험분석 기법과 수명주기 적용': {
    'description': ''' - 위험성 평가는 ‘유해‧위험요인 파악 → 빈도·중대성 평가 → 허용 여부 판단 → 저감 대책 수립·실행’의 순으로 진행된다.
 - PHA(Preliminary Hazard Analysis): 시스템 정의·개념 설계 단계에서 수행, 사고 범주는 파국적‧중대‧한계적‧무시가능이 표준이며 ‘수용가능’은 범주가 아니다.
 - FHA(Functional Hazard Analysis): 기능 단위로 위험을 점검, 기본 설계‧요구조건 정의 단계에 적용된다.
 - OHA(Operational Hazard Analysis): 운전·정비 단계의 위험을 다루며 PHA/FHA 이후에 실시된다.
 - HAZOP: P&ID 수준의 세부 설계 단계에서 ‘Guide-word(예: Other than = 의도와 다른 상태)’를 이용해 공정 편차를 체계적으로 도출한다. 시간·비용이 많이 들지만 은닉 위험을 잘 찾아낸다.
 - ETA(Event Tree Analysis): ‘초기사건 → 연속적 성공/실패 가지’ 구조로 결과 시나리오를 정량화(예: 화재 발생 후 감지기·경보·스프링클러 작동 여부).
 - Technology Assessment: 기술 개발 시 효율성과 위험성을 종합적으로 판단해 사업성을 결정한다.''',
    'related_questions': [
      {'date': '2022년 4월', 'question_id': 21},
      {'date': '2022년 4월', 'question_id': 27},
      {'date': '2022년 4월', 'question_id': 37},
      {'date': '2022년 3월', 'question_id': 23},
      {'date': '2022년 3월', 'question_id': 25},
      {'date': '2022년 3월', 'question_id': 29},
      {'date': '2021년 8월', 'question_id': 31},
      {'date': '2021년 8월', 'question_id': 34},
    ],
  },
  '2. FTA·논리 해석과 최소 컷셋': {
    'description': ''' - FTA(Fault Tree Analysis)는 Top-down 방식으로 정상(Top)사건의 논리 구조를 AND, OR, 부정(NOT) 게이트로 표현하여 정성·정량 분석 모두 수행한다.
 - 기호: 사각형-결함사상, 원형-기초사상, 구름-외부사상, ‘조건사상’ 기호는 평상 조건(작업·환경) 존재를 표시한다.
 - 최소 컷셋(MCS): Top 사건을 유발하는 ‘최소’ 기본사상 조합. Fussell 알고리즘이나 Boolean 축약으로 도출한다. 예) {1,3}.
 - 확률 계산: 독립 가정 시 P(T)=q₁q₂+q₁q₃+q₂q₃−2q₁q₂q₃ 등 공집합 배제법 활용.
 - Boolean 대수 핵심 정리: A·Ā=0, A+Ā=1, A(A+B)=A, (A+B)(A+ C)=A+BC 등. 오식 오류는 컷셋 단순화에 직결된다.
 - NOT(부정) 게이트는 입력의 반대를 출력하며, 논리식 부정(¯) 기호와 동일 개념이다.''',
    'related_questions': [
      {'date': '2022년 4월', 'question_id': 28},
      {'date': '2022년 4월', 'question_id': 30},
      {'date': '2022년 4월', 'question_id': 31},
      {'date': '2022년 4월', 'question_id': 39},
      {'date': '2022년 3월', 'question_id': 26},
      {'date': '2022년 3월', 'question_id': 30},
      {'date': '2022년 3월', 'question_id': 37},
      {'date': '2021년 8월', 'question_id': 25},
      {'date': '2021년 8월', 'question_id': 28},
      {'date': '2021년 8월', 'question_id': 33},
    ],
  },
  '3. 시스템 신뢰도와 욕조곡선': {
    'description': ''' - 욕조곡선: 초기고장(감소형)-우발(상수)-마모(증가형). 초기 구간의 고장률 저감을 ‘디버깅’이라 한다.
 - 직렬 시스템: R=∏ri. 병렬 시스템: R=1−∏(1−ri). 동일 부품 두 직렬 블록 병렬 연결 시 R=r²(2−r²).
 - n개 요소 병렬(지수수명)의 평균수명: MTTF_system = MTTF ×(1+½+…+1/n).
 - 사례 계산: 타이어 4개(고장 0.01) 자동차의 신뢰도 =0.99⁴≈0.96.
 - Fail-operational: 요소 고장 후에도 일정 기간 안전 기능 유지(운항·제어 연속성 확보).''',
    'related_questions': [
      {'date': '2022년 4월', 'question_id': 24},
      {'date': '2022년 4월', 'question_id': 34},
      {'date': '2022년 3월', 'question_id': 22},
      {'date': '2022년 3월', 'question_id': 38},
      {'date': '2021년 8월', 'question_id': 23},
      {'date': '2021년 8월', 'question_id': 35},
    ],
  },
  '4. 휴먼에러 분류와 대책': {
    'description': ''' - Mistake(착오): 계획 단계 오류, 상황 해석·목표 설정 오판.
• Rule-based mistake: 익숙한 규칙을 다른 상황에 부적절 적용(좌측통행 도로에서 우측 운전).
 - Slip/omission: 실행 단계에서 필요한 행위 누락(부품 하나 빼먹음).
 - Violation: 의도적 규칙 위반.
 - 효과적 예방: 인터페이스 단순화, 체크리스트, 피드백 제공, 규칙 전이 교육.''',
    'related_questions': [
      {'date': '2022년 4월', 'question_id': 22},
      {'date': '2022년 3월', 'question_id': 40},
      {'date': '2021년 8월', 'question_id': 21},
    ],
  },
  '5. 인간-기계 기능 할당과 시스템 설계': {
    'description': ''' - 인간공학 철학: 작업·기계를 인간 특성에 맞춘다(반대로 설계 X).
 - 시스템 설계 단계: 목표 명세 → 시스템 정의 → 기본 설계(인간·기계 기능 할당) → 인터페이스 설계 → 편의/보조물 설계 → 평가.
 - 수동 시스템: 인간이 동력·제어. 반자동‧자동은 기계가 동력 제공.
 - Fail-safe 설계: fail-operational, fail-active, fail-passive, fail-soft 등 조건에 맞춰 안전성 확보.
 - 최종 목표: 안전성과 효율성 동시 향상.''',
    'related_questions': [
      {'date': '2022년 4월', 'question_id': 26},
      {'date': '2022년 4월', 'question_id': 35},
      {'date': '2022년 3월', 'question_id': 38},
      {'date': '2021년 8월', 'question_id': 27},
      {'date': '2021년 8월', 'question_id': 30},
    ],
  },
  '6. 인체치수·작업자세 설계와 근골격계 평가': {
    'description': ''' - 치수 적용 원칙:
• 최대치(95~99백분위): 통로·문, 가드 간격 등 ‘들어갈 수 있어야 하는’ 설계.
• 최소치(1~5백분위): 손잡이 거리, 발판 높이 등 ‘닿을 수 있어야 하는’ 설계.
• 평균치: 조작 위치가 고정된 공용 설비.
 - 좌판 높이: 5% 오금높이 기준 → 대부분 착석 가능.
 - 좌식작업 적합 작업: 정밀 조립처럼 안정·정밀성이 핵심인 과제.
 - OWAS 평가요소: 상지·하지·허리 자세 + 취급 하중.
 - 근골격계부담작업 고시 예외: 손/무릎 충격 작업(2h·5회/h) 등은 제외 항목.''',
    'related_questions': [
      {'date': '2022년 4월', 'question_id': 32},
      {'date': '2022년 4월', 'question_id': 33},
      {'date': '2022년 3월', 'question_id': 32},
      {'date': '2021년 8월', 'question_id': 29},
      {'date': '2021년 8월', 'question_id': 32},
    ],
  },
  '7. 작업 부하·휴식 및 생리적 지표': {
    'description': ''' - 에너지 부하 관리: ‘작업+휴식’ 1시간 평균 ≤5 kcal/min 유지. 필요 휴식시간 t_r = (E_work−E_limit)/(E_work−E_rest) × 60. 예) 13.3 분.
 - 정신적 작업 부하 지표: EEG, 부정맥 지수, 점멸융합주파수(CFF) 등. EMG·GSR은 주로 신체적‧정서적 반응용.
 - 스트레스→스트레인: 자율신경·근육 반응 측정으로 부담을 정량화하고, 작업시간·휴식배분·레イ아웃 개선으로 저감한다.''',
    'related_questions': [
      {'date': '2022년 4월', 'question_id': 23},
      {'date': '2022년 3월', 'question_id': 24},
      {'date': '2021년 8월', 'question_id': 22},
    ],
  },
  '8. 열 환경 지수와 적정 한계': {
    'description': ''' - WBGT(습구흑구온도지수)
• 옥외(태양): 0.7 Tn + 0.2 Tg + 0.1 Td.
• 옥내(무태양): 0.7 Tn + 0.3 Tg.
• 예) 20 ℃/18 ℃/30 ℃ 옥외 → 20.6 ℃.
 - Oxford index: (건구+습구)/2.
 - WBGT 30 ℃ 이상은 고온 작업, 강도·노출시간·휴식 비율을 조정해야 함.''',
    'related_questions': [
      {'date': '2022년 4월', 'question_id': 38},
      {'date': '2022년 3월', 'question_id': 36},
      {'date': '2021년 8월', 'question_id': 39},
    ],
  },
  '9. 감각·표시 설계와 양립성': {
    'description': ''' - 시각
• 조도 E = I/d², 광원의 세기는 광도(I), illuminance가 아님. 3 m 300 lx → 2 m 675 lx.
• 어둠 순응(암조응) 완전 형성: 약 30~40 분.
• 시야 구분: 유도시야는 존재 여부만 판별 가능하나 공간 감각에는 영향.
• 시각 식별 ↑: 충분 조도, 고휘도 대비, 적절 반사율.
 - 청각
• 긴급·장거리 경보(>300 m)는 1 kHz 이하 저주파가 감쇠 적어 효과적.
• 1 sone: 1 kHz 40 dB 순음의 음량.
• 음성전달 품질 지표: Speech Interference Level(=통화간섭수준)·명료도 지수(C₅₀, 예 1.38).
• 양식 양립성(modal compatibility): 청각 자극-음성 반응처럼 입력·출력 감각양식 일치. 감성 양립성은 정식 분류에 없음.
• 청각 표시 설계 원리: 검약성(적은 ‘음’ 종류), 근사성(같은 의미는 비슷한 소리), 분리성(상충 신호 주파수 분리), 양립성(직관적 연결).
 - 정보량: I=log₂N, 대안 64개 → 6 bit 필요.
---''',
    'related_questions': [
      {'date': '2022년 4월', 'question_id': 25},
      {'date': '2022년 4월', 'question_id': 29},
      {'date': '2022년 4월', 'question_id': 36},
      {'date': '2022년 4월', 'question_id': 40},
      {'date': '2022년 3월', 'question_id': 28},
      {'date': '2022년 3월', 'question_id': 31},
      {'date': '2022년 3월', 'question_id': 33},
      {'date': '2022년 3월', 'question_id': 39},
      {'date': '2021년 8월', 'question_id': 24},
      {'date': '2021년 8월', 'question_id': 26},
      {'date': '2021년 8월', 'question_id': 36},
      {'date': '2021년 8월', 'question_id': 37},
    ],
  },
};

class SummaryLecture2Page extends StatefulWidget {
  final String dbPath;

  SummaryLecture2Page({required this.dbPath});

  @override
  _SummaryLecture2PageState createState() => _SummaryLecture2PageState();
}

class _SummaryLecture2PageState extends State<SummaryLecture2Page>
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
    print('SummaryLecture2Page: Test mode enabled: $_isTestMode');

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
        'SummaryLecture2Page: Starting test mode timer: ${_testModeDuration.inSeconds} seconds');
    _testModeTimer = Timer(_testModeDuration, () {
      print('SummaryLecture2Page: Test mode timer expired - stopping audio');
      if (mounted && _isPlaying) {
        _audioPlayer.pause();
      }
    });
  }

  // 테스트 모드 타이머 취소
  void _cancelTestModeTimer() {
    if (_testModeTimer != null) {
      print('SummaryLecture2Page: Cancelling test mode timer');
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
            AudioSource.asset('assets/audio/summary/lecture2.mp3'),
            preload: true,
          );
          print('DEBUG: 전체 경로 AssetSource 성공');
        } catch (fullPathError) {
          print('DEBUG: 전체 경로도 실패: $fullPathError');

          // 방법 3: BytesAudioSource (마지막 수단)
          try {
            print('DEBUG: BytesAudioSource로 fallback 시도');
            final ByteData data =
                await rootBundle.load('assets/audio/summary/lecture2.mp3');
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
        await rootBundle.load('assets/audio/summary/lecture2.mp3');
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
