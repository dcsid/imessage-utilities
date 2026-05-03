import 'dart:async';

import 'package:chat_utilities_hub/src/auth/auth_controller.dart';
import 'package:chat_utilities_hub/src/auth/auth_screen.dart';
import 'package:chat_utilities_hub/src/data/in_memory_utility_repository.dart';
import 'package:chat_utilities_hub/src/data/utility_repository.dart';
import 'package:chat_utilities_hub/src/models/utility_link.dart';
import 'package:chat_utilities_hub/src/presentation/app_palette.dart';
import 'package:chat_utilities_hub/src/screens/home_screen.dart';
import 'package:chat_utilities_hub/src/screens/utility_detail_screen.dart';
import 'package:chat_utilities_hub/src/state/utility_app_state.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ChatUtilitiesHubApp extends StatefulWidget {
  const ChatUtilitiesHubApp({
    super.key,
    this.initialLink,
    this.repository,
    this.authenticationEnabled = false,
  });

  final String? initialLink;
  final UtilityRepository? repository;
  final bool authenticationEnabled;

  @override
  State<ChatUtilitiesHubApp> createState() => _ChatUtilitiesHubAppState();
}

class _ChatUtilitiesHubAppState extends State<ChatUtilitiesHubApp> {
  late final AuthController _authController;
  late final UtilityAppState _appState;
  late final UtilityRouterDelegate _routerDelegate;
  PlatformRouteInformationProvider? _routeInformationProvider;
  String? _hydratedUserId;

  @override
  void initState() {
    super.initState();
    _authController = AuthController(enabled: widget.authenticationEnabled);
    _appState = UtilityAppState(
      repository: widget.repository ?? InMemoryUtilityRepository(),
    );
    _routerDelegate = UtilityRouterDelegate(_appState, _authController);
    _authController.addListener(_handleAuthStateChanged);

    final initialLink = widget.initialLink;
    if (initialLink != null) {
      _routeInformationProvider = PlatformRouteInformationProvider(
        initialRouteInformation: RouteInformation(uri: Uri.parse(initialLink)),
      );
    }

    _authController.initialize();
    _handleAuthStateChanged();
  }

  @override
  void dispose() {
    _authController.removeListener(_handleAuthStateChanged);
    _routeInformationProvider?.dispose();
    _routerDelegate.dispose();
    _authController.dispose();
    _appState.dispose();
    super.dispose();
  }

