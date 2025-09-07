// lib/dictionary_audio_page.dart
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:provider/provider.dart';
import 'dart:developer' as developer;
import 'audio_player_state.dart';
import 'audio_term.dart';
import 'constants.dart';
import 'full_screen_audio_player.dart';

class DictionaryAudioPage extends StatefulWidget {
  const DictionaryAudioPage({Key? key}) : super(key: key);

  @override
  _DictionaryAudioPageState createState() => _DictionaryAudioPageState();
}

class _DictionaryAudioPageState extends State<DictionaryAudioPage> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearchActive = false;
  late AudioPlayerState _audioPlayerState;

  @override
  void initState() {
    super.initState();
    _audioPlayerState = AudioPlayerState();
    developer.log('DictionaryAudioPage initialized');
  }

  @override
  void dispose() {
    _searchController.dispose();
    _audioPlayerState.dispose();
    developer.log('DictionaryAudioPage disposed');
    super.dispose();
  }

  void _showFullScreenPlayer(BuildContext context, AudioTerm term) {
    final audioPlayerState =
        Provider.of<AudioPlayerState>(context, listen: false);
    developer.log(
        'Opening full screen player for term: ${term.term}, rowid: ${term.rowid}');

    // 이미 재생 중인 곡과 다른 곡을 선택하면 새로 재생
    if (audioPlayerState.currentlyPlayingTerm?.rowid != term.rowid) {
      developer.log('Playing new term: ${term.term}');
      audioPlayerState.play(term);
    } else if (audioPlayerState.playerState == PlayerState.paused ||
        audioPlayerState.playerState == PlayerState.stopped) {
      developer.log('Resuming paused term: ${term.term}');
      audioPlayerState.resume();
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        // Provider 공유
        return ChangeNotifierProvider.value(
          value: audioPlayerState,
          child: FullScreenAudioPlayer(),
        );
      },
    ).whenComplete(() {
      developer.log('Full screen player closed');
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return ChangeNotifierProvider.value(
      value: _audioPlayerState,
      child: Consumer<AudioPlayerState>(
        builder: (context, audioState, child) {
          return Scaffold(
            backgroundColor: isDarkMode ? Color(0xFF1E1E1E) : Color(0xFFF4F6F8),
            appBar: AppBar(
              backgroundColor: isDarkMode ? Color(0xFF2C2C2C) : Colors.white,
              elevation: 0.5,
              leading: IconButton(
                icon: Icon(Icons.arrow_back_ios_new_rounded,
                    color: isDarkMode ? Colors.white : Colors.black87),
                onPressed: () => Navigator.of(context).pop(),
              ),
              title: _isSearchActive
                  ? TextField(
                      controller: _searchController,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: '용어 검색...',
                        border: InputBorder.none,
                        hintStyle: TextStyle(
                            color:
                                isDarkMode ? Colors.white70 : Colors.black54),
                      ),
                      style: TextStyle(
                          color: isDarkMode ? Colors.white : Colors.black87,
                          fontSize: 16),
                      onChanged: (value) {
                        audioState.updateSearchTerm(value);
                      },
                    )
                  : Text(
                      '용어사전 음성듣기',
                      style: TextStyle(
                          color: isDarkMode ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.bold),
                    ),
              actions: [
                IconButton(
                  icon: Icon(
                      _isSearchActive
                          ? Icons.close_rounded
                          : Icons.search_rounded,
                      color: isDarkMode ? Colors.white : Colors.black87),
                  onPressed: () {
                    setState(() {
                      _isSearchActive = !_isSearchActive;
                      if (!_isSearchActive) {
                        _searchController.clear();
                        audioState.updateSearchTerm("");
                      }
                    });
                  },
                ),
              ],
            ),
            body: Column(
              children: [
                // Category Filter Chips
                _buildCategoryFilters(context, audioState, isDarkMode),
                // Favorite Filter Toggle
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '즐겨찾기한 용어만 보기',
                        style: TextStyle(
                            fontSize: 15,
                            color:
                                isDarkMode ? Colors.white70 : Colors.black87),
                      ),
                      Switch(
                        value: audioState.filterFavoritesOnly,
                        onChanged: (value) {
                          audioState.toggleFavoriteFilter();
                        },
                        activeColor: favoriteColor,
                      ),
                    ],
                  ),
                ),
                Divider(
                    height: 1,
                    color: isDarkMode ? Colors.grey[700] : Colors.grey[300]),

                // 현재 재생 중인 상태 표시
                if (audioState.currentlyPlayingTerm != null)
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    color: primaryColor.withOpacity(0.1),
                    child: Row(
                      children: [
                        Icon(
                          audioState.playerState == PlayerState.playing
                              ? Icons.pause_circle_filled
                              : Icons.play_circle_filled,
                          color: primaryColor,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '현재 재생: ${audioState.currentlyPlayingTerm!.term}',
                            style: TextStyle(
                              color: primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Text(
                          '${audioState.currentPosition.inMinutes}:${(audioState.currentPosition.inSeconds % 60).toString().padLeft(2, '0')} / '
                          '${audioState.totalDuration.inMinutes}:${(audioState.totalDuration.inSeconds % 60).toString().padLeft(2, '0')}',
                          style: TextStyle(color: primaryColor),
                        ),
                      ],
                    ),
                  ),

                // Terms List
                Expanded(
                  child: audioState.isLoadingManifest
                      ? Center(
                          child: CircularProgressIndicator(color: primaryColor))
                      : audioState.currentPlaylist.isEmpty
                          ? Center(
                              child: Text(
                                _searchController.text.isNotEmpty ||
                                        audioState.filterFavoritesOnly ||
                                        audioState.currentCategoryFilter != "전체"
                                    ? '해당 조건의 용어가 없습니다.'
                                    : '표시할 용어가 없습니다.\nmanifest 파일을 확인해주세요.',
                                textAlign: TextAlign.center,
                                style:
                                    TextStyle(fontSize: 16, color: Colors.grey),
                              ),
                            )
                          : ListView.builder(
                              itemCount: audioState.currentPlaylist.length,
                              itemBuilder: (context, index) {
                                final term = audioState.currentPlaylist[index];
                                final isPlaying =
                                    audioState.currentlyPlayingTerm?.rowid ==
                                            term.rowid &&
                                        audioState.playerState ==
                                            PlayerState.playing;
                                final isPaused =
                                    audioState.currentlyPlayingTerm?.rowid ==
                                            term.rowid &&
                                        audioState.playerState ==
                                            PlayerState.paused;

                                IconData playIcon;
                                if (isPlaying) {
                                  playIcon = Icons.pause_circle_filled_rounded;
                                } else if (isPaused) {
                                  playIcon = Icons.play_circle_filled_rounded;
                                } else {
                                  playIcon = Icons.play_arrow_rounded;
                                }

                                return Material(
                                  color: Colors.transparent,
                                  child: ListTile(
                                    // leading 제거 (스피커 아이콘 삭제)
                                    title: Text(
                                      term.term,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: audioState.currentlyPlayingTerm
                                                    ?.rowid ==
                                                term.rowid
                                            ? primaryColor
                                            : (isDarkMode
                                                ? Colors.white
                                                : Colors.black87),
                                      ),
                                    ),
                                    subtitle: Text(
                                      term.category,
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: isDarkMode
                                              ? Colors.white60
                                              : Colors.black54),
                                    ),
                                    trailing: IconButton(
                                      icon: Icon(playIcon,
                                          size: 30, color: primaryColor),
                                      onPressed: () {
                                        _showFullScreenPlayer(context, term);
                                      },
                                    ),
                                    onTap: () {
                                      _showFullScreenPlayer(context, term);
                                    },
                                  ),
                                );
                              },
                            ),
                ),
              ],
            ),
            // 현재 재생 중이면 하단에 미니 플레이어 표시
            bottomNavigationBar: audioState.currentlyPlayingTerm != null
                ? _buildMiniPlayer(audioState, isDarkMode)
                : null,
          );
        },
      ),
    );
  }

  Widget _buildCategoryFilters(
      BuildContext context, AudioPlayerState audioState, bool isDarkMode) {
    List<String> displayCategories = ["전체", ...categories];

    return Container(
      height: 50,
      margin: EdgeInsets.symmetric(vertical: 8.0),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 12.0),
        itemCount: displayCategories.length,
        itemBuilder: (context, index) {
          final category = displayCategories[index];
          final isSelected = audioState.currentCategoryFilter == category;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: ChoiceChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  audioState.updateCategoryFilter(category);
                }
              },
              backgroundColor: isDarkMode ? Colors.grey[800] : Colors.grey[200],
              selectedColor: primaryColor,
              labelStyle: TextStyle(
                color: isSelected
                    ? Colors.white
                    : (isDarkMode ? Colors.white70 : Colors.black87),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              checkmarkColor: Colors.white,
              elevation: isSelected ? 2 : 0,
            ),
          );
        },
      ),
    );
  }

  // 미니 플레이어 위젯
  Widget _buildMiniPlayer(AudioPlayerState audioState, bool isDarkMode) {
    return Container(
      height: 60,
      color: isDarkMode ? Color(0xFF2C2C2C) : Colors.white,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (audioState.currentlyPlayingTerm != null) {
              _showFullScreenPlayer(context, audioState.currentlyPlayingTerm!);
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Icon(
                  audioState.playerState == PlayerState.playing
                      ? Icons.pause_circle_filled
                      : Icons.play_circle_filled,
                  color: primaryColor,
                  size: 32,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min, // 추가: 최소 크기만 사용
                    children: [
                      Text(
                        audioState.currentlyPlayingTerm?.term ?? '선택된 용어 없음',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black87,
                          height: 1.0, // 줄 간격 축소
                          fontSize: 14, // 글꼴 크기 추가 및 조정
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 1), // 2에서 1로 축소
                      Text(
                        audioState.currentlyPlayingTerm?.category ?? '',
                        style: TextStyle(
                          fontSize: 11, // 12에서 11로 축소
                          color: isDarkMode ? Colors.white70 : Colors.black54,
                          height: 1.0, // 줄 간격 축소
                        ),
                        maxLines: 1, // 한 줄로 제한
                        overflow: TextOverflow.ellipsis, // 오버플로우 처리
                      ),
                    ],
                  ),
                ),
                Text(
                  '${audioState.currentIndexInPlaylist + 1}/${audioState.currentPlaylist.length}',
                  style: TextStyle(
                    color: isDarkMode ? Colors.white70 : Colors.black54,
                  ),
                ),
                SizedBox(width: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.skip_previous, color: primaryColor),
                      onPressed: audioState.playPrevious,
                      padding: EdgeInsets.all(8),
                      constraints: BoxConstraints(),
                    ),
                    IconButton(
                      icon: Icon(
                        audioState.playerState == PlayerState.playing
                            ? Icons.pause
                            : Icons.play_arrow,
                        color: primaryColor,
                      ),
                      onPressed: () {
                        if (audioState.playerState == PlayerState.playing) {
                          audioState.pause();
                        } else {
                          if (audioState.currentlyPlayingTerm != null) {
                            audioState.resume();
                          }
                        }
                      },
                      padding: EdgeInsets.all(8),
                      constraints: BoxConstraints(),
                    ),
                    IconButton(
                      icon: Icon(Icons.skip_next, color: primaryColor),
                      onPressed: () => audioState.playNext(),
                      padding: EdgeInsets.all(8),
                      constraints: BoxConstraints(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
