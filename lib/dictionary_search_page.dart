import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'database_helper.dart';
import 'constants.dart';
import 'home.dart';

class DictionarySearchPage extends StatefulWidget {
  final String? category; // 특정 카테고리로 필터링 (선택사항)
  final String? initialQuery; // 초기 검색어 (선택사항)

  const DictionarySearchPage({
    Key? key,
    this.category,
    this.initialQuery,
  }) : super(key: key);

  @override
  _DictionarySearchPageState createState() => _DictionarySearchPageState();
}

class _DictionarySearchPageState extends State<DictionarySearchPage> with TickerProviderStateMixin {
  late DatabaseHelper dbHelper;
  
  // 검색 관련
  TextEditingController _searchController = TextEditingController();
  String selectedCategory = '';
  List<Map<String, dynamic>> allTerms = [];
  List<Map<String, dynamic>> filteredTerms = [];
  bool isLoading = true;
  
  // 즐겨찾기
  Set<String> favoriteTerms = {};
  
  // 애니메이션 컨트롤러들
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    dbHelper = DatabaseHelper.getInstance('assets/dictionary.db');
    selectedCategory = widget.category ?? '';
    
    if (widget.initialQuery != null) {
      _searchController.text = widget.initialQuery!;
    }
    
    _loadFavorites();
    _loadTerms();
    