  void _handleAuthStateChanged() {
    if (_authController.isEnabled &&
        _authController.status == AuthStatus.loading) {
      return;
    }

    // Auto-activate the demo session for shareable invite links pointing
    // at a seeded outing (e.g. https://.../utility/demo-cville). Lets a
    // recruiter click a deep link and land directly on the detail
    // screen without having to find the "Browse the demo" button.
    if (_authController.isEnabled &&
        !_authController.isSignedIn &&
        _authController.status == AuthStatus.signedOut) {
      final pending = _appState.pendingUtilityId;
      if (pending != null && pending.startsWith('demo-')) {
        _authController.startDemoSession();
        // The auth listener fires again on the state flip and this same
        // method re-enters with isSignedIn = true; hydration kicks off
        // there.
        return;
      }
    }

    final nextUserId = _authController.isEnabled
        ? (_authController.isSignedIn ? _authController.userId : null)
        : 'local';
    if (_hydratedUserId == nextUserId) {
      return;
    }

    _hydratedUserId = nextUserId;
    unawaited(
      _appState.hydrateForUser(
        nextUserId,
        legacyStorageKeys: _authController.storageAliases,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppPalette.primary,
      onPrimary: Colors.white,
      primaryContainer: AppPalette.primarySoft,
      onPrimaryContainer: AppPalette.primaryInk,
      secondary: AppPalette.ink,
      onSecondary: AppPalette.canvas,
      secondaryContainer: AppPalette.surfaceMuted,
      onSecondaryContainer: AppPalette.ink,
      tertiary: AppPalette.warning,
      onTertiary: Colors.white,
      error: AppPalette.danger,
      onError: Colors.white,
      surface: AppPalette.surface,
      onSurface: AppPalette.ink,
      onSurfaceVariant: AppPalette.mutedText,
      outline: AppPalette.border,
      outlineVariant: AppPalette.borderSoft,
    );

    final base = ThemeData(colorScheme: colorScheme, useMaterial3: true);
    final body = GoogleFonts.interTextTheme(base.textTheme).apply(
      bodyColor: AppPalette.ink,
      displayColor: AppPalette.ink,
    );
    final display = GoogleFonts.frauncesTextTheme(base.textTheme);

    final textTheme = body.copyWith(
      displayLarge: display.displayLarge?.copyWith(
        color: AppPalette.ink,
        fontWeight: FontWeight.w700,
        height: 0.98,
        letterSpacing: -1.5,
      ),
      displayMedium: display.displayMedium?.copyWith(
        color: AppPalette.ink,
        fontWeight: FontWeight.w700,
        height: 1.0,
        letterSpacing: -1.0,
      ),
      displaySmall: display.displaySmall?.copyWith(
        color: AppPalette.ink,
        fontWeight: FontWeight.w700,
        height: 1.05,
      ),
      headlineLarge: display.headlineLarge?.copyWith(
        color: AppPalette.ink,
        fontWeight: FontWeight.w700,
        height: 1.05,
      ),
      headlineMedium: display.headlineMedium?.copyWith(
        color: AppPalette.ink,
        fontWeight: FontWeight.w700,
        height: 1.1,
      ),
      headlineSmall: display.headlineSmall?.copyWith(
        color: AppPalette.ink,
        fontWeight: FontWeight.w600,
        height: 1.15,
      ),
      titleLarge: display.titleLarge?.copyWith(
        color: AppPalette.ink,
        fontWeight: FontWeight.w600,
      ),
    );

    return MaterialApp.router(
      title: 'Plan Together',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: colorScheme,
        useMaterial3: true,
        scaffoldBackgroundColor: AppPalette.canvas,
        textTheme: textTheme,
        primaryTextTheme: textTheme,
        canvasColor: AppPalette.canvas,
        dividerColor: AppPalette.borderSoft,
        appBarTheme: AppBarTheme(
          centerTitle: false,
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          foregroundColor: AppPalette.ink,
          titleTextStyle: textTheme.titleLarge,
        ),
        cardTheme: CardThemeData(
          color: AppPalette.surface,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
            side: const BorderSide(color: AppPalette.border, width: 1.6),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppPalette.surface,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 18,
          ),
          labelStyle: const TextStyle(
            color: AppPalette.mutedText,
            fontWeight: FontWeight.w500,
          ),
          floatingLabelStyle: const TextStyle(
            color: AppPalette.ink,
            fontWeight: FontWeight.w600,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(color: AppPalette.border, width: 1.4),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(color: AppPalette.border, width: 1.4),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(color: AppPalette.ink, width: 2),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: AppPalette.ink,
            foregroundColor: AppPalette.canvas,
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
            textStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              letterSpacing: 0.1,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppPalette.ink,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            side: const BorderSide(color: AppPalette.border, width: 1.4),
            textStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppPalette.ink,
            textStyle: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: AppPalette.surfaceMuted,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
            side: const BorderSide(color: AppPalette.borderSoft),
          ),
          labelStyle: const TextStyle(
            color: AppPalette.ink,
            fontWeight: FontWeight.w600,
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppPalette.ink,
          contentTextStyle: GoogleFonts.inter(
            color: AppPalette.canvas,
            fontWeight: FontWeight.w500,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      routerDelegate: _routerDelegate,
      routeInformationParser: const UtilityRouteInformationParser(),
      routeInformationProvider: _routeInformationProvider,
      backButtonDispatcher: RootBackButtonDispatcher(),
    );
  }
}

class UtilityRoutePath {
  const UtilityRoutePath.home() : utilityId = null;

  const UtilityRoutePath.utility(this.utilityId);

  final String? utilityId;

  bool get isHome => utilityId == null;
}

class UtilityRouteInformationParser
    extends RouteInformationParser<UtilityRoutePath> {
  const UtilityRouteInformationParser();

  @override
  Future<UtilityRoutePath> parseRouteInformation(
    RouteInformation routeInformation,
  ) async {
    final segments = UtilityLink.normalizedSegments(routeInformation.uri);
    if (segments.length >= 2 && segments.first == UtilityLink.utilityHost) {
      return UtilityRoutePath.utility(segments[1]);
    }
    return const UtilityRoutePath.home();
  }

  @override
  RouteInformation? restoreRouteInformation(UtilityRoutePath configuration) {
    if (configuration.isHome) {
      return RouteInformation(uri: Uri(path: '/'));
    }

    return RouteInformation(
      uri: Uri(path: '/${UtilityLink.utilityHost}/${configuration.utilityId}'),
    );
  }
}

class UtilityRouterDelegate extends RouterDelegate<UtilityRoutePath>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin<UtilityRoutePath> {
  UtilityRouterDelegate(this._appState, this._authController) {
    _appState.addListener(notifyListeners);
    _authController.addListener(notifyListeners);
  }

  final UtilityAppState _appState;
  final AuthController _authController;

  @override
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  UtilityRoutePath get currentConfiguration => _appState.currentPath;

  @override
  Future<void> setNewRoutePath(UtilityRoutePath configuration) async {
    _appState.applyRoutePath(configuration);
  }

  @override
  Widget build(BuildContext context) {
    if (_authController.isEnabled && !_authController.isSignedIn) {
      if (_authController.status == AuthStatus.loading) {
        return Navigator(
          key: navigatorKey,
          pages: [
            const MaterialPage<void>(
              key: ValueKey('auth-loading-page'),
              child: _AppLoadingScreen(message: 'Checking your account...'),
            ),
          ],
          onDidRemovePage: (page) {},
        );
      }

      return Navigator(
        key: navigatorKey,
        pages: [
          MaterialPage<void>(
            key: const ValueKey('auth-page'),
            child: AuthScreen(controller: _authController),
          ),
        ],
        onDidRemovePage: (page) {},
      );
    }

    if (!_appState.isHydrated) {
      return Navigator(
        key: navigatorKey,
        pages: [
          const MaterialPage<void>(
            key: ValueKey('outings-loading-page'),
            child: _AppLoadingScreen(message: 'Loading your outings...'),
          ),
        ],
        onDidRemovePage: (page) {},
      );
    }

    final selectedUtility = _appState.selectedUtility;

    return Navigator(
      key: navigatorKey,
      pages: [
        MaterialPage<void>(
          key: const ValueKey('home-page'),
          child: HomeScreen(
            utilities: _appState.utilities,
            onOpenUtility: _appState.openUtility,
            onCreateBoard: _appState.createPlanningBoard,
            onDeleteUtility: _appState.removeUtility,
            userContact: _authController.userContact,
            onSignOut: _authController.isEnabled
                ? () {
                    _appState.showHome();
                    _authController.signOut();
                  }
                : null,
          ),
        ),
        if (selectedUtility != null)
          MaterialPage<void>(
            key: ValueKey('utility-${selectedUtility.id}'),
            child: UtilityDetailScreen(
              utility: selectedUtility,
              onBack: _appState.showHome,
              onSaveResponse: _appState.saveResponse,
              onAddTripStop: _appState.addTripStop,
              onRemoveTripStop: _appState.removeTripStop,
              onEnableExpenseTracking: _appState.enableExpenseTracking,
              onAddExpense: _appState.addExpense,
              onRemoveExpense: _appState.removeExpense,
              onSaveLocationShare: _appState.saveLocationShare,
              onEndLocationShare: _appState.endLocationShare,
              onLockTime: _appState.lockTime,
              onUnlockTime: _appState.unlockTime,
              userContact: _authController.userContact,
            ),
          ),
      ],
      onDidRemovePage: (page) {
        if (!_appState.currentPath.isHome) {
          _appState.showHome();
        }
      },
    );
  }

  @override
  void dispose() {
    _appState.removeListener(notifyListeners);
    _authController.removeListener(notifyListeners);
    super.dispose();
  }
}

class _AppLoadingScreen extends StatelessWidget {
  const _AppLoadingScreen({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(message),
          ],
        ),
      ),
    );
  }
}
