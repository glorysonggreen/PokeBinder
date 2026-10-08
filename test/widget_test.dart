import 'package:flutter_test/flutter_test.dart';
import 'package:pokebinder/services/auth_service.dart';

void main() {
  group('AuthService email helpers', () {
    test('normalizeEmail trims and lowercases', () {
      expect(
        AuthService.normalizeEmail('  Ash.Ketchum@Pallet.COM '),
        'ash.ketchum@pallet.com',
      );
    });

    test('isValidEmail accepts normal addresses', () {
      expect(AuthService.isValidEmail('ash@pallet.com'), isTrue);
      expect(AuthService.isValidEmail(' misty@cerulean.gym.ph '), isTrue);
    });

    test('isValidEmail rejects malformed addresses', () {
      expect(AuthService.isValidEmail(''), isFalse);
      expect(AuthService.isValidEmail('ash'), isFalse);
      expect(AuthService.isValidEmail('ash@pallet'), isFalse);
      expect(AuthService.isValidEmail('ash @pallet.com'), isFalse);
    });
  });

  group('AuthService messages', () {
    test('duplicate account gets a clear message', () {
      final message = AuthService.signUpErrorMessage(
        const AccountAlreadyExistsException(),
      );
      expect(message, contains('already exists'));
    });

    test('non-auth errors read as a connection problem', () {
      final message = AuthService.signInErrorMessage(Exception('socket'));
      expect(message.toLowerCase(), contains('connect'));
    });
  });
}
