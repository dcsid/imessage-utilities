import 'package:chat_utilities_hub/src/data/in_memory_utility_repository.dart';
import 'package:chat_utilities_hub/src/data/utility_repository.dart';
import 'package:chat_utilities_hub/src/models/utility_link.dart';
import 'package:chat_utilities_hub/src/screens/home_screen.dart';
import 'package:chat_utilities_hub/src/screens/utility_detail_screen.dart';
import 'package:chat_utilities_hub/src/state/utility_app_state.dart';
import 'package:flutter/material.dart';

class ChatUtilitiesHubApp extends StatefulWidget {
  const ChatUtilitiesHubApp({super.key, this.initialLink, this.repository});

  final String? initialLink;
  final UtilityRepository? repository;

  @override
  State<ChatUtilitiesHubApp> createState() => _ChatUtilitiesHubAppState();
}

class _ChatUtilitiesHubAppState extends State<ChatUtilitiesHubApp> {
  late final UtilityAppState _appState;
  late final UtilityRouterDelegate _routerDelegate;
  PlatformRouteInformationProvider? _routeInformationProvider;

  @override
  void initState() {
    super.initState();
    _appState = UtilityAppState(
      repository: widget.repository ?? InMemoryUtilityRepository(),
    );
    _routerDelegate = UtilityRouterDelegate(_appState);

    final initialLink = widget.initialLink;
    if (initialLink != null) {
      _routeInformationProvider = PlatformRouteInformationProvider(
        initialRouteInformation: RouteInformation(uri: Uri.parse(initialLink)),
      );
    }
  }

  @override
  void dispose() {
    _routeInformationProvider?.dispose();
    _routerDelegate.dispose();
    _appState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF0D5C63),
      brightness: Brightness.light,
      surface: const Color(0xFFF6F1E7),
    );

    return MaterialApp.router(
      title: 'Chat Utilities Hub',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: colorScheme,
        scaffoldBackgroundColor: const Color(0xFFF3EBDD),
        useMaterial3: true,
        textTheme: Theme.of(context).textTheme.apply(
          bodyColor: const Color(0xFF1B263B),
          displayColor: const Color(0xFF102A43),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
            side: const BorderSide(color: Color(0xFFE7DBC8)),
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
    final uri = routeInformation.uri;
    final segments = UtilityLink.normalizedSegments(uri);

    if (segments.isEmpty) {
      return const UtilityRoutePath.home();
    }

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
  UtilityRouterDelegate(this._appState) {
    _appState.addListener(notifyListeners);
  }

  final UtilityAppState _appState;

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
    final selectedUtility = _appState.selectedUtility;

    return Navigator(
      key: navigatorKey,
      pages: [
        MaterialPage<void>(
          key: const ValueKey('home-page'),
          child: HomeScreen(
            utilities: _appState.utilities,
            onOpenUtility: _appState.openUtility,
            onOpenLink: _appState.openUtilityLink,
          ),
        ),
        if (selectedUtility != null)
          MaterialPage<void>(
            key: ValueKey('utility-${selectedUtility.id}'),
            child: UtilityDetailScreen(
              utility: selectedUtility,
              onBack: _appState.showHome,
            ),
          ),
      ],
      onDidRemovePage: (Page<Object?> page) {
        if (!_appState.currentPath.isHome) {
          _appState.showHome();
        }
      },
    );
  }

  @override
  void dispose() {
    _appState.removeListener(notifyListeners);
    super.dispose();
  }
}
