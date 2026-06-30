import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../home/presentation/bloc/home_bloc.dart';
import '../bloc/auth_bloc.dart';
import 'auth_page.dart';
import 'home_page.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state.isInitializing) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!state.isAuthenticated) {
          return const AuthPage();
        }

        return BlocProvider(
          create: (context) => HomeBloc()..add(const HomeLoadRequested()),
          child: const HomePage(),
        );
      },
    );
  }
}
