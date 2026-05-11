import '../domain/user.dart';
import 'local_insight_shelf_backend.dart';

class AuthRepository {
  const AuthRepository(this._api);

  final LocalInsightShelfBackend _api;

  Future<User?> restoreSession() => _api.restoreSession();

  Future<User> login({required String email, required String password}) {
    return _api.login(email, password);
  }

  Future<void> logout() => _api.logout();
}
