import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class Account {
  const Account(this.uid, this.email, {this.name, this.isAdmin = false});
  final String uid, email;
  final String? name;
  final bool isAdmin;
}

abstract class AuthService extends ChangeNotifier {
  Account? get account;
  bool get ready;
  String? get sessionError => null;
  Future<void> signIn(String email, String password);
  Future<void> register(String email, String password);
  Future<void> resetPassword(String email);
  Future<void> signOut();
}

class FirebaseAuthService extends AuthService {
  FirebaseAuthService({FirebaseAuth? firebaseAuth})
    : _auth = firebaseAuth ?? FirebaseAuth.instance {
    _subscription = _auth.idTokenChanges().listen(
      (user) async {
        final generation = ++_generation;
        var isAdmin = false;
        if (user != null) {
          try {
            isAdmin = (await user.getIdTokenResult()).claims?['admin'] == true;
          } catch (_) {
            /* Fail closed for admin access when claims cannot be read. */
          }
        }
        if (_disposed || generation != _generation) return;
        _account = user == null
            ? null
            : Account(
                user.uid,
                user.email ?? '',
                name: user.displayName,
                isAdmin: isAdmin,
              );
        _ready = true;
        _sessionError = null;
        notifyListeners();
      },
      onError: (Object error) {
        if (_disposed) return;
        _generation++;
        _account = null;
        _ready = true;
        _sessionError =
            'Không kiểm tra được phiên đăng nhập. Hãy thử đăng nhập lại.';
        notifyListeners();
      },
    );
  }
  final FirebaseAuth _auth;
  late final StreamSubscription<User?> _subscription;
  Account? _account;
  bool _ready = false;
  int _generation = 0;
  bool _disposed = false;
  String? _sessionError;
  @override
  Account? get account => _account;
  @override
  bool get ready => _ready;
  @override
  String? get sessionError => _sessionError;
  @override
  Future<void> signIn(String email, String password) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  @override
  Future<void> register(String email, String password) async {
    // The auth stream owns navigation; onboarding collects a local display name.
    await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  @override
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (error) {
      // Do not disclose whether an email address has an account.
      if (error.code != 'user-not-found') rethrow;
    }
  }

  @override
  Future<void> signOut() => _auth.signOut();
  @override
  void dispose() {
    _disposed = true;
    _subscription.cancel();
    super.dispose();
  }
}

String authError(Object error) {
  if (error is! FirebaseAuthException) {
    return 'Chưa thực hiện được. Vui lòng thử lại.';
  }
  return switch (error.code) {
    'invalid-email' => 'Địa chỉ email không hợp lệ.',
    'weak-password' => 'Mật khẩu quá yếu. Hãy chọn mật khẩu mạnh hơn.',
    'email-already-in-use' => 'Email này đã được đăng ký. Bạn hãy đăng nhập.',
    'invalid-credential' ||
    'wrong-password' ||
    'user-not-found' => 'Email hoặc mật khẩu không đúng.',
    'user-disabled' => 'Tài khoản đã bị vô hiệu hóa. Vui lòng liên hệ hỗ trợ.',
    'network-request-failed' =>
      'Không có kết nối mạng. Kiểm tra mạng và thử lại.',
    'too-many-requests' => 'Bạn đã thử quá nhiều lần. Vui lòng thử lại sau.',
    'operation-not-allowed' =>
      'Đăng nhập hiện chưa khả dụng. Vui lòng thử lại sau.',
    _ => 'Chưa thực hiện được. Vui lòng thử lại.',
  };
}
