class NavJeevanRoutes {
  static const splash = '/';
  static const roleSelect = '/role-select';

  // Mother routes
  static const motherAuth = '/mother/auth';
  static const motherHelpRequest = '/mother/help-request';
  static const motherNgoMap = '/mother/ngo-map';
  static const motherCounseling = '/mother/counseling';
  static const motherCounselingBooking = '/mother/counseling/booking';
  static const motherProfile = '/mother/profile';

  // Parent (Adoptive) routes
  static const parentAuth = '/parent/auth';
  static const parentRegistrationWizard = '/parent/registration-wizard';
  static const parentVerificationStatus = '/parent/verification-status';
  static const parentGuidance = '/parent/guidance';
  static const parentSupport = '/parent/support';
  static const parentProfile = '/parent/profile';

  // Agency / NGO routes
  static const agencyAuth = '/agency/auth';
  static const agencyRequestsDashboard = '/agency/requests-dashboard';
  static const agencyWelfareMonitoring = '/agency/welfare-monitoring';
  static const agencyCounselorManagement = '/agency/counselor-management';
  static const agencyProfile = '/agency/profile';

  // Legal/Common
  static const legalGuidance = '/legal-guidance';

  // Admin routes
  static const adminAuth = '/admin/auth';
  static const adminDashboard = '/admin/dashboard';
}
