import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_links/app_links.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/wallet_provider.dart';
import '../app_navigation_shell.dart';
import '../onboarding/onboarding_screen.dart';
import '../../services/auth_service.dart';
import '../../services/notification_service.dart';
import '../../core/di/injector.dart';
import '../../services/subscription_service.dart';
import '../../services/navigation_service.dart';
import '../settings/accept_invitation_screen.dart';
import 'pin_entry_screen.dart';

enum AuthStatus { loading, onboarding, needsPinAuth, authenticated }

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final AuthService _authService = getIt<AuthService>();
  final SubscriptionService _subscriptionService = getIt<SubscriptionService>();
  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;
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
    if (_authService.currentUser != null) {
      if (mounted) setState(() => _status = AuthStatus.authenticated);
      await _runStartupChecks();
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final bool onboardingCompleted =
        prefs.getBool(AppConstants.prefsKeyOnboardingComplete) ?? false;
    
    if (!onboardingCompleted) {
      if (mounted) setState(() => _status = AuthStatus.onboarding);
      return;
    }
    
    if(mounted) {
      await getIt<NotificationService>().requestPermissions(context);
      await context.read<WalletProvider>().initialLoad();
    }
    
    final pinIsSet = await _authService.hasPin();
    if (!pinIsSet) {
      if (mounted) setState(() => _status = AuthStatus.authenticated);
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
      _initializeApp();
    }
  }

  Future<void> _initUniLinks() async {
    try {
      final initialUri = await _appLinks.getInitialAppLink();
      if (initialUri != null && mounted) {
        _handleIncomingLink(initialUri);
      }
    } catch (e) {
    }
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      if (mounted) {
        _handleIncomingLink(uri);
      }
    }, onError: (err) {});
  }

  void _handleIncomingLink(Uri link) {
    if (link.pathSegments.contains('invite')) {
      final invitationToken = link.queryParameters['code'];
      if (invitationToken != null && invitationToken.isNotEmpty) {
        final navigator = NavigationService.navigatorKey.currentState;
        if (navigator != null && navigator.context.mounted) {
          navigator.push(MaterialPageRoute(
              builder: (_) =>
                  AcceptInvitationScreen(invitationToken: invitationToken)));
        }
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    switch (_status) {
      case AuthStatus.loading:
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      case AuthStatus.onboarding:
        return OnboardingScreen(onFinished: _handleOnboardingFinished);
      case AuthStatus.authenticated:
        return const AppNavigationShell();
      case AuthStatus.needsPinAuth:
        return PinEntryScreen(onSuccess: () async {
          if (mounted) {
            setState(() => _status = AuthStatus.authenticated);
            await _runStartupChecks();
          }
        });
    }
  }
}