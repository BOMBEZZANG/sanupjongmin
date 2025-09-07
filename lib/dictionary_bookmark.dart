import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math'; // For max function
import 'database_helper.dart';
import 'constants.dart'; // primaryColor, favoriteColor 등
import 'home.dart'; // 홈으로 이동

class DictionaryBookmarkPage extends StatefulWidget {
  const DictionaryBookmarkPage({Key? key}) : super(key: key);

  @override
  _DictionaryBookmarkPageState createState() => _DictionaryBookmarkPageState();
}

class _DictionaryBookmarkPageState extends State<DictionaryBookmarkPage> with TickerProviderStateMixin {
  late DatabaseHelper dbHelper;
  List<Map<String, dynamic>> favoriteTermsDetails = [];
  Set<String> favoriteTermNames = {};
  bool isLoading = true;
  bool isListView = true;

  PageController? _pageController;
  int _currentCardIndex = 0;
  bool _showDefinitionForCurrentPage = false;

  // Animation controllers (not strictly needed if only using FadeTransition for card flip)
  // late AnimationController _flipController; // Kept for structural similarity if needed later

  @override
  void initState() {
    super.initState();
    dbHelper = DatabaseHelper.getInstance('assets/dictionary.db');
    _loadFavoriteTerms();

    // _flipController = AnimationController(
    //   duration: const Duration(milliseconds: 300),
    //   vsync: this,
    // );
  }

  @override
  void dispose() {
    _pageController?.dispose();
    // _flipController.dispose();
    dbHelper.dispose(); // dbHelper도 dispose 해주는 것이 좋습니다.
    super.dispose();
  }

  Future<void> _loadFavoriteTerms() async {
    setState(() => isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    favoriteTermNames = (prefs.getStringList('dictionary_favorites') ?? []).toSet();

    List<Map<String, dynamic>> details = [];
    for (String termName in favoriteTermNames) {
      final termData = await dbHelper.getTermByName(termName);
      if (termData != null) {
        details.add(termData);
      }
    }
    details.sort((a, b) => (a['term'] as String).compareTo(b['term'] as String));

    setState(() {
      favoriteTermsDetails = details;
      isLoading = false;
      if (favoriteTermsDetails.isNotEmpty) {
        _currentCardIndex = min(_currentCardIndex, favoriteTermsDetails.length - 1);
         _pageController = PageController(initialPage: _currentCardIndex);
      } else {
        _pageController = null;
      }
      _showDefinitionForCurrentPage = false;
    });
  }

  Future<void> _toggleFavorite(String termName, {bool fromCardView = false}) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> favorites = prefs.getStringList('dictionary_favorites') ?? [];
    
    int oldIndex = _currentCardIndex;

    if (favoriteTermNames.contains(termName)) {
      favorites.remove(termName);
      favoriteTermNames.remove(termName);
      favoriteTermsDetails.removeWhere((term) => term['term'] == termName);
    }

    await prefs.setStringList('dictionary_favorites', favorites);
    
    setState(() {
      if (favoriteTermsDetails.isEmpty) {
        isListView = true; // 항목이 없으면 리스트뷰로 전환 (또는 다른 UI 처리)
        _pageController = null;
        _currentCardIndex = 0;
      } else {
        // 현재 인덱스가 삭제로 인해 범위를 벗어나는 경우 조정
        _currentCardIndex = min(oldIndex, favoriteTermsDetails.length - 1);
        _currentCardIndex = max(0, _currentCardIndex); // 0보다 작아지지 않도록

        if (!isListView) {
           // PageController가 이미 생성되어 있다면, 페이지를 다시 설정할 필요는 없을 수 있습니다.
           // PageView.builder가 itemCount 변경을 감지하고 다시 빌드합니다.
           // 다만, 삭제 후 현재 인덱스가 변경되었다면 해당 페이지로 이동하거나 상태를 초기화할 수 있습니다.
          if (_pageController == null || _pageController?.hasClients == false) {
            _pageController = PageController(initialPage: _currentCardIndex);
          } else if (_pageController!.page?.round() != _currentCardIndex) {
            // 페이지가 실제로 변경되어야 할 때만 jumpToPage 또는 animateToPage 호출
            // WidgetsBinding.instance.addPostFrameCallback((_) { // UI 빌드 후 실행
            //   _pageController?.jumpToPage(_currentCardIndex);
            // });
          }
        }
      }
      _showDefinitionForCurrentPage = false; // 카드가 변경되거나 삭제되면 앞면으로
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('용어가 즐겨찾기에서 제거되었습니다.', style: TextStyle(fontWeight: FontWeight.w500)),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: Duration(milliseconds: 1500),
      ),
    );
  }

  void _toggleView() {
    setState(() {
      isListView = !isListView;
      if (!isListView && favoriteTermsDetails.isNotEmpty) {
        _pageController = PageController(initialPage: _currentCardIndex);
        _showDefinitionForCurrentPage = false;
      } else {
        // _pageController?.dispose(); // dispose는 여기서 하지 않고, State의 dispose에서 처리
        // _pageController = null;
      }
    });
  }

