import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:prbd_2526_f01/core/tools/params.dart';
import 'package:prbd_2526_f01/models/security.dart';

final currentUserProvider = AsyncNotifierProvider<CurrentUserNotifier, String?>(
  CurrentUserNotifier.new,
);

class CurrentUserNotifier extends AsyncNotifier<String?> {
  static const _tokenKey = 'token';

  @override
  Future<String?> build() async {
    final token = Params.getValue(_tokenKey) as String?;
    state = AsyncData(token);
    return token;
  }

  Future<void> login(String email, String password) async {
    state = const AsyncLoading();
    try {
      final token = await Security.login(email, password);
      await Params.setValue(_tokenKey, token);
      state = AsyncData(token);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }

  Future<void> logout() async {
    await Params.clearValue(_tokenKey);
    state = const AsyncData(null);
  }

  bool get isLoggedIn => loggedUser != null;

  String? get loggedUser {
    return _getUserFromToken(state.value);
  }

  static String? _getUserFromToken(String? token) {
    if (token == null) return null;
    try {
      Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
      return decodedToken['sub'];
    } catch (_) {
      return null;
    }
  }

  String? get userName => _getNameFromToken(state.value);

  static String? _getNameFromToken(String? token) {
    if (token == null) return null;
    try {
      Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
      return decodedToken['name'];
    } catch (_) {
      return null;
    }
  }

  bool get isManager => _getRoleFromToken(state.value) == 'manager';

  static String? _getRoleFromToken(String? token) {
    if (token == null) return null;
    try {
      Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
      return decodedToken['role'];
    } catch (_) {
      return null;
    }
  }

  Future<void> signup({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async {
    const AsyncLoading();
    try {
      await Security.signup(
        email: email,
        password: password,
        fullName: fullName,
        phone: phone,
      );
      await login(email, password);
      state = AsyncData(Params.getValue(_tokenKey));
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }

  Future<void> resetDatabase() async {
    await Security.resetDatabase();
  }
}
