# Future Features & Implementation Plan

## Counselor Registration System ⏳

**Status:** Not yet implemented  
**Priority:** Medium  
**Estimated Effort:** 3-4 hours

### Overview
Complete end-to-end counselor registration, verification, and management system for agencies to onboard mental health professionals.

---

### 1. Counselor Registration Screen
**File:** `lib/screens/agency/counselor_registration_screen.dart`

#### Components:
- **Multi-step Registration Form**
  - Step 1: Basic Info (Full Name, Email, Phone, DOB)
  - Step 2: Professional Qualifications (Education, Certifications, Years of Experience)
  - Step 3: Specialization (Mother Support, Adoption Counseling, etc.)
  - Step 4: Availability (Days/Hours, Max Cases per Week)
  - Step 5: Document Uploads (Certifications, License, Background Check)

#### Fields to Collect:
```
Personal:
- fullName (required)
- email (required, unique)
- phoneNumber (required)
- dateOfBirth (required)

Professional:
- licensingBody (e.g., "AICTE", "State Board")
- licenseNumber (required)
- certifications (multiple)
- yearsOfExperience (required)
- specializations (multiple choice)
- bio (optional)

Availability:
- availableDays (Monday-Sunday)
- availableHours (time range)
- maxCasesPerWeek (integer)
- languages (multiple)

Documents:
- legalIdFile (PDF/Image)
- licenseFile (PDF/Image)
- certificationFiles (multiple)
- backgroundCheckFile (PDF/Image)
```

#### UI Features:
- Progress indicator showing current step
- Validation at each step before proceeding
- File upload with preview
- Estimated response time display
- Success modal with reference ID on submission

---

### 2. Firebase Backend Methods
**File:** `lib/core/services/firebase_service.dart`

#### Add Methods:

```dart
// Submit counselor registration application
Future<String> submitCounselorRegistration({
  required String agencyId,
  required Map<String, dynamic> counselorData,
  required Map<String, String> documentPaths,
}) async
  // Returns: applicationId

// Fetch pending counselor applications for agency
Stream<QuerySnapshot> watchPendingCounselors(String agencyId)

// Approve counselor application
Future<void> approveCounselorApplication({
  required String applicationId,
  required String counselorEmail,
}) async

// Reject counselor application
Future<void> rejectCounselorApplication({
  required String applicationId,
  required String rejectionReason,
}) async

// Update counselor availability
Future<void> updateCounselorAvailability({
  required String counselorId,
  required Map<String, dynamic> availabilityData,
}) async

// Get all active counselors for agency
Stream<QuerySnapshot> watchActiveCounselors(String agencyId)
```

#### Firestore Collections:

**`counselor_applications/{applicationId}`**
```
{
  agencyId: string,
  counselorEmail: string,
  fullName: string,
  phoneNumber: string,
  licenseNumber: string,
  certifications: array,
  yearsOfExperience: number,
  specializations: array,
  bio: string,
  availableDays: array,
  availableHours: { start: string, end: string },
  maxCasesPerWeek: number,
  languages: array,
  documentUrls: {
    legalId: string,
    license: string,
    certifications: array,
    backgroundCheck: string
  },
  status: "Pending" | "Approved" | "Rejected",
  applicationDate: timestamp,
  reviewedBy: string (admin uid),
  reviewDate: timestamp,
  rejectionReason: string (optional)
}
```

**`counselor_management/{counselorId}`** (after approval)
```
{
  agencyId: string,
  applicationId: string (reference),
  counselorEmail: string,
  fullName: string,
  phoneNumber: string,
  licenseNumber: string,
  specializations: array,
  bio: string,
  rating: number (0-5),
  totalCases: number,
  activeCases: number,
  maxCasesPerWeek: number,
  availableDays: array,
  availableHours: { start: string, end: string },
  languages: array,
  status: "Active" | "On Leave" | "Inactive",
  approvedDate: timestamp,
  lastUpdated: timestamp
}
```

---

### 3. Agency Counselor Approval Workflow
**File:** `lib/screens/agency/agency_counselor_management_screen.dart` (Enhancement)

#### New Tab: "Pending Applications"
- Display counselors awaiting approval
- Show application form details
- Quick action buttons:
  - **Approve** - Move to Active tab, send approval email
  - **Request More Info** - Open modal for message
  - **Reject** - Requires rejection reason

#### Approval Modal:
- Review all counselor details
- View uploaded documents (preview)
- Document verification checklist
- Approve/Reject with optional notes
- Automatic email notification to counselor

#### Updated Logic:
```dart
// Replace dummy data filtering with Firestore streams
// Current: DummyAgencyData.agencyCounsellors
// New: FirebaseService.instance.watchActiveCounselors(agencyId)

// Add "Pending" tab to show applications
// New stream: FirebaseService.instance.watchPendingCounselors(agencyId)
```

---

### 4. Counselor Email Notifications

**Trigger Points:**
- ✉️ Application submitted → "Application received, will be reviewed within 2-3 business days"
- ✉️ Application approved → "Welcome! You're now registered with [Agency Name]"
- ✉️ Application rejected → "Your application status: [Rejection reason]"
- ✉️ Status changed → "Your counselor profile status changed to [Status]"

---

### 5. Firestore Security Rules Enhancement

**Add to `firestore.rules`:**
```firestore
match /counselor_applications/{applicationId} {
  // Counselors can create their own applications
  allow create: if isAuthenticated() && request.resource.data.counselorEmail == request.auth.token.email;
  
  // Agencies can read applications for their organization
  allow read: if isAuthenticated() && 
    (getUserRole() == 'agency' || isAdmin());
  
  // Only admins can approve/reject
  allow update: if isAuthenticated() && isAdmin();
}

match /counselor_management/{counselorId} {
  // Counselors can read/update their own profile
  allow read, update: if isAuthenticated() && 
    resource.data.counselorEmail == request.auth.token.email;
  
  // Agencies can read counselors they manage
  allow read: if isAuthenticated() && 
    (getUserRole() == 'agency' || isAdmin());
  
  // Only admins can update status
  allow update: if isAuthenticated() && isAdmin();
}
```

---

### 6. Integration Points

**Step 1: Add to Route Navigation**
- File: `lib/core/constants/route_names.dart`
- Add: `static const String counselorRegistration = '/counselor-registration';`

**Step 2: Add to App Router**
- File: `lib/app.dart`
- Add GoRoute for counselor registration (public route, can access after agency auth)

**Step 3: Add Counselor Registration Button**
- File: `lib/screens/agency/agency_auth_screen.dart` or agency dashboard
- Button: "Register as Counselor" → routes to counselor registration

**Step 4: Wire Agency Management Screen**
- Replace dummy data with Firestore streams
- Update Pending tab logic

---

### 7. Testing Checklist

- [ ] Counselor can fill all 5 steps of registration form
- [ ] Form validation works (email format, license number, etc.)
- [ ] File uploads succeed (<=5MB, supported formats)
- [ ] Application saved to `counselor_applications` collection
- [ ] Agency sees pending applications in management screen
- [ ] Agency can approve applications
- [ ] Approved counselor moved to `counselor_management` collection
- [ ] Counselor receives approval email notification
- [ ] Rejected application triggers rejection email
- [ ] Firestore rules prevent unauthorized access
- [ ] Counselor can view/update their own profile

---

## Implementation Order
1. Create Firestore collections structure
2. Build backend methods in FirebaseService
3. Create Counselor Registration Screen (5-step form)
4. Wire Agency Management Screen to Firestore
5. Add email notifications
6. Add route integration
7. Test end-to-end workflow

---

## Related Code References
- FirebaseService: `lib/core/services/firebase_service.dart`
- Agency Dashboard: `lib/screens/agency/agency_counselor_management_screen.dart`
- Auth Flow: `lib/providers/auth_provider.dart`
- Route Constants: `lib/core/constants/route_names.dart`

---

**Last Updated:** March 11, 2026  
**Status:** Pending Implementation
