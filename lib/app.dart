import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/theme/app_theme.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/data/local_insight_shelf_backend.dart';
import 'features/auth/presentation/auth_cubit.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/library/data/reader_backend_store.dart';
import 'features/library/data/library_repository.dart';
import 'features/library/presentation/library_cubit.dart';
import 'features/library/presentation/main_shell.dart';
import 'features/reader/presentation/reader_cubit.dart';

class InsightShelfApp extends StatelessWidget {
  const InsightShelfApp({this.backendStore, super.key});

  final ReaderBackendStore? backendStore;

  @override
  Widget build(BuildContext context) {
    final api = LocalInsightShelfBackend(backendStore: backendStore);
    final authRepository = AuthRepository(api);
    final libraryRepository = LibraryRepository(api);

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: authRepository),
        RepositoryProvider.value(value: libraryRepository),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) => AuthCubit(authRepository)..restoreSession(),
          ),
          BlocProvider(create: (_) => LibraryCubit(libraryRepository)),
          BlocProvider(create: (_) => ReaderCubit(libraryRepository)),
        ],
        child: MaterialApp(
          title: 'InsightShelf Mobile',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          home: const AuthGate(),
        ),
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listenWhen: (previous, current) =>
          previous.status != current.status &&
          current.status == AuthStatus.authenticated,
      listener: (context, state) {
        context.read<LibraryCubit>().loadLibrary();
      },
      child: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, state) {
          if (state.status == AuthStatus.checking) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (state.status == AuthStatus.authenticated) {
            return const MainShell();
          }

          return const LoginScreen();
        },
      ),
    );
  }
}

class MyApp extends InsightShelfApp {
  const MyApp({super.key});
}
