import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/foundation.dart';

enum AuthStatus {
  loading,
  signedOut,
  awaitingConfirmation,
  awaitingResetPassword,
  signedIn,
}

enum AuthIdentifierMethod { email, phone }

class AuthController extends ChangeNotifier {
  AuthController({required bool enabled}) : _enabled = enabled {
    if (!enabled) {
      _status = AuthStatus.signedIn;
    }
  }

  final bool _enabled;

  /// Userid handed out for the read-only "Browse demo" path. Bypasses
  /// Cognito and uses an in-memory seeded set of outings so resume
  /// reviewers can poke around without signing up.
  static const String demoUserId = 'demo-session';
  static const String demoContact = 'demo@plantogether.app';

  AuthStatus _status = AuthStatus.loading;
  bool _busy = false;
  bool _demoSession = false;
  String? _errorMessage;
  String? _infoMessage;
  String? _pendingIdentifier;
  String? _pendingEmail;
  String? _pendingPhoneNumber;
  String? _pendingPassword;
  String? _deliveryDestination;
  String? _deliveryMedium;
  _AuthAccount? _account;

  AuthStatus get status => _status;
  bool get isBusy => _busy;
  bool get isSignedIn => _status == AuthStatus.signedIn;
  bool get needsConfirmation => _status == AuthStatus.awaitingConfirmation;
  String? get errorMessage => _errorMessage;
  String? get infoMessage => _infoMessage;
  bool get isEnabled => _enabled;
  bool get isDemoSession => _demoSession;
  String? get userId => _demoSession ? demoUserId : _account?.userId;
  String? get userContact => _demoSession
      ? demoContact
      : _account?.displayContact ??
            _pendingEmail ??
            _pendingPhoneNumber ??
            _pendingIdentifier;
  String? get deliveryDestination => _deliveryDestination ?? userContact;
  String get confirmationPrompt {
    final destination = deliveryDestination;
    final medium = _deliveryMedium;
    if (destination != null && medium != null) {
      return 'Enter the confirmation code sent to $destination by $medium.';
    }
    if (destination != null) {
      return 'Enter the confirmation code for $destination, or resend one below.';
    }
    return 'Enter the confirmation code for this account, or resend one below.';
  }

  String get resetPasswordPrompt {
    final destination = deliveryDestination;
    final medium = _deliveryMedium;
    if (destination != null && medium != null) {
      return 'Enter the reset code sent to $destination by $medium, then choose a new password.';
    }
    if (destination != null) {
      return 'Enter the reset code for $destination, then choose a new password.';
    }
    return 'Enter the reset code and choose a new password.';
  }

  Iterable<String> get storageAliases =>
      _account?.storageAliases ?? const <String>[];

  Future<void> initialize() async {
    if (!_enabled) {
      _status = AuthStatus.signedIn;
      notifyListeners();
      return;
    }

    await _runBusy(() async {
      final session = await Amplify.Auth.fetchAuthSession();
      if (session.isSignedIn) {
        _account = await _loadCurrentAccount();
        _status = AuthStatus.signedIn;
        return;
      }

      _status = AuthStatus.signedOut;
    });
  }

  Future<void> signIn({
    required String identifier,
    required String password,
  }) async {
    await _runBusy(() async {
      final normalizedIdentifier = _normalizeIdentifier(identifier);
      final result = await Amplify.Auth.signIn(
        username: normalizedIdentifier,
        password: password,
      );

      if (result.isSignedIn) {
        _account = await _loadCurrentAccount();
        _clearPendingState();
        _status = AuthStatus.signedIn;
        return;
      }

      if (result.nextStep.signInStep == AuthSignInStep.confirmSignUp) {
        _pendingIdentifier = normalizedIdentifier;
        _pendingPassword = password;
        _setDeliveryDetails(
          result.nextStep.codeDeliveryDetails,
          fallbackDestination: _displayIdentifier(normalizedIdentifier),
        );
        _status = AuthStatus.awaitingConfirmation;
        _infoMessage =
            'This account still needs to be confirmed before sign-in can finish.';
        return;
      }

      throw StateError(
        'Unsupported sign-in challenge: ${result.nextStep.signInStep}',
      );
    });
  }

