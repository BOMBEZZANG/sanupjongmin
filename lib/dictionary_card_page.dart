import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';
import 'database_helper.dart';
import 'constants.dart';
import 'home.dart';

class DictionaryCardPage extends StatefulWidget {
  final String? category; // Optional category filter
  
  const DictionaryCardPage({
    Key? key,
    this.category,
  }) : super(key: key);
  
  @override
  _DictionaryCardPageState createState() => _DictionaryCardPageState();
}

class _DictionaryCardPageState extends State<DictionaryCardPage> with TickerProviderStateMixin {
  // Core state
  late DatabaseHelper dbHelper;
  List<Map<String, dynamic>> terms = [];
  int currentIndex = 0;
  bool isLoading = true;
  bool showDefinition = false;
  Set<String> knownTerms = {};
  
  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _flipController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  @override
  void initState() {
    super.initState();
    dbHelper = DatabaseHelper.getInstance('assets/dictionary.db');
    print('DictionaryCardPage: DatabaseHelper initialized with path assets/dictionary.db');
    _loadTerms();
    _loadKnownTerms();
    _loadFavoriteTerms();
    
    // Animation controllers setup
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _flipController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    
    _slideAnimation = Tween<Offset>(begin: Offset(0, 0.2), end: Offset.zero).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );
    
