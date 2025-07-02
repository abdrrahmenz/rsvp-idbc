import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'config/supabase_config.dart';
import 'providers/auth_provider.dart';
import 'providers/student_provider.dart';
import 'providers/invitation_provider.dart';
import 'providers/dashboard_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => StudentProvider()),
        ChangeNotifierProvider(create: (_) => InvitationProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
      ],
      builder: (context, child) {
        // Wire up dashboard provider references after providers are created
        final dashboardProvider =
            Provider.of<DashboardProvider>(context, listen: false);
        final studentProvider =
            Provider.of<StudentProvider>(context, listen: false);
        final invitationProvider =
            Provider.of<InvitationProvider>(context, listen: false);

        // Set dashboard provider references so CRUD operations can refresh dashboard stats
        studentProvider.setDashboardProvider(dashboardProvider);
        invitationProvider.setDashboardProvider(dashboardProvider);

        return child!;
      },
      child: MaterialApp(
        title: 'Undangan Wisuda',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          textTheme: GoogleFonts.poppinsTextTheme(),
          appBarTheme: AppBarTheme(
            elevation: 0,
            centerTitle: true,
            backgroundColor: Colors.blue[700],
            foregroundColor: Colors.white,
          ),
        ),
        home: Consumer<AuthProvider>(
          builder: (context, authProvider, _) {
            // Show splash screen while loading
            if (authProvider.isLoading) {
              return const SplashScreen();
            }

            // Navigate based on authentication status
            return authProvider.isAuthenticated
                ? const DashboardScreen()
                : const LoginScreen();
          },
        ),
      ),
    );
  }
}
