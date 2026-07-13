import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:admin_app/services/admin_service.dart';
import 'package:admin_app/view/login_screen.dart';
import 'package:admin_app/view/dashboard_screen.dart';

class AppColors {
  static const Color primaryColor = Color(0xFF1C6ECD);
  static const Color blackDark = Color(0xFF1A1A1A);
  static const Color blackLight = Color(0xFF666666);
  static const Color greyMedium = Color(0xFFE6E6E6);
  static const Color greyLight = Color(0xFFF5F5F5);
  static const Color errorColor = Color(0xFFB9727C);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://bdmtimgiqtcximckagle.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJkbXRpbWdpcXRjeGltY2thZ2xlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njk5NTkwNDAsImV4cCI6MjA4NTUzNTA0MH0.rolHffP2nRWabyhuJxN4Vsx7uuxaYRpaDXpcpGQ0xUw',
  );
  runApp(const AdminApp());
}

final supabase = Supabase.instance.client;

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ア・ラ・モード 管理者アプリ',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primaryColor),
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.blackDark,
          elevation: 0,
        ),
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final Stream<AuthState> _authStateChanges;

  @override
  void initState() {
    super.initState();
    _authStateChanges = AdminService.instance.authStateChanges;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: _authStateChanges,
      builder: (context, snapshot) {
        final isLoggedIn = AdminService.instance.isLoggedIn;
        if (!isLoggedIn) {
          return const LoginScreen();
        }
        return FutureBuilder<bool>(
          future: AdminService.instance.isAdmin(),
          builder: (context, adminSnapshot) {
            if (!adminSnapshot.hasData) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            if (adminSnapshot.data == true) {
              return const DashboardScreen();
            }
            return const _NotAdminScreen();
          },
        );
      },
    );
  }
}

class _NotAdminScreen extends StatelessWidget {
  const _NotAdminScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_outline, size: 48, color: AppColors.errorColor),
              const SizedBox(height: 16),
              const Text(
                'このアカウントには管理者権限がありません',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => AdminService.instance.signOut(),
                child: const Text('サインアウト'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