  Future<void> signUp({
    required AuthIdentifierMethod method,
    required String identifier,
    required String password,
  }) async {
    await _runBusy(() async {
      _validateIdentifier(method, identifier);
      final normalizedIdentifier = _normalizeIdentifierForMethod(
        method,
        identifier,
      );
      final userAttributes = switch (method) {
        AuthIdentifierMethod.email => <AuthUserAttributeKey, String>{
          AuthUserAttributeKey.email: normalizedIdentifier,
        },
        AuthIdentifierMethod.phone => <AuthUserAttributeKey, String>{
          AuthUserAttributeKey.phoneNumber: normalizedIdentifier,
        },
      };
      final result = await Amplify.Auth.signUp(
        username: normalizedIdentifier,
        password: password,
        options: SignUpOptions(userAttributes: userAttributes),
      );

      _pendingIdentifier = normalizedIdentifier;
      _pendingEmail = switch (method) {
        AuthIdentifierMethod.email => normalizedIdentifier,
        AuthIdentifierMethod.phone => null,
      };
      _pendingPhoneNumber = switch (method) {
        AuthIdentifierMethod.email => null,
        AuthIdentifierMethod.phone => normalizedIdentifier,
      };
      _pendingPassword = password;

      if (result.nextStep.signUpStep == AuthSignUpStep.confirmSignUp) {
        _setDeliveryDetails(
          result.nextStep.codeDeliveryDetails,
          fallbackDestination: _displayIdentifier(normalizedIdentifier),
        );
        _infoMessage = _deliveryDestination == null
            ? 'We created your account. Enter the confirmation code to continue.'
            : 'We sent a confirmation code to $_deliveryDestination.';
        _status = AuthStatus.awaitingConfirmation;
        return;
      }

      final signInResult = await Amplify.Auth.signIn(
        username: normalizedIdentifier,
        password: password,
      );
      if (!signInResult.isSignedIn) {
        _status = AuthStatus.signedOut;
        return;
      }

      _account = await _loadCurrentAccount();
      _clearPendingState();
      _status = AuthStatus.signedIn;
    });
  }

  Future<void> confirmSignUp(String confirmationCode) async {
    final pendingIdentifier = _pendingIdentifier;
    if (pendingIdentifier == null) {
      _errorMessage = 'Start account creation again to confirm your account.';
      notifyListeners();
      return;
    }

    await _runBusy(() async {
      final result = await Amplify.Auth.confirmSignUp(
        username: pendingIdentifier,
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
        username: pendingIdentifier,
        password: pendingPassword,
      );

      if (!signInResult.isSignedIn) {
        throw StateError(
          'Account confirmed, but automatic sign-in did not finish.',
        );
      }

      _account = await _loadCurrentAccount();
      _clearPendingState();
      _status = AuthStatus.signedIn;
    });
  }

  Future<void> resendConfirmationCode() async {
    final pendingIdentifier = _pendingIdentifier;
    if (pendingIdentifier == null) {
      _errorMessage = 'Start account creation again to resend the code.';
      notifyListeners();
      return;
    }

    await _runBusy(() async {
      final result = await Amplify.Auth.resendSignUpCode(
        username: pendingIdentifier,
      );
      _setDeliveryDetails(
        result.codeDeliveryDetails,
        fallbackDestination: _displayIdentifier(pendingIdentifier),
      );
      _infoMessage = _deliveryDestination == null
          ? 'A fresh confirmation code was sent.'
          : 'A fresh confirmation code was sent to $_deliveryDestination.';
    });
  }

  Future<void> resetPassword({required String identifier}) async {
    await _runBusy(() async {
      final normalizedIdentifier = _normalizeIdentifier(identifier);
      final result = await Amplify.Auth.resetPassword(
        username: normalizedIdentifier,
      );

      _pendingIdentifier = normalizedIdentifier;

      if (result.nextStep.updateStep ==
          AuthResetPasswordStep.confirmResetPasswordWithCode) {
        _setDeliveryDetails(
          result.nextStep.codeDeliveryDetails,
          fallbackDestination: _displayIdentifier(normalizedIdentifier),
        );
        _infoMessage = _deliveryDestination == null
            ? 'We sent a password reset code.'
            : 'We sent a password reset code to $_deliveryDestination.';
        _status = AuthStatus.awaitingResetPassword;
        return;
      }

      _status = AuthStatus.signedOut;
      _infoMessage =
          'Password reset complete. Please sign in with your new password.';
    });
  }

  Future<void> confirmResetPassword({
    required String newPassword,
    required String confirmationCode,
  }) async {
    final pendingIdentifier = _pendingIdentifier;
    if (pendingIdentifier == null) {
      _errorMessage = 'Start password reset again to confirm.';
      notifyListeners();
      return;
    }

    await _runBusy(() async {
      final result = await Amplify.Auth.confirmResetPassword(
        username: pendingIdentifier,
        newPassword: newPassword,
        confirmationCode: confirmationCode.trim(),
      );

      if (result.nextStep.updateStep != AuthResetPasswordStep.done) {
        return;
      }

      final signInResult = await Amplify.Auth.signIn(
        username: pendingIdentifier,
        password: newPassword,
      );

      if (!signInResult.isSignedIn) {
        _status = AuthStatus.signedOut;
        _infoMessage = 'Password reset successful. Please sign in.';
        return;
      }

      _account = await _loadCurrentAccount();
      _clearPendingState();
      _status = AuthStatus.signedIn;
    });
  }

