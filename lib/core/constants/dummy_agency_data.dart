class AgencySupportRequest {
  final String requestId;
  final String region;
  final int age;
  final String reason;
  final String supportNeeded;
  final bool anonymous;
  final String riskLevel;
  final String status;

  const AgencySupportRequest({
    required this.requestId,
    required this.region,
    required this.age,
    required this.reason,
    required this.supportNeeded,
    required this.anonymous,
    required this.riskLevel,
    required this.status,
  });
}

class AgencyNgoCenter {
  final String ngoId;
  final String name;
  final String region;
  final List<String> services;
  final String contact;
  final double rating;

  const AgencyNgoCenter({
    required this.ngoId,
    required this.name,
    required this.region,
    required this.services,
    required this.contact,
    required this.rating,
  });
}

class AgencyAdoptiveFamily {
  final String familyId;
  final String familyName;
  final String region;
  final String incomeLevel;
  final bool homeVerified;
  final String backgroundCheck;
  final int children;
  final String adoptionStatus;

  const AgencyAdoptiveFamily({
    required this.familyId,
    required this.familyName,
    required this.region,
    required this.incomeLevel,
    required this.homeVerified,
    required this.backgroundCheck,
    required this.children,
    required this.adoptionStatus,
  });
}

class AgencyChildWelfare {
  final String childId;
  final String adoptedBy;
  final String region;
  final String healthStatus;
  final String educationStatus;
  final String lastHomeVisit;
  final int welfareScore;

  const AgencyChildWelfare({
    required this.childId,
    required this.adoptedBy,
    required this.region,
    required this.healthStatus,
    required this.educationStatus,
    required this.lastHomeVisit,
    required this.welfareScore,
  });
}

class AgencyCounselor {
  final String counselorId;
  final String name;
  final String specialty;
  final String availability;
  final int activeCases;
  final int maxCases;
  final String status;
  final String? qualification;
  final String? email;
  final String? phone;

  const AgencyCounselor({
    required this.counselorId,
    required this.name,
    required this.specialty,
    required this.availability,
    required this.activeCases,
    required this.maxCases,
    required this.status,
    this.qualification,
    this.email,
    this.phone,
  });
}

class Counsellor {
  final String name;
  final String specialty;
  final List<String> availabilityDays;
  final int activeCases;
  final int maxCases;
  final String status;
  final String image;
  final String action;

  const Counsellor({
    required this.name,
    required this.specialty,
    required this.availabilityDays,
    required this.activeCases,
    required this.maxCases,
    required this.status,
    required this.image,
    required this.action,
  });
}

class DummyAgencyData {
  static const List<AgencySupportRequest> motherSupportRequests = [
    AgencySupportRequest(
      requestId: '#MH-9021',
      region: 'North Highlands',
      age: 22,
      reason: 'Postpartum Support',
      supportNeeded: 'Adoption Assistance',
      anonymous: true,
      riskLevel: 'High',
      status: 'Pending',
    ),
    AgencySupportRequest(
      requestId: '#MH-8843',
      region: 'East Riverside',
      age: 19,
      reason: 'Emergency Housing',
      supportNeeded: 'Counseling',
      anonymous: true,
      riskLevel: 'Medium',
      status: 'Assigned',
    ),
    AgencySupportRequest(
      requestId: '#MH-8712',
      region: 'South Bay',
      age: 24,
      reason: 'Nutrition Guidance',
      supportNeeded: 'Legal Guidance',
      anonymous: true,
      riskLevel: 'Low',
      status: 'Pending',
    ),
    AgencySupportRequest(
      requestId: '#MH-8655',
      region: 'West Valley',
      age: 27,
      reason: 'Lactation Consult',
      supportNeeded: 'Immediate Shelter',
      anonymous: false,
      riskLevel: 'Medium',
      status: 'In Progress',
    ),
    AgencySupportRequest(
      requestId: '#MH-8540',
      region: 'Central Metro',
      age: 21,
      reason: 'Medical Supplies',
      supportNeeded: 'Adoption Assistance',
      anonymous: true,
      riskLevel: 'High',
      status: 'Pending',
    ),
  ];

  static const List<AgencyNgoCenter> ngoCenters = [
    AgencyNgoCenter(
      ngoId: 'NGO101',
      name: 'Snehalaya Child Support Center',
      region: 'Hadapsar',
      services: ['Counseling', 'Adoption Support'],
      contact: '+91 9876543210',
      rating: 4.5,
    ),
    AgencyNgoCenter(
      ngoId: 'NGO102',
      name: 'Child Welfare Society Pune',
      region: 'Shivajinagar',
      services: ['Legal Guidance', 'Shelter'],
      contact: '+91 9876543211',
      rating: 4.3,
    ),
    AgencyNgoCenter(
      ngoId: 'NGO103',
      name: 'Sakhi Women\'s Support NGO',
      region: 'Katraj',
      services: ['Counseling', 'Medical Support'],
      contact: '+91 9876543212',
      rating: 4.6,
    ),
    AgencyNgoCenter(
      ngoId: 'NGO104',
      name: 'Hope Adoption Services',
      region: 'Wakad',
      services: ['Adoption Processing', 'Family Verification'],
      contact: '+91 9876543213',
      rating: 4.4,
    ),
  ];

