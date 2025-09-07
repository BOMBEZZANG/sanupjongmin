import 'summary_lecture1.dart';
import 'summary_lecture2.dart';
import 'summary_lecture3.dart';
import 'summary_lecture4.dart';
import 'summary_lecture5.dart';
import 'summary_lecture6.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'ad_helper.dart';
import 'ad_state.dart';
import 'constants.dart';
import 'home.dart';
import 'package:provider/provider.dart';
import 'config.dart';

class SummarySelectPage extends StatefulWidget {
  @override
  _SummarySelectPageState createState() => _SummarySelectPageState();
}

class _SummarySelectPageState extends State<SummarySelectPage> {
  RewardedAd? _rewardedAd;
  bool _isRewardedAdLoaded = false;
  bool _isAdStateInitialized = false; // AdState 초기화 상태 추적

  @override
  void initState() {
    super.initState();
    // _initializeAdState를 빌드 완료 후 호출하도록 수정
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) { // 위젯이 트리에 남아 있는지 확인
        _initializeAdState();
      }
    });
  }

  // AdState 초기화 대기
  Future<void> _initializeAdState() async {
    final adState = Provider.of<AdState>(context, listen: false);
    await adState.isInitialized; // AdState 초기화 완료까지 대기
    if (mounted) { // 위젯이 여전히 트리에 있는지 확인
      setState(() {
        _isAdStateInitialized = true;
      });
      if (!adState.adsRemoved && !kDisableAdsForTesting) {
        _loadRewardedAd(); // 광고 제거 상태가 아니면 광고 로드
      }
    }
  }

  void _loadRewardedAd() {
    final adState = Provider.of<AdState>(context, listen: false);
    if (adState.adsRemoved || kDisableAdsForTesting) return;

    RewardedAd.load(
      adUnitId: AdHelper.rewardedAdUnitId,
      request: AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          setState(() {
            _rewardedAd = ad;
            _isRewardedAdLoaded = true;
          });
          _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              setState(() => _isRewardedAdLoaded = false);
              if (!adState.adsRemoved && !kDisableAdsForTesting) _loadRewardedAd();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              setState(() => _isRewardedAdLoaded = false);
              if (!adState.adsRemoved && !kDisableAdsForTesting) _loadRewardedAd();
            },
          );
        },
        onAdFailedToLoad: (error) {
          print('RewardedAd failed to load: $error');
          setState(() => _isRewardedAdLoaded = false);
        },
      ),
    );
  }

  void _showRewardAdDialog(BuildContext context, String category) {
    final adState = Provider.of<AdState>(context, listen: false);
    if (adState.adsRemoved || kDisableAdsForTesting) {
      _navigateToSummaryPage(category); // 광고 제거 상태면 바로 이동
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        final isDarkMode = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: isDarkMode ? Colors.grey[800] : Colors.white,
          title: Row(
            children: [
              Icon(Icons.videocam, color: Colors.blue),
              SizedBox(width: 8),
              Text(
                '리워드 광고',
                style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
              ),
            ],
          ),
          content: Text(
            '광고를 시청하시겠습니까?\n시청 후 학습노트 페이지로 이동합니다.',
            style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.grey[800]),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // 다이얼로그만 닫기
              },
              child: Text(
                '아니오',
                style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.grey[600]),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _showRewardedAd(category);
              },
              child: Text(
                '예: 시청하기',
                style: TextStyle(color: Colors.blue),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showRewardedAd(String category) {
    final adState = Provider.of<AdState>(context, listen: false);
    if (adState.adsRemoved || kDisableAdsForTesting || !_isRewardedAdLoaded || _rewardedAd == null) {
      _navigateToSummaryPage(category); // 광고 제거 상태면 바로 이동
      return;
    }

    _rewardedAd!.show(
      onUserEarnedReward: (ad, reward) {
        print('User earned reward: $reward');
        _navigateToSummaryPage(category);
      },
    );
  }

    void _navigateToSummaryPage(String category) {
    if (category == '안전관리론') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SummaryLecture1Page(dbPath: 'assets/your_database.db'),
        ),
      );
    } else     if (category == '인간공학 및 시스템안전공학') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SummaryLecture2Page(dbPath: 'assets/your_database.db'),
        ),
      );
    } else     if (category == '기계위험방지기술') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SummaryLecture3Page(dbPath: 'assets/your_database.db'),
        ),
      );
    } else     if (category == '전기위험방지기술') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SummaryLecture4Page(dbPath: 'assets/your_database.db'),
        ),
      );
    } else     if (category == '화학설비위험방지기술') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SummaryLecture5Page(dbPath: 'assets/your_database.db'),
        ),
      );
    } else     if (category == '건설안전기술') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SummaryLecture6Page(dbPath: 'assets/your_database.db'),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$category 학습노트는 준비 중입니다.')),
      );
    }
  }

   

  @override
  void dispose() {
    _rewardedAd?.dispose();
    super.dispose();
  }

  Widget _buildCategoryButton(BuildContext context, String title, IconData icon, [Color? color]) {
    // 색상 매개변수가 제공되지 않으면 기본 색상 사용
    final buttonColor = color ?? const Color.fromARGB(255, 255, 255, 255);

    return GestureDetector(
      onTap: () {
        final adState = Provider.of<AdState>(context, listen: false);
        if (adState.adsRemoved || kDisableAdsForTesting) {
          _navigateToSummaryPage(title); // 광고 제거 상태면 바로 이동
        } else {
          _showRewardAdDialog(context, title);
        }
      },
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: buttonColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
          ],
        ),
        padding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: Colors.black),
            SizedBox(width: 8),
            Flexible(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAdStateInitialized) {
      return Scaffold(body: Center(child: CircularProgressIndicator())); // 초기화 대기 중 로딩 화면
    }

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '핵심강의 선택',
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: isDarkMode ? Color(0xFF4A5A78) : Color(0xFF6AA8F7),
        elevation: 4,
        actions: [
          IconButton(
            icon: Icon(Icons.home, color: Colors.black12),
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => HomePage()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDarkMode
                ? [Color(0xFF2D2D41), Color(0xFF4A5A78)]
                : [Color(0xFFEAF2FA), Color(0xFF9BC2FF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              SizedBox(height: 40),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: categories.map((category) {
                      return Padding(
                        padding: EdgeInsets.only(bottom: 20.0),
                        child: _buildCategoryButton(
                          context,
                          category,
                          Icons.book,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
