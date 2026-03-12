import 'package:go_router/go_router.dart';

import '../features/auth/presentation/screens/edit_profile_screen.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/profile_screen.dart';
import '../features/auth/presentation/screens/register_screen.dart';
import '../features/auth/presentation/screens/splash_screen.dart';
import '../features/auth/state/auth_controller.dart';
import '../features/integration/presentation/screens/protected_workspace_placeholder_screen.dart';

class AppRouter {
  AppRouter(this._authController);

  final AuthController _authController;

  GoRouter get router => GoRouter(
        initialLocation: SplashScreen.path,
        refreshListenable: _authController,
        redirect: (context, state) {
          final location = state.matchedLocation;
          final isLoading = _authController.isLoading;
          final isLoggedIn = _authController.isAuthenticated;
          final isInAuthFlow = location == LoginScreen.path || location == RegisterScreen.path;
          final isSplash = location == SplashScreen.path;
          final isProtectedRoute = location == ProfileScreen.path ||
              location == EditProfileScreen.path ||
              location == ProtectedWorkspacePlaceholderScreen.path;

          if (isLoading) {
            return isSplash ? null : SplashScreen.path;
          }

          if (!isLoggedIn && isSplash) {
            return LoginScreen.path;
          }

          if (!isLoggedIn && isProtectedRoute) {
            return LoginScreen.path;
          }

          if (isLoggedIn && (isInAuthFlow || isSplash)) {
            return ProfileScreen.path;
          }

          return null;
        },
        routes: <RouteBase>[
          GoRoute(
            path: SplashScreen.path,
            builder: (context, state) => const SplashScreen(),
          ),
          GoRoute(
            path: LoginScreen.path,
            builder: (context, state) => LoginScreen(controller: _authController),
          ),
          GoRoute(
            path: RegisterScreen.path,
            builder: (context, state) => RegisterScreen(controller: _authController),
          ),
          GoRoute(
            path: ProfileScreen.path,
            builder: (context, state) => ProfileScreen(controller: _authController),
          ),
          GoRoute(
            path: EditProfileScreen.path,
            builder: (context, state) => EditProfileScreen(controller: _authController),
          ),
          GoRoute(
            path: ProtectedWorkspacePlaceholderScreen.path,
            builder: (context, state) => const ProtectedWorkspacePlaceholderScreen(),
          ),
        ],
      );
}
