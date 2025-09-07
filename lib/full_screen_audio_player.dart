// lib/full_screen_audio_player.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'audio_player_state.dart';
import 'constants.dart';

class FullScreenAudioPlayer extends StatelessWidget {
  const FullScreenAudioPlayer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Consumer<AudioPlayerState>(
      builder: (context, audioState, child) {
        final term = audioState.currentlyPlayingTerm;
        
        if (term == null) {
          return Container(
            color: isDarkMode ? Colors.black : Colors.white,
            child: Center(
              child: Text('재생 중인 용어가 없습니다.'),
            ),
          );
        }
        
        return Container(
          height: MediaQuery.of(context).size.height * 0.9,
          decoration: BoxDecoration(
            color: isDarkMode ? Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10,
                spreadRadius: 0,
                offset: Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            children: [
              // 드래그 핸들
              Container(
                margin: EdgeInsets.symmetric(vertical: 10),
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),
              
              // 헤더
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.close, color: isDarkMode ? Colors.white : Colors.black87),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Text(
                        '용어 음성 듣기',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(width: 48), // 균형을 위한 더미 공간
                  ],
                ),
              ),
              
              Divider(),
              
              // 용어 정보
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 카테고리
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          term.category,
                          style: TextStyle(
                            color: primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      
                      SizedBox(height: 24),
                      
                      // 용어
                      Text(
                        term.term,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                      
                      SizedBox(height: 24),
                      
                      // 정의
                      Text(
                        term.definition,
                        style: TextStyle(
                          fontSize: 18,
                          height: 1.6,
                          color: isDarkMode ? Colors.white70 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // 재생 컨트롤
              Container(
                padding: EdgeInsets.all(24),
                child: Column(
                  children: [
                    // 재생 슬라이더
                    Slider(
                      value: audioState.currentPosition.inSeconds.toDouble(),
                      max: audioState.totalDuration.inSeconds > 0 
                          ? audioState.totalDuration.inSeconds.toDouble() 
                          : 1.0,
                      activeColor: primaryColor,
                      inactiveColor: primaryColor.withOpacity(0.3),
                      onChanged: (value) {
                        audioState.seek(Duration(seconds: value.toInt()));
                      },
                    ),
                    
                    // 시간 표시
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatDuration(audioState.currentPosition),
                            style: TextStyle(
                              color: isDarkMode ? Colors.white70 : Colors.black54,
                            ),
                          ),
                          Text(
                            _formatDuration(audioState.totalDuration),
                            style: TextStyle(
                              color: isDarkMode ? Colors.white70 : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    SizedBox(height: 16),
                    
                    // 재생 제어 버튼
                    // 재생 제어 버튼 Row 수정 (문제가 발생하는 부분)
Row(
  mainAxisAlignment: MainAxisAlignment.center,
  mainAxisSize: MainAxisSize.min, // 최소 크기로 설정
  children: [
    // 반복 모드 버튼
    IconButton(
      padding: EdgeInsets.symmetric(horizontal: 4),
      constraints: BoxConstraints(),
      icon: Icon(
        audioState.repeatMode == RepeatMode.off
            ? Icons.repeat
            : audioState.repeatMode == RepeatMode.one
                ? Icons.repeat_one
                : Icons.repeat,
        color: audioState.repeatMode != RepeatMode.off
            ? primaryColor
            : (isDarkMode ? Colors.white70 : Colors.black54),
        size: 22, // 아이콘 크기 줄임
      ),
      onPressed: () {
        if (audioState.repeatMode == RepeatMode.off) {
          audioState.setRepeatMode(RepeatMode.all);
        } else if (audioState.repeatMode == RepeatMode.all) {
          audioState.setRepeatMode(RepeatMode.one);
        } else {
          audioState.setRepeatMode(RepeatMode.off);
        }
      },
    ),
    
    SizedBox(width: 12),
    
    // 이전 곡 버튼
    IconButton(
      padding: EdgeInsets.symmetric(horizontal: 4),
      constraints: BoxConstraints(),
      icon: Icon(
        Icons.skip_previous,
        color: isDarkMode ? Colors.white : Colors.black87,
        size: 30,
      ),
      onPressed: audioState.playPrevious,
    ),
    
    SizedBox(width: 12),
    
    // 재생/일시정지 버튼
    Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: primaryColor,
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(
          audioState.playerState == PlayerState.playing
              ? Icons.pause
              : Icons.play_arrow,
          color: Colors.white,
          size: 32,
        ),
        onPressed: () {
          if (audioState.playerState == PlayerState.playing) {
            audioState.pause();
          } else {
            audioState.resume();
          }
        },
      ),
    ),
    
    SizedBox(width: 12),
    
    // 다음 곡 버튼
    IconButton(
      padding: EdgeInsets.symmetric(horizontal: 4),
      constraints: BoxConstraints(),
      icon: Icon(
        Icons.skip_next,
        color: isDarkMode ? Colors.white : Colors.black87,
        size: 30,
      ),
      onPressed: () => audioState.playNext(),
    ),
    
    SizedBox(width: 12),
    
    // 재생 속도 선택
    PopupMenuButton<double>(
      padding: EdgeInsets.symmetric(horizontal: 4),
      icon: Icon(
        Icons.speed,
        color: isDarkMode ? Colors.white70 : Colors.black54,
        size: 22, // 아이콘 크기 줄임
      ),
      onSelected: (value) {
        audioState.setPlaybackSpeed(value);
      },
      itemBuilder: (context) => [
        PopupMenuItem(value: 0.75, child: Text('0.75x')),
        PopupMenuItem(value: 1.0, child: Text('1.0x')),
        PopupMenuItem(value: 1.25, child: Text('1.25x')),
        PopupMenuItem(value: 1.5, child: Text('1.5x')),
        PopupMenuItem(value: 2.0, child: Text('2.0x')),
      ],
    ),
  ],
)
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }
}