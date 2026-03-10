class AdoptiveFamily {
  final String familyId;
  final String familyName;
  final String region;
  final String incomeLevel;
  final bool homeVerified;
  final String backgroundCheck;
  final int children;
  final String adoptionStatus;
  final String? contactPhone;
  final String? email;
  final DateTime? registrationDate;
  final int? verificationScore;

  AdoptiveFamily({
    required this.familyId,
    required this.familyName,
    required this.region,
    required this.incomeLevel,
    required this.homeVerified,
    required this.backgroundCheck,
    required this.children,
    required this.adoptionStatus,
    this.contactPhone,
    this.email,
    this.registrationDate,
    this.verificationScore,
  });

  factory AdoptiveFamily.fromJson(Map<String, dynamic> json) {
    return AdoptiveFamily(
      familyId: json['family_id'] as String,
      familyName: json['family_name'] as String,
      region: json['region'] as String,
      incomeLevel: json['income_level'] as String,
      homeVerified: json['home_verified'] as bool,
      backgroundCheck: json['background_check'] as String,
      children: json['children'] as int,
      adoptionStatus: json['adoption_status'] as String,
      contactPhone: json['contact_phone'] as String?,
      email: json['email'] as String?,
      registrationDate: json['registration_date'] != null
          ? DateTime.parse(json['registration_date'] as String)
          : null,
      verificationScore: json['verification_score'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'family_id': familyId,
      'family_name': familyName,
      'region': region,
      'income_level': incomeLevel,
      'home_verified': homeVerified,
      'background_check': backgroundCheck,
      'children': children,
      'adoption_status': adoptionStatus,
      'contact_phone': contactPhone,
      'email': email,
      'registration_date': registrationDate?.toIso8601String(),
      'verification_score': verificationScore,
    };
  }
}

class VerificationDocument {
  final String docId;
  final String docType;
  final String fileName;
  final String status;
  final DateTime uploadDate;
  final String? remarks;

  VerificationDocument({
    required this.docId,
    required this.docType,
    required this.fileName,
    required this.status,
    required this.uploadDate,
    this.remarks,
  });
}

class GuidanceResource {
  final String resourceId;
  final String title;
  final String description;
  final String category;
  final String icon;
  final String? contentUrl;

  GuidanceResource({
    required this.resourceId,
    required this.title,
    required this.description,
    required this.category,
    required this.icon,
    this.contentUrl,
  });
}

class SupportGroup {
  final String groupId;
  final String name;
  final String description;
  final int memberCount;
  final String nextMeetingDate;
  final bool isActive;

  SupportGroup({
    required this.groupId,
    required this.name,
    required this.description,
    required this.memberCount,
    required this.nextMeetingDate,
    required this.isActive,
  });
}

class FAQ {
  final String question;
  final String answer;
  final String category;

  FAQ({required this.question, required this.answer, required this.category});
}
