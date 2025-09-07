import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:fluttertoast/fluttertoast.dart';

import 'widgets/common/index.dart';
import 'config.dart';
import 'constants.dart';
import 'home.dart';
import 'database_helper.dart';
import 'dictionary_search_page.dart';
import 'dictionary_card_page.dart';
import 'dictionary_bookmark.dart';
import 'dictionary_audio_page.dart'; // 음성 듣기 페이지 import
import 'ad_helper.dart';
import 'ad_config.dart'; // adsRemovedGlobal, kDisableAdsForTesting

class DictionarySelectPage extends StatefulWidget {
  @override
  _DictionarySelectPageState createState() => _DictionarySelectPageState();
}

class _DictionarySelectPageState extends State<DictionarySelectPage> with TickerProviderStateMixin {
  late DatabaseHelper dbHelper;
  Map<String, int> categoryStats = {};
  int totalTermsCount = 0;
  bool isLoading = true;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  RewardedAd? _rewardedAd;
  bool _isRewardedAdLoaded = false;
  String? _pendingNavigationType;
  String? _pendingCategoryForFlashcard;

  @override
  void initState() {
    super.initState();
    dbHelper = DatabaseHelper.getInstance('assets/dictionary.db');
    _loadDictionaryData();
    if (!adsRemovedGlobal && !kDisableAdsForTesting) {
      _loadRewardedAd();
    }

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

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _rewardedAd?.dispose();
    super.dispose();
  }

  Future<void> _loadDictionaryData() async {
    try {
      final stats = await dbHelper.getTermsCountByCategory();
      final allTerms = await dbHelper.getAllTerms();

      setState(() {
        categoryStats = stats;
        totalTermsCount = allTerms.length;
        isLoading = false;
      });
    } catch (e) {
      print('Error loading dictionary data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  void _loadRewardedAd() {
    if (adsRemovedGlobal || kDisableAdsForTesting) {
      print("리워드 광고 로드 건너뛰기: 광고 제거됨 또는 테스트 모드");
      return;
    }

    RewardedAd.load(
      adUnitId: AdHelper.rewardedAdUnitId,
      request: AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          print('리워드 광고가 로드되었습니다.');
          setState(() {
            _rewardedAd = ad;
            _isRewardedAdLoaded = true;
          });
          _rewardedAd!.setImmersiveMode(true);
        },
        onAdFailedToLoad: (LoadAdError error) {
          print('리워드 광고 로드 실패: $error');
          setState(() {
            _rewardedAd = null;
            _isRewardedAdLoaded = false;
          });
        },
      ),
    );
  }

