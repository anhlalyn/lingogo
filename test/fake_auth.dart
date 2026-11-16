import 'dart:async';
import 'package:lingogo/auth_service.dart';

class FakeAuth extends AuthService {
  FakeAuth({Account? account = const Account('test-user', 'test@example.com')})
    : _account = account;
  Account? _account;
  Object? failure;
  Completer<void>? pending;
  int signInCalls = 0, registerCalls = 0, resetCalls = 0;
  String? resetEmail;
  @override
  Account? get account => _account;
  @override
  bool get ready => true;
  void setAccount(Account? value) {
    _account = value;
    notifyListeners();
  }

  @override
  Future<void> signIn(String email, String password) async {
    signInCalls++;
    if (pending != null) await pending!.future;
    if (failure != null) throw failure!;
    setAccount(Account('signed-in-user', email));
  }

  @override
  Future<void> register(String email, String password) async {
    registerCalls++;
    if (failure != null) throw failure!;
    setAccount(Account('registered-user', email));
  }

  @override
  Future<void> resetPassword(String email) async {
    resetCalls++;
    resetEmail = email;
    if (failure != null) throw failure!;
  }

  @override
  Future<void> signOut() async => setAccount(null);
}