  static const List<AgencyAdoptiveFamily> verifiedFamilies = [
    AgencyAdoptiveFamily(
      familyId: 'FAM201',
      familyName: 'Kulkarni',
      region: 'Baner',
      incomeLevel: 'High',
      homeVerified: true,
      backgroundCheck: 'Approved',
      children: 0,
      adoptionStatus: 'Eligible',
    ),
    AgencyAdoptiveFamily(
      familyId: 'FAM202',
      familyName: 'Patil',
      region: 'Aundh',
      incomeLevel: 'Medium',
      homeVerified: true,
      backgroundCheck: 'Approved',
      children: 1,
      adoptionStatus: 'Eligible',
    ),
    AgencyAdoptiveFamily(
      familyId: 'FAM203',
      familyName: 'Deshmukh',
      region: 'Kothrud',
      incomeLevel: 'High',
      homeVerified: true,
      backgroundCheck: 'Approved',
      children: 0,
      adoptionStatus: 'Eligible',
    ),
    AgencyAdoptiveFamily(
      familyId: 'FAM204',
      familyName: 'Shinde',
      region: 'Pimpri',
      incomeLevel: 'Medium',
      homeVerified: true,
      backgroundCheck: 'Pending',
      children: 2,
      adoptionStatus: 'Under Review',
    ),
  ];

  static const List<AgencyChildWelfare> childWelfare = [
    AgencyChildWelfare(
      childId: '#8821',
      adoptedBy: 'Thompson Family',
      region: 'North Highlands',
      healthStatus: 'Good',
      educationStatus: 'Pre-school',
      lastHomeVisit: '2 days ago',
      welfareScore: 42,
    ),
    AgencyChildWelfare(
      childId: '#9012',
      adoptedBy: 'Miller Residence',
      region: 'East Riverside',
      healthStatus: 'Good',
      educationStatus: 'Primary School',
      lastHomeVisit: '1 week ago',
      welfareScore: 89,
    ),
    AgencyChildWelfare(
      childId: '#7743',
      adoptedBy: 'Davies Home',
      region: 'South Bay',
      healthStatus: 'Good',
      educationStatus: 'Primary School',
      lastHomeVisit: 'Today',
      welfareScore: 67,
    ),
    AgencyChildWelfare(
      childId: '#9255',
      adoptedBy: 'Henderson Care',
      region: 'West Valley',
      healthStatus: 'Excellent',
      educationStatus: 'Secondary School',
      lastHomeVisit: '3 days ago',
      welfareScore: 94,
    ),
  ];

  static const List<AgencyCounselor> counselors = [
    AgencyCounselor(
      counselorId: 'C001',
      name: 'Dr. Sarah Jenkins',
      specialty: 'Child Psychology',
      availability: 'Mon, Wed, Fri',
      activeCases: 12,
      maxCases: 15,
      status: 'Active',
      qualification: 'PhD in Clinical Psychology',
      email: 'sarah.jenkins@agency.com',
      phone: '+1 (555) 123-4567',
    ),
    AgencyCounselor(
      counselorId: 'C002',
      name: 'Marcus Thompson, MSW',
      specialty: 'Trauma Recovery',
      availability: 'Tue, Thu, Sat',
      activeCases: 8,
      maxCases: 15,
      status: 'Active',
      qualification: 'MSW Social Work',
      email: 'marcus.thompson@agency.com',
      phone: '+1 (555) 234-5678',
    ),
    AgencyCounselor(
      counselorId: 'C003',
      name: 'Elena Rodriguez',
      specialty: 'Family Systems',
      availability: 'Mon-Fri',
      activeCases: 15,
      maxCases: 15,
      status: 'Active',
      qualification: 'MEd Family Counseling',
      email: 'elena.rodriguez@agency.com',
      phone: '+1 (555) 345-6789',
    ),
    AgencyCounselor(
      counselorId: 'C004',
      name: 'Dr. David Chen',
      specialty: 'Cognitive Behavioral',
      availability: 'Weekends Only',
      activeCases: 3,
      maxCases: 10,
      status: 'Pending',
      qualification: 'PhD in CBT',
      email: 'david.chen@agency.com',
      phone: '+1 (555) 456-7890',
    ),
    AgencyCounselor(
      counselorId: 'C005',
      name: 'Dr. Priya Sharma',
      specialty: 'Maternal Health',
      availability: 'Mon, Wed, Fri, Sat',
      activeCases: 11,
      maxCases: 14,
      status: 'Active',
      qualification: 'MD Maternal Psychology',
      email: 'priya.sharma@agency.com',
      phone: '+1 (555) 567-8901',
    ),
    AgencyCounselor(
      counselorId: 'C006',
      name: 'Adv. Rajesh Kumar',
      specialty: 'Legal Consultation',
      availability: 'Tue, Thu, Sat',
      activeCases: 6,
      maxCases: 10,
      status: 'On Leave',
      qualification: 'LLM Family Law',
      email: 'rajesh.kumar@agency.com',
      phone: '+1 (555) 678-9012',
    ),
  ];

