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

  @override
  void initState() {
    super.initState();
    _authController = AuthController(enabled: widget.authenticationEnabled);
    _appState = UtilityAppState(
      repository: widget.repository ?? InMemoryUtilityRepository(),
    );
    _routerDelegate = UtilityRouterDelegate(_appState, _authController);

    final initialLink = widget.initialLink;
    if (initialLink != null) {
      _routeInformationProvider = PlatformRouteInformationProvider(
        initialRouteInformation: RouteInformation(uri: Uri.parse(initialLink)),
      );
    }

    _authController.initialize();
  }

  @override
  void dispose() {
    _routeInformationProvider?.dispose();
    _routerDelegate.dispose();
    _authController.dispose();
    _appState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppPalette.primary,
      brightness: Brightness.light,
      surface: AppPalette.surface,
    );

    return MaterialApp.router(
      title: 'Plan Together',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: colorScheme,
        useMaterial3: true,
        scaffoldBackgroundColor: AppPalette.canvas,
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          foregroundColor: AppPalette.text,
        ),
        cardTheme: CardThemeData(
          color: AppPalette.surface,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: AppPalette.border),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppPalette.surface,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: AppPalette.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: AppPalette.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(
              color: AppPalette.primary,
              width: 1.2,
            ),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: AppPalette.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppPalette.text,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            side: const BorderSide(color: AppPalette.border),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        snackBarTheme: const SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
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
            userEmail: _authController.userEmail,
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
              onSaveLocationShare: _appState.saveLocationShare,
              onEndLocationShare: _appState.endLocationShare,
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
