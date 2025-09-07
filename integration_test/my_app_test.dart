import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sanupjongmin/constants.dart'; // Assuming this is a valid import in your project
import 'main_test.dart' as app; // Assuming this is how you run your app for tests

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

// 앱 추적 권한 팝업 처리 메서드
Future<void> _handleTrackingPermissionPopup(WidgetTester tester) async {
  // 권한 팝업이 나타날 때까지 최대 3초 대기
  bool foundPopup = false;
  for (int i = 0; i < 15; i++) {
    await tester.pump(Duration(milliseconds: 200));

    // '허용' 버튼 찾기
    final allowButtonFinder = find.text('허용');
    if (allowButtonFinder.evaluate().isNotEmpty) {
      await tester.tap(allowButtonFinder);
      await tester.pumpAndSettle();
      foundPopup = true;
      print('Tracking permission popup handled: Allowed');
      break;
    }
  }

  if (!foundPopup) {
    print('No tracking permission popup found or it was already handled');
  }
}

// 홈으로 돌아가는 함수
Future<void> _navigateToHome(WidgetTester tester) async {
  print('홈으로 돌아가기 시도 중...');
  bool homeFound = false;

  // 방법 1: 홈 아이콘 찾기
  try {
final homeButtonFinder = find.byKey(const Key('home_button'));
if (homeButtonFinder.evaluate().isNotEmpty) {
  await tester.tap(homeButtonFinder);
  await tester.pumpAndSettle();
  print('홈 버튼을 Key로 찾아 탭했습니다.');
  return;
}

// 방법 2: 아이콘으로 찾기
final homeFinder = find.byIcon(Icons.home_rounded);
if (homeFinder.evaluate().isNotEmpty) {
  await tester.tap(homeFinder);
  await tester.pumpAndSettle();
  print('홈 아이콘을 찾아 탭했습니다.');
  return;
}
  } catch (e) {
    print('홈 아이콘을 찾지 못했습니다. 다른 방법 시도...');
  }

  // 방법 2: 앱바의 GestureDetector 찾기
  if (!homeFound) {
    try {
      final appBarRow = find.byType(Row).first;
      final gestures = find.descendant(
        of: appBarRow,
        matching: find.byType(GestureDetector),
      );
      if (gestures.evaluate().length >= 2) {
        await tester.tap(gestures.at(1)); // Assuming the home button is the second gesture detector
        await tester.pumpAndSettle();
        homeFound = true;
        print('앱바에서 홈 버튼을 찾아 탭했습니다.');
        return; // Return after successful tap
      }
    } catch (e) {
      print('앱바에서 GestureDetector를 찾지 못했습니다.');
    }
  }

  // 방법 3: 화면 오른쪽 상단 탭하기 (최후의 수단)
  if (!homeFound) {
    print('모든 방법이 실패했습니다. 화면 오른쪽 상단을 탭합니다.');
    // This is a fallback, might not always work as expected depending on screen layout
    final topRight = Offset(
      tester.getBottomRight(find.byType(Scaffold)).dx - 50,
      tester.getTopLeft(find.byType(Scaffold)).dy + 50
    );
    await tester.tapAt(topRight);
  }

  await tester.pumpAndSettle();
  await Future.delayed(Duration(seconds: 3)); // Wait for navigation
  print('홈으로 돌아갑니다.');
}

