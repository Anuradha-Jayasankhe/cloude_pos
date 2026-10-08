import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:store_buddy_pos/services/api_client.dart';
import 'package:store_buddy_pos/services/auth_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AuthService', () {
    late AuthService authService;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      authService = AuthService(ApiClient());
    });

    test('creates first trial store owner and allows login', () async {
      final created = await authService.createTrialStoreOwner(
        storeName: 'Test Store',
        ownerEmail: 'owner@test.com',
        ownerPassword: '123456',
      );

      expect(created, isTrue);
      expect(await authService.hasAnyStoreLogins(), isTrue);

      final user = await authService.login('owner@test.com', '123456');
      expect(user, isNotNull);
      expect(user!.tenantId, isNotEmpty);
      expect(user.role, 'manager');
    });

    test('preserves trial login after logout', () async {
      await authService.createTrialStoreOwner(
        storeName: 'Test Store',
        ownerEmail: 'owner@test.com',
        ownerPassword: '123456',
      );

      await authService.logout();

      final user = await authService.login('owner@test.com', '123456');

      expect(user, isNotNull);
      expect(user!.tenantId, isNotEmpty);
      expect(user.role, 'manager');
    });

    test('rejects duplicate store email on createStoreLogin', () async {
      final first = await authService.createStoreLogin(
        storeName: 'Store A',
        tenantId: 'store-a',
        email: 'dup@test.com',
        password: 'pass1',
      );
      final second = await authService.createStoreLogin(
        storeName: 'Store B',
        tenantId: 'store-b',
        email: 'dup@test.com',
        password: 'pass2',
      );

      expect(first, isTrue);
      expect(second, isFalse);
    });

    test('supports platform admin login', () async {
      final user = await authService.login(
        'admin@storebuddy.com',
        'admin123',
        isPlatform: true,
      );

      expect(user, isNotNull);
      expect(user!.role, 'platform_admin');
      expect(user.tenantId, 'platform');
    });
  });
}
