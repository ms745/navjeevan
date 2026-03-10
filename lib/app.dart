import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'core/theme/theme.dart';
import 'core/constants/route_names.dart';
import 'providers/auth_provider.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/role_select/role_select_screen.dart';
import 'screens/mother/mother_auth_screen.dart';
import 'screens/mother/help_request_screen.dart';
import 'screens/mother/ngo_support_map_screen.dart';
import 'screens/mother/counseling_screen.dart';
import 'screens/mother/counseling_booking_screen.dart';
import 'screens/mother/mother_profile_screen.dart';
import 'screens/parent/parent_auth_screen.dart';
import 'screens/parent/parent_registration_wizard_screen.dart';
import 'screens/parent/parent_verification_status_screen.dart';
import 'screens/parent/parent_guidance_screen.dart';
import 'screens/parent/parent_support_screen.dart';
import 'screens/parent/parent_profile_screen.dart';
import 'screens/agency/agency_auth_screen.dart';
import 'screens/agency/agency_requests_dashboard_screen.dart';
import 'screens/agency/agency_welfare_monitoring_screen.dart';
import 'screens/agency/agency_counselor_management_screen.dart';
import 'screens/agency/agency_profile_screen.dart';
import 'screens/updated_legal_guidance_screen.dart';
import 'screens/admin/admin_auth_screen.dart';
import 'screens/admin/admin_dashboard_screen.dart';

class NavJeevanApp extends StatelessWidget {
  const NavJeevanApp({super.key});

  @override
  Widget build(BuildContext context) {
    final GoRouter router = GoRouter(
      initialLocation: NavJeevanRoutes.splash,
      redirect: (context, state) {
        final auth = context.read<AuthProvider>();

        // Allow access to splash, role select, and auth screens without authentication
        final publicRoutes = [
          NavJeevanRoutes.splash,
          NavJeevanRoutes.roleSelect,
          NavJeevanRoutes.motherAuth,
          NavJeevanRoutes.parentAuth,
          NavJeevanRoutes.agencyAuth,
          NavJeevanRoutes.adminAuth,
        ];

        // If already on a public route, allow access
        if (publicRoutes.contains(state.matchedLocation)) {
          return null;
        }

        // Protected routes require authentication and role verification
        final protectedMotherRoutes = [
          NavJeevanRoutes.motherHelpRequest,
          NavJeevanRoutes.motherNgoMap,
          NavJeevanRoutes.motherCounseling,
          NavJeevanRoutes.motherCounselingBooking,
          NavJeevanRoutes.motherProfile,
        ];

        final protectedParentRoutes = [
          NavJeevanRoutes.parentRegistrationWizard,
          NavJeevanRoutes.parentVerificationStatus,
          NavJeevanRoutes.parentGuidance,
          NavJeevanRoutes.parentSupport,
          NavJeevanRoutes.parentProfile,
        ];

        final protectedAgencyRoutes = [
          NavJeevanRoutes.agencyRequestsDashboard,
          NavJeevanRoutes.agencyWelfareMonitoring,
          NavJeevanRoutes.agencyCounselorManagement,
          NavJeevanRoutes.agencyProfile,
        ];

        final protectedAdminRoutes = [NavJeevanRoutes.adminDashboard];

        // If user is not logged in, redirect to role select
        if (!auth.isAuthenticated) {
          return NavJeevanRoutes.roleSelect;
        }

        // Enforce role-based access
        if (protectedMotherRoutes.contains(state.matchedLocation) &&
            auth.userRole != 'mother') {
          return NavJeevanRoutes.roleSelect;
        }

        if (protectedParentRoutes.contains(state.matchedLocation) &&
            auth.userRole != 'parent') {
          return NavJeevanRoutes.roleSelect;
        }

        if (protectedAgencyRoutes.contains(state.matchedLocation) &&
            auth.userRole != 'agency') {
          return NavJeevanRoutes.roleSelect;
        }

        if (protectedAdminRoutes.contains(state.matchedLocation) &&
            auth.userRole != 'admin') {
          return NavJeevanRoutes.roleSelect;
        }

        // Allow access to legal guidance and other shared routes
        return null;
      },
      routes: [
        GoRoute(
          path: NavJeevanRoutes.splash,
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          path: NavJeevanRoutes.roleSelect,
          builder: (context, state) => const RoleSelectScreen(),
        ),
        GoRoute(
          path: NavJeevanRoutes.motherAuth,
          builder: (context, state) => const MotherAuthScreen(),
        ),
        GoRoute(
          path: NavJeevanRoutes.motherHelpRequest,
          builder: (context, state) => const HelpRequestScreen(),
        ),
        GoRoute(
          path: NavJeevanRoutes.motherNgoMap,
          builder: (context, state) => const NgoSupportMapScreen(),
        ),
        GoRoute(
          path: NavJeevanRoutes.motherCounseling,
          builder: (context, state) => const CounselingScreen(),
        ),
        GoRoute(
          path: NavJeevanRoutes.motherCounselingBooking,
          builder: (context, state) => CounselingBookingScreen(
            counselor: state.extra as Map<String, dynamic>?,
          ),
        ),
        GoRoute(
          path: NavJeevanRoutes.motherProfile,
          builder: (context, state) => const MotherProfileScreen(),
        ),
        GoRoute(
          path: NavJeevanRoutes.parentAuth,
          builder: (context, state) => const ParentAuthScreen(),
        ),
        GoRoute(
          path: NavJeevanRoutes.parentRegistrationWizard,
          builder: (context, state) => const ParentRegistrationWizardScreen(),
        ),
        GoRoute(
          path: NavJeevanRoutes.parentVerificationStatus,
          builder: (context, state) => const ParentVerificationStatusScreen(),
        ),
        GoRoute(
          path: NavJeevanRoutes.parentGuidance,
          builder: (context, state) => const ParentGuidanceScreen(),
        ),
        GoRoute(
          path: NavJeevanRoutes.parentSupport,
          builder: (context, state) => const ParentSupportScreen(),
        ),
        GoRoute(
          path: NavJeevanRoutes.parentProfile,
          builder: (context, state) => const ParentProfileScreen(),
        ),
        GoRoute(
          path: NavJeevanRoutes.agencyAuth,
          builder: (context, state) => const AgencyAuthScreen(),
        ),
        GoRoute(
          path: NavJeevanRoutes.agencyRequestsDashboard,
          builder: (context, state) => const AgencyRequestsDashboardScreen(),
        ),
        GoRoute(
          path: NavJeevanRoutes.agencyWelfareMonitoring,
          builder: (context, state) => const AgencyWelfareMonitoringScreen(),
        ),
        GoRoute(
          path: NavJeevanRoutes.agencyCounselorManagement,
          builder: (context, state) => const AgencyCounselorManagementScreen(),
        ),
        GoRoute(
          path: NavJeevanRoutes.agencyProfile,
          builder: (context, state) => const AgencyProfileScreen(),
        ),
        GoRoute(
          path: NavJeevanRoutes.legalGuidance,
          builder: (context, state) => const UpdatedLegalGuidanceScreen(),
        ),
        GoRoute(
          path: NavJeevanRoutes.adminAuth,
          builder: (context, state) => const AdminAuthScreen(),
        ),
        GoRoute(
          path: NavJeevanRoutes.adminDashboard,
          builder: (context, state) => const AdminDashboardScreen(),
        ),
      ],
    );

    return MaterialApp.router(
      title: 'NavJeevan',
      theme: NavJeevanTheme.theme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
