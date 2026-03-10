import 'parent_models.dart';

class DummyParentData {
  // Verified Adoptive Families
  static final List<AdoptiveFamily> verifiedFamilies = [
    AdoptiveFamily(
      familyId: "FAM201",
      familyName: "Kulkarni",
      region: "Baner",
      incomeLevel: "High",
      homeVerified: true,
      backgroundCheck: "Approved",
      children: 0,
      adoptionStatus: "Eligible",
      contactPhone: "9876501234",
      email: "kulkarni.family@example.com",
      registrationDate: DateTime(2025, 8, 15),
      verificationScore: 95,
    ),
    AdoptiveFamily(
      familyId: "FAM202",
      familyName: "Patil",
      region: "Aundh",
      incomeLevel: "Medium",
      homeVerified: true,
      backgroundCheck: "Approved",
      children: 1,
      adoptionStatus: "Eligible",
      contactPhone: "9876502345",
      email: "patil.home@example.com",
      registrationDate: DateTime(2025, 9, 20),
      verificationScore: 88,
    ),
    AdoptiveFamily(
      familyId: "FAM203",
      familyName: "Deshmukh",
      region: "Kothrud",
      incomeLevel: "High",
      homeVerified: true,
      backgroundCheck: "Approved",
      children: 0,
      adoptionStatus: "Eligible",
      contactPhone: "9876503456",
      email: "deshmukh.family@example.com",
      registrationDate: DateTime(2025, 10, 5),
      verificationScore: 92,
    ),
    AdoptiveFamily(
      familyId: "FAM204",
      familyName: "Shinde",
      region: "Pimpri",
      incomeLevel: "Medium",
      homeVerified: true,
      backgroundCheck: "Pending",
      children: 2,
      adoptionStatus: "Under Review",
      contactPhone: "9876504567",
      email: "shinde.residence@example.com",
      registrationDate: DateTime(2026, 1, 10),
      verificationScore: 75,
    ),
    AdoptiveFamily(
      familyId: "FAM205",
      familyName: "Joshi",
      region: "Wakad",
      incomeLevel: "High",
      homeVerified: true,
      backgroundCheck: "Approved",
      children: 1,
      adoptionStatus: "Eligible",
      contactPhone: "9876505678",
      email: "joshi.family@example.com",
      registrationDate: DateTime(2025, 11, 12),
      verificationScore: 90,
    ),
    AdoptiveFamily(
      familyId: "FAM206",
      familyName: "Mehta",
      region: "Viman Nagar",
      incomeLevel: "Medium",
      homeVerified: true,
      backgroundCheck: "Approved",
      children: 0,
      adoptionStatus: "Eligible",
      contactPhone: "9876506789",
      email: "mehta.home@example.com",
      registrationDate: DateTime(2025, 12, 8),
      verificationScore: 87,
    ),
  ];

  // Guidance Resources
  static final List<GuidanceResource> guidanceResources = [
    GuidanceResource(
      resourceId: "RES001",
      title: "Legal Requirements",
      description:
          "Understand the legal framework, age criteria, and mandatory documents needed for registration.",
      category: "Legal",
      icon: "gavel",
    ),
    GuidanceResource(
      resourceId: "RES002",
      title: "Home Study Preparation",
      description:
          "Complete guide to preparing your home for the official home study visit and assessment.",
      category: "Preparation",
      icon: "home_health",
    ),
    GuidanceResource(
      resourceId: "RES003",
      title: "Financial Planning",
      description:
          "Learn about adoption costs, government subsidies, and long-term financial planning for your child.",
      category: "Financial",
      icon: "account_balance_wallet",
    ),
    GuidanceResource(
      resourceId: "RES004",
      title: "Post-Adoption Support",
      description:
          "Resources for parenting, counseling, and community support after adoption is finalized.",
      category: "Support",
      icon: "favorite",
    ),
    GuidanceResource(
      resourceId: "RES005",
      title: "Child Development Guide",
      description:
          "Understanding developmental milestones and providing the best care for your adopted child.",
      category: "Parenting",
      icon: "child_care",
    ),
    GuidanceResource(
      resourceId: "RES006",
      title: "Document Checklist",
      description:
          "Complete checklist of all documents required during the adoption process.",
      category: "Documents",
      icon: "checklist",
    ),
  ];

