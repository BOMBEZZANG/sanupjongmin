#!/bin/bash
set -e

# 환경 변수 SCREENSHOT_FOLDER가 설정되어 있는지 확인
if [ -z "$SCREENSHOT_FOLDER" ]; then
  echo "Error: SCREENSHOT_FOLDER environment variable must be set."
  exit 1
fi

mkdir -p "$SCREENSHOT_FOLDER"

# 전역 변수: 현재 테스트 중인 기기 이름
CURRENT_DEVICE=""

# 중복 방지용 일반 배열
TRIGGERED_ARRAY=()

# 스크린샷 찍기 함수
take_screenshot() {
  local filename="$1"
  local TIMESTAMP
  TIMESTAMP=$(date +%Y%m%d_%H%M%S)
  local filepath="${SCREENSHOT_FOLDER}/${CURRENT_DEVICE}_${filename}_${TIMESTAMP}.png"
  echo "Taking screenshot: $filepath"
  xcrun simctl io booted screenshot "$filepath"
}

# signal을 한 번만 처리하기 위한 함수
handle_signal_once() {
  local signal="$1"
  local screenshot_name="$2"

  # 디버깅용 로그 추가
  echo "Debug: Signal received: $signal"
  echo "Debug: Current triggered array: ${TRIGGERED_ARRAY[*]}"

  # 이미 처리한 적이 있는지 배열에서 확인
  if [[ " ${TRIGGERED_ARRAY[*]} " != *" $signal "* ]]; then
    # 배열에 해당 signal 추가
    TRIGGERED_ARRAY+=("$signal")
    echo "Debug: Added signal to array: $signal"
    echo "Debug: Updated array: ${TRIGGERED_ARRAY[*]}"

    echo "Triggering screenshot for signal: $signal..."
    take_screenshot "$screenshot_name"
  else
    echo "Debug: Signal $signal already processed, skipping"
  fi
}

# 주어진 기기에서 테스트를 실행하는 함수
run_tests_for_device() {
  local device_name="$1"

  # 기기마다 테스트 시작시, 배열을 비움
  TRIGGERED_ARRAY=()

  # CURRENT_DEVICE에 공백을 언더바로 변환
  CURRENT_DEVICE=$(echo "$device_name" | tr ' ' '_')

  echo "------------------------------------------------------"
  echo "Running tests for device: $device_name (CURRENT_DEVICE=$CURRENT_DEVICE)"
  echo "------------------------------------------------------"

  # 디바이스가 이미 부팅되어 있는지 확인 후 부팅
  if xcrun simctl list devices booted | grep -q "$device_name"; then
      echo "$device_name is already booted."
  else
      echo "Booting simulator: $device_name"
      xcrun simctl boot "$device_name"
  fi

  open -a Simulator.app

  # 아이패드인 경우 추가 대기
  if [[ "$device_name" == "iPad Pro (12.9-inch) (6th generation)" ]]; then
    echo "Detected iPad. Waiting extra 10 seconds for the screen to fully load..."
    sleep 10
  fi

  # Flutter 클린, 빌드 및 앱 설치
  flutter clean
  flutter pub get
  cd ios
  pod install
  cd ..
  flutter build ios --simulator
  xcrun simctl install booted build/ios/iphonesimulator/Runner.app

  echo "Starting flutter drive for $device_name with DISABLE_ADS=true and SHOW_DEBUG_BANNER=false..."
  flutter drive \
    --dart-define=DISABLE_ADS=true \
    --dart-define=SHOW_DEBUG_BANNER=false \
    --driver=test_driver/integration_test_driver.dart \
    --target=integration_test/my_app_test.dart \
    -d "$device_name" 2>&1 | while IFS= read -r line; do
      echo "$line"

      # SCREENSHOT_SIGNAL 매칭 - 테스트 파일의 시그널에 맞춰 업데이트
      if echo "$line" | grep -Fq "SCREENSHOT_SIGNAL:1_HOME_LOADED"; then
        handle_signal_once "SCREENSHOT_SIGNAL:1_HOME_LOADED" "1_homepage"
      fi


      if echo "$line" | grep -Fq "SCREENSHOT_SIGNAL:3_QuestionSelectPage_LOADED"; then
        handle_signal_once "SCREENSHOT_SIGNAL:3_QuestionSelectPage_LOADED" "3_questionselect"
      fi

      if echo "$line" | grep -Fq "SCREENSHOT_SIGNAL:4_QuestionScreenPage_LOADED"; then
        handle_signal_once "SCREENSHOT_SIGNAL:4_QuestionScreenPage_LOADED" "4_questionscreen"
      fi

      if echo "$line" | grep -Fq "SCREENSHOT_SIGNAL:6_RandomQuestionPage"; then
        handle_signal_once "SCREENSHOT_SIGNAL:6_RandomQuestionPage" "6_randomquestion"
      fi

      if echo "$line" | grep -Fq "SCREENSHOT_SIGNAL:7_OXQuizPage"; then
        handle_signal_once "SCREENSHOT_SIGNAL:7_OXQuizPage" "7_oxquiz"
      fi

      if echo "$line" | grep -Fq "SCREENSHOT_SIGNAL:12_AudioListenPage"; then
        handle_signal_once "SCREENSHOT_SIGNAL:12_AudioListenPage" "12_audiolisten"
      fi
      
      # 추가 시그널이 있을 경우 여기에 추가
    done

  echo "Tests for $device_name completed. Shutting down simulator..."
  xcrun simctl shutdown "$device_name"

  echo "All screenshots for $device_name have been saved to $SCREENSHOT_FOLDER"
  echo "Deleting and resizing extra screenshots if needed..."
}

# 두 번째 기기: iPad Pro (12.9-inch) (6th generation)에서 테스트 실행
run_tests_for_device "iPad Pro (12.9-inch) (6th generation)"

# 첫 번째 기기: iPhone 15에서 테스트 실행
run_tests_for_device "iPhone 15"