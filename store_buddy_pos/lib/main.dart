import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

import 'blocs/auth/auth_bloc.dart';
import 'screens/dashboard_screen.dart';
import 'screens/login_screen.dart';
import 'services/api_client.dart';
import 'services/auth_service.dart';
import 'theme/app_theme.dart';
import 'theme/theme_controller.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ApiClient>(create: (_) => ApiClient()),
        ProxyProvider<ApiClient, AuthService>(
          update: (_, apiClient, _) => AuthService(apiClient),
        ),
        ChangeNotifierProvider<ThemeController>(
          create: (_) => ThemeController()..load(),
        ),
      ],
      child: Builder(
        builder: (context) => BlocProvider<AuthBloc>(
          create: (_) => AuthBloc(context.read<AuthService>()),
          child: Consumer<ThemeController>(
            builder: (context, themeController, _) => MaterialApp(
              title: 'Store Buddy POS',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.light(),
              darkTheme: AppTheme.dark(),
              themeMode: themeController.themeMode,
              home: const StartupGate(),
            ),
          ),
        ),
      ),
    );
  }
}

class StartupGate extends StatefulWidget {
  const StartupGate({super.key});

  @override
  State<StartupGate> createState() => _StartupGateState();
}

class _StartupGateState extends State<StartupGate> {
  @override
  void initState() {
    super.initState();
    context.read<AuthBloc>().add(AuthCheckStatusRequested());
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is AuthLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (state is AuthAuthenticated) {
          return DashboardScreen(user: state.user);
        }

        return const LoginScreen();
      },
    );
  }
}
