import '../domain/user.dart';
import 'mock_insight_shelf_api.dart';

class AuthRepository {
  const AuthRepository(this._api);

  final MockInsightShelfApi _api;

  Future<User?> restoreSession() => _api.restoreSession();

  Future<User> login({required String email, required String password}) {
    return _api.login(email, password);
  }

  Future<void> logout() => _api.logout();
}