  // Support Groups
  static final List<SupportGroup> supportGroups = [
    SupportGroup(
      groupId: "GRP001",
      name: "Pune Adoptive Parents Circle",
      description:
          "Monthly meetup for adoptive parents in Pune to share experiences and support each other.",
      memberCount: 45,
      nextMeetingDate: "March 15, 2026 at 4:00 PM",
      isActive: true,
    ),
    SupportGroup(
      groupId: "GRP002",
      name: "First-Time Adopters Support",
      description:
          "Guidance and mentorship for families going through their first adoption journey.",
      memberCount: 32,
      nextMeetingDate: "March 20, 2026 at 5:30 PM",
      isActive: true,
    ),
    SupportGroup(
      groupId: "GRP003",
      name: "Weekend Family Activities",
      description:
          "Organize fun activities and outings for adopted children and their families.",
      memberCount: 28,
      nextMeetingDate: "March 18, 2026 at 10:00 AM",
      isActive: true,
    ),
    SupportGroup(
      groupId: "GRP004",
      name: "Legal & Documentation Help",
      description:
          "Expert volunteers help with paperwork and legal processes in adoption.",
      memberCount: 15,
      nextMeetingDate: "March 22, 2026 at 3:00 PM",
      isActive: true,
    ),
  ];

  // FAQs
  static final List<FAQ> faqs = [
    FAQ(
      question: "What is the age requirement for adoptive parents?",
      answer:
          "Prospective adoptive parents must be at least 25 years old. The maximum age difference between the child and parent should not exceed 45 years.",
      category: "Eligibility",
    ),
    FAQ(
      question: "How long does the adoption process take?",
      answer:
          "The adoption process typically takes 6-12 months from registration to placement, depending on your preferences and available matches.",
      category: "Timeline",
    ),
    FAQ(
      question: "What documents are required for registration?",
      answer:
          "You need: ID proof, address proof, income proof, medical certificates, marriage certificate (if applicable), and police verification documents.",
      category: "Documents",
    ),
    FAQ(
      question: "Can single parents adopt a child?",
      answer:
          "Yes, single parents can adopt a child. However, a single male cannot adopt a girl child.",
      category: "Eligibility",
    ),
    FAQ(
      question: "What is the home study process?",
      answer:
          "A social worker will visit your home to assess the living environment, family dynamics, and readiness to adopt. This typically takes 2-3 visits.",
      category: "Process",
    ),
    FAQ(
      question: "Are there any adoption fees?",
      answer:
          "There are minimal government fees for documentation and processing. Private agencies may charge additional fees. Financial assistance is available for eligible families.",
      category: "Financial",
    ),
    FAQ(
      question: "Can I choose the age and gender of the child?",
      answer:
          "Yes, you can specify your preferences during registration. However, being flexible with preferences may reduce waiting time.",
      category: "Process",
    ),
    FAQ(
      question: "What support is available after adoption?",
      answer:
          "Post-adoption support includes counseling services, parenting workshops, support groups, and financial assistance programs.",
      category: "Support",
    ),
  ];

  // Sample Verification Documents
  static final List<VerificationDocument> sampleDocuments = [
    VerificationDocument(
      docId: "DOC001",
      docType: "Government ID",
      fileName: "aadhar_card.pdf",
      status: "Verified",
      uploadDate: DateTime(2026, 2, 1),
      remarks: "Approved by legal team",
    ),
    VerificationDocument(
      docId: "DOC002",
      docType: "Income Proof",
      fileName: "salary_slips_2025.pdf",
      status: "Verified",
      uploadDate: DateTime(2026, 2, 5),
      remarks: "Income verified - Eligible",
    ),
    VerificationDocument(
      docId: "DOC003",
      docType: "Medical Certificate",
      fileName: "health_report.pdf",
      status: "Pending Review",
      uploadDate: DateTime(2026, 2, 15),
    ),
    VerificationDocument(
      docId: "DOC004",
      docType: "Police Verification",
      fileName: "background_clearance.pdf",
      status: "In Progress",
      uploadDate: DateTime(2026, 2, 20),
      remarks: "Awaiting police department response",
    ),
  ];

  // Current logged-in parent (for demo)
  static AdoptiveFamily getCurrentParent() {
    return AdoptiveFamily(
      familyId: "FAM999",
      familyName: "Sarah & Michael",
      region: "Hadapsar",
      incomeLevel: "High",
      homeVerified: true,
      backgroundCheck: "Approved",
      children: 1,
      adoptionStatus: "In Process",
      contactPhone: "9876509999",
      email: "sarah.michael@example.com",
      registrationDate: DateTime(2026, 1, 15),
      verificationScore: 85,
    );
  }
}
