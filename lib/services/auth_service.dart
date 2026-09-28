import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const String _serverClientId =
      '253578063656-vs2n2q3pfcqpuv43er4mkvhoqnvmluhs.apps.googleusercontent.com';

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    try {
      await GoogleSignIn.instance.initialize(
        serverClientId: _serverClientId,
      );
      _initialized = true;
    } catch (e) {
      debugPrint('AuthService init GoogleSignIn error: $e');
    }
  }

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<UserCredential?> signInWithGoogle() async {
    try {
      await init();
      final GoogleSignInAccount googleAccount =
          await GoogleSignIn.instance.authenticate();

      final GoogleSignInAuthentication googleAuth = googleAccount.authentication;

      final OAuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      return userCredential;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        debugPrint('Google Sign-In canceled by user.');
        return null;
      }
      debugPrint('AuthService signInWithGoogle GoogleSignInException: $e');
      rethrow;
    } catch (e) {
      debugPrint('AuthService signInWithGoogle error: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await GoogleSignIn.instance.signOut();
    } catch (e) {
      debugPrint('GoogleSignIn signOut error: $e');
    }
    await _auth.signOut();
  }
}
