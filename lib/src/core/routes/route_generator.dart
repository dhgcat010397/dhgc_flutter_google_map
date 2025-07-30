import 'package:flutter/material.dart';

import 'package:dhgc_flutter_google_map/src/core/routes/app_routes.dart';

class RouteGenerator {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    final args = settings.arguments;

    switch (settings.name) {
      // case AppRoutes.splash:
      //   return MaterialPageRoute(builder: (_) => SplashPage());

      // case AppRoutes.auth:
      //   return MaterialPageRoute(builder: (_) => const AuthPage());

      // case AppRoutes.home:
      //   return _buildRoute(
      //     settings,
      //     BlocBuilder<AuthBloc, AuthState>(
      //       builder: (context, state) {
      //         return state.maybeWhen(
      //           authenticated: (user) => HomePage(user: user),
      //           orElse: () => const RedirectToAuthPage(),
      //         );
      //       },
      //     ),
      //   );

      // case AppRoutes.chat:
      //   if (args is Map<String, dynamic>) {
      //     return MaterialPageRoute(
      //       builder:
      //           (_) => ChatPage(
      //             conversation: args['conversation'],
      //             user: args['user'],
      //           ),
      //     );
      //   }

      //   return _errorRoute();

      default:
        return _errorRoute();
    }
  }

  static PageRouteBuilder _buildRoute(RouteSettings settings, Widget builder) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (_, __, ___) => builder,
      transitionsBuilder:
          (_, animation, __, child) =>
              FadeTransition(opacity: animation, child: child),
    );
  }

  static Route<dynamic> _errorRoute() {
    return MaterialPageRoute(
      builder:
          (_) => Scaffold(
            appBar: AppBar(title: const Text('Error')),
            body: const Center(child: Text('Page not found')),
          ),
    );
  }
}
