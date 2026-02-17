class Translations {
  static const Map<String, Map<String, String>> _data = {
    'English': {
      'welcome': 'Unlimited movies, TV shows, and more.',
      'watch_anywhere': 'Watch anywhere. Cancel anytime.',
      'get_started': 'GET STARTED',
      'sign_in': 'SIGN IN',
      'home': 'Home',
      'category': 'Category',
      'downloads': 'Downloads',
      'search': 'Search',
      'profile': 'My RIYOBOX',
      'trending': 'Trending Now',
      'popular': 'Popular on RIYOBOX',
      'new_releases': 'New Releases',
      'watchlist': 'My List',
      'play': 'PLAY',
      'details': 'DETAILS',
    },
    'Somali': {
      'welcome': 'Filimaan aan xad lahayn, musalsallo, iyo waxyaabo kale.',
      'watch_anywhere': 'Ka daawo meel kasta. Iska jooji wakhti kasta.',
      'get_started': 'BILOW HADDA',
      'sign_in': 'SOO GAL',
      'home': 'Hoyga',
      'category': 'Qaybaha',
      'downloads': 'Lagu soo degsaday',
      'search': 'Raadi',
      'profile': 'RIYOBOX-gayga',
      'trending': 'Hadda caan ah',
      'popular': 'Loogu jecelyahay RIYOBOX',
      'new_releases': 'Kuwa cusub',
      'watchlist': 'Liiskayga',
      'play': 'DAAWO',
      'details': 'FAAHFAAHIN',
    },
    'Arabic': {
      'welcome': 'أفلام وعروض تلفزيونية غير محدودة وغيرها الكثير.',
      'watch_anywhere': 'شاهد في أي مكان. ألغِ في أي وقت.',
      'get_started': 'ابدأ الآن',
      'sign_in': 'تسجيل الدخول',
      'home': 'الرئيسية',
      'category': 'الفئات',
      'downloads': 'التنزيلات',
      'search': 'بحث',
      'profile': 'حسابي',
      'trending': 'الأكثر رواجاً الآن',
      'popular': 'شائع على RIYOBOX',
      'new_releases': 'إصدارات جديدة',
      'watchlist': 'قائمتي',
      'play': 'تشغيل',
      'details': 'التفاصيل',
    },
  };

  static String translate(String key, String language) {
    return _data[language]?[key] ?? _data['English']![key] ?? key;
  }
}
