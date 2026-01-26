import 'dart:math';

class LoadingAnimations {
  static const _basePath = 'assets/lottie';
  static const _count = 4;
  static final _random = Random();

  static String byIndex(int index) {
    assert(index >= 1 && index <= _count);
    return '$_basePath/loading_$index.lottie';
  }

  static String random() {
    final index = _random.nextInt(_count) + 1;
    return byIndex(index);
  }

  static List<String> get all => List.generate(_count, (i) => byIndex(i + 1));
}

class LoadingTexts {
  static final _random = Random();

  static const _texts = [
    'Fetching happy tails… 🐶',
    'Calling the fur squad… 🐾',
    'Getting treats ready… 🦴',
    'Brushing whiskers… 🐱',
    'Chasing the data squirrel… 🐿️',
    'Loading pawsome content… 🐾',
    'Preparing pet magic… ✨',
    'Checking food bowls… 🍽️',
    'Walking the data dog… 🐕',
    'Warming up the cuddles… 🤍',
  ];

  static String random() {
    return _texts[_random.nextInt(_texts.length)];
  }

  static List<String> get all => List.unmodifiable(_texts);
}