// 홈 화면에서 버튼을 찾고 클릭하는 헬퍼 함수 (스크롤 포함)
Future<void> _scrollAndTapButton(WidgetTester tester, String buttonText) async {
  final buttonFinder = find.text(buttonText);
  
  // 먼저 버튼이 이미 보이는지 확인
  if (buttonFinder.evaluate().isNotEmpty) {
    try {
      // ensureVisible을 사용하여 버튼이 화면에 보이도록 스크롤
      await tester.ensureVisible(buttonFinder);
      await tester.pumpAndSettle();
      await tester.tap(buttonFinder);
      await tester.pumpAndSettle();
      print('$buttonText 버튼을 성공적으로 클릭했습니다.');
      return;
    } catch (e) {
      print('ensureVisible 실패, 수동 스크롤을 시도합니다: $e');
    }
  }
  
  // ensureVisible이 실패한 경우 수동으로 스크롤
  print('$buttonText 버튼을 찾기 위해 스크롤을 시도합니다.');
  
  // 스크롤 가능한 영역 찾기 (ListView, ScrollView, SingleChildScrollView 등)
  final scrollableFinder = find.byType(Scrollable);
  
  if (scrollableFinder.evaluate().isNotEmpty) {
    // 아래로 스크롤하면서 버튼 찾기
    for (int i = 0; i < 5; i++) {
      await tester.drag(scrollableFinder.first, Offset(0, -200)); // 200픽셀만큼 아래로 스크롤
      await tester.pumpAndSettle();
      
      final buttonFinder = find.text(buttonText);
      if (buttonFinder.evaluate().isNotEmpty) {
        await tester.tap(buttonFinder);
        await tester.pumpAndSettle();
        print('스크롤 후 $buttonText 버튼을 성공적으로 클릭했습니다.');
        return;
      }
    }
  } else {
    // Scrollable이 없는 경우 전체 화면을 스크롤
    final scaffoldFinder = find.byType(Scaffold);
    if (scaffoldFinder.evaluate().isNotEmpty) {
      for (int i = 0; i < 5; i++) {
        await tester.drag(scaffoldFinder.first, Offset(0, -200));
        await tester.pumpAndSettle();
        
        final buttonFinder = find.text(buttonText);
        if (buttonFinder.evaluate().isNotEmpty) {
          await tester.tap(buttonFinder);
          await tester.pumpAndSettle();
          print('화면 스크롤 후 $buttonText 버튼을 성공적으로 클릭했습니다.');
          return;
        }
      }
    }
  }
  
  // 모든 시도가 실패한 경우
  throw Exception('$buttonText 버튼을 찾을 수 없습니다.');
}


  group('My App Test', () {
    testWidgets('Full App Navigation Flow', (WidgetTester tester) async {
      // 앱 실행 -> HomePage
      app.main();
      await tester.pumpAndSettle();
      await _handleTrackingPermissionPopup(tester);

      print('HomePage loaded.');
      print("SCREENSHOT_SIGNAL:1_HOME_LOADED"); // Renumbered
      await Future.delayed(Duration(seconds: 5));

      print('HomePage loaded.'); // This seems like a duplicate log, but renumbering signal
      print("SCREENSHOT_SIGNAL:2_HOME_LOADED"); // Renumbered
      await Future.delayed(Duration(seconds: 5)); // 스크린샷을 위한 충분한 대기 시간

      // '연도별 문제풀기' 탭 클릭
      final yearButtonFinder = find.text('연도별\n문제풀기');
      expect(yearButtonFinder, findsOneWidget, reason: '"연도별 문제풀기" 버튼을 찾을 수 없습니다.');
      await tester.tap(yearButtonFinder);
      await tester.pumpAndSettle();
      await Future.delayed(Duration(seconds: 3));

      print('QuestionSelectPage loaded.');
      print("SCREENSHOT_SIGNAL:3_QuestionSelectPage_LOADED"); // Renumbered
      await tester.pumpAndSettle();
      await Future.delayed(Duration(seconds: 7)); // 충분한 대기 시간
      await tester.pumpAndSettle(); // 한번 더 화면 갱신

      // 로딩 인디케이터가 사라졌는지 확인
      if (find.byType(CircularProgressIndicator).evaluate().isNotEmpty) {
        print('아직 로딩 중입니다. 더 기다립니다.');
        await Future.delayed(Duration(seconds: 5));
        await tester.pumpAndSettle();
      }

      // 첫 번째 라운드 이름으로 버튼 찾기
      // Assuming reverseRoundMapping is defined in 'constants.dart' or accessible here
      final rounds = reverseRoundMapping.values.toList();
      final firstRoundName = rounds[0];
      print('첫 번째 라운드 이름: $firstRoundName');

      // 방법 1: 키로 찾기
      final firstRoundButtonFinder = find.byKey(Key('round_card_${firstRoundName}'));

      expect(firstRoundButtonFinder, findsOneWidget,
          reason: '첫 번째 연도 버튼을 찾을 수 없습니다: $firstRoundName');

      // 위젯을 화면에 표시
      await tester.ensureVisible(firstRoundButtonFinder);
      await tester.pumpAndSettle();

      // 탭 동작 수행
      await tester.tap(firstRoundButtonFinder);
      await tester.pumpAndSettle();
      await Future.delayed(Duration(seconds: 3));

      print('QuestionScreenPage loaded.');
      await Future.delayed(Duration(seconds: 3));

      // 첫 번째 문제의 Option 1 클릭
      print('첫 번째 옵션을 찾는 중...');
      await tester.pumpAndSettle();
      await Future.delayed(Duration(seconds: 5)); // 화면 로딩 기다리기

      // ListView 찾기
      final listViewFinder = find.byType(ListView);
      expect(listViewFinder, findsOneWidget, reason: '문제 ListView를 찾을 수 없습니다.');

      // 첫 번째 옵션 찾기 (여러 방법 시도)
      Finder optionFinder;
      // 방법 1: 아이콘으로 찾기 (더 구체적인 방법이 있다면 수정)
      optionFinder = find.descendant(
        of: listViewFinder,
        matching: find.byIcon(Icons.radio_button_unchecked_rounded)
      ).first;

      if (optionFinder.evaluate().isEmpty) {
        // 방법 2: GestureDetector로 찾기 (더 구체적인 식별자 사용 권장)
        print('아이콘으로 옵션을 찾지 못했습니다. GestureDetector로 시도합니다.');
        optionFinder = find.descendant(
          of: listViewFinder,
          matching: find.byType(GestureDetector),
        ).first;
      }

      if (optionFinder.evaluate().isNotEmpty) {
        await tester.ensureVisible(optionFinder); // 옵션이 화면에 보이도록 스크롤
        await tester.pumpAndSettle();
        await tester.tap(optionFinder);
        await tester.pumpAndSettle();
        print('옵션 탭 완료');
      } else {
          print('옵션을 찾지 못했습니다. 화면 좌측을 탭합니다. (대체 동작)');
          final center = tester.getCenter(listViewFinder);
          await tester.tapAt(Offset(center.dx * 0.3, center.dy * 0.5)); // This is a very generic fallback
          await tester.pumpAndSettle();
          await Future.delayed(Duration(seconds: 3));
          print('화면 탭 완료');
      }

      await Future.delayed(Duration(seconds: 3));
      print("SCREENSHOT_SIGNAL:4_QuestionScreenPage_LOADED"); // Renumbered
      await Future.delayed(Duration(seconds: 5)); // 스크린샷을 위한 충분한 대기 시간

      // 홈으로 돌아가기
      await _navigateToHome(tester);

      // '과목별 문제풀기' 버튼 클릭 -> QuestionSelectPage로 이동
      final categoryButtonFinder = find.text('과목별\n문제풀기');
      expect(categoryButtonFinder, findsOneWidget,
          reason: '"과목별 문제풀기" 버튼을 찾을 수 없습니다.');
      await tester.tap(categoryButtonFinder);
      await tester.pumpAndSettle();
      await Future.delayed(Duration(seconds: 3));

      print('QuestionSelectPage (Category) loaded.');
      print("SCREENSHOT_SIGNAL:5_QuestionSelectPage"); // Renumbered
      await Future.delayed(Duration(seconds: 5)); // 스크린샷을 위한 충분한 대기 시간

      // 앱 상단바의 뒤로가기 버튼 클릭 -> HomePage로 이동
      // 홈으로 돌아가기
      await _navigateToHome(tester);
      await Future.delayed(Duration(seconds: 3));

      print('Returned to HomePage.');
      await Future.delayed(Duration(seconds: 3));

      // '랜덤 문제풀기' 버튼 클릭 -> RandomQuestionSelectPage로 이동
      final randomButtonFinder = find.text('랜덤\n문제풀기');
      expect(randomButtonFinder, findsOneWidget,
          reason: '"랜덤 문제풀기" 버튼을 찾을 수 없습니다.');
      await tester.tap(randomButtonFinder);
      await tester.pumpAndSettle();

      print('RandomQuestionSelectPage loaded.');

      // '전체 문제 랜덤 풀기' 버튼 클릭 -> RandomQuestionPage로 이동
      final allRandomButtonFinder = find.text('전체 문제 랜덤 풀기');
      expect(allRandomButtonFinder, findsOneWidget,
          reason: '"전체 문제 랜덤 풀기" 버튼을 찾을 수 없습니다.');
      await tester.tap(allRandomButtonFinder);
      await tester.pumpAndSettle();
      await Future.delayed(Duration(seconds: 3));

      print('RandomQuestionPage loaded.');
      print("SCREENSHOT_SIGNAL:6_RandomQuestionPage"); // Renumbered
      await Future.delayed(Duration(seconds: 5)); // 스크린샷을 위한 충분한 대기 시간

      // 홈으로 돌아가기
      await _navigateToHome(tester);

       final oxQuizButtonFinder = find.text('OX\n퀴즈');
      expect(oxQuizButtonFinder, findsOneWidget,
          reason: '"OX 퀴즈" 버튼을 찾을 수 없습니다.');
      await tester.tap(oxQuizButtonFinder);
      await tester.pumpAndSettle();
      await Future.delayed(Duration(seconds: 3));

      // 광고 다이얼로그가 나타나면 "예: 시청하기" 클릭
      // More robustly find the dialog, e.g., by a unique title or content if available
      final adDialogFinder = find.text("OX 퀴즈"); // Assuming this text is part of the dialog
      if (adDialogFinder.evaluate().isNotEmpty) {
        final yesButtonFinder = find.text("예: 시청하기"); // Make sure this text is exact
        if (yesButtonFinder.evaluate().isNotEmpty) {
          await tester.tap(yesButtonFinder);
          await tester.pumpAndSettle();
          await Future.delayed(Duration(seconds: 3)); // Wait for dialog to close/ad to potentially load
        }
      }

      print('OXQuizPage loaded.');
      print("SCREENSHOT_SIGNAL:7_OXQuizPage"); // Renumbered
      await Future.delayed(Duration(seconds: 5));

      // 4. 홈으로 돌아가기
      await _navigateToHome(tester);
      print('Returned to HomePage.');
      await Future.delayed(Duration(seconds: 3));

      // '기출 음성듣기' 버튼 클릭 -> AudioSelectPage로 이동
      await _scrollAndTapButton(tester, '기출 음성듣기');
      await Future.delayed(Duration(seconds: 3));

      print('AudioSelectPage loaded.');
      await Future.delayed(Duration(seconds: 3));
      final homeIconFinder = find.byIcon(Icons.home); // Define earlier if used multiple times before this

      // '연도별 듣기' 버튼 클릭 (ExpansionTile 확장)
      final yearAudioButtonFinder = find.text('연도별 듣기');
      expect(yearAudioButtonFinder, findsOneWidget,
          reason: '"연도별 듣기" 버튼을 찾을 수 없습니다.');
      await tester.tap(yearAudioButtonFinder);
      await tester.pumpAndSettle();
      await Future.delayed(Duration(seconds: 3)); // Wait for expansion

      // '과목별 듣기' 버튼 클릭 (ExpansionTile 확장)
      final categoryAudioButtonFinder = find.text('과목별 듣기');
      expect(categoryAudioButtonFinder, findsOneWidget,
          reason: '"과목별 듣기" 버튼을 찾을 수 없습니다.');
      await tester.tap(categoryAudioButtonFinder);
      await tester.pumpAndSettle();

      await Future.delayed(Duration(seconds: 3));
      print("SCREENSHOT_SIGNAL:11_AudioSelectPage"); // Renumbered
      await Future.delayed(Duration(seconds: 5)); // 스크린샷을 위한 충분한 대기 시간

      // 가장 첫 번째 연도의 듣기 버튼 클릭 -> AudioListenPage로 이동
      // This assumes the first ExpansionTile is '연도별 듣기' and it's expanded
      final firstAudioRoundButtonFinder = find
          .descendant(
            of: find.widgetWithText(ExpansionTile, '연도별 듣기'), // Be more specific
            matching: find.byType(ElevatedButton),
          )
          .first;
      expect(firstAudioRoundButtonFinder, findsOneWidget,
          reason: '첫 번째 연도 듣기 버튼을 찾을 수 없습니다.');
      await tester.ensureVisible(firstAudioRoundButtonFinder);
      await tester.pumpAndSettle();
      await tester.tap(firstAudioRoundButtonFinder);
      await tester.pumpAndSettle();
      await Future.delayed(Duration(seconds: 3));


      print('AudioListenPage loaded.');
      print("SCREENSHOT_SIGNAL:12_AudioListenPage"); // Renumbered
      await Future.delayed(Duration(seconds: 3));

      // 오디오 재생 버튼 찾아서 클릭
      // 재생 버튼 클릭
      final playButtonFinder = find.text('Play'); // Ensure this is the correct text or use a Key
      expect(playButtonFinder, findsOneWidget, reason: '재생 버튼을 찾을 수 없습니다.');
      await tester.tap(playButtonFinder);
      await tester.pumpAndSettle();

      print('Audio playing...');
      await Future.delayed(Duration(seconds: 10)); // Listen for 10 seconds

      // 정지 버튼 찾아서 클릭 (If there is a stop button to test)
      print("SCREENSHOT_SIGNAL:13_AudioListenPage_PLAYING"); // Renumbered (Added _PLAYING for clarity)
      await Future.delayed(Duration(seconds: 10)); // Wait for screenshot

      // 상단 앱바의 홈 아이콘 클릭 -> 홈페이지로 이동
      // Re-using _navigateToHome for consistency
      await _navigateToHome(tester);
      // expect(homeIconFinder, findsOneWidget, reason: '홈 아이콘을 찾을 수 없습니다.');
      // await tester.tap(homeIconFinder);
      // await tester.pumpAndSettle();
      // await Future.delayed(Duration(seconds: 3));


    });
  });
}