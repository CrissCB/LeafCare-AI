import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

// Main Shell import
import 'package:leafcare_ia/core/widgets/main_shell.dart';

// login imports
import 'package:leafcare_ia/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:leafcare_ia/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:leafcare_ia/features/auth/presentation/screens/login_screen.dart';
// dashboard imports
import 'package:leafcare_ia/features/dashboard/presentation/screens/home_screen.dart';
// scanner imports
import 'package:leafcare_ia/features/scanner/presentation/screens/scanner_screen.dart';
// alerts imports
import 'package:leafcare_ia/features/alerts/presentation/screens/alerts_screen.dart';
// blog imports
import 'package:leafcare_ia/features/blog/presentation/screens/blog_screen.dart';
// profile imports
import 'package:leafcare_ia/features/profile/presentation/screens/profile_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/login',
  routes: [
    // Ruta de Login
    GoRoute(
      path: '/login',
      builder: (context, state) => BlocProvider(
        create: (_) => AuthBloc(datasource: AuthRemoteDatasource()),
        child: const LoginScreen(),
      ),
    ),

    // Rutas con Barra de Navegación Inferior (Shell)
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return MainShell(navigationShell: navigationShell);
      },
      branches: [
        // Rama 0: Inicio / Dashboard
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/dashboard',
              builder: (context, state) => const HomeScreen(),
            ),
          ],
        ),
        // Rama 1: Alertas
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/alerts',
              builder: (context, state) => const AlertsScreen(),
            ),
          ],
        ),
        // Rama 2: Escáner
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/scan',
              builder: (context, state) => const ScanScreen(),
            ),
          ],
        ),
        // Rama 3: Blog
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/blog',
              builder: (context, state) => const BlogScreen(),
            ),
          ],
        ),
        // Rama 4: Perfil
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/profile',
              builder: (context, state) => const ProfileScreen(),
            ),
          ],
        ),
      ],
    ),
  ],
);