  Future<void> signOut() async {
    if (_demoSession) {
      _demoSession = false;
      _clearPendingState();
      _status = AuthStatus.signedOut;
      notifyListeners();
      return;
    }
    if (!_enabled) {
      return;
    }

    await _runBusy(() async {
      await Amplify.Auth.signOut();
      _account = null;
      _clearPendingState();
      _status = AuthStatus.signedOut;
    });
  }

  /// Drop the user into a stateless, sandbox demo session — no Cognito
  /// call, no cloud sync, in-memory seeded outings only. Used for the
  /// "Browse demo" entry point on the auth screen so reviewers can
  /// explore the app without creating an account.
  void startDemoSession() {
    _demoSession = true;
    _account = null;
    _clearPendingState();
    _errorMessage = null;
    _infoMessage = null;
    _status = AuthStatus.signedIn;
    notifyListeners();
  }

  void showSignIn() {
    _account = null;
    _clearPendingState();
    _errorMessage = null;
    _status = AuthStatus.signedOut;
    notifyListeners();
  }

  Future<void> _runBusy(Future<void> Function() action) async {
    _busy = true;
    _errorMessage = null;
    _infoMessage = null;
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

  Future<_AuthAccount> _loadCurrentAccount() async {
    final currentUser = await Amplify.Auth.getCurrentUser();
    final attributes = await Amplify.Auth.fetchUserAttributes();
    String? email;
    String? phoneNumber;

    for (final attribute in attributes) {
      if (attribute.userAttributeKey == AuthUserAttributeKey.email) {
        email = _normalizeEmail(attribute.value);
      }
      if (attribute.userAttributeKey == AuthUserAttributeKey.phoneNumber) {
        phoneNumber = _normalizePhoneNumber(attribute.value);
      }
    }

    return _AuthAccount(
      userId: currentUser.userId,
      username: currentUser.username,
      email: email,
      phoneNumber: phoneNumber,
    );
  }

  void _clearPendingState() {
    _pendingIdentifier = null;
    _pendingEmail = null;
    _pendingPhoneNumber = null;
    _pendingPassword = null;
    _deliveryDestination = null;
    _deliveryMedium = null;
    _infoMessage = null;
  }

  String _normalizeIdentifier(String value) {
    final trimmed = value.trim();
    if (trimmed.contains('@')) {
      return _normalizeEmail(trimmed);
    }
    return _normalizePhoneNumber(trimmed);
  }

  String _normalizeIdentifierForMethod(
    AuthIdentifierMethod method,
    String value,
  ) {
    return switch (method) {
      AuthIdentifierMethod.email => _normalizeEmail(value),
      AuthIdentifierMethod.phone => _normalizePhoneNumber(value),
    };
  }

  String _normalizeEmail(String value) => value.trim().toLowerCase();

  String _normalizePhoneNumber(String value) {
    var normalized = value.trim().replaceAll(RegExp(r'[\s().-]+'), '');
    if (normalized.startsWith('00')) {
      normalized = '+${normalized.substring(2)}';
    }

    if (normalized.startsWith('+')) {
      final digits = normalized.substring(1).replaceAll(RegExp(r'\D'), '');
      return '+$digits';
    }

    final digits = normalized.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 10) {
      return '+1$digits';
    }
    if (digits.length == 11 && digits.startsWith('1')) {
      return '+$digits';
    }

    return '+$digits';
  }

  void _validateIdentifier(AuthIdentifierMethod method, String value) {
    final trimmed = value.trim();
    if (method == AuthIdentifierMethod.email && !trimmed.contains('@')) {
      throw Exception('Enter a valid email address.');
    }

    if (method == AuthIdentifierMethod.phone) {
      final digits = trimmed.replaceAll(RegExp(r'\D'), '');
      if (digits.length < 10) {
        throw Exception(
          'Enter a valid phone number that can receive text messages.',
        );
      }
    }
  }

  void _setDeliveryDetails(
    AuthCodeDeliveryDetails? details, {
    String? fallbackDestination,
  }) {
    _deliveryDestination = details?.destination ?? fallbackDestination;
    _deliveryMedium = details?.deliveryMedium.name.toLowerCase();
  }

  String _displayIdentifier(String identifier) {
    if (identifier.contains('@')) {
      return _normalizeEmail(identifier);
    }

    final normalized = _normalizePhoneNumber(identifier);
    if (normalized.length <= 4) {
      return normalized;
    }
    final suffix = normalized.substring(normalized.length - 4);
    return 'phone ending in $suffix';
  }
}

class _AuthAccount {
  const _AuthAccount({
    required this.userId,
    required this.username,
    this.email,
    this.phoneNumber,
  });

  final String userId;
  final String username;
  final String? email;
  final String? phoneNumber;

  String get displayContact => email ?? phoneNumber ?? username;

  Iterable<String> get storageAliases sync* {
    final seen = <String>{};
    for (final candidate in <String?>[username, email, phoneNumber]) {
      final normalized = candidate?.trim();
      if (normalized == null || normalized.isEmpty || !seen.add(normalized)) {
        continue;
      }
      yield normalized;
    }
  }
}