    // Start animations
    _fadeController.forward();
    _slideController.forward();
  }
  
  @override
  void dispose() {
    dbHelper.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _flipController.dispose();
    super.dispose();
  }
  
  // Load terms from database
  Future<void> _loadTerms() async {
    try {
      setState(() => isLoading = true);
      
      print('DictionaryCardPage: Loading terms from assets/dictionary.db');
      
      // 데이터베이스 연결 테스트
      final db = await dbHelper.database;
      print('DictionaryCardPage: Database connection successful');
      
      // 테이블 존재 여부 및 스키마 확인
      final tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table' AND name='dictionary'");
      print('DictionaryCardPage: Tables query result: $tables');
      
      if (tables.isEmpty) {
        print('DictionaryCardPage: ERROR - dictionary table does not exist!');
        setState(() {
          isLoading = false;
        });
        return;
      }
      
      // 테이블 구조 확인
      final columns = await db.rawQuery("PRAGMA table_info(dictionary)");
      print('DictionaryCardPage: Table structure: $columns');
      
      print('DictionaryCardPage: dictionary table exists, now getting data');
      
      // 직접 SQL 쿼리로 데이터 가져오기
      List<Map<String, dynamic>> loadedTerms;
      
      if (widget.category != null && widget.category!.isNotEmpty) {
        print('DictionaryCardPage: Loading terms for category: ${widget.category}');
        loadedTerms = await db.rawQuery(
          "SELECT * FROM dictionary WHERE category = ? ORDER BY term ASC",
          [widget.category]
        );
      } else {
        print('DictionaryCardPage: Loading all terms');
        loadedTerms = await db.rawQuery("SELECT * FROM dictionary ORDER BY term ASC");
      }
      
      print('DictionaryCardPage: Raw query returned ${loadedTerms.length} terms');
      
      if (loadedTerms.isEmpty) {
        print('DictionaryCardPage: WARNING - No terms found. Sample of first 10 rows in table:');
        final sampleRows = await db.rawQuery("SELECT * FROM dictionary LIMIT 10");
        print('Sample rows: $sampleRows');
      } else {
        print('DictionaryCardPage: First term: ${loadedTerms.first}');
      }
      
      // 로컬 변수에 복사 (읽기 전용 객체의 변경을 방지)
      List<Map<String, dynamic>> termsCopy = List<Map<String, dynamic>>.from(loadedTerms);
      
      // Shuffle terms for flashcard mode (로컬 복사본에서 수행)
      if (termsCopy.isNotEmpty) {
        termsCopy.shuffle(Random());
        print('DictionaryCardPage: Terms shuffled for flashcard mode, count: ${termsCopy.length}');
      }
      
      setState(() {
        terms = termsCopy;
        isLoading = false;
        print('DictionaryCardPage: Terms set in state, count: ${terms.length}');
      });
    } catch (e) {
      print('DictionaryCardPage: Error loading terms: $e');
      setState(() => isLoading = false);
    }
  }
  
  // Load known terms from preferences
  Future<void> _loadKnownTerms() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final known = prefs.getStringList('dictionary_known_terms') ?? [];
      setState(() {
        knownTerms = known.toSet();
      });
    } catch (e) {
      print('Error loading known terms: $e');
    }
  }
  
  // Mark term as known/unknown
  Future<void> _toggleKnownTerm(String termName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final known = prefs.getStringList('dictionary_known_terms') ?? [];
      
      if (knownTerms.contains(termName)) {
        known.remove(termName);
        knownTerms.remove(termName);
      } else {
        known.add(termName);
        knownTerms.add(termName);
      }
      
      await prefs.setStringList('dictionary_known_terms', known);
      setState(() {});
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            knownTerms.contains(termName) 
                ? '용어를 아는 것으로 표시했습니다.' 
                : '용어를 모르는 것으로 표시했습니다.',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          backgroundColor: Color(0xFF2196F3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: Duration(milliseconds: 1500),
        ),
      );
    } catch (e) {
      print('Error toggling known term: $e');
    }
  }
  
  // Flip card to show/hide definition
  void _flipCard() {
    setState(() {
      showDefinition = !showDefinition;
    });
    
    if (showDefinition) {
      _flipController.forward();
    } else {
      _flipController.reverse();
    }
  }
  
  // Navigate to next card
  void _nextCard() {
    if (currentIndex < terms.length - 1) {
      setState(() {
        currentIndex++;
        showDefinition = false;
      });
      _flipController.reset();
    }
  }
  
  // Navigate to previous card
  void _previousCard() {
    if (currentIndex > 0) {
      setState(() {
        currentIndex--;
        showDefinition = false;
      });
      _flipController.reset();
    }
  }
  
  // Modern header widget
  Widget _buildModernHeader(bool isDarkMode) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.white.withOpacity(0.15) : Colors.white.withOpacity(0.7),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: isDarkMode ? Colors.white.withOpacity(0.2) : Colors.black.withOpacity(0.1)),
              ),
              child: Icon(
                Icons.arrow_back_ios_rounded,
                color: isDarkMode ? Colors.white : Colors.black87,
                size: 16,
              ),
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '암기카드 모드',
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black87,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                  ),
                ),
                Text(
                  widget.category != null && widget.category!.isNotEmpty
                      ? '${widget.category} - ${terms.length}개 용어'
                      : '전체 - ${terms.length}개 용어',
                  style: TextStyle(
                    color: isDarkMode ? Colors.white.withOpacity(0.8) : Colors.black54,
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => HomePage())),
            child: Container(
              padding: EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.white.withOpacity(0.15) : Colors.white.withOpacity(0.7),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: isDarkMode ? Colors.white.withOpacity(0.2) : Colors.black.withOpacity(0.1)),
              ),
              child: Icon(
                Icons.home_rounded,
                color: isDarkMode ? Colors.white : Colors.black87,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // Progress indicator
  Widget _buildProgressIndicator(bool isDarkMode) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '진행도: ${currentIndex + 1}/${terms.length}',
                style: TextStyle(
                  color: isDarkMode ? Colors.white.withOpacity(0.8) : Colors.black54,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                terms.isEmpty ? '0%' : '${((currentIndex + 1) / terms.length * 100).toInt()}%',
                style: TextStyle(
                  color: Color(0xFF8B5CF6),
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
              value: terms.isEmpty ? 0 : (currentIndex + 1) / terms.length,
              backgroundColor: isDarkMode ? Colors.white.withOpacity(0.1) : Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8B5CF6)),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }
  
  // Flashcard widget
  Widget _buildFlashcard(bool isDarkMode) {
    if (terms.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.layers_outlined,
              size: 48,
              color: isDarkMode ? Colors.white.withOpacity(0.5) : Colors.black54,
            ),
            SizedBox(height: 16),
            Text(
              '사용 가능한 용어가 없습니다',
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black87,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8),
            Text(
              '데이터베이스 문제가 발생했을 수 있습니다.\n디버그 버튼을 눌러 정보를 확인해보세요.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDarkMode ? Colors.white.withOpacity(0.7) : Colors.black54,
                fontSize: 14,
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _reloadData,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF8B5CF6),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text('다시 시도'),
            ),
          ],
        ),
      );
    }
    
    final term = terms[currentIndex];
    final termName = term['term'] ?? '';
    final definition = term['definition'] ?? '';
    final category = term['category'] ?? '';
    final isKnown = knownTerms.contains(termName);
    
    return GestureDetector(
      onTap: _flipCard,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16),
        height: 380,
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.white.withOpacity(0.1) : Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isDarkMode ? Colors.white.withOpacity(0.2) : Colors.black.withOpacity(0.1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: AnimatedSwitcher(
          duration: Duration(milliseconds: 300), // 애니메이션 시간을 약간 줄여 더 빠르게 느껴지도록 합니다.
          transitionBuilder: (Widget child, Animation<double> animation) {
            // 간단한 FadeTransition 사용
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          child: showDefinition 
              ? _buildCardBack(definition, category, isDarkMode) 
              : _buildCardFront(termName, category, isKnown, isDarkMode),
        ),
      ),
    );
  }
  
  // Front of flashcard (term)
  Widget _buildCardFront(String termName, String category, bool isKnown, bool isDarkMode) {
    // 해당 용어가 즐겨찾기에 있는지 확인
    bool isFavorite = _isTermFavorite(termName);
    
    return Container(
      key: ValueKey(false),
      padding: EdgeInsets.all(24),
      width: double.infinity,
      height: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Color(0xFF8B5CF6).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  category,
                  style: TextStyle(
                    color: Color(0xFF8B5CF6),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Spacer(),
              // 즐겨찾기 버튼
              GestureDetector(
                onTap: () => _toggleFavoriteTerm(termName),
                child: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isFavorite 
                        ? Color(0xFFEC4899).withOpacity(0.2) 
                        : Colors.grey.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    color: isFavorite ? Color(0xFFEC4899) : Colors.grey,
                    size: 20,
                  ),
                ),
              ),
              SizedBox(width: 8),
              // 암기 완료 체크 버튼
              GestureDetector(
                onTap: () => _toggleKnownTerm(termName),
                child: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isKnown 
                        ? Color(0xFF10B981).withOpacity(0.2) 
                        : Colors.grey.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isKnown ? Icons.check_circle_rounded : Icons.circle_outlined,
                    color: isKnown ? Color(0xFF10B981) : Colors.grey,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
          Expanded(
            child: Center(
              child: Text(
                termName,
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black87,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  height: 1.3,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          Center(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Color(0xFF8B5CF6).withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.touch_app_rounded, // 아이콘은 유지하거나 변경할 수 있습니다.
                    color: Color(0xFF8B5CF6),
                    size: 18,
                  ),
                  SizedBox(width: 8),
                  Text(
                    '뒤집기', // <<--- 여기를 수정했습니다.
                    style: TextStyle(
                      color: Color(0xFF8B5CF6),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // Back of flashcard (definition)
  Widget _buildCardBack(String definition, String category, bool isDarkMode) {
    return Container(
      key: ValueKey(true),
      padding: EdgeInsets.all(24),
      width: double.infinity,
      height: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Color(0xFF8B5CF6).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  category,
                  style: TextStyle(
                    color: Color(0xFF8B5CF6),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Color(0xFF6366F1).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '정의',
                  style: TextStyle(
                    color: Color(0xFF6366F1),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                child: Text(
                  definition,
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black87,
                    fontSize: 18,
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
                color: Color(0xFF8B5CF6).withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.touch_app_rounded,
                    color: Color(0xFF8B5CF6),
                    size: 18,
                  ),
                  SizedBox(width: 8),
                  Text(
                    '뒤집기',
                    style: TextStyle(
                      color: Color(0xFF8B5CF6),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // Navigation controls
  Widget _buildNavigationControls(bool isDarkMode) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Previous button
          GestureDetector(
            onTap: currentIndex > 0 ? _previousCard : null,
            child: Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: currentIndex > 0
                    ? (isDarkMode ? Colors.white.withOpacity(0.1) : Colors.white.withOpacity(0.7))
                    : (isDarkMode ? Colors.white.withOpacity(0.05) : Colors.grey.shade200),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: currentIndex > 0
                      ? (isDarkMode ? Colors.white.withOpacity(0.2) : Colors.black.withOpacity(0.1))
                      : Colors.transparent,
                ),
              ),
              child: Icon(
                Icons.arrow_back_rounded,
                color: currentIndex > 0
                    ? (isDarkMode ? Colors.white : Colors.black87)
                    : Colors.grey,
                size: 24,
              ),
            ),
          ),
          
          // Flip button
          // GestureDetector(
          //   onTap: _flipCard,
          //   child: Container(
          //     padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          //     decoration: BoxDecoration(
          //       color: Color(0xFF8B5CF6),
          //       borderRadius: BorderRadius.circular(16),
          //       boxShadow: [
          //         BoxShadow(
          //           color: Color(0xFF8B5CF6).withOpacity(0.3),
          //           blurRadius: 8,
          //           offset: Offset(0, 4),
          //         ),
          //       ],
          //     ),
          //     child: Row(
          //       children: [
          //         Icon(
          //           Icons.flip_rounded,
          //           color: Colors.white,
          //           size: 24,
          //         ),
          //         SizedBox(width: 8),
          //         Text(
          //           '뒤집기',
          //           style: TextStyle(
          //             color: Colors.white,
          //             fontSize: 16,
          //             fontWeight: FontWeight.bold,
          //           ),
          //         ),
          //       ],
          //     ),
          //   ),
          // ),
          
          // Next button
          GestureDetector(
            onTap: currentIndex < terms.length - 1 ? _nextCard : null,
            child: Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: currentIndex < terms.length - 1
                    ? (isDarkMode ? Colors.white.withOpacity(0.1) : Colors.white.withOpacity(0.7))
                    : (isDarkMode ? Colors.white.withOpacity(0.05) : Colors.grey.shade200),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: currentIndex < terms.length - 1
                      ? (isDarkMode ? Colors.white.withOpacity(0.2) : Colors.black.withOpacity(0.1))
                      : Colors.transparent,
                ),
              ),
              child: Icon(
                Icons.arrow_forward_rounded,
                color: currentIndex < terms.length - 1
                    ? (isDarkMode ? Colors.white : Colors.black87)
                    : Colors.grey,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDarkMode
                ? [Color(0xFF2C2C2C), Color(0xFF3E3E3E), Color(0xFF4A4A4A)]
                : [Color(0xFFF5F7FA), Color(0xFFE8ECF0), Color(0xFFDDE4EA)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Column(
                children: [
                  // Modern header
                  _buildModernHeader(isDarkMode),
                  
                  // Progress indicator
                  _buildProgressIndicator(isDarkMode),
                  
                  // Main content
                  Expanded(
                    child: isLoading
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(
                                color: isDarkMode ? Colors.white : Color(0xFF8B5CF6),
                              ),
                              SizedBox(height: 16),
                              Text(
                                '암기카드를 불러오는 중...',
                                style: TextStyle(
                                  color: isDarkMode ? Colors.white.withOpacity(0.8) : Colors.black54,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        )
                      : Column(
                          children: [
                            SizedBox(height: 16),
                            
                            // Flashcard
                            _buildFlashcard(isDarkMode),
                            
                            Spacer(),
                            
                            // Navigation controls
                            _buildNavigationControls(isDarkMode),
                          ],
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  // 즐겨찾기 관련 변수와 메서드
  Set<String> favoriteTerms = {};
  
  // 용어가 즐겨찾기에 있는지 확인
  bool _isTermFavorite(String termName) {
    return favoriteTerms.contains(termName);
  }
  
  // 즐겨찾기 목록 로드
  Future<void> _loadFavoriteTerms() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favorites = prefs.getStringList('dictionary_favorites') ?? [];
      setState(() {
        favoriteTerms = favorites.toSet();
      });
    } catch (e) {
      print('Error loading favorites: $e');
    }
  }
  
  // 즐겨찾기 토글
  Future<void> _toggleFavoriteTerm(String termName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favorites = prefs.getStringList('dictionary_favorites') ?? [];
      
      if (favoriteTerms.contains(termName)) {
        favorites.remove(termName);
        favoriteTerms.remove(termName);
      } else {
        favorites.add(termName);
        favoriteTerms.add(termName);
      }
      
      await prefs.setStringList('dictionary_favorites', favorites);
      setState(() {});
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            favoriteTerms.contains(termName) 
                ? '용어가 즐겨찾기에 추가되었습니다.' 
                : '용어가 즐겨찾기에서 제거되었습니다.',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          backgroundColor: Color(0xFFEC4899),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: Duration(milliseconds: 1500),
        ),
      );
    } catch (e) {
      print('Error toggling favorite: $e');
    }
  }
  
  // 데이터 다시 로드
  void _reloadData() {
    setState(() {
      isLoading = true;
      terms = [];
    });
    _loadTerms();
  }
}