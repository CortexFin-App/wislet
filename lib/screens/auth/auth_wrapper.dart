import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:sage_wallet_reborn/core/constants/app_constants.dart';
import 'package:sage_wallet_reborn/core/di/injector.dart';
import 'package:sage_wallet_reborn/providers/wallet_provider.dart';
import 'package:sage_wallet_reborn/screens/auth/invitation_handler_screen.dart';
import 'package:sage_wallet_reborn/screens/auth/pin_entry_screen.dart';
import 'package:sage_wallet_reborn/screens/onboarding/interactive_onboarding_screen.dart';
import 'package:sage_wallet_reborn/screens/onboarding/onboarding_screen.dart';
import 'package:sage_wallet_reborn/services/auth_service.dart';
import 'package:sage_wallet_reborn/services/navigation_service.dart';
import 'package:sage_wallet_reborn/services/notification_service.dart';
import 'package:sage_wallet_reborn/services/subscription_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uni_links/uni_links.dart';

enum AuthStatus {
  loading,
  onboarding,
  interactiveOnboarding,
  needsPinAuth,
  authenticated,
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final AuthService _authService = getIt<AuthService>();
  final SubscriptionService _subscriptionService = getIt<SubscriptionService>();
  StreamSubscription<Uri?>? _linkSubscription;
  AuthStatus _status = AuthStatus.loading;

  @override
  void initState() {
    super.initState();
    _initUniLinks();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeApp();
    });
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    final walletProvider = context.read<WalletProvider>();
    final notificationService = getIt<NotificationService>();

    if (_authService.currentUser != null) {
      if (!mounted) return;
      setState(() => _status = AuthStatus.authenticated);
      await _runStartupChecks();
      return;
    }

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

    final pinIsSet = await _authService.hasPin();
    if (!pinIsSet) {
      if (!mounted) return;
      setState(() => _status = AuthStatus.authenticated);
      await _runStartupChecks();
      return;
    }

    if (mounted) setState(() => _status = AuthStatus.needsPinAuth);
  }

  Future<void> _runStartupChecks() async {
    await _subscriptionService.checkForUnusedSubscriptions();
  }

  Future<void> _handleOnboardingFinished() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.prefsKeyOnboardingComplete, true);
    if (mounted) {
      setState(() {
        _status = AuthStatus.loading;
      });
      await _initializeApp();
    }
  }

  Future<void> _handleInteractiveOnboardingFinished() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('interactiveOnboardingComplete', true);
    if (mounted) {
      setState(() {
        _status = AuthStatus.loading;
      });
      await _initializeApp();
    }
  }

  Future<void> _initUniLinks() async {
    _linkSubscription = uriLinkStream.listen(
      (Uri? uri) {
        if (uri != null && mounted) {
          _handleIncomingLink(uri);
        }
      },
      onError: (Object err) {
        debugPrint('uni_links error: $err');
      },
    );

    try {
      final initialUri = await getInitialUri();
      if (initialUri != null && mounted) {
        _handleIncomingLink(initialUri);
      }
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
        return InteractiveOnboardingScreen(
          onFinished: _handleInteractiveOnboardingFinished,
        );
      case AuthStatus.authenticated:
        return const SizedBox.shrink();
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
