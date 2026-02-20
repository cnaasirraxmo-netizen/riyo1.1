
import 'package:flutter_test/flutter_test.dart';
import 'package:riyobox/providers/football_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  group('FootballProvider Tests', () {
    test('Initial state should be empty', () {
      final provider = FootballProvider();
      expect(provider.fixtures, isEmpty);
      expect(provider.isLoading, isFalse);
    });

    test('isFollowing should return false for unknown team', () {
      final provider = FootballProvider();
      expect(provider.isFollowing(123), isFalse);
    });

    test('toggleFollowTeam should add/remove team', () {
      final provider = FootballProvider();
      provider.toggleFollowTeam(123);
      expect(provider.isFollowing(123), isTrue);

      provider.toggleFollowTeam(123);
      expect(provider.isFollowing(123), isFalse);
    });

    test('setLeague should update selected league', () {
      final provider = FootballProvider();
      provider.setLeague(140);
      expect(provider.selectedLeague, 140);
    });
  });
}
