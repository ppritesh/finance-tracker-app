import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/api_client.dart';
import 'data/auth_controller.dart';
import 'data/finance_repository.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'screens/two_factor_verify_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FinanceTrackerApp());
}

class FinanceTrackerApp extends StatefulWidget {
  const FinanceTrackerApp({super.key});

  @override
  State<FinanceTrackerApp> createState() => _FinanceTrackerAppState();
}

class _FinanceTrackerAppState extends State<FinanceTrackerApp> {
  late final ApiClient _api;
  late final AuthController _auth;
  late final FinanceRepository _repo;

  @override
  void initState() {
    super.initState();
    _api = ApiClient();
    _auth = AuthController(_api)..load();
    _repo = FinanceRepository(api: _api, auth: _auth);
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _auth),
        ChangeNotifierProvider.value(value: _repo),
      ],
      child: MaterialApp(
        title: 'Finance Tracker',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF1565C0),
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          inputDecorationTheme: const InputDecorationTheme(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          navigationBarTheme: const NavigationBarThemeData(
            height: 64,
          ),
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF1565C0),
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
          inputDecorationTheme: const InputDecorationTheme(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          navigationBarTheme: const NavigationBarThemeData(
            height: 64,
          ),
        ),
        home: const _AppGate(),
      ),
    );
  }
}

class _AppGate extends StatefulWidget {
  const _AppGate();

  @override
  State<_AppGate> createState() => _AppGateState();
}

class _AppGateState extends State<_AppGate> {
  bool _dataLoaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncDataLoad());
  }

  Future<void> _syncDataLoad() async {
    final auth = context.read<AuthController>();
    while (!auth.isLoaded) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }

    if (!mounted) return;

    try {
      if (auth.isAuthenticated && !auth.needsTwoFactor && !_dataLoaded) {
        await context.read<FinanceRepository>().refreshAll();
        if (mounted) setState(() => _dataLoaded = true);
        return;
      }
    } catch (_) {
      if (mounted) setState(() => _dataLoaded = true);
      return;
    }

    if ((!auth.isAuthenticated || auth.needsTwoFactor) && _dataLoaded) {
      setState(() => _dataLoaded = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();

    if (auth.isAuthenticated && !auth.needsTwoFactor && !_dataLoaded) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _syncDataLoad());
    }

    if (!auth.isLoaded || (auth.isAuthenticated && !auth.needsTwoFactor && !_dataLoaded)) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!auth.isAuthenticated) {
      if (auth.needsTwoFactor) {
        return const TwoFactorVerifyScreen();
      }
      return const AuthScreen();
    }

    return const HomeScreen();
  }
}
