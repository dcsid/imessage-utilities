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
      seedColor: AppPalette.heroMiddle,
      brightness: Brightness.light,
      surface: AppPalette.surfaceStrong,
    );
    final baseTextTheme = GoogleFonts.manropeTextTheme();
    final textTheme = baseTextTheme.copyWith(
      displayLarge: GoogleFonts.spaceGrotesk(
        fontSize: 56,
        fontWeight: FontWeight.w700,
        color: AppPalette.text,
        height: 0.92,
      ),
      displayMedium: GoogleFonts.spaceGrotesk(
        fontSize: 44,
        fontWeight: FontWeight.w700,
        color: AppPalette.text,
        height: 0.96,
      ),
      headlineLarge: GoogleFonts.spaceGrotesk(
        fontSize: 34,
        fontWeight: FontWeight.w700,
        color: AppPalette.text,
        height: 1,
      ),
      headlineMedium: GoogleFonts.spaceGrotesk(
        fontSize: 30,
        fontWeight: FontWeight.w700,
        color: AppPalette.text,
        height: 1.02,
      ),
      headlineSmall: GoogleFonts.spaceGrotesk(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: AppPalette.text,
        height: 1.1,
      ),
      titleLarge: GoogleFonts.spaceGrotesk(
        fontSize: 21,
        fontWeight: FontWeight.w700,
        color: AppPalette.text,
      ),
      titleMedium: GoogleFonts.spaceGrotesk(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: AppPalette.text,
      ),
      bodyLarge: GoogleFonts.manrope(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: AppPalette.text,
      ),
      bodyMedium: GoogleFonts.manrope(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppPalette.text,
      ),
      bodySmall: GoogleFonts.manrope(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppPalette.mutedText,
      ),
      labelLarge: GoogleFonts.manrope(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppPalette.text,
      ),
    );

    return MaterialApp.router(
      title: 'Chat Utilities Hub',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: colorScheme,
        scaffoldBackgroundColor: AppPalette.canvas,
        useMaterial3: true,
        textTheme: textTheme,
        appBarTheme: AppBarTheme(
          centerTitle: false,
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          foregroundColor: AppPalette.text,
          titleTextStyle: textTheme.titleLarge?.copyWith(
            color: AppPalette.text,
          ),
        ),
        cardTheme: CardThemeData(
          color: AppPalette.surfaceStrong,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
            side: const BorderSide(color: AppPalette.border),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: AppPalette.heroMiddle,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            textStyle: textTheme.labelLarge,
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppPalette.text,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            side: const BorderSide(color: AppPalette.border),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            textStyle: textTheme.labelLarge,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.9),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 18,
          ),
          labelStyle: textTheme.bodyMedium?.copyWith(
            color: AppPalette.mutedText,
          ),
          hintStyle: textTheme.bodyMedium?.copyWith(
            color: AppPalette.mutedText.withValues(alpha: 0.82),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(22),
            borderSide: const BorderSide(color: AppPalette.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(22),
            borderSide: const BorderSide(
              color: AppPalette.heroMiddle,
              width: 1.4,
            ),
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: AppPalette.heroStart,
          contentTextStyle: textTheme.bodyMedium?.copyWith(color: Colors.white),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
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
