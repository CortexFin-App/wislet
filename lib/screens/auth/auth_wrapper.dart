import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:wislet/core/constants/app_constants.dart';
import 'package:wislet/core/di/injector.dart';
import 'package:wislet/providers/wallet_provider.dart';
import 'package:wislet/screens/auth/invitation_handler_screen.dart';
import 'package:wislet/screens/auth/pin_entry_screen.dart';
import 'package:wislet/screens/onboarding/interactive_onboarding_screen.dart';
import 'package:wislet/screens/onboarding/onboarding_screen.dart';
import 'package:wislet/services/auth_service.dart';
import 'package:wislet/services/navigation_service.dart';
import 'package:wislet/services/notification_service.dart';
import 'package:wislet/services/subscription_service.dart';
import 'package:wislet/services/sync_service.dart';

enum AuthStatus {
  loading,
  onboarding,
  interactiveOnboarding,
  needsPinAuth,
  authenticated,
  guest,
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final AuthService _authService = getIt<AuthService>();
  final SubscriptionService _subscriptionService = getIt<SubscriptionService>();
  final _appLinks = AppLinks();
  StreamSubscription<Uri?>? _linkSubscription;
  AuthStatus _status = AuthStatus.loading;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
    _authService.addListener(_onAuthChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeApp();
    });
  }

  @override
  void dispose() {
    _authService.removeListener(_onAuthChanged);
    _linkSubscription?.cancel();
    super.dispose();
  }

  void _onAuthChanged() {
    if (!mounted) return;
    // Якщо guest mode, і user щойно увійшов, ініціалізуємо повторно
    if (_status == AuthStatus.guest && _authService.currentUser != null) {
      setState(() => _status = AuthStatus.loading);
      _initializeApp();
    }
    // Якщо залогінені, і user щойно вийшов, повертаємося до guest mode
    if (_status == AuthStatus.authenticated && _authService.currentUser == null) {
      setState(() => _status = AuthStatus.guest);
    }
  }


  Future<void> _initializeApp() async {
    final walletProvider = context.read<WalletProvider>();
    final notificationService = getIt<NotificationService>();

    final prefs = await SharedPreferences.getInstance();
    final onboardingCompleted =
        prefs.getBool(AppConstants.prefsKeyOnboardingComplete) ?? false;
    final interactiveOnboardingCompleted =
        prefs.getBool('interactiveOnboardingComplete') ?? false;

    if (!onboardingCompleted) {
      if (!mounted) return;
      setState(() => _status = AuthStatus.onboarding);
      return;
    }

    if (!interactiveOnboardingCompleted) {
      if (!mounted) return;
      setState(() => _status = AuthStatus.interactiveOnboarding);
      return;
    }

    if (mounted) {
      await notificationService.requestPermissions();
      await walletProvider.loadWallets();
    }

    // Є сесія Supabase — перевіряємо PIN, потім авторизуємо користувача
    if (_authService.currentUser != null) {
      final pinIsSet = await _authService.hasPin();
      if (pinIsSet) {
        if (!mounted) return;
        setState(() => _status = AuthStatus.needsPinAuth);
        return;
      }
      if (!mounted) return;
      setState(() => _status = AuthStatus.authenticated);
      await _runStartupChecks();
      return;
    }

    // Немає сесії → гостьовий офлайн-режим
    if (!mounted) return;
    setState(() => _status = AuthStatus.guest);
  }

  Future<void> _runStartupChecks() async {
    await _subscriptionService.checkForUnusedSubscriptions();
    // Запуск синхронізації на фоні
    unawaited(getIt<SyncService>().startAutoSync());
  }

  Future<void> _handleOnboardingFinished() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.prefsKeyOnboardingComplete, true);
    if (mounted) {
      setState(() => _status = AuthStatus.loading);
      await _initializeApp();
    }
  }

  Future<void> _handleInteractiveOnboardingFinished() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('interactiveOnboardingComplete', true);
    if (mounted) {
      setState(() => _status = AuthStatus.loading);
      await _initializeApp();
    }
  }

  Future<void> _initDeepLinks() async {
    _linkSubscription = _appLinks.uriLinkStream.listen(
          (Uri? uri) {
        if (uri != null && mounted) _handleIncomingLink(uri);
      },
      onError: (Object err) {
        debugPrint('app_links error: $err');
      },
    );

    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null && mounted) _handleIncomingLink(initialUri);
    } on PlatformException {
      debugPrint('Failed to get initial deep link.');
    } on FormatException {
      debugPrint('Malformed initial deep link.');
    }
  }

  void _handleIncomingLink(Uri link) {
    if (link.pathSegments.contains('invite')) {
      final invitationToken = link.queryParameters['token'];
      if (invitationToken != null && invitationToken.isNotEmpty) {
        final navigator = NavigationService.navigatorKey.currentState;
        if (navigator != null && navigator.context.mounted) {
          navigator.push(
            MaterialPageRoute<void>(
              builder: (_) =>
                  InvitationHandlerScreen(invitationToken: invitationToken),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    switch (_status) {
      case AuthStatus.loading:
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      case AuthStatus.onboarding:
        return OnboardingScreen(onFinished: _handleOnboardingFinished);
      case AuthStatus.interactiveOnboarding:
        return InteractiveOnboarding(
          onFinished: _handleInteractiveOnboardingFinished,
        );

      // І для авторизованих, і для гостей показуємо основний інтерфейс,
      // а через AppModeProvider.isOnline визначаємо, чи доступна синхронізація
      case AuthStatus.authenticated:
      case AuthStatus.guest:
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) context.go('/home');
        });
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      case AuthStatus.needsPinAuth:
        return PinEntryScreen(
          onSuccess: () async {
            if (mounted) {
              setState(() => _status = AuthStatus.authenticated);
              await _runStartupChecks();
            }
          },
        );
    }
  }
}
