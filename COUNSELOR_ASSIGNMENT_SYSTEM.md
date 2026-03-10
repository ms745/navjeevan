# Counselor Assignment System - Implementation Guide

**Status:** Backend Ready | UI Pending
**Date:** March 11, 2026
**Priority:** High

---

## Completed ✅

### 1. Firebase Backend Methods
**File:** `lib/core/services/firebase_service.dart`

Added complete API for counselor management:
- `assignCounselorToRequest()` - Create new assignments
- `getAssignedCounselor()` - Get counselor for a request
- `watchUserAssignments()` - Stream user's assignments
- `watchCounselorAssignments()` - Stream counselor's assignments
- `updateCounselorStatus()` - Change status (available, full, on_leave)
- `getCounselorStatus()` - Get current status
- `watchCounselorStatuses()` - Stream all counselor statuses
- `getAvailableCounselors()` - Query available counselors
- `getCounselorActiveAssignmentCount()` - Count active cases
- `unassignCounselor()` - Remove assignment

### 2. Firestore Collections Defined
```
counselor_assignments/{assignmentId}
├── assignmentId: string
├── counselorName: string
├── counselorEmail: string
├── requestId: string
├── userId: string
├── requestType: 'mother' | 'parent'
├── status: 'Active' | 'Inactive'
├── assignedAt: timestamp
└── updatedAt: timestamp

counselor_status/{counselorEmail}
├── counselorEmail: string
├── status: 'available' | 'full' | 'on_leave'
└── updatedAt: timestamp
```

### 3. Firestore Security Rules
**File:** `firestore.rules`

Added comprehensive rules for:
- Counselor assignments (role-based read/write)
- Counselor status (public read, agency/admin write)
- User can see their own assignments
- Counselors can see their own assignments
- Agencies manage their counselors
- Admins have full access

### 4. Enhanced Counselor Data Model
**File:** `lib/core/constants/dummy_agency_data.dart`

Expanded `Counsellor` class with fields:
- `email` - Professional email
- `phone` - Contact number
- `qualification` - Educational degree
- `rating` - Client rating (4.6-4.9)
- `yearsExperience` - Years of practice
- `certifications` - Array of specializations
- `bio` - Professional biography
- `languages` - Languages spoken

**Dummy Data:** 13 counselors with complete profiles

---

## Remaining Work 📋

### Phase 1: Agency Counselor Management UI Enhancements

**File:** `lib/screens/agency/agency_counselor_management_screen.dart`

**Changes Needed:**

1. **Quick Status Update Menu**
   - Pop-up menu on each counselor card
   - Options: Mark Available, Mark Full, Mark On Leave
   - Calls: `FirebaseService.updateCounselorStatus()`
   - Shows notification on completion

2. **Expanded Counselor Card**
   - Show rating, experience, qualifications
   - Display contact info (phone, email)
   - Certifications as small badges
   - Status indicator with color coding

3. **Counselor Details Modal**
   - Bottom sheet showing full profile
   - All certifications listed
   - Languages spoken
   - Professional bio
   - Contact information

4. **Assignment Quick Action**
   - Button to assign from pending requests queue
   - Shows available counselors filtered by specialty
   - One-click assignment UI

**Code Pattern:**
```dart
// Status update
FirebaseService.instance.updateCounselorStatus(
  counselorEmail: counselor.email ?? 'unknown@email.com',
  status: 'available', // or 'full', 'on_leave'
);

// Show available counselors
final available = await FirebaseService.instance.getAvailableCounselors();

// Check caseload
final count = await FirebaseService.instance
    .getCounselorActiveAssignmentCount(counselor.email!);
```

---

### Phase 2: Mother Counseling Support UI

**File:** `lib/screens/mother/counseling_screen.dart` (or similar)

**Changes Needed:**

1. **Show Assigned Counselor**
   ```dart
   StreamBuilder<QuerySnapshot>(
     stream: FirebaseService.instance.watchUserAssignments(userId),
     builder: (context, snapshot) {
       if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
         final assignment = snapshot.data!.docs.first.data() as Map;
         // Display: Assigned Counselor Card
         //   Name, Specialty, Contact Info, Rating
       }
     },
   )
   ```

2. **Book Session Button**
   - Show if counselor assigned and available
   - Routes to counseling_booking_screen with counselor data

3. **View Schedule**
   - Show counselor's available days/times
   - Filter based on `counselor.availabilityDays`
   - From dummy data or future Firebase schedule collection

4. **Contact Counselor**
   - Quick call button → `Uri(scheme: 'tel', path: counselor.phone)`
   - WhatsApp/Message link
   - Email option

---

### Phase 3: Parent Support & Guidance UI