    // 애니메이션 컨트롤러 초기화
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(begin: Offset(0, 0.2), end: Offset.zero).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );

    // 애니메이션 시작
    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  /// 즐겨찾기 로드
  Future<void> _loadFavorites() async {
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

  /// 용어 데이터 로드
  Future<void> _loadTerms() async {
    try {
      setState(() => isLoading = true);
      
      List<Map<String, dynamic>> terms;
      
      if (selectedCategory.isNotEmpty) {
        terms = await dbHelper.getTermsByCategory(selectedCategory);
      } else {
        terms = await dbHelper.getAllTerms();
      }
      
      setState(() {
        allTerms = terms;
        _applyFilters();
        isLoading = false;
      });
    } catch (e) {
      print('Error loading terms: $e');
      setState(() => isLoading = false);
    }
  }

  /// 검색 및 필터 적용
/// 검색 및 필터 적용
void _applyFilters() {
  List<Map<String, dynamic>> filtered = allTerms;
  
  // 검색어 필터
  final query = _searchController.text.trim().toLowerCase();
  if (query.isNotEmpty) {
    filtered = filtered.where((term) {
      final termName = (term['term'] ?? '').toString().toLowerCase();
      // definition 검색 제거, 용어(term)만 검색
      return termName.contains(query);
    }).toList();
  }
  
  setState(() {
    filteredTerms = filtered;
  });
}

  /// 카테고리 변경
  void _changeCategory(String category) {
    setState(() {
      selectedCategory = category;
    });
    _loadTerms();
  }

  /// 즐겨찾기 토글
  Future<void> _toggleFavorite(String termName) async {
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
          backgroundColor: Color(0xFF2196F3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: Duration(milliseconds: 1500),
        ),
      );
    } catch (e) {
      print('Error toggling favorite: $e');
    }
  }

  /// 용어 상세보기로 이동
  void _viewTermDetail(Map<String, dynamic> term) {
    print('용어 상세보기: ${term['term']}');
    // Navigator.push(context, MaterialPageRoute(builder: (_) => DictionaryDetailPage(term: term)));
  }

  /// 모던 헤더
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
                  selectedCategory.isNotEmpty ? '$selectedCategory 용어' : '용어 검색',
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black87,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                  ),
                ),
                Text(
                  '${filteredTerms.length}개 용어',
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

  /// 검색바
  Widget _buildSearchBar(bool isDarkMode) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.white.withOpacity(0.1) : Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: isDarkMode ? Colors.white.withOpacity(0.2) : Colors.black.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => _applyFilters(),
        style: TextStyle(
          color: isDarkMode ? Colors.white : Colors.black87,
          fontSize: 16,
        ),
        decoration: InputDecoration(
          hintText: '용어명 또는 정의를 검색하세요...',
          hintStyle: TextStyle(
            color: isDarkMode ? Colors.white.withOpacity(0.6) : Colors.black54,
            fontSize: 16,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: isDarkMode ? Colors.white.withOpacity(0.7) : Colors.black54,
            size: 24,
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? GestureDetector(
                  onTap: () {
                    _searchController.clear();
                    _applyFilters();
                  },
                  child: Icon(
                    Icons.clear_rounded,
                    color: isDarkMode ? Colors.white.withOpacity(0.7) : Colors.black54,
                    size: 20,
                  ),
                )
              : null,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  /// 카테고리 필터 칩들
  Widget _buildCategoryFilters(bool isDarkMode) {
    return Container(
      height: 50,
      margin: EdgeInsets.symmetric(vertical: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildCategoryChip('전체', '', isDarkMode),
          ...categories.map((category) => _buildCategoryChip(category, category, isDarkMode)),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String label, String value, bool isDarkMode) {
    final isSelected = selectedCategory == value;
    
    return GestureDetector(
      onTap: () => _changeCategory(value),
      child: Container(
        margin: EdgeInsets.only(right: 8),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected 
              ? Color(0xFF6366F1) 
              : (isDarkMode ? Colors.white.withOpacity(0.1) : Colors.white.withOpacity(0.7)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected 
                ? Color(0xFF6366F1) 
                : (isDarkMode ? Colors.white.withOpacity(0.2) : Colors.black.withOpacity(0.1)),
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: Color(0xFF6366F1).withOpacity(0.3),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ] : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected 
                ? Colors.white 
                : (isDarkMode ? Colors.white.withOpacity(0.8) : Colors.black87),
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  /// 용어 카드
  Widget _buildTermCard(Map<String, dynamic> term, bool isDarkMode) {
    final termName = term['term'] ?? '';
    final definition = term['definition'] ?? '';
    final category = term['category'] ?? '';
    final isFavorite = favoriteTerms.contains(termName);

    return GestureDetector(
      onTap: () => _viewTermDetail(term),
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.white.withOpacity(0.1) : Colors.white.withOpacity(0.9),
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
              // 상단: 용어명, 카테고리, 즐겨찾기
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          termName,
                          style: TextStyle(
                            color: isDarkMode ? Colors.white : Colors.black87,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Color(0xFF6366F1).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            category,
                            style: TextStyle(
                              color: Color(0xFF6366F1),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _toggleFavorite(termName),
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
                ],
              ),
              
              SizedBox(height: 12),
              
              // 정의
              Text(
                definition,
                style: TextStyle(
                  color: isDarkMode ? Colors.white.withOpacity(0.8) : Colors.black87,
                  fontSize: 15,
                  height: 1.4,
                ),
            //     maxLines: 3,
            //     overflow: TextOverflow.ellipsis,
            //   ),
              
            //   SizedBox(height: 12),
              
            //   // 더보기 버튼
            //   Row(
            //     mainAxisAlignment: MainAxisAlignment.end,
            //     children: [
            //       Text(
            //         '자세히 보기',
            //         style: TextStyle(
            //           color: Color(0xFF6366F1),
            //           fontSize: 14,
            //           fontWeight: FontWeight.w600,
            //         ),
            //       ),
            //       SizedBox(width: 4),
            //       Icon(
            //         Icons.arrow_forward_ios_rounded,
            //         color: Color(0xFF6366F1),
            //         size: 14,
            //       ),
            //     ],
              ),
            ],
          ),
        ),
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
                  // 모던 헤더
                  _buildModernHeader(isDarkMode),
                  
                  // 검색바
                  _buildSearchBar(isDarkMode),
                  
                  // 카테고리 필터
                  _buildCategoryFilters(isDarkMode),
                  
                  // 메인 콘텐츠
                  Expanded(
                    child: isLoading
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircularProgressIndicator(
                                  color: isDarkMode ? Colors.white : Color(0xFF6366F1),
                                ),
                                SizedBox(height: 16),
                                Text(
                                  '용어를 불러오는 중...',
                                  style: TextStyle(
                                    color: isDarkMode ? Colors.white.withOpacity(0.8) : Colors.black54,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : filteredTerms.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.search_off_rounded,
                                      size: 48,
                                      color: isDarkMode ? Colors.white.withOpacity(0.5) : Colors.black54,
                                    ),
                                    SizedBox(height: 16),
                                    Text(
                                      _searchController.text.isNotEmpty 
                                          ? '검색 결과가 없습니다' 
                                          : '용어가 없습니다',
                                      style: TextStyle(
                                        color: isDarkMode ? Colors.white : Colors.black87,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      _searchController.text.isNotEmpty 
                                          ? '다른 검색어를 시도해보세요' 
                                          : '아직 등록된 용어가 없습니다',
                                      style: TextStyle(
                                        color: isDarkMode ? Colors.white.withOpacity(0.7) : Colors.black54,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                padding: EdgeInsets.symmetric(vertical: 8),
                                itemCount: filteredTerms.length,
                                itemBuilder: (context, index) {
                                  final term = filteredTerms[index];
                                  return _buildTermCard(term, isDarkMode);
                                },
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
}