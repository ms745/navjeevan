import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'core/theme/theme.dart';
import 'core/constants/route_names.dart';
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
          builder: (context, state) =>
              const AgencyCounselorManagementScreen(),
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
