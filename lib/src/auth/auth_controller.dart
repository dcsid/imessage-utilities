import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/foundation.dart';

enum AuthStatus { loading, signedOut, awaitingConfirmation, awaitingResetPassword, signedIn }

class AuthController extends ChangeNotifier {
  AuthController({required bool enabled}) : _enabled = enabled {
    if (!enabled) {
      _status = AuthStatus.signedIn;
    }
  }

  final bool _enabled;

  AuthStatus _status = AuthStatus.loading;
  bool _busy = false;
  String? _errorMessage;
  String? _pendingEmail;
  String? _pendingPassword;
  String? _userEmail;

  AuthStatus get status => _status;
  bool get isBusy => _busy;
  bool get isSignedIn => _status == AuthStatus.signedIn;
  bool get needsConfirmation => _status == AuthStatus.awaitingConfirmation;
  String? get errorMessage => _errorMessage;
  String? get userEmail => _userEmail ?? _pendingEmail;
  bool get isEnabled => _enabled;

  Future<void> initialize() async {
    if (!_enabled) {
      _status = AuthStatus.signedIn;
      notifyListeners();
      return;
    }

    await _runBusy(() async {
      final session = await Amplify.Auth.fetchAuthSession();
      if (session.isSignedIn) {
        _userEmail = await _loadUserEmail();
        _status = AuthStatus.signedIn;
        return;
      }

      _status = AuthStatus.signedOut;
    });
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    await _runBusy(() async {
      final normalizedEmail = email.trim();
      final result = await Amplify.Auth.signIn(
        username: normalizedEmail,
        password: password,
      );

      if (result.isSignedIn) {
        _userEmail = normalizedEmail;
        _pendingEmail = null;
        _pendingPassword = null;
        _status = AuthStatus.signedIn;
        return;
      }

      if (result.nextStep.signInStep == AuthSignInStep.confirmSignUp) {
        _pendingEmail = normalizedEmail;
        _pendingPassword = password;
        _status = AuthStatus.awaitingConfirmation;
        _errorMessage =
            'Check your email for the confirmation code before signing in.';
        return;
      }

      throw StateError('Unsupported sign-in challenge: ${result.nextStep.signInStep}');
    });
  }

  Future<void> signUp({
    required String email,
    required String password,
  }) async {
    await _runBusy(() async {
      final normalizedEmail = email.trim();
      final result = await Amplify.Auth.signUp(
        username: normalizedEmail,
        password: password,
        options: SignUpOptions(
          userAttributes: {
            AuthUserAttributeKey.email: normalizedEmail,
          },
        ),
      );

      _pendingEmail = normalizedEmail;
      _pendingPassword = password;

      switch (result.nextStep.signUpStep) {
        case AuthSignUpStep.confirmSignUp:
          _status = AuthStatus.awaitingConfirmation;
        case AuthSignUpStep.done:
          final signInResult = await Amplify.Auth.signIn(
            username: normalizedEmail,
            password: password,
          );
          if (!signInResult.isSignedIn) {
            _status = AuthStatus.signedOut;
            return;
          }

          _userEmail = normalizedEmail;
          _pendingEmail = null;
          _pendingPassword = null;
          _status = AuthStatus.signedIn;
      }
    });
  }

  Future<void> confirmSignUp(String confirmationCode) async {
    final pendingEmail = _pendingEmail;
    if (pendingEmail == null) {
      _errorMessage = 'Start account creation again to confirm your email.';
      notifyListeners();
      return;
    }

    await _runBusy(() async {
      final result = await Amplify.Auth.confirmSignUp(
        username: pendingEmail,
        confirmationCode: confirmationCode.trim(),
      );

      if (result.nextStep.signUpStep != AuthSignUpStep.done) {
        return;
      }

      final pendingPassword = _pendingPassword;
      if (pendingPassword == null) {
        _status = AuthStatus.signedOut;
        return;
      }

      final signInResult = await Amplify.Auth.signIn(
        username: pendingEmail,
        password: pendingPassword,
      );

      if (!signInResult.isSignedIn) {
        throw StateError('Email confirmed, but automatic sign-in did not finish.');
      }

      _userEmail = pendingEmail;
      _pendingEmail = null;
      _pendingPassword = null;
      _status = AuthStatus.signedIn;
    });
  }

  Future<void> resendConfirmationCode() async {
    final pendingEmail = _pendingEmail;
    if (pendingEmail == null) {
      _errorMessage = 'Start account creation again to resend the code.';
      notifyListeners();
      return;
    }

    await _runBusy(() async {
      await Amplify.Auth.resendSignUpCode(username: pendingEmail);
      _errorMessage = 'A fresh confirmation code was sent to $pendingEmail.';
    });
  }

  Future<void> resetPassword({required String email}) async {
    await _runBusy(() async {
      final normalizedEmail = email.trim();
      final result = await Amplify.Auth.resetPassword(
        username: normalizedEmail,
      );

      _pendingEmail = normalizedEmail;

      switch (result.nextStep.updateStep) {
        case AuthResetPasswordStep.confirmResetPasswordWithCode:
          _status = AuthStatus.awaitingResetPassword;
        case AuthResetPasswordStep.done:
          _status = AuthStatus.signedOut;
          _errorMessage = 'Password reset complete. Please sign in with your new password.';
      }
    });
  }

  Future<void> confirmResetPassword({
    required String newPassword,
    required String confirmationCode,
  }) async {
    final pendingEmail = _pendingEmail;
    if (pendingEmail == null) {
      _errorMessage = 'Start password reset again to confirm.';
      notifyListeners();
      return;
    }

    await _runBusy(() async {
      final result = await Amplify.Auth.confirmResetPassword(
        username: pendingEmail,
        newPassword: newPassword,
        confirmationCode: confirmationCode.trim(),
      );

      if (result.nextStep.updateStep != AuthResetPasswordStep.done) {
        return;
      }

      final signInResult = await Amplify.Auth.signIn(
        username: pendingEmail,
        password: newPassword,
      );

      if (!signInResult.isSignedIn) {
        _status = AuthStatus.signedOut;
        _errorMessage = 'Password reset successful. Please sign in.';
        return;
      }

      _userEmail = pendingEmail;
      _pendingEmail = null;
      _pendingPassword = null;
      _status = AuthStatus.signedIn;
    });
  }

  Future<void> signOut() async {
    if (!_enabled) {
      return;
    }

    await _runBusy(() async {
      await Amplify.Auth.signOut();
      _userEmail = null;
      _pendingEmail = null;
      _pendingPassword = null;
      _status = AuthStatus.signedOut;
    });
  }

  void showSignIn() {
    _pendingEmail = null;
    _pendingPassword = null;
    _userEmail = null;
    _errorMessage = null;
    _status = AuthStatus.signedOut;
    notifyListeners();
  }

  Future<void> _runBusy(Future<void> Function() action) async {
    _busy = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await action();
    } on AuthException catch (error) {
      _errorMessage = error.message;
      if (_status == AuthStatus.loading) {
        _status = AuthStatus.signedOut;
      }
    } on Exception catch (error) {
      _errorMessage = error.toString().replaceFirst('Exception: ', '');
      if (_status == AuthStatus.loading) {
        _status = AuthStatus.signedOut;
      }
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<String?> _loadUserEmail() async {
    final attributes = await Amplify.Auth.fetchUserAttributes();
    for (final attribute in attributes) {
      if (attribute.userAttributeKey == AuthUserAttributeKey.email) {
        return attribute.value;
      }
    }

    final currentUser = await Amplify.Auth.getCurrentUser();
    return currentUser.username;
  }
}