  static const List<Counsellor> agencyCounsellors = [
    Counsellor(
      name: 'Dr. Sarah Jenkins',
      specialty: 'Child Psychology',
      availabilityDays: ['Mon', 'Wed', 'Fri'],
      activeCases: 12,
      maxCases: 15,
      status: 'available',
      image:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuCtTAkR7V90sYgAsEkOjDzy1uFrHQeuDaACdWJmDga7yz3RQvlyG8LM7v7LN4_eU1WSo_jsbJI6KRup9DecQhRZSaUiXEDVX4UUpPDhTWWB3x4ktiyUFqiKdPRToYX44Wz8suPlAEBZ2Mn71xLlhYwnEaDbiMvsVNzy6D3hfoMgfFqvXL6V3-WhplYDMC2u0lLN4MuyZ183h2WqsgbuK8Rd-YKW62kUYrzVqRwqh6qVcpFCgpNNwCQpCl4sCO95tiE4vDEVbLEkCnBR',
      action: 'Schedule',
    ),
    Counsellor(
      name: 'Marcus Thompson',
      specialty: 'Trauma Recovery',
      availabilityDays: ['Tue', 'Thu', 'Sat'],
      activeCases: 8,
      maxCases: 15,
      status: 'available',
      image:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuD5n4dBVx2g7I-qDwaW_-5YpkJEGUA61kxkiy1oHd1S0XLu6ufd8qTy4yFXpG9s81yaa7IWUe8KefzMAgX7cD_-hIRy3aMD6Ar33X_GDkuJR3caXeLQBB23eAC9C15ytYazzh1h1UAYx1zaHOIwbpysPrpT4XeZ5fstY1noinIWI744hWkoHVisabzWJcV49a1tr-VPvAjFfAxXwab1CBf448LNJq0SH_kOP6f7mysttpDA3vMF-S_ilovA1gLc7CDeKhEE7pOqUXP7',
      action: 'Schedule',
    ),
    Counsellor(
      name: 'Elena Rodriguez',
      specialty: 'Family Systems',
      availabilityDays: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'],
      activeCases: 15,
      maxCases: 15,
      status: 'full',
      image:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuBi_AzXMEcJ4XeAdkeLZOqZdPv-v7P6Slpzy0ORZH0rznM0H0ZPRKmVRhS1eqGA5fufjZl7d5EegZsf8ZdI1RCRxTGZo_7kmN6W9iix4ST_Lvo7GnbQdmXFphr-cZe-wtwx7RwMNkHzFMJcgrqnxNN1Chk8okGzErihcoKJzbJ7bODu7D3DnNL9OntU8rD1-nESuXymISc-BazSHYQPnOWJhqw6VptRwTTUmSGY08bvXbnH1zxRjI-eXTe7vLLKl94H_lG6RS0p6NFo',
      action: 'Waitlist',
    ),
    Counsellor(
      name: 'Dr. David Chen',
      specialty: 'Cognitive Behavioral',
      availabilityDays: ['Sat', 'Sun'],
      activeCases: 3,
      maxCases: 10,
      status: 'available',
      image:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuDOC91kwto3S6BGW-IOTfL5MdaGuHAh0Q6tLBNDejTLEna7HDzyc4VxY-b7et-fPF6rLUoFWj73T16JsjpzmfuqwcbbOHKqU4n-Mgym93jiyv71pL13QD649BNn6mMbzsXRTEqS-gVIGluk0ZluwnVOtqLuRbttPp4FAzE2hICgvozgBwRXPLV4-HI_0v3-BDClf-xqW6KabfQqNQwhcdufQqseOP9GRG4xkYskZvK06Y1Tarnycjg1HqiJiYJo0n6K1dnWDzGN57ca',
      action: 'Schedule',
    ),
  ];

  static List<Map<String, String>> adoptionRequests = [
    {
      'requestId': 'ADP501',
      'familyId': 'FAM201',
      'familyName': 'Kulkarni',
      'region': 'Baner',
      'type': 'Adoption Request',
      'risk': 'Low',
      'status': 'Resolved',
    },
    {
      'requestId': 'ADP502',
      'familyId': 'FAM204',
      'familyName': 'Shinde',
      'region': 'Pimpri',
      'type': 'Adoption Request',
      'risk': 'Medium',
      'status': 'In Progress',
    },
    {
      'requestId': 'ADP503',
      'familyId': 'FAM202',
      'familyName': 'Patil',
      'region': 'Aundh',
      'type': 'Adoption Request',
      'risk': 'Low',
      'status': 'Pending',
    },
    {
      'requestId': 'ADP504',
      'familyId': 'FAM203',
      'familyName': 'Deshmukh',
      'region': 'Kothrud',
      'type': 'Adoption Request',
      'risk': 'Low',
      'status': 'Resolved',
    },
  ];
}