**File:** `lib/screens/parent/parent_support_screen.dart` (or similar)

**Changes Needed:**

1. **Available Counselors List**
   ```dart
   StreamBuilder<QuerySnapshot>(
     stream: FirebaseService.instance.watchCounselorStatuses(),
     builder: (context, snapshot) {
       final counselors = snapshot.data?.docs
           .where((d) => d['status'] == 'available')
           .toList() ?? [];
       // Display: Filtered counselor cards
     },
   )
   ```

2. **Assignment Panel**
   - Show currently assigned coun selor if any
   - Or "No advisor assigned" with request button
   - Request assignment → triggers agency notification

3. **Filter by Specialty**
   - Chips: Adoption, Family Support, Financial, etc.
   - Filter counselors based on specialty match
   - Show expected wait time

4. **Rating & Reviews**
   - Display counselor rating
   - Show experience level
   - Certifications relevant to adoption

---

### Phase 4: Agency Requests Dashboard Assignment UI

**File:** `lib/screens/agency/agency_requests_dashboard_screen.dart`

**Changes Needed:**

1. **Assignment Status Column**
   - Shows "Not Assigned" or counselor name
   - Color-coded by status
   - Quick assignment button

2. **Quick Assign Modal**
   ```dart
   showModalBottomSheet(
     builder: (context) {
       // Show available counselors by specialty
       // Priority: Less busy counselors first
       // One-tap assignment
     }
   )
   ```

3. **After Assignment**
   ```dart
   FirebaseService.instance.assignCounselorToRequest(
     counselorName: 'Dr. Sarah Jenkins',
     counselorEmail: 'sarah.jenkins@navjeevan.com',
     requestId: request.id,
     userId: request['userId'],
     requestType: 'mother',
   );
   // Show confirmation
   // Update Firestore counselor status if full
   ```

4. **Sort Options**
   - By urgency (high risk first)
   - By unassigned count
   - By counselor workload

---

## Firestore Data Flow Diagram

```
Mother/Parent submits request
         ↓
Creates: mother_requests/{id} or adoptive_families/{id}
         ↓
Agency reviews in dashboard
         ↓
Agency selects available counselor
         ↓
Creates: counselor_assignments/{id}
    ├── requestId
    ├── counselorEmail
    └── userId
         ↓
Mother/Parent sees assigned counselor
    (via watchUserAssignments stream)
         ↓
Can book session with counselor
```

---

## Firestore Query Examples

```dart
// Get all assignments for a user (Mother)
FirebaseService.instance.watchUserAssignments(userId)

// Get all assignments for a counselor
FirebaseService.instance.watchCounselorAssignments('sarah.jenkins@navjeevan.com')

// Get counselor for a specific request
final assignment = await FirebaseService.instance.getAssignedCounselor(requestId);

// Get available counselors
final available = await FirebaseService.instance.getAvailableCounselors();

// Update status
FirebaseService.instance.updateCounselorStatus(
  counselorEmail: 'sarah.jenkins@navjeevan.com',
  status: 'full', // or 'available', 'on_leave'
);

// Count active cases for workload tracking
final count = await FirebaseService.instance
    .getCounselorActiveAssignmentCount(counselorEmail);
```

---

## Testing Checklist

- [ ] Create counselor_assignments collection in Firestore
- [ ] Test assignCounselorToRequest() - creates assignment doc
- [ ] Test updateCounselorStatus() - updates counselor_status collection
- [ ] Test watchUserAssignments() - streams assignments for mother/parent
- [ ] Test watchCounselorAssignments() - streams assignments for counselor
- [ ] Verify Firestore rules allow proper access
- [ ] UI shows assigned counselor on mother screen
- [ ] UI shows assigned counselor on parent screen
- [ ] Agency can update counselor status
- [ ] Agency can assign from requests dashboard
- [ ] Notifications trigger on assignment
- [ ] Unassign removes from counselor_assignments

---

## Implementation Priority

**Week 1:** Agency Counselor Management Status UI
**Week 2:** Mother/Parent Counselor View & Booking
**Week 3:** Agency Dashboard Assignment Integration
**Week 4:** Testing & Refinement

---

## Related Files

- Backend: `lib/core/services/firebase_service.dart`
- Security: `firestore.rules`
- Data: `lib/core/constants/dummy_agency_data.dart`
- Screens:
  - `lib/screens/agency/agency_counselor_management_screen.dart`
  - `lib/screens/mother/counseling_screen.dart`
  - `lib/screens/parent/parent_support_screen.dart`
  - `lib/screens/agency/agency_requests_dashboard_screen.dart`

---

**Last Updated:** March 11, 2026
