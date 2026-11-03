import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

// Main Shell import
import 'package:leafcare_ia/core/widgets/main_shell.dart';

// Auth imports
import 'package:leafcare_ia/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:leafcare_ia/features/auth/presentation/screens/login_screen.dart';
import 'package:leafcare_ia/features/auth/presentation/screens/register_screen.dart';
// Dashboard imports
import 'package:leafcare_ia/features/dashboard/presentation/screens/home_screen.dart';
// Scanner imports
import 'package:leafcare_ia/features/scanner/presentation/screens/scanner_screen.dart';
// Alerts imports
import 'package:leafcare_ia/features/alerts/presentation/screens/alerts_screen.dart';
// Blog imports
import 'package:leafcare_ia/features/blog/data/datasources/rss_blog_datasource.dart';
import 'package:leafcare_ia/features/blog/data/repositories/blog_repository.dart';
import 'package:leafcare_ia/features/blog/presentation/bloc/blog_bloc.dart';
import 'package:leafcare_ia/features/blog/presentation/screens/blog_screen.dart';
// Profile imports
import 'package:leafcare_ia/features/profile/presentation/screens/profile_screen.dart';

import 'go_router_refresh_stream.dart';

GoRouter createRouter(AuthBloc authBloc) {
  return GoRouter(
    initialLocation: '/dashboard',
    refreshListenable: GoRouterRefreshStream(authBloc.stream),
    redirect: (BuildContext context, GoRouterState state) {
      final authState = authBloc.state;
      final isLoggingIn =
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';

      if (authState is AuthInitialState || authState is AuthLoadingState) {
        return null;
      }

      final isAuthenticated = authState is AuthenticatedState;

      if (!isAuthenticated && !isLoggingIn) {
        return '/login';
      }

      if (isAuthenticated && isLoggingIn) {
        return '/dashboard';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),

      // Rutas Protegidas dentro de la Shell de Navegación
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/dashboard',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/alerts',
                builder: (context, state) => const AlertsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/scan',
                builder: (context, state) => const ScanScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/blog',
                builder: (context, state) => BlocProvider(
                  create: (_) => BlogBloc(
                    repository: BlogRepository(
                      rssDatasource: RssBlogDatasource(),
                    ),
                  )..add(BlogStarted()),
                  child: const BlogScreen(),
                ),
              ),
            ],
          ),
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
}