  void _flipCurrentCard() {
    setState(() {
      _showDefinitionForCurrentPage = !_showDefinitionForCurrentPage;
    });
    // if (_showDefinitionForCurrentPage) {
    //   _flipController.forward();
    // } else {
    //   _flipController.reverse();
    // }
  }

  void _previousCard() {
    if (_currentCardIndex > 0) {
      _pageController?.previousPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      // onPageChanged 콜백이 _currentCardIndex와 _showDefinitionForCurrentPage를 업데이트합니다.
    }
  }

  void _nextCard() {
    if (_currentCardIndex < favoriteTermsDetails.length - 1) {
      _pageController?.nextPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      // onPageChanged 콜백이 _currentCardIndex와 _showDefinitionForCurrentPage를 업데이트합니다.
    }
  }

  Widget _buildTermListItem(Map<String, dynamic> term, bool isDarkMode) {
    final termName = term['term'] ?? 'N/A';
    final definition = term['definition'] ?? 'N/A';
    final category = term['category'] ?? 'N/A';

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.white.withOpacity(0.1) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDarkMode ? Colors.white.withOpacity(0.2) : Colors.black.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    termName,
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black87,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.favorite, color: favoriteColor),
                  onPressed: () => _toggleFavorite(termName),
                  tooltip: '즐겨찾기 해제',
                ),
              ],
            ),
            SizedBox(height: 4),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                category,
                style: TextStyle(color: primaryColor, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
            SizedBox(height: 12),
            Text(
              definition,
              style: TextStyle(
                color: isDarkMode ? Colors.white.withOpacity(0.8) : Colors.black54,
                fontSize: 15,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookmarkCardFront(Map<String, dynamic> termData, bool isDarkMode) {
    final termName = termData['term'] ?? 'N/A';
    final category = termData['category'] ?? 'N/A';

    return Container(
      key: ValueKey<String>('front_${termName}'), // 고유한 키
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  category,
                  style: TextStyle(color: primaryColor, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
              IconButton(
                icon: Icon(Icons.favorite_rounded, color: favoriteColor, size: 24),
                onPressed: () => _toggleFavorite(termName, fromCardView: true),
                tooltip: '즐겨찾기 해제',
              ),
            ],
          ),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                child: Text(
                  termName,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black87,
                    fontSize: 28, // DictionaryCardPage와 유사한 크기
                    fontWeight: FontWeight.bold,
                    height: 1.3,
                  ),
                ),
              ),
            ),
          ),
          Center(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.touch_app_rounded, color: primaryColor, size: 18),
                  SizedBox(width: 8),
                  Text('뒤집기', style: TextStyle(color: primaryColor, fontSize: 14, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookmarkCardBack(Map<String, dynamic> termData, bool isDarkMode) {
    final definition = termData['definition'] ?? 'N/A';
    final termName = termData['term'] ?? 'N/A';
    final category = termData['category'] ?? 'N/A';


    return Container(
      key: ValueKey<String>('back_${termName}'), // 고유한 키
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
               Container( // 카테고리 표시 (DictionaryCardPage와 유사하게)
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  category,
                  style: TextStyle(color: primaryColor, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.2), // 다른 색상 사용 가능
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('정의', style: TextStyle(color: primaryColor, fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                child: Text(
                  definition,
                  textAlign: TextAlign.start, // 정의는 보통 왼쪽 정렬
                  style: TextStyle(
                    color: isDarkMode ? Colors.white.withOpacity(0.9) : Colors.black.withOpacity(0.8),
                    fontSize: 18, // DictionaryCardPage와 유사한 크기
                    height: 1.5,
                  ),
                ),
              ),
            ),
          ),
          Center(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.touch_app_rounded, color: primaryColor, size: 18),
                  SizedBox(width: 8),
                  Text('뒤집기', style: TextStyle(color: primaryColor, fontSize: 14, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildProgressIndicator(bool isDarkMode) {
    if (favoriteTermsDetails.isEmpty) return SizedBox.shrink();
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '진행도: ${_currentCardIndex + 1}/${favoriteTermsDetails.length}',
                style: TextStyle(
                  color: isDarkMode ? Colors.white.withOpacity(0.8) : Colors.black54,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${((_currentCardIndex + 1) / favoriteTermsDetails.length * 100).toInt()}%',
                style: TextStyle(
                  color: primaryColor, // DictionaryCardPage의 보라색 계열
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (_currentCardIndex + 1) / favoriteTermsDetails.length,
              backgroundColor: isDarkMode ? Colors.white.withOpacity(0.1) : Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(primaryColor), // DictionaryCardPage의 보라색 계열
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationControls(bool isDarkMode) {
     if (favoriteTermsDetails.isEmpty) return SizedBox.shrink();
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween, // 양쪽으로 배치
        children: [
          GestureDetector(
            onTap: _currentCardIndex > 0 ? _previousCard : null,
            child: Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _currentCardIndex > 0
                    ? (isDarkMode ? Colors.white.withOpacity(0.15) : Colors.white.withOpacity(0.8))
                    : (isDarkMode ? Colors.white.withOpacity(0.05) : Colors.grey.shade300),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _currentCardIndex > 0
                      ? (isDarkMode ? Colors.white.withOpacity(0.2) : Colors.black.withOpacity(0.15))
                      : Colors.transparent,
                ),
              ),
              child: Icon(
                Icons.arrow_back_rounded,
                color: _currentCardIndex > 0
                    ? (isDarkMode ? Colors.white : Colors.black87)
                    : Colors.grey.shade500,
                size: 24,
              ),
            ),
          ),
          // 즐겨찾기 버튼 (카드 중앙 하단 대신 여기에 배치 가능)
          // IconButton(
          //   icon: Icon(Icons.favorite_rounded, color: favoriteColor, size: 28),
          //   onPressed: () {
          //     if (favoriteTermsDetails.isNotEmpty) {
          //       _toggleFavorite(favoriteTermsDetails[_currentCardIndex]['term']!, fromCardView: true);
          //     }
          //   },
          //   tooltip: '즐겨찾기 해제',
          // ),
          GestureDetector(
            onTap: _currentCardIndex < favoriteTermsDetails.length - 1 ? _nextCard : null,
            child: Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _currentCardIndex < favoriteTermsDetails.length - 1
                    ? (isDarkMode ? Colors.white.withOpacity(0.15) : Colors.white.withOpacity(0.8))
                    : (isDarkMode ? Colors.white.withOpacity(0.05) : Colors.grey.shade300),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _currentCardIndex < favoriteTermsDetails.length - 1
                      ? (isDarkMode ? Colors.white.withOpacity(0.2) : Colors.black.withOpacity(0.15))
                      : Colors.transparent,
                ),
              ),
              child: Icon(
                Icons.arrow_forward_rounded,
                color: _currentCardIndex < favoriteTermsDetails.length - 1
                    ? (isDarkMode ? Colors.white : Colors.black87)
                    : Colors.grey.shade500,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildCardViewContent(bool isDarkMode) {
    if (favoriteTermsDetails.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bookmark_border_rounded, size: 60, color: Colors.grey),
            SizedBox(height: 16),
            Text('즐겨찾기한 용어가 없습니다.', style: TextStyle(fontSize: 18, color: Colors.grey)),
          ],
        ),
      );
    }

    return Column(
      children: [
        _buildProgressIndicator(isDarkMode),
        SizedBox(height: 8), // 카드와 프로그레스 바 사이 간격
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            itemCount: favoriteTermsDetails.length,
            onPageChanged: (index) {
              setState(() {
                _currentCardIndex = index;
                _showDefinitionForCurrentPage = false;
              });
            },
            itemBuilder: (context, index) {
              final termData = favoriteTermsDetails[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0), // 카드 좌우 패딩
                child: GestureDetector(
                  onTap: _flipCurrentCard,
                  child: Container(
                    height: 380, // DictionaryCardPage와 유사한 높이
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.white.withOpacity(0.1) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: isDarkMode ? Colors.white.withOpacity(0.2) : Colors.black.withOpacity(0.1)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: AnimatedSwitcher(
                      duration: Duration(milliseconds: 300),
                      transitionBuilder: (Widget child, Animation<double> animation) {
                        return FadeTransition(opacity: animation, child: child);
                      },
                      child: _showDefinitionForCurrentPage
                          ? _buildBookmarkCardBack(termData, isDarkMode)
                          : _buildBookmarkCardFront(termData, isDarkMode),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        _buildNavigationControls(isDarkMode),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? Color(0xFF1E1E1E) : Color(0xFFF4F6F8),
      appBar: AppBar(
        backgroundColor: isDarkMode ? Color(0xFF2C2C2C) : Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDarkMode ? Colors.white : Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          '즐겨찾기 용어',
          style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87, fontWeight: FontWeight.bold),
        ),
        actions: [
          if (favoriteTermsDetails.isNotEmpty)
            IconButton(
              icon: Icon(isListView ? Icons.grid_view_rounded : Icons.view_list_rounded, color: isDarkMode ? Colors.white : Colors.black87),
              onPressed: _toggleView,
              tooltip: isListView ? '카드뷰로 보기' : '리스트뷰로 보기',
            ),
          IconButton(
            icon: Icon(Icons.home_rounded, color: isDarkMode ? Colors.white : Colors.black87),
            onPressed: () => Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => HomePage()),
              (Route<dynamic> route) => false,
            ),
            tooltip: '홈으로',
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: primaryColor))
          : isListView
              ? favoriteTermsDetails.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.bookmark_border_rounded, size: 60, color: Colors.grey),
                          SizedBox(height: 16),
                          Text('즐겨찾기한 용어가 없습니다.', style: TextStyle(fontSize: 18, color: Colors.grey)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.all(8),
                      itemCount: favoriteTermsDetails.length,
                      itemBuilder: (context, index) {
                        return _buildTermListItem(favoriteTermsDetails[index], isDarkMode);
                      },
                    )
              : _buildCardViewContent(isDarkMode),
    );
  }
}