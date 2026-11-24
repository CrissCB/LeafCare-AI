import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:leafcare_ia/app/config/app_router.dart';
import 'package:leafcare_ia/app/config/app_theme.dart';
import 'package:leafcare_ia/core/network/supabase_client.dart';
import 'package:leafcare_ia/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:leafcare_ia/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:leafcare_ia/features/auth/presentation/bloc/auth_bloc.dart';

class LeafCareApp extends StatefulWidget {
  const LeafCareApp({super.key});

  @override
  State<LeafCareApp> createState() => _LeafCareAppState();
}

class _LeafCareAppState extends State<LeafCareApp> {
  late final AuthBloc _authBloc;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();

    const supabaseClient = AppSupabaseClient();

    _authBloc = AuthBloc(
      repository: AuthRepositoryImpl(
        remoteDatasource: AuthRemoteDatasource(supabaseClient: supabaseClient),
      ),
    )..add(CheckAuthStatusEvent());

    _router = createRouter(_authBloc);
  }

  @override
  void dispose() {
    _authBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _authBloc,
      child: MaterialApp.router(
        title: 'LeafCare AI',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        routerConfig: _router,
      ),
    );
  }
}