  void _showRewardedAd() {
    if (adsRemovedGlobal || kDisableAdsForTesting) {
      print("리워드 광고 표시 건너뛰기: 광고 제거됨 또는 테스트 모드");
      _navigateToFeature();
      return;
    }

    if (_rewardedAd == null) {
      print('리워드 광고가 준비되지 않았습니다. 바로 이동합니다.');
      _navigateToFeature();
      if (!adsRemovedGlobal && !kDisableAdsForTesting) {
         _loadRewardedAd();
      }
      return;
    }

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (RewardedAd ad) =>
          print('리워드 광고가 표시되었습니다.'),
      onAdDismissedFullScreenContent: (RewardedAd ad) {
        print('리워드 광고가 닫혔습니다 (시청 완료 안 함 가능성).');
        ad.dispose();
        setState(() {
          _rewardedAd = null;
          _isRewardedAdLoaded = false;
        });
         if (!adsRemovedGlobal && !kDisableAdsForTesting) {
            _loadRewardedAd();
         }
        Fluttertoast.showToast(
          msg: "광고 시청을 완료해야 기능을 이용할 수 있습니다.",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
        );
        _pendingNavigationType = null;
      },
      onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError error) {
        print('리워드 광고 표시 실패: $error');
        ad.dispose();
        setState(() {
          _rewardedAd = null;
          _isRewardedAdLoaded = false;
        });
         if (!adsRemovedGlobal && !kDisableAdsForTesting) {
            _loadRewardedAd();
         }
        _navigateToFeature();
      },
    );

    _rewardedAd!.setImmersiveMode(true);
    _rewardedAd!.show(
      onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
        print('리워드 획득: ${reward.amount} ${reward.type}');
        _navigateToFeature();
      },
    );
  }

  void _navigateToFeature() {
    String? targetCategory = _pendingCategoryForFlashcard;
    _pendingCategoryForFlashcard = null;


    switch (_pendingNavigationType) {
      case 'search':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => DictionarySearchPage())
        );
        break;
      case 'flashcard':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => DictionaryCardPage(category: targetCategory))
        );
        break;
      case 'bookmarks':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => DictionaryBookmarkPage())
        );
        break;
      case 'tts': // ** 기존 'tts' 값은 용어사전 '음성 읽기'로 변경 **
        Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => DictionaryAudioPage())
        );
        break;
      default:
         print("알 수 없는 네비게이션 타입: $_pendingNavigationType. 이동하지 않습니다.");
    }
    _pendingNavigationType = null;
  }

  void _showRewardAdDialog(String navigationType, {String? category}) {
     if (adsRemovedGlobal || kDisableAdsForTesting) {
      print("광고 다이얼로그 건너뛰기: 광고 제거됨 또는 테스트 모드. 바로 기능으로 이동합니다.");
      _pendingNavigationType = navigationType;
      _pendingCategoryForFlashcard = category;
      _navigateToFeature();
      return;
    }

    setState(() {
      _pendingNavigationType = navigationType;
      _pendingCategoryForFlashcard = category;
    });

    String featureName = '';
    IconData featureIcon = Icons.play_circle_filled_rounded;

    switch (navigationType) {
      case 'search':
        featureName = '용어 검색';
        featureIcon = Icons.search_rounded;
        break;
      case 'flashcard':
        featureName = '암기카드';
        featureIcon = Icons.style_rounded;
        break;
      case 'bookmarks':
        featureName = '즐겨찾기';
        featureIcon = Icons.bookmark_rounded;
        break;
      case 'tts': // ** 'tts'는 이제 용어사전 음성 듣기를 의미 **
        featureName = '음성듣기';
        featureIcon = Icons.volume_up_rounded;
        break;
      default:
        featureName = '선택된 기능';
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        final isDarkMode = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDarkMode ? Color(0xFF2C2C2C) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  featureIcon,
                  color: primaryColor,
                  size: 24,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  '$featureName 광고 시청',
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black87,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$featureName을(를) 이용하려면 짧은 광고를 시청해주세요.',
                style: TextStyle(
                  color: isDarkMode ? Colors.white.withOpacity(0.8) : Colors.black87,
                  fontSize: 16,
                  height: 1.4,
                ),
              ),
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Color(0xFF10B981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Color(0xFF10B981).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.star_rounded,
                      color: Color(0xFF10B981),
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '광고 시청 완료 후 모든 기능을 이용할 수 있습니다.',
                        style: TextStyle(
                          color: Color(0xFF10B981),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _pendingNavigationType = null;
                  _pendingCategoryForFlashcard = null;
                });
              },
              child: Text(
                '취소',
                style: TextStyle(
                  color: isDarkMode ? Colors.white.withOpacity(0.7) : Colors.black54,
                  fontSize: 16,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                if (!_isRewardedAdLoaded && !adsRemovedGlobal && !kDisableAdsForTesting) {
                  _loadRewardedAd();
                }
                _showRewardedAd();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: Text(
                '광고 시청하기',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

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
                  '용어사전',
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black87,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                  ),
                ),
                Text(
                  '핵심 용어를 학습하세요',
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
            onTap: () => Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => HomePage()),
                (Route<dynamic> route) => false,
            ),
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

  Widget _buildSearchCard(bool isDarkMode) {
    return GestureDetector(
      onTap: () {
        _showRewardAdDialog('search');
      },
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              primaryColor,
              primaryColor.withOpacity(0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withOpacity(0.3),
              blurRadius: 12,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: -10,
                right: -10,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Icon(
                        Icons.search_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '용어 검색하기',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '${totalTermsCount}개의 용어를 검색할 수 있습니다',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: Colors.white.withOpacity(0.7),
                      size: 16,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainFeatures(bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '학습 도구',
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildFeatureCard(
                title: '암기카드',
                subtitle: '플래시카드로 암기',
                icon: Icons.style_rounded,
                color: Color(0xFF8B5CF6),
                isDarkMode: isDarkMode,
                onTap: () => _showRewardAdDialog('flashcard'),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildFeatureCard(
                title: '즐겨찾기',
                subtitle: '저장한 용어 보기',
                icon: Icons.bookmark_rounded,
                color: favoriteColor,
                isDarkMode: isDarkMode,
                onTap: () => _showRewardAdDialog('bookmarks'),
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildFeatureCard(
                title: '음성듣기', // ** '음성 읽기' 에서 '음성 듣기'로 변경 **
                subtitle: '용어 음성 듣기', // ** 부제 변경 **
                icon: Icons.volume_up_rounded,
                color: Color(0xFF10B981),
                isDarkMode: isDarkMode,
                onTap: () => _showRewardAdDialog('tts'), // ** 'tts' 네비게이션 타입 사용 **
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Container(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFeatureCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isDarkMode,
    required VoidCallback onTap,
    bool isNew = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color,
              color.withOpacity(0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 12,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: -10,
                right: -10,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              if (isNew)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'NEW',
                      style: TextStyle(
                        color: color,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        icon,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    Spacer(),
                    Text(
                      title,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
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
      body: ThemedBackgroundWidget(
        isDarkMode: isDarkMode,
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Column(
                children: [
                  CommonHeaderWidget(
                    title: '용어사전',
                    subtitle: '전공 용어를 학습하세요',
                  // ▼▼▼▼▼ 이 줄을 추가해 주세요! ▼▼▼▼▼
                  onHomePressed: () => Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => HomePage()),
                    (route) => false,
                  ),
                ),                  Expanded(
                    child: isLoading
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircularProgressIndicator(
                                  color: isDarkMode ? Colors.white : primaryColor,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  '용어 데이터를 불러오는 중...',
                                  style: TextStyle(
                                    color: isDarkMode ? Colors.white.withOpacity(0.8) : Colors.black54,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : SingleChildScrollView(
                            padding: EdgeInsets.symmetric(horizontal: 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(height: 16),
                                _buildSearchCard(isDarkMode),
                                SizedBox(height: 24),
                                _buildMainFeatures(isDarkMode),
                                SizedBox(height: 20),
                              ],
                            ),
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