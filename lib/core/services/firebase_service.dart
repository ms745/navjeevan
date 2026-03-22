import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:navjeevan/core/cloudinary_config.dart';
import 'package:navjeevan/core/constants/dummy_agency_data.dart';

class FirebaseService {
  static final FirebaseService instance = FirebaseService._();
  FirebaseService._();

  // Cloudinary credentials are centralised in CloudinaryConfig.
  static const String _cloudinaryCloudName = CloudinaryConfig.cloudName;
  static const String _cloudinaryUploadPreset = CloudinaryConfig.uploadPreset;

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // --- Auth & User Profile ---

  User? get currentUser => _auth.currentUser;

  Future<void> createUserProfile({
    required String uid,
    required String role,
    required Map<String, dynamic> data,
  }) async {
    await _db.collection('users').doc(uid).set({
      'role': role,
      'uid': uid,
      'createdAt': FieldValue.serverTimestamp(),
      ...data,
    });
  }

  // --- Mother Pillar: Help Requests ---

  Future<String> submitMotherRequest({
    required List<String> reasons,
    required bool needsCounseling,
    required bool isAnonymous,
    required String region,
    String? additionalDetails,
    double? urgencyLevel,
    String? preferredContact,
    Map<String, dynamic>? childProfile,
    Uint8List? childPhotoBytes,
    String? childPhotoFileName,
    Map<String, Uint8List>? childDocumentBytes,
    Map<String, String>? childDocumentFileNames,
  }) async {
    final uid = currentUser?.uid;
    if (uid == null) {
      throw StateError('User must be authenticated to submit a request.');
    }

    final existingActive = await _db
        .collection('mother_requests')
        .where('userId', isEqualTo: uid)
        .where('status', isEqualTo: 'Active')
        .limit(1)
        .get();

    if (existingActive.docs.isNotEmpty) {
      final activeRequestId =
          (existingActive.docs.first.data()['requestId'] ??
                  existingActive.docs.first.id)
              .toString();
      throw StateError(
        'You already have an active surrender request ($activeRequestId). Cancel it first before submitting a new request.',
      );
    }

    // Basic Risk Calculation (Logic can be expanded)
    String riskLevel = 'Low';
    final childHealthFlags =
      '${(childProfile?['medicalNotes'] ?? '').toString()} ${(childProfile?['specialFeatures'] ?? '').toString()}'
        .toLowerCase();
    final hasCriticalChildNotes =
        childHealthFlags.contains('critical') ||
        childHealthFlags.contains('urgent') ||
        childHealthFlags.contains('special');

    if ((urgencyLevel ?? 1) >= 4 ||
        reasons.length > 2 ||
        region == 'Hadapsar' ||
        hasCriticalChildNotes) {
      riskLevel = 'High';
    } else if (reasons.isNotEmpty || (urgencyLevel ?? 1) >= 3) {
      riskLevel = 'Medium';
    }

    final requestRef = _db.collection('mother_requests').doc();
    final childPhoto = childPhotoBytes != null
        ? await _uploadMotherRequestChildPhoto(
            userId: uid,
            requestId: requestRef.id,
            data: childPhotoBytes,
            fileName: childPhotoFileName ?? 'child_photo.jpg',
          )
        : null;
    final childDocuments = <String, dynamic>{};

    for (final entry in (childDocumentBytes ?? <String, Uint8List>{}).entries) {
      final fileName = childDocumentFileNames?[entry.key] ?? '${_normalizeDocumentKey(entry.key)}.bin';
      childDocuments[_normalizeDocumentKey(entry.key)] =
          await _uploadMotherRequestDocumentRecord(
            userId: uid,
            requestId: requestRef.id,
            docType: entry.key,
            data: entry.value,
            fileName: fileName,
          );
    }

    final normalizedChildDocuments = _canonicalizeChildDocuments(childDocuments);

    final childReviewFields = _buildMotherChildDocumentsReviewFields(
      normalizedChildDocuments,
    );

    await requestRef.set({
      'requestId': requestRef.id,
      'userId': uid,
      'requestType': 'child_surrender',
      'reasons': reasons,
      'needsCounseling': needsCounseling,
      'isAnonymous': isAnonymous,
      'region': region,
      'additionalDetails': additionalDetails?.trim(),
      'urgencyLevel': urgencyLevel,
      'preferredContact': preferredContact,
      'childProfile': childProfile,
      'childPhoto': childPhoto,
      'childDocuments': normalizedChildDocuments,
      ...childReviewFields,
      'riskLevel': riskLevel,
      'status': 'Active',
      'latestAction': 'Request submitted',
      'latestActorRole': 'mother',
      'latestActorId': uid,
      'resolved': false,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await _appendRequestEvent(
      requestId: requestRef.id,
      eventType: 'created',
      status: 'Active',
      actorRole: 'mother',
      actorId: uid,
      notes: 'Child surrender request submitted',
    );

    return requestRef.id;
  }

  Future<void> reuploadMotherRequestDocument({
    required String requestId,
    required String docType,
    required Uint8List data,
    required String fileName,
  }) async {
    final uid = currentUser?.uid;
    if (uid == null) {
      throw StateError('User must be authenticated to update request documents.');
    }

    final requestRef = _db.collection('mother_requests').doc(requestId);
    final snapshot = await requestRef.get();
    if (!snapshot.exists) {
      throw StateError('Mother request not found.');
    }

    final requestData = snapshot.data() as Map<String, dynamic>;
    final status = (requestData['status'] ?? 'Active').toString().toLowerCase();
    if (status.contains('accepted') || status.contains('declined') || status.contains('cancelled')) {
      throw StateError('Documents can only be updated while the request is active or in process.');
    }

    final documents = _canonicalizeChildDocuments(Map<String, dynamic>.from(
      requestData['childDocuments'] as Map<String, dynamic>? ?? <String, dynamic>{},
    ));
    final normalizedDocKey = _normalizeDocumentKey(docType);
    final previousDocument = Map<String, dynamic>.from(
      documents[normalizedDocKey] as Map<String, dynamic>? ?? <String, dynamic>{},
    );

    documents[normalizedDocKey] = await _uploadMotherRequestDocumentRecord(
      userId: uid,
      requestId: requestId,
      docType: docType,
      data: data,
      fileName: fileName,
    );

    final oldPublicId = (previousDocument['storagePath'] ?? '').toString();
    final newPublicId = (documents[normalizedDocKey] as Map<String, dynamic>)['storagePath']
            ?.toString() ??
        '';
    if (oldPublicId.isNotEmpty && oldPublicId != newPublicId) {
      await _markCloudinaryAssetSuperseded(
        publicId: oldPublicId,
        replacedByPublicId: newPublicId,
        reason: '$docType re-uploaded by mother',
        actorRole: 'mother',
        actorId: uid,
      );
    }

    final normalizedDocuments = _canonicalizeChildDocuments(documents);
    final childReviewFields = _buildMotherChildDocumentsReviewFields(normalizedDocuments);

    await requestRef.set({
      'childDocuments': normalizedDocuments,
      ...childReviewFields,
      'updatedAt': FieldValue.serverTimestamp(),
      'latestAction': '$docType document re-uploaded',
      'latestActorRole': 'mother',
      'latestActorId': uid,
    }, SetOptions(merge: true));

    await _appendRequestEvent(
      requestId: requestId,
      eventType: 'document_reupload',
      status: (requestData['status'] ?? 'Active').toString(),
      actorRole: 'mother',
      actorId: uid,
      notes: '$docType document re-uploaded by mother',
    );
  }

  Future<void> updateMotherRequestDocumentVerification({
    required String requestId,
    required String docKey,
    required String status,
    String? notes,
  }) async {
    final requestRef = _db.collection('mother_requests').doc(requestId);
    final snapshot = await requestRef.get();
    if (!snapshot.exists) {
      throw StateError('Mother request not found.');
    }

    final requestData = snapshot.data() as Map<String, dynamic>;
    final documents = _canonicalizeChildDocuments(Map<String, dynamic>.from(
      requestData['childDocuments'] as Map<String, dynamic>? ??
          <String, dynamic>{},
    ));
    final normalizedKey = _normalizeDocumentKey(docKey);
    final existingDocument = Map<String, dynamic>.from(
      documents[normalizedKey] as Map<String, dynamic>? ?? <String, dynamic>{},
    );
    if (existingDocument.isEmpty) {
      throw StateError('Child document not found for verification.');
    }

    final nextNotes = notes?.trim() ?? '';
    final currentStatus = (existingDocument['verificationStatus'] ?? 'Pending')
        .toString();
    final currentNotes = (existingDocument['verificationNotes'] ?? '').toString();
    if (currentStatus == status && currentNotes == nextNotes) {
      return;
    }

    existingDocument['verificationStatus'] = status;
    existingDocument['verificationNotes'] = nextNotes;
    existingDocument['verifiedBy'] = currentUser?.uid;
    existingDocument['verifiedAt'] = FieldValue.serverTimestamp();
    documents[normalizedKey] = existingDocument;

    final publicId = (existingDocument['storagePath'] ?? '').toString();
    if (publicId.isNotEmpty) {
      await _syncCloudinaryVerificationStatus(
        publicId: publicId,
        verificationStatus: status,
        verificationNotes: notes,
        actorRole: 'admin',
        actorId: currentUser?.uid,
      );
    }

    final normalizedDocuments = _canonicalizeChildDocuments(documents);
    final childReviewFields = _buildMotherChildDocumentsReviewFields(normalizedDocuments);

    await requestRef.set({
      'childDocuments': normalizedDocuments,
      ...childReviewFields,
      'updatedAt': FieldValue.serverTimestamp(),
      'latestAction': 'Child document ${status.toLowerCase()} by admin',
      'latestActorRole': 'admin',
      'latestActorId': currentUser?.uid,
    }, SetOptions(merge: true));

    await _appendRequestEvent(
      requestId: requestId,
      eventType: 'document_verification',
      status: (requestData['status'] ?? 'Active').toString(),
      actorRole: 'admin',
      actorId: currentUser?.uid,
      notes:
          '${existingDocument['type'] ?? docKey} marked as $status${notes?.trim().isNotEmpty == true ? ' • ${notes!.trim()}' : ''}',
    );
  }

  Future<void> updateMotherRequestStatus({
    required String requestId,
    required String status,
    required String actorRole,
    String? actorId,
    String? notes,
  }) async {
    await _db.collection('mother_requests').doc(requestId).set({
      'status': status,
      'latestAction': notes ?? 'Status updated to $status',
      'latestActorRole': actorRole,
      'latestActorId': actorId,
      'resolved':
          status == 'Accepted' || status == 'Declined' || status == 'Cancelled',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await _appendRequestEvent(
      requestId: requestId,
      eventType: 'status_update',
      status: status,
      actorRole: actorRole,
      actorId: actorId,
      notes: notes,
    );
  }

  Future<void> _appendRequestEvent({
    required String requestId,
    required String eventType,
    required String status,
    required String actorRole,
    String? actorId,
    String? notes,
  }) async {
    await _db
        .collection('mother_requests')
        .doc(requestId)
        .collection('events')
        .add({
          'eventType': eventType,
          'status': status,
          'actorRole': actorRole,
          'actorId': actorId,
          'notes': notes,
          'createdAt': FieldValue.serverTimestamp(),
        });
  }

  Stream<QuerySnapshot> watchMotherRequestsForUser(String userId) {
    return _db
        .collection('mother_requests')
        .where('userId', isEqualTo: userId)
        .snapshots();
  }

  Stream<QuerySnapshot> watchCurrentUserMotherRequests() {
    final uid = currentUser?.uid ?? '__none__';
    return _db
        .collection('mother_requests')
        .where('userId', isEqualTo: uid)
        .snapshots();
  }

  Stream<QuerySnapshot> watchRequestEvents(String requestId) {
    return _db
        .collection('mother_requests')
        .doc(requestId)
        .collection('events')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<String> createCounselingBooking({
    required String counselorId,
    required String counselorName,
    required String sessionMode,
    required DateTime sessionDate,
    required String slot,
    String? notes,
    String? source,
    String requestType = 'mother',
    String? serviceType,
    String? supportRequestId,
    String? assignmentId,
    String? ngoId,
    String? ngoName,
  }) async {
    final uid = currentUser?.uid;
    if (uid == null) {
      throw StateError('User must be authenticated to book counseling.');
    }

    final bookingRef = _db.collection('counseling_bookings').doc();
    await bookingRef.set({
      'bookingId': bookingRef.id,
      'userId': uid,
      'counselorId': counselorId,
      'counselorName': counselorName,
      'sessionMode': sessionMode,
      'sessionDate': Timestamp.fromDate(sessionDate),
      'slot': slot,
      'notes': notes?.trim(),
      'status': 'Requested',
      'source': source ?? 'mother_counseling_booking',
      'requestType': requestType,
      'serviceType': serviceType,
      'supportRequestId': supportRequestId,
      'assignmentId': assignmentId,
      'ngoId': ngoId,
      'ngoName': ngoName,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await _db
        .collection('counseling_bookings')
        .doc(bookingRef.id)
        .collection('events')
        .add({
          'eventType': 'created',
          'status': 'Requested',
          'actorRole': requestType == 'parent' ? 'parent' : 'mother',
          'actorId': uid,
          'notes': 'Counseling booking requested',
          'createdAt': FieldValue.serverTimestamp(),
        });

    return bookingRef.id;
  }

  Future<String> createParentSupportCounselingBooking({
    required String serviceType,
    required String counselorId,
    required String counselorName,
    String? counselorEmail,
    required String sessionMode,
    required DateTime sessionDate,
    required String slot,
    String? notes,
  }) async {
    final uid = currentUser?.uid;
    if (uid == null) {
      throw StateError('User must be authenticated to book support counseling.');
    }

    final supportRequestsSnapshot = await _db
        .collection('parent_support_requests')
        .where('userId', isEqualTo: uid)
        .where('serviceType', isEqualTo: serviceType)
        .get();

    final supportRequests = supportRequestsSnapshot.docs
        .map((doc) => Map<String, dynamic>.from(doc.data()))
        .toList()
      ..sort((a, b) {
        final aTs = a['createdAt'];
        final bTs = b['createdAt'];
        if (aTs is! Timestamp && bTs is! Timestamp) return 0;
        if (aTs is! Timestamp) return 1;
        if (bTs is! Timestamp) return -1;
        return bTs.compareTo(aTs);
      });

    Map<String, dynamic>? activeRequest;
    for (final request in supportRequests) {
      final status = (request['status'] ?? '').toString().toLowerCase();
      if (status != 'completed' && status != 'closed' && status != 'cancelled') {
        activeRequest = request;
        break;
      }
    }

    if (activeRequest == null) {
      final requestId = await createParentSupportRequest(
        serviceType: serviceType,
        notes: notes ?? 'Booking initiated for $serviceType.',
      );
      final createdRequest = await _db
          .collection('parent_support_requests')
          .doc(requestId)
          .get();
      activeRequest = createdRequest.data() ?? <String, dynamic>{'requestId': requestId};
    }

    final supportRequestId = (activeRequest['requestId'] ?? '').toString();
    if (supportRequestId.isEmpty) {
      throw StateError('Support request could not be resolved for this booking.');
    }

    final ngoId = (activeRequest['ngoId'] ?? '').toString();
    final ngoName = (activeRequest['ngoName'] ?? '').toString();
    final scheduleLabel =
        '$sessionMode • ${sessionDate.day}/${sessionDate.month}/${sessionDate.year} • $slot';

    final assignmentSnapshot = await _db
        .collection('counselor_assignments')
        .where('userId', isEqualTo: uid)
        .where('requestType', isEqualTo: 'parent')
        .where('supportRequestId', isEqualTo: supportRequestId)
        .get();

    String? assignmentId;
    for (final doc in assignmentSnapshot.docs) {
      final data = doc.data();
      final sameEmail = counselorEmail?.trim().isNotEmpty == true &&
          (data['counselorEmail'] ?? '').toString() == counselorEmail!.trim();
      final sameName = (data['counselorName'] ?? '').toString() == counselorName;
      if (sameEmail || sameName) {
        assignmentId = doc.id;
        break;
      }
    }

    if (assignmentId == null) {
      assignmentId = await assignCounselorToRequest(
        counselorName: counselorName,
        counselorEmail: counselorEmail ?? '',
        requestId: supportRequestId,
        userId: uid,
        requestType: 'parent',
        supportRequestId: supportRequestId,
        ngoId: ngoId,
        ngoName: ngoName,
        assignmentStatus: 'Scheduled',
        slot: scheduleLabel,
      );
    }

    final bookingId = await createCounselingBooking(
      counselorId: counselorId,
      counselorName: counselorName,
      sessionMode: sessionMode,
      sessionDate: sessionDate,
      slot: slot,
      notes: notes,
      source: 'parent_support_${serviceType.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_')}',
      requestType: 'parent',
      serviceType: serviceType,
      supportRequestId: supportRequestId,
      assignmentId: assignmentId,
      ngoId: ngoId,
      ngoName: ngoName,
    );

    await _db.collection('counselor_assignments').doc(assignmentId).set({
      'bookingId': bookingId,
      'bookingMode': sessionMode,
      'bookingDate': Timestamp.fromDate(sessionDate),
      'slot': scheduleLabel,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await updateCounselorAssignmentLifecycle(
      assignmentId: assignmentId,
      status: 'Scheduled',
      slot: scheduleLabel,
      actorRole: 'parent',
      actorId: uid,
      notes: notes?.trim().isNotEmpty == true
          ? notes!.trim()
          : 'Parent booked $serviceType session with $counselorName.',
    );

    await _db.collection('parent_support_requests').doc(supportRequestId).set({
      'bookingId': bookingId,
      'selectedCounselorId': counselorId,
      'selectedCounselorName': counselorName,
      'selectedCounselorEmail': counselorEmail,
      'selectedSessionMode': sessionMode,
      'selectedSessionDate': Timestamp.fromDate(sessionDate),
      'selectedSlot': slot,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await _db.collection('counseling_bookings').doc(bookingId).set({
      'status': 'Scheduled',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await _db
        .collection('counseling_bookings')
        .doc(bookingId)
        .collection('events')
        .add({
          'eventType': 'linked_to_support_request',
          'status': 'Scheduled',
          'actorRole': 'parent',
          'actorId': uid,
          'notes': 'Linked booking with support request $supportRequestId and assignment $assignmentId.',
          'createdAt': FieldValue.serverTimestamp(),
        });

    return bookingId;
  }

  Future<void> updateCounselingBookingStatus({
    required String bookingId,
    required String status,
    required String actorRole,
    String? actorId,
    String? notes,
  }) async {
    await _db.collection('counseling_bookings').doc(bookingId).set({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await _db
        .collection('counseling_bookings')
        .doc(bookingId)
        .collection('events')
        .add({
          'eventType': 'status_update',
          'status': status,
          'actorRole': actorRole,
          'actorId': actorId,
          'notes': notes,
          'createdAt': FieldValue.serverTimestamp(),
        });
  }

  Stream<QuerySnapshot> watchCurrentUserCounselingBookings() {
    final uid = currentUser?.uid ?? '__none__';
    return _db
        .collection('counseling_bookings')
        .where('userId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot> watchAllCounselingBookings() {
    return _db
        .collection('counseling_bookings')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot> watchAllCounselingRequests() {
    return _db
        .collection('counseling_requests')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> submitCounselingSupportRequest({
    required String requestKind,
    String? notes,
  }) async {
    final uid = currentUser?.uid;
    await _db.collection('counseling_requests').add({
      'requestId': 'csr_${DateTime.now().millisecondsSinceEpoch}',
      'userId': uid,
      'requestKind': requestKind,
      'status': 'Requested',
      'notes': notes,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> logEmergencyCall({
    required String helpline,
    required String source,
    String outcome = 'Requested',
  }) async {
    final uid = currentUser?.uid;
    await _db.collection('emergency_calls').add({
      'userId': uid,
      'helpline': helpline,
      'source': source,
      'outcome': outcome,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> logNgoContactCall({
    required String ngoId,
    required String ngoName,
    required String contact,
    required String source,
    String status = 'Dial requested',
  }) async {
    final uid = currentUser?.uid;
    await _db.collection('ngo_contact_calls').add({
      'userId': uid,
      'ngoId': ngoId,
      'ngoName': ngoName,
      'contact': contact,
      'source': source,
      'status': status,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> logCounselorCall({
    required String contact,
    required String source,
    bool isEmergency = false,
    String status = 'Dial requested',
  }) async {
    final uid = currentUser?.uid;
    await _db.collection('counselor_calls').add({
      'userId': uid,
      'contact': contact,
      'source': source,
      'isEmergency': isEmergency,
      'status': status,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot> watchCurrentUserEmergencyCalls() {
    final uid = currentUser?.uid ?? '__none__';
    return _db
        .collection('emergency_calls')
        .where('userId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // --- Parent Pillar: Adoption Applications ---

  Stream<DocumentSnapshot<Map<String, dynamic>>>
  watchCurrentParentApplication() {
    final uid = currentUser?.uid ?? '__none__';
    return _db.collection('adoptive_families').doc(uid).snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchParentApplicationEvents(
    String familyId,
  ) {
    return _db
        .collection('adoptive_families')
        .doc(familyId)
        .collection('events')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<bool> canStartNewParentAdoptionRequest() async {
    final uid = currentUser?.uid;
    if (uid == null) {
      throw StateError('User must be authenticated to create an adoption request.');
    }

    final snapshot = await _db.collection('adoptive_families').doc(uid).get();
    if (!snapshot.exists) {
      return true;
    }

    final status = (snapshot.data()?['adoptionStatus'] ?? '').toString();
    return _isParentAdoptionProcessCompleted(status);
  }

  Future<void> submitAdoptionApplication({
    required String familyName,
    required String region,
    required double annualIncome,
    required Map<String, String> documentPaths,
    Map<String, Uint8List>? documentBytes,
    Map<String, String>? documentFileNames,
    String? email,
    String? phone,
    String? maritalStatus,
    String? spouseName,
    int? existingChildrenCount,
    String? address,
    int requestedChildrenCount = 1,
    String? preferredChildAge,
    String? genderPreference,
    String? specialNeedsAcceptance,
    String? additionalNotes,
    double? homeLatitude,
    double? homeLongitude,
  }) async {
    final uid = currentUser?.uid;
    if (uid == null) {
      throw StateError('User must be authenticated to submit an application.');
    }

    final familyRef = _db.collection('adoptive_families').doc(uid);
    final existingSnapshot = await familyRef.get();
    if (existingSnapshot.exists) {
      final existingStatus =
          (existingSnapshot.data()?['adoptionStatus'] ?? '').toString();
      final canCreateNewRequest = _isParentAdoptionProcessCompleted(
        existingStatus,
      );
      if (!canCreateNewRequest) {
        throw StateError(
          'You already have an adoption request in progress. New request is available only after the current process is completed.',
        );
      }
    }

    final existingDocuments = Map<String, dynamic>.from(
      existingSnapshot.data()?['documents'] as Map<String, dynamic>? ??
          <String, dynamic>{},
    );

    final uploadedDocuments = Map<String, dynamic>.from(existingDocuments);

    for (final entry in documentPaths.entries) {
      final normalizedKey = _normalizeDocumentKey(entry.key);
      final bytes = documentBytes?[entry.key];
      final fileName = documentFileNames?[entry.key];
      final filePath = entry.value.trim();

      if (bytes == null && filePath.isEmpty) {
        continue;
      }

      if (bytes != null) {
        uploadedDocuments[normalizedKey] =
            await _uploadParentDocumentRecordFromData(
              userId: uid,
              data: bytes,
              fileName: fileName ?? '$normalizedKey.bin',
              docType: entry.key,
            );
      } else {
        uploadedDocuments[normalizedKey] = await _uploadParentDocumentRecord(
          userId: uid,
          filePath: filePath,
          docType: entry.key,
        );
      }
    }

    final reviewFields = _buildParentReviewFields(uploadedDocuments);

    await familyRef.set({
      'userId': uid,
      'familyName': familyName,
      'email': email,
      'phone': phone,
      'region': region,
      'maritalStatus': maritalStatus,
      'spouseName': spouseName,
      'existingChildrenCount': existingChildrenCount ?? 0,
      'address': address,
        'homeLocation':
          homeLatitude != null && homeLongitude != null
          ? GeoPoint(homeLatitude, homeLongitude)
          : null,
        'homeLatitude': homeLatitude,
        'homeLongitude': homeLongitude,
      'annualIncome': annualIncome,
      'incomeLevel': annualIncome > 1000000
          ? 'High'
          : (annualIncome > 500000 ? 'Medium' : 'Low'),
      'requestedChildrenCount': requestedChildrenCount,
      'preferredChildAge': preferredChildAge,
      'genderPreference': genderPreference,
      'specialNeedsAcceptance': specialNeedsAcceptance,
      'additionalNotes': additionalNotes,
      'homeVerified': false,
      'documents': uploadedDocuments,
      ...reviewFields,
      'submittedAt':
          existingSnapshot.data()?['submittedAt'] ??
          FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      if (!existingSnapshot.exists) 'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await _appendParentApplicationEvent(
      familyId: uid,
      title: existingSnapshot.exists
          ? 'Application updated'
          : 'Application submitted',
      description: existingSnapshot.exists
          ? 'Parent application details and documents were updated.'
          : 'Parent application and supporting documents were submitted.',
      status: (reviewFields['verificationStage'] ?? 'Pending').toString(),
    );
  }

  Future<void> reuploadParentDocument({
    required String docType,
    required String filePath,
  }) async {
    final uid = currentUser?.uid;
    if (uid == null) {
      throw StateError('User must be authenticated to upload documents.');
    }

    final familyRef = _db.collection('adoptive_families').doc(uid);
    final snapshot = await familyRef.get();
    if (!snapshot.exists) {
      throw StateError('Application not found. Submit the application first.');
    }

    final documents = Map<String, dynamic>.from(
      snapshot.data()?['documents'] as Map<String, dynamic>? ??
          <String, dynamic>{},
    );
    final normalizedKey = _normalizeDocumentKey(docType);
    final previousDocument = Map<String, dynamic>.from(
      documents[normalizedKey] as Map<String, dynamic>? ?? <String, dynamic>{},
    );
    documents[normalizedKey] = await _uploadParentDocumentRecord(
      userId: uid,
      filePath: filePath,
      docType: docType,
    );

    final oldPublicId = (previousDocument['storagePath'] ?? '').toString();
    final newPublicId = (documents[normalizedKey] as Map<String, dynamic>)['storagePath']
            ?.toString() ??
        '';
    if (oldPublicId.isNotEmpty && oldPublicId != newPublicId) {
      await _markCloudinaryAssetSuperseded(
        publicId: oldPublicId,
        replacedByPublicId: newPublicId,
        reason: '$docType re-uploaded by parent',
        actorRole: 'parent',
        actorId: uid,
      );
    }

    final reviewFields = _buildParentReviewFields(documents);

    await familyRef.set({
      'documents': documents,
      ...reviewFields,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await _appendParentApplicationEvent(
      familyId: uid,
      title: 'Document re-uploaded',
      description: '$docType was re-uploaded by the parent.',
      status: (reviewFields['verificationStage'] ?? 'Pending').toString(),
      documentKey: normalizedKey,
    );
  }

  Future<void> updateParentDocumentVerification({
    required String familyId,
    required String documentKey,
    required String status,
    String? notes,
  }) async {
    final familyRef = _db.collection('adoptive_families').doc(familyId);
    final snapshot = await familyRef.get();
    if (!snapshot.exists) {
      throw StateError('Parent application does not exist.');
    }

    final documents = Map<String, dynamic>.from(
      snapshot.data()?['documents'] as Map<String, dynamic>? ??
          <String, dynamic>{},
    );
    final normalizedKey = _normalizeDocumentKey(documentKey);
    final existingDocument = Map<String, dynamic>.from(
      documents[normalizedKey] as Map<String, dynamic>? ?? <String, dynamic>{},
    );

    if (existingDocument.isEmpty) {
      throw StateError('Document not found for verification.');
    }

    existingDocument['verificationStatus'] = status;
    existingDocument['verificationNotes'] = notes?.trim() ?? '';
    existingDocument['verifiedBy'] = currentUser?.uid;
    existingDocument['verifiedAt'] = FieldValue.serverTimestamp();
    documents[normalizedKey] = existingDocument;

    final publicId = (existingDocument['storagePath'] ?? '').toString();
    if (publicId.isNotEmpty) {
      await _syncCloudinaryVerificationStatus(
        publicId: publicId,
        verificationStatus: status,
        verificationNotes: notes,
        actorRole: 'admin',
        actorId: currentUser?.uid,
      );
    }

    final reviewFields = _buildParentReviewFields(documents);

    await familyRef.set({
      'documents': documents,
      ...reviewFields,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await _appendParentApplicationEvent(
      familyId: familyId,
      title: 'Document $status',
      description:
          '${existingDocument['type'] ?? documentKey} marked as $status by admin.',
      status: status,
      documentKey: normalizedKey,
      notes: notes,
    );
  }

  Future<void> finalizeParentVerification({
    required String familyId,
    required String status,
    String? notes,
  }) async {
    final familyRef = _db.collection('adoptive_families').doc(familyId);
    final snapshot = await familyRef.get();
    if (!snapshot.exists) {
      throw StateError('Parent application does not exist.');
    }

    final documents = Map<String, dynamic>.from(
      snapshot.data()?['documents'] as Map<String, dynamic>? ??
          <String, dynamic>{},
    );
    final reviewSnapshot = _buildParentReviewFields(documents);
    final allDocumentsVerified =
        Map<String, dynamic>.from(
          reviewSnapshot['verificationSummary'] as Map<String, dynamic>? ??
              <String, dynamic>{},
        )['allDocumentsVerified'] ==
        true;

    if (status == 'Verified' && !allDocumentsVerified) {
      throw StateError('All documents must be verified before final approval.');
    }

    final reviewFields = _buildParentReviewFields(
      documents,
      finalStatus: status,
    );

    await familyRef.set({
      ...reviewFields,
      'adminDecisionNotes': notes?.trim(),
      'finalDecisionAt': FieldValue.serverTimestamp(),
      'finalDecisionBy': currentUser?.uid,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await _appendParentApplicationEvent(
      familyId: familyId,
      title: 'Application $status',
      description: notes?.trim().isNotEmpty == true
          ? notes!.trim()
          : 'Application marked as $status by admin.',
      status: status,
      notes: notes,
    );
  }

  // --- Counselor Assignments & Availability ---

  /// Assign a counselor to a support request
  Future<String> assignCounselorToRequest({
    required String counselorName,
    required String counselorEmail,
    required String requestId,
    required String userId,
    required String requestType, // 'mother' or 'parent'
    String? supportRequestId,
    String? ngoId,
    String? ngoName,
    String assignmentStatus = 'Active',
    String? slot,
  }) async {
    final assignmentRef = _db.collection('counselor_assignments').doc();

    await assignmentRef.set({
      'assignmentId': assignmentRef.id,
      'counselorName': counselorName,
      'counselorEmail': counselorEmail,
      'requestId': requestId,
      'userId': userId,
      'requestType': requestType,
      'supportRequestId': supportRequestId,
      'ngoId': ngoId,
      'ngoName': ngoName,
      'slot': slot,
      'status': assignmentStatus,
      'assignedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return assignmentRef.id;
  }

  /// Get counselor assigned to a specific request
  Future<Map<String, dynamic>?> getAssignedCounselor(String requestId) async {
    final snapshot = await _db
        .collection('counselor_assignments')
        .where('requestId', isEqualTo: requestId)
        .where('status', isEqualTo: 'Active')
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    return snapshot.docs.first.data();
  }

  /// Get all assignments for a user (mother or parent)
  Stream<QuerySnapshot> watchUserAssignments(String userId) {
    return _db
        .collection('counselor_assignments')
        .where('userId', isEqualTo: userId)
      .orderBy('assignedAt', descending: true)
        .snapshots();
  }

  /// Get all assignments for a counselor
  Stream<QuerySnapshot> watchCounselorAssignments(String counselorEmail) {
    return _db
        .collection('counselor_assignments')
        .where('counselorEmail', isEqualTo: counselorEmail)
        .orderBy('assignedAt', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot> watchAllCounselorAssignments() {
    return _db
        .collection('counselor_assignments')
        .orderBy('assignedAt', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchAllParentSupportRequests() {
    return _db
        .collection('parent_support_requests')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> updateCounselingSupportRequestStatus({
    required String requestId,
    required String status,
    required String actorRole,
    String? actorId,
    String? notes,
  }) async {
    final query = await _db
        .collection('counseling_requests')
        .where('requestId', isEqualTo: requestId)
        .limit(1)
        .get();

    if (query.docs.isEmpty) return;
    await query.docs.first.reference.set({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
      'latestActorRole': actorRole,
      'latestActorId': actorId,
      'latestNote': notes?.trim(),
      'history': FieldValue.arrayUnion([
        {
          'message': notes?.trim().isNotEmpty == true
              ? notes!.trim()
              : 'Status updated to $status',
          'actorRole': actorRole,
          'actorId': actorId,
          'createdAt': Timestamp.now(),
        },
      ]),
    }, SetOptions(merge: true));
  }

  Future<void> updateCounselorAssignmentLifecycle({
    required String assignmentId,
    required String status,
    String? slot,
    required String actorRole,
    String? actorId,
    String? notes,
  }) async {
    final assignmentRef = _db.collection('counselor_assignments').doc(assignmentId);
    final assignmentDoc = await assignmentRef.get();
    if (!assignmentDoc.exists) {
      throw StateError('Counselor assignment not found.');
    }

    final assignmentData = assignmentDoc.data() ?? <String, dynamic>{};
    final requestType = (assignmentData['requestType'] ?? '').toString().toLowerCase();
    final supportRequestId = (assignmentData['supportRequestId'] ?? '').toString();
    final requestId = (assignmentData['requestId'] ?? '').toString();

    int phase = 1;
    if (status == 'Accepted') phase = 2;
    if (status == 'Scheduled') phase = 3;
    if (status == 'In Session') phase = 4;
    if (status == 'Completed') phase = 5;

    final sessionPatch = <String, dynamic>{};
    if (status == 'In Session') {
      sessionPatch['session.startedAt'] = FieldValue.serverTimestamp();
    }
    if (status == 'Completed') {
      sessionPatch['session.endedAt'] = FieldValue.serverTimestamp();
    }

    await assignmentRef.set({
      'status': status,
      'slot': slot?.trim().isNotEmpty == true ? slot!.trim() : assignmentData['slot'],
      'updatedAt': FieldValue.serverTimestamp(),
      'latestActorRole': actorRole,
      'latestActorId': actorId,
      'latestNote': notes?.trim(),
      'phase': phase,
      'history': FieldValue.arrayUnion([
        {
          'message': notes?.trim().isNotEmpty == true
              ? notes!.trim()
              : 'Assignment updated to $status',
          'status': status,
          'actorRole': actorRole,
          'actorId': actorId,
          'createdAt': Timestamp.now(),
        },
      ]),
      ...sessionPatch,
    }, SetOptions(merge: true));

    final linkedBookingId = (assignmentData['bookingId'] ?? '').toString();
    if (linkedBookingId.isNotEmpty) {
      await updateCounselingBookingStatus(
        bookingId: linkedBookingId,
        status: status,
        actorRole: actorRole,
        actorId: actorId,
        notes: notes ?? 'Assignment status updated to $status',
      );
    }

    if (requestType == 'parent') {
      final targetRequestId = supportRequestId.isNotEmpty ? supportRequestId : requestId;
      if (targetRequestId.isNotEmpty) {
        await updateParentSupportRequestStatus(
          requestId: targetRequestId,
          status: status,
          phase: phase,
          actorRole: actorRole,
          actorId: actorId,
          notes: notes ?? 'Counselor assignment moved to $status',
        );
      }
      return;
    }

    if (requestType == 'mother') {
      final targetRequestId = requestId.isNotEmpty ? requestId : supportRequestId;
      if (targetRequestId.isNotEmpty) {
        await updateCounselingSupportRequestStatus(
          requestId: targetRequestId,
          status: status,
          actorRole: actorRole,
          actorId: actorId,
          notes: notes ?? 'Counselor assignment moved to $status',
        );
      }
    }
  }

  Future<void> scheduleCounselorSession({
    required String assignmentId,
    required String sessionMode,
    required DateTime scheduledAt,
    required String slot,
    String? meetingLink,
    String? notes,
    required String actorRole,
    String? actorId,
  }) async {
    final assignmentRef = _db.collection('counselor_assignments').doc(assignmentId);
    final assignmentDoc = await assignmentRef.get();
    if (!assignmentDoc.exists) {
      throw StateError('Counselor assignment not found. Assign counselor first.');
    }

    final assignmentData = assignmentDoc.data() ?? <String, dynamic>{};
    final supportRequestId = (assignmentData['supportRequestId'] ?? '').toString();
    final requestId = (assignmentData['requestId'] ?? '').toString();
    final requestType = (assignmentData['requestType'] ?? '').toString().toLowerCase();
    final linkedBookingId = (assignmentData['bookingId'] ?? '').toString();
    final scheduleLabel =
        '$sessionMode • ${scheduledAt.day}/${scheduledAt.month}/${scheduledAt.year} • $slot';

    await assignmentRef.set({
      'session': {
        'mode': sessionMode,
        'scheduledAt': Timestamp.fromDate(scheduledAt),
        'meetingLink': meetingLink?.trim(),
        'slot': slot,
        'notes': notes?.trim(),
      },
      'slot': scheduleLabel,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    if (linkedBookingId.isNotEmpty) {
      await _db.collection('counseling_bookings').doc(linkedBookingId).set({
        'status': 'Scheduled',
        'sessionMode': sessionMode,
        'sessionDate': Timestamp.fromDate(scheduledAt),
        'slot': slot,
        'meetingLink': meetingLink?.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    if (requestType == 'parent') {
      final targetRequestId = supportRequestId.isNotEmpty ? supportRequestId : requestId;
      if (targetRequestId.isNotEmpty) {
        await _db.collection('parent_support_requests').doc(targetRequestId).set({
          'selectedSessionMode': sessionMode,
          'selectedSessionDate': Timestamp.fromDate(scheduledAt),
          'selectedSlot': slot,
          'meetingLink': meetingLink?.trim(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    }

    await updateCounselorAssignmentLifecycle(
      assignmentId: assignmentId,
      status: 'Scheduled',
      slot: scheduleLabel,
      actorRole: actorRole,
      actorId: actorId,
      notes: notes?.trim().isNotEmpty == true
          ? notes!.trim()
          : 'Session scheduled for ${scheduledAt.day}/${scheduledAt.month}/${scheduledAt.year} $slot.',
    );
  }

  /// Update counselor availability status (Available, Full, On Leave)
  Future<void> updateCounselorStatus({
    required String counselorEmail,
    required String status, // 'available', 'full', 'on_leave'
  }) async {
    await _db.collection('counselor_status').doc(counselorEmail).set({
      'counselorEmail': counselorEmail,
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Get counselor status
  Future<String?> getCounselorStatus(String counselorEmail) async {
    final doc = await _db
        .collection('counselor_status')
        .doc(counselorEmail)
        .get();
    return doc.data()?['status'] as String?;
  }

  /// Stream of counselor status updates
  Stream<QuerySnapshot> watchCounselorStatuses() {
    return _db.collection('counselor_status').snapshots();
  }

  Future<void> upsertCounselorDirectoryEntry({
    required String counselorId,
    required String name,
    required String specialty,
    required String status,
    String? category,
    String? email,
    String? phone,
    String? address,
    int? yearsExperience,
    String? expertiseDomain,
    int? activeCases,
    int? maxCases,
    String? image,
  }) async {
    await _db.collection('counselor_directory').doc(counselorId).set({
      'counselorId': counselorId,
      'name': name,
      'specialty': specialty,
      'status': status,
      'category': category,
      'email': email,
      'phone': phone,
      'address': address,
      'yearsExperience': yearsExperience,
      'expertiseDomain': expertiseDomain,
      'activeCases': activeCases ?? 0,
      'maxCases': maxCases ?? 0,
      'image': image,
      'updatedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<String> addAgencyCounselorProfile({
    required String name,
    required String address,
    required String contact,
    required int yearsExperience,
    required String expertiseDomain,
    required String category,
    required Uint8List photoBytes,
    required String photoFileName,
    String? email,
  }) async {
    final normalizedCategory = category.trim().toLowerCase();
    final baseIdSource =
        email?.trim().isNotEmpty == true ? email!.trim() : '$name-$contact';
    final counselorId = baseIdSource
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');

    final uploadResult = await _uploadBinaryToCloudinary(
      data: photoBytes,
      fileName: photoFileName,
      folder: 'profiles/counselors/$counselorId',
      publicIdPrefix: 'counselor_photo',
    );

    await upsertCounselorDirectoryEntry(
      counselorId: counselorId,
      name: name.trim(),
      specialty: expertiseDomain.trim(),
      status: 'available',
      category: normalizedCategory,
      email: email?.trim(),
      phone: contact.trim(),
      address: address.trim(),
      yearsExperience: yearsExperience,
      expertiseDomain: expertiseDomain.trim(),
      activeCases: 0,
      maxCases: 10,
      image: (uploadResult['downloadUrl'] ?? '').toString(),
    );

    await updateCounselorStatus(
      counselorEmail:
          email?.trim().isNotEmpty == true ? email!.trim() : counselorId,
      status: 'available',
    );

    return counselorId;
  }

  Future<void> updateAgencyCounselorProfile({
    required String counselorId,
    required String name,
    required String address,
    required String contact,
    required int yearsExperience,
    required String expertiseDomain,
    required String category,
    required String status,
    required int activeCases,
    required int maxCases,
    String? email,
    String? currentImageUrl,
    Uint8List? photoBytes,
    String? photoFileName,
  }) async {
    final normalizedCategory = category.trim().toLowerCase();
    String finalImageUrl = currentImageUrl?.trim() ?? '';

    if (photoBytes != null && (photoFileName ?? '').trim().isNotEmpty) {
      final uploadResult = await _uploadBinaryToCloudinary(
        data: photoBytes,
        fileName: photoFileName!.trim(),
        folder: 'profiles/counselors/$counselorId',
        publicIdPrefix: 'counselor_photo',
      );
      finalImageUrl = (uploadResult['downloadUrl'] ?? '').toString();
    }

    await upsertCounselorDirectoryEntry(
      counselorId: counselorId,
      name: name.trim(),
      specialty: expertiseDomain.trim(),
      status: status.trim().isEmpty ? 'available' : status.trim(),
      category: normalizedCategory,
      email: email?.trim(),
      phone: contact.trim(),
      address: address.trim(),
      yearsExperience: yearsExperience,
      expertiseDomain: expertiseDomain.trim(),
      activeCases: activeCases,
      maxCases: maxCases,
      image: finalImageUrl,
    );

    await updateCounselorStatus(
      counselorEmail:
          email?.trim().isNotEmpty == true ? email!.trim() : counselorId,
      status: status.trim().isEmpty ? 'available' : status.trim(),
    );
  }

  Future<void> seedCounselorDirectoryIfEmpty(
    List<Map<String, dynamic>> counselors,
  ) async {
    final existing = await _db.collection('counselor_directory').limit(1).get();
    if (existing.docs.isNotEmpty) return;

    for (final counselor in counselors) {
      final counselorId =
          (counselor['id'] ?? counselor['email'] ?? counselor['name'] ?? '')
              .toString();
      if (counselorId.isEmpty) continue;

      await upsertCounselorDirectoryEntry(
        counselorId: counselorId,
        name: (counselor['name'] ?? 'Counselor').toString(),
        specialty: (counselor['specialty'] ?? 'Support').toString(),
        status: (counselor['status'] ?? 'available').toString(),
        category: (counselor['category'] ?? '').toString(),
        email: counselor['email']?.toString(),
        phone: counselor['phone']?.toString(),
        activeCases: int.tryParse((counselor['activeCases'] ?? 0).toString()),
        maxCases: int.tryParse((counselor['maxCases'] ?? 0).toString()),
        image: counselor['image']?.toString(),
      );
    }
  }

  String _deriveCounselorCategoryFromSpecialty(String specialty) {
    final value = specialty.toLowerCase();
    if (value.contains('legal') || value.contains('law')) return 'legal';
    if (value.contains('medical') || value.contains('maternal') || value.contains('health')) {
      return 'medical';
    }
    return 'general';
  }

  Future<void> ensureSharedCounselorDirectorySeed() async {
    final sharedSeed = DummyAgencyData.agencyCounsellors
        .map(
          (c) => {
            'id': (c.email ?? c.name).replaceAll(' ', '_').toLowerCase(),
            'name': c.name,
            'specialty': c.specialty,
            'category': _deriveCounselorCategoryFromSpecialty(c.specialty),
            'status': c.status,
            'email': c.email,
            'phone': c.phone,
            'activeCases': c.activeCases,
            'maxCases': c.maxCases,
            'image': c.image,
          },
        )
        .toList();

    await seedCounselorDirectoryIfEmpty(sharedSeed);
  }

  Stream<QuerySnapshot> watchCounselorDirectory({String? status}) {
    Query query = _db.collection('counselor_directory');
    if (status != null && status.isNotEmpty) {
      query = query.where('status', isEqualTo: status);
    }
    return query.orderBy('updatedAt', descending: true).snapshots();
  }

  /// Get available counselors by specialty
  Future<List<Map<String, dynamic>>> getAvailableCounselors({
    String? specialty,
    String? requestType, // 'mother' or 'parent'
  }) async {
    Query query = _db
        .collection('counselor_status')
        .where('status', isEqualTo: 'available');

    final snapshot = await query.get();
    return snapshot.docs.map((d) => d.data() as Map<String, dynamic>).toList();
  }

  /// Count active assignments for a counselor
  Future<int> getCounselorActiveAssignmentCount(String counselorEmail) async {
    final snapshot = await _db
        .collection('counselor_assignments')
        .where('counselorEmail', isEqualTo: counselorEmail)
        .where('status', isEqualTo: 'Active')
        .count()
        .get();

    return snapshot.count ?? 0;
  }

  /// Unassign a counselor from a request
  Future<void> unassignCounselor(String assignmentId) async {
    await _db.collection('counselor_assignments').doc(assignmentId).update({
      'status': 'Inactive',
      'unassignedAt': FieldValue.serverTimestamp(),
    });
  }

  // --- Parent Support Center: Dynamic NGO/Counselor Pipeline ---

  Stream<QuerySnapshot<Map<String, dynamic>>> watchParentSupportRequests() {
    final uid = currentUser?.uid ?? '__none__';
    return _db
        .collection('parent_support_requests')
        .where('userId', isEqualTo: uid)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchParentCounselorAssignments() {
    final uid = currentUser?.uid ?? '__none__';
    return _db
        .collection('counselor_assignments')
        .where('userId', isEqualTo: uid)
        .where('requestType', isEqualTo: 'parent')
        .snapshots();
  }

  Future<String> createParentSupportRequest({
    required String serviceType,
    String? notes,
  }) async {
    final uid = currentUser?.uid;
    if (uid == null) {
      throw StateError('User must be authenticated to request support.');
    }

    final parentDoc = await _db.collection('adoptive_families').doc(uid).get();
    final parentData = parentDoc.data() ?? <String, dynamic>{};
    final region = (parentData['region'] ?? '').toString();

    final ngosSnapshot = await _db.collection('ngos').limit(50).get();
    final ngoDocs = ngosSnapshot.docs;
    if (ngoDocs.isEmpty) {
      throw StateError('No NGO records found. Please seed NGO data first.');
    }

    QueryDocumentSnapshot<Map<String, dynamic>> selectedNgo = ngoDocs.first;
    for (final ngo in ngoDocs) {
      final data = ngo.data();
      final ngoRegion = (data['region'] ?? '').toString();
      final services = (data['services'] as List<dynamic>? ?? <dynamic>[])
          .map((e) => e.toString().toLowerCase())
          .toList();
      if (ngoRegion.toLowerCase() == region.toLowerCase() &&
          services.any((s) => serviceType.toLowerCase().contains(s) || s.contains('counsel'))) {
        selectedNgo = ngo;
        break;
      }
    }

    final requestRef = _db.collection('parent_support_requests').doc();
    await requestRef.set({
      'requestId': requestRef.id,
      'userId': uid,
      'familyName': (parentData['familyName'] ?? '').toString(),
      'serviceType': serviceType,
      'notes': notes?.trim(),
      'region': region,
      'ngoId': selectedNgo.id,
      'ngoName': (selectedNgo.data()['name'] ?? 'Assigned NGO').toString(),
      'status': 'Requested',
      'phase': 1,
      'process': [
        'Request submitted',
        'NGO acknowledged',
        'Counselor assigned',
        'Slot confirmed',
        'Session completed',
      ],
      'history': [
        {
          'message': 'Support request created and routed to NGO',
          'actorRole': 'parent',
          'createdAt': Timestamp.now(),
        },
      ],
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return requestRef.id;
  }

  Future<void> updateParentSupportRequestStatus({
    required String requestId,
    required String status,
    required int phase,
    required String actorRole,
    String? actorId,
    String? notes,
  }) async {
    await _db.collection('parent_support_requests').doc(requestId).set({
      'status': status,
      'phase': phase,
      'updatedAt': FieldValue.serverTimestamp(),
      'latestActorRole': actorRole,
      'latestActorId': actorId,
      'latestNote': notes?.trim(),
      'history': FieldValue.arrayUnion([
        {
          'message': notes?.trim().isNotEmpty == true ? notes!.trim() : 'Status updated to $status',
          'actorRole': actorRole,
          'actorId': actorId,
          'createdAt': Timestamp.now(),
        },
      ]),
    }, SetOptions(merge: true));
  }

  Future<void> submitParentCounselorFeedback({
    required String assignmentId,
    required int rating,
    required String feedback,
  }) async {
    final uid = currentUser?.uid;
    await _db.collection('counselor_assignments').doc(assignmentId).set({
      'feedback': {
        'rating': rating,
        'comment': feedback.trim(),
        'submittedBy': uid,
        'submittedAt': FieldValue.serverTimestamp(),
      },
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> assignChildToVerifiedParent({
    required String familyId,
    required String motherRequestId,
    String? notes,
  }) async {
    final parentRef = _db.collection('adoptive_families').doc(familyId);
    final motherRef = _db.collection('mother_requests').doc(motherRequestId);

    final parentSnapshot = await parentRef.get();
    if (!parentSnapshot.exists) {
      throw StateError('Parent application not found.');
    }
    final parentData = parentSnapshot.data() ?? <String, dynamic>{};
    final parentStatus = (parentData['adoptionStatus'] ?? '').toString();
    if (parentStatus != 'Verified') {
      throw StateError('Child can only be assigned to an approved/verified parent.');
    }

    final motherSnapshot = await motherRef.get();
    if (!motherSnapshot.exists) {
      throw StateError('Mother request not found.');
    }
    final motherData = motherSnapshot.data() ?? <String, dynamic>{};
    final childStage = (motherData['childDocumentStage'] ?? '').toString();
    if (childStage != 'Child Documents Verified') {
      throw StateError('Mother child documents must be fully verified before assignment.');
    }

    if ((motherData['assignedParentId'] ?? '').toString().isNotEmpty) {
      throw StateError('This child request is already assigned to another parent.');
    }

    final childProfile = Map<String, dynamic>.from(
      motherData['childProfile'] as Map<String, dynamic>? ?? <String, dynamic>{},
    );
    final childPhoto = Map<String, dynamic>.from(
      motherData['childPhoto'] as Map<String, dynamic>? ?? <String, dynamic>{},
    );

    await parentRef.set({
      'adoptionStatus': 'Child Assigned',
      'assignedChildRequestId': motherRequestId,
      'assignedChild': {
        ...childProfile,
        'photoUrl': (childPhoto['downloadUrl'] ?? '').toString(),
        'sourceRequestId': motherRequestId,
      },
      'assignmentNotes': notes?.trim(),
      'assignedAt': FieldValue.serverTimestamp(),
      'assignedBy': currentUser?.uid,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await motherRef.set({
      'status': 'Accepted',
      'assignedParentId': familyId,
      'assignedParentFamilyName': (parentData['familyName'] ?? '').toString(),
      'assignedAt': FieldValue.serverTimestamp(),
      'latestAction': 'Child assigned to verified parent',
      'latestActorRole': 'admin',
      'latestActorId': currentUser?.uid,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await _appendParentApplicationEvent(
      familyId: familyId,
      title: 'Child assigned',
      description: notes?.trim().isNotEmpty == true
          ? notes!.trim()
          : 'A child surrender request has been assigned to this parent.',
      status: 'Child Assigned',
      notes: notes,
    );

    await _appendRequestEvent(
      requestId: motherRequestId,
      eventType: 'child_assigned',
      status: 'Accepted',
      actorRole: 'admin',
      actorId: currentUser?.uid,
      notes:
          'Assigned to ${(parentData['familyName'] ?? 'verified parent').toString()} (${parentRef.id})',
    );
  }

  // --- NGO/Agency Pillar ---

  Future<List<Map<String, dynamic>>> getNGOs({String? serviceFilter}) async {
    Query query = _db.collection('ngos');
    if (serviceFilter != null && serviceFilter != 'All') {
      query = query.where('services', arrayContains: serviceFilter);
    }
    final snap = await query.get();
    return snap.docs.map((d) => d.data() as Map<String, dynamic>).toList();
  }

  // --- Admin Pillar: Monitoring & Analytics ---

  Stream<QuerySnapshot> watchAllRequests() {
    return _db
        .collection('mother_requests')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot> getVerificationQueue() {
    return _db.collection('adoptive_families').snapshots();
  }

  Future<void> updateVerificationStatus(String docId, String status) async {
    await finalizeParentVerification(familyId: docId, status: status);
  }

  /// Stream all child-surrender requests that have been assigned to a parent.
  /// Sorting is done client-side to avoid requiring a composite index.
  Stream<QuerySnapshot> watchAssignedChildRequests() {
    return _db
        .collection('mother_requests')
        .where('requestType', isEqualTo: 'child_surrender')
        .where('status', isEqualTo: 'Accepted')
        .snapshots();
  }

  // --- Storage Helper ---

  Future<String> uploadDocument(String filePath, String docType) async {
    final uid = currentUser?.uid ?? 'anonymous';
    final record = await _uploadParentDocumentRecord(
      userId: uid,
      filePath: filePath,
      docType: docType,
    );
    return (record['downloadUrl'] ?? '').toString();
  }

  Future<Map<String, dynamic>> _uploadMotherRequestChildPhoto({
    required String userId,
    required String requestId,
    required Uint8List data,
    required String fileName,
  }) async {
    final extension = _extractFileExtension(fileName);
    final storageFileName =
        'child_photo_${DateTime.now().millisecondsSinceEpoch}${extension.isEmpty ? '' : '.$extension'}';
    final uploadResult = await _uploadBinaryToCloudinary(
      data: data,
      fileName: storageFileName,
      folder: 'documents/mother_requests/$userId/$requestId',
      publicIdPrefix: 'child_photo',
    );
    final managementDocPath = await _upsertCloudinaryManagementEntry(
      ownerUserId: userId,
      requestDomain: 'mother_surrender',
      entityCollection: 'mother_requests',
      entityId: requestId,
      roleContext: 'mother',
      docType: 'Child Photo',
      fileName: fileName,
      extension: extension,
      verificationStatus: 'Pending',
      verificationNotes: '',
      uploadResult: uploadResult,
      isPrimaryPhoto: true,
    );
    return {
      'fileName': fileName,
      'downloadUrl': uploadResult['downloadUrl'],
      'storagePath': uploadResult['publicId'],
      'storageProvider': 'cloudinary',
      'cloudinaryAssetId': uploadResult['assetId'],
      'cloudinaryResourceType': uploadResult['resourceType'],
      'cloudinaryManagementDoc': managementDocPath,
      'uploadedAt': FieldValue.serverTimestamp(),
    };
  }

  Future<Map<String, dynamic>> _uploadMotherRequestDocumentRecord({
    required String userId,
    required String requestId,
    required String docType,
    required Uint8List data,
    required String fileName,
  }) async {
    final extension = _extractFileExtension(fileName);
    final normalizedType = _normalizeDocumentKey(docType);
    final storageFileName =
        '${normalizedType}_${DateTime.now().millisecondsSinceEpoch}${extension.isEmpty ? '' : '.$extension'}';
    final uploadResult = await _uploadBinaryToCloudinary(
      data: data,
      fileName: storageFileName,
      folder: 'documents/mother_requests/$userId/$requestId/docs',
      publicIdPrefix: normalizedType,
    );
    final managementDocPath = await _upsertCloudinaryManagementEntry(
      ownerUserId: userId,
      requestDomain: 'mother_surrender',
      entityCollection: 'mother_requests',
      entityId: requestId,
      roleContext: 'mother',
      docType: docType,
      fileName: fileName,
      extension: extension,
      verificationStatus: 'Pending',
      verificationNotes: '',
      uploadResult: uploadResult,
    );
    return {
      'type': docType,
      'fileName': fileName,
      'extension': extension,
      'downloadUrl': uploadResult['downloadUrl'],
      'storagePath': uploadResult['publicId'],
      'storageProvider': 'cloudinary',
      'cloudinaryAssetId': uploadResult['assetId'],
      'cloudinaryResourceType': uploadResult['resourceType'],
      'cloudinaryManagementDoc': managementDocPath,
      'uploadedAt': FieldValue.serverTimestamp(),
      'verificationStatus': 'Pending',
      'verificationNotes': '',
      'verifiedBy': null,
      'verifiedAt': null,
    };
  }

  Map<String, dynamic> _buildMotherChildDocumentsReviewFields(
    Map<String, dynamic> documents,
  ) {
    final totalDocuments = documents.length;
    int verifiedCount = 0;
    int rejectedCount = 0;
    int pendingCount = 0;

    for (final value in documents.values) {
      final document = Map<String, dynamic>.from(
        value as Map<String, dynamic>? ?? <String, dynamic>{},
      );
      final status =
          (document['verificationStatus'] ?? 'Pending').toString().toLowerCase();
      if (status == 'verified') {
        verifiedCount++;
      } else if (status == 'rejected') {
        rejectedCount++;
      } else {
        pendingCount++;
      }
    }

    final percentComplete = totalDocuments == 0
        ? 0
        : ((verifiedCount / totalDocuments) * 100).round();
    String stage;
    if (totalDocuments == 0) {
      stage = 'Awaiting Child Documents';
    } else if (rejectedCount > 0) {
      stage = 'Child Documents Need Updates';
    } else if (verifiedCount == totalDocuments) {
      stage = 'Child Documents Verified';
    } else if (verifiedCount > 0) {
      stage = 'Child Document Review In Progress';
    } else {
      stage = 'Pending Child Document Review';
    }

    return {
      'childDocumentStage': stage,
      'childDocumentSummary': {
        'totalDocuments': totalDocuments,
        'verifiedCount': verifiedCount,
        'rejectedCount': rejectedCount,
        'pendingCount': pendingCount,
        'percentComplete': percentComplete,
      },
    };
  }

  Future<Map<String, dynamic>> _uploadParentDocumentRecord({
    required String userId,
    required String filePath,
    required String docType,
  }) async {
    final sourceFile = File(filePath);
    final fileName = _extractFileName(filePath);
    if (!await sourceFile.exists()) {
      throw StateError(
        'Selected document "$fileName" is no longer accessible. Please attach it again and retry.',
      );
    }
    final bytes = await sourceFile.readAsBytes();
    return _uploadParentDocumentRecordFromData(
      userId: userId,
      data: bytes,
      fileName: fileName,
      docType: docType,
    );
  }

  Future<Map<String, dynamic>> _uploadParentDocumentRecordFromData({
    required String userId,
    required Uint8List data,
    required String fileName,
    required String docType,
  }) async {
    final extension = _extractFileExtension(fileName);
    final normalizedType = _normalizeDocumentKey(docType);
    final storageFileName =
        '${DateTime.now().millisecondsSinceEpoch}_$normalizedType${extension.isEmpty ? '' : '.$extension'}';
    final uploadResult = await _uploadBinaryToCloudinary(
      data: data,
      fileName: storageFileName,
      folder: 'documents/parents/$userId/$normalizedType',
      publicIdPrefix: normalizedType,
    );
    final managementDocPath = await _upsertCloudinaryManagementEntry(
      ownerUserId: userId,
      requestDomain: 'adoptive_parent',
      entityCollection: 'adoptive_families',
      entityId: userId,
      roleContext: 'parent',
      docType: docType,
      fileName: fileName,
      extension: extension,
      verificationStatus: 'Pending',
      verificationNotes: '',
      uploadResult: uploadResult,
    );

    return {
      'type': docType,
      'fileName': fileName,
      'extension': extension,
      'downloadUrl': uploadResult['downloadUrl'],
      'storagePath': uploadResult['publicId'],
      'storageProvider': 'cloudinary',
      'cloudinaryAssetId': uploadResult['assetId'],
      'cloudinaryResourceType': uploadResult['resourceType'],
      'cloudinaryManagementDoc': managementDocPath,
      'uploadedAt': FieldValue.serverTimestamp(),
      'verificationStatus': 'Pending',
      'verificationNotes': '',
      'verifiedAt': null,
      'verifiedBy': null,
    };
  }

  Future<Map<String, dynamic>> _uploadBinaryToCloudinary({
    required Uint8List data,
    required String fileName,
    required String folder,
    String? publicIdPrefix,
  }) async {
    if (_cloudinaryCloudName.isEmpty || _cloudinaryUploadPreset.isEmpty) {
      throw StateError(
        'Cloudinary is not configured. Check lib/core/cloudinary_config.dart.',
      );
    }

    final endpoint = Uri.parse(CloudinaryConfig.uploadUrl);

    final request = http.MultipartRequest('POST', endpoint)
      ..fields['upload_preset'] = _cloudinaryUploadPreset
      ..fields['folder'] = folder;

    if (publicIdPrefix != null && publicIdPrefix.trim().isNotEmpty) {
      request.fields['public_id'] =
          '${publicIdPrefix.trim()}_${DateTime.now().millisecondsSinceEpoch}';
    }

    request.files.add(
      http.MultipartFile.fromBytes('file', data, filename: fileName),
    );

    final streamedResponse = await request.send();
    final responseBody = await streamedResponse.stream.bytesToString();
    final responseJson = jsonDecode(responseBody) as Map<String, dynamic>;

    if (streamedResponse.statusCode < 200 || streamedResponse.statusCode >= 300) {
      final message = responseJson['error'] is Map<String, dynamic>
          ? (responseJson['error']['message'] ?? 'Upload failed').toString()
          : 'Upload failed';
      throw StateError('Cloudinary upload failed: $message');
    }

    final secureUrl = (responseJson['secure_url'] ?? '').toString();
    final publicId = (responseJson['public_id'] ?? '').toString();
    if (secureUrl.isEmpty) {
      throw StateError('Cloudinary upload failed: empty secure_url returned.');
    }

    return {
      'downloadUrl': secureUrl,
      'publicId': publicId,
      'assetId': (responseJson['asset_id'] ?? '').toString(),
      'resourceType': (responseJson['resource_type'] ?? '').toString(),
      'format': (responseJson['format'] ?? '').toString(),
      'bytes': responseJson['bytes'] ?? 0,
      'width': responseJson['width'],
      'height': responseJson['height'],
      'version': responseJson['version'],
      'folder': (responseJson['folder'] ?? '').toString(),
      'originalFilename': (responseJson['original_filename'] ?? '').toString(),
      'createdAt': (responseJson['created_at'] ?? '').toString(),
      'signature': (responseJson['signature'] ?? '').toString(),
      'rawResponse': responseJson,
    };
  }

  Future<String> _upsertCloudinaryManagementEntry({
    required String ownerUserId,
    required String requestDomain,
    required String entityCollection,
    required String entityId,
    required String roleContext,
    required String docType,
    required String fileName,
    required String extension,
    required String verificationStatus,
    required String verificationNotes,
    required Map<String, dynamic> uploadResult,
    bool isPrimaryPhoto = false,
  }) async {
    final publicId = (uploadResult['publicId'] ?? '').toString();
    if (publicId.isEmpty) {
      throw StateError('Cloudinary public ID missing for metadata persistence.');
    }

    final docId = _cloudinaryManagementDocId(publicId);
    final docRef = _db.collection('cloudinary_management').doc(docId);

    await docRef.set({
      'docId': docId,
      'storageProvider': 'cloudinary',
      'cloudName': _cloudinaryCloudName,
      'asset': {
        'assetId': (uploadResult['assetId'] ?? '').toString(),
        'publicId': publicId,
        'downloadUrl': (uploadResult['downloadUrl'] ?? '').toString(),
        'resourceType': (uploadResult['resourceType'] ?? '').toString(),
        'format': (uploadResult['format'] ?? '').toString(),
        'folder': (uploadResult['folder'] ?? '').toString(),
        'version': uploadResult['version'],
        'bytes': uploadResult['bytes'] ?? 0,
        'width': uploadResult['width'],
        'height': uploadResult['height'],
        'originalFilename': (uploadResult['originalFilename'] ?? '').toString(),
        'createdAtCloudinary': (uploadResult['createdAt'] ?? '').toString(),
        'signature': (uploadResult['signature'] ?? '').toString(),
      },
      'reference': {
        'ownerUserId': ownerUserId,
        'roleContext': roleContext,
        'requestDomain': requestDomain,
        'entityCollection': entityCollection,
        'entityId': entityId,
        'isPrimaryPhoto': isPrimaryPhoto,
      },
      'document': {
        'docType': docType,
        'fileName': fileName,
        'extension': extension,
        'verificationStatus': verificationStatus,
        'verificationNotes': verificationNotes,
      },
      'lifecycle': {
        'status': 'Active',
        'replacedByPublicId': null,
        'supersededAt': null,
      },
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    return 'cloudinary_management/$docId';
  }

  String _cloudinaryManagementDocId(String publicId) {
    final base64 = base64UrlEncode(utf8.encode(publicId));
    return base64.replaceAll('=', '');
  }

  Future<void> _syncCloudinaryVerificationStatus({
    required String publicId,
    required String verificationStatus,
    String? verificationNotes,
    required String actorRole,
    String? actorId,
  }) async {
    final docId = _cloudinaryManagementDocId(publicId);
    await _db.collection('cloudinary_management').doc(docId).set({
      'document.verificationStatus': verificationStatus,
      'document.verificationNotes': verificationNotes?.trim() ?? '',
      'document.verifiedBy': actorId,
      'document.verifiedAt': FieldValue.serverTimestamp(),
      'verificationLastActorRole': actorRole,
      'verificationLastActorId': actorId,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> _markCloudinaryAssetSuperseded({
    required String publicId,
    required String replacedByPublicId,
    required String reason,
    required String actorRole,
    String? actorId,
  }) async {
    final docId = _cloudinaryManagementDocId(publicId);
    await _db.collection('cloudinary_management').doc(docId).set({
      'lifecycle.status': 'Superseded',
      'lifecycle.replacedByPublicId': replacedByPublicId,
      'lifecycle.supersededReason': reason,
      'lifecycle.supersededAt': FieldValue.serverTimestamp(),
      'lifecycle.supersededByRole': actorRole,
      'lifecycle.supersededById': actorId,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> _appendParentApplicationEvent({
    required String familyId,
    required String title,
    required String description,
    required String status,
    String? documentKey,
    String? notes,
  }) async {
    await _db
        .collection('adoptive_families')
        .doc(familyId)
        .collection('events')
        .add({
          'title': title,
          'description': description,
          'status': status,
          'documentKey': documentKey,
          'notes': notes,
          'actorId': currentUser?.uid,
          'createdAt': FieldValue.serverTimestamp(),
        });
  }

  Map<String, dynamic> _buildParentReviewFields(
    Map<String, dynamic> documents, {
    String? finalStatus,
  }) {
    final totalDocuments = documents.length;
    int verifiedCount = 0;
    int rejectedCount = 0;
    int pendingCount = 0;

    for (final value in documents.values) {
      final document = Map<String, dynamic>.from(
        value as Map<String, dynamic>? ?? <String, dynamic>{},
      );
      final status = (document['verificationStatus'] ?? 'Pending')
          .toString()
          .toLowerCase();

      if (status == 'verified') {
        verifiedCount++;
      } else if (status == 'rejected') {
        rejectedCount++;
      } else {
        pendingCount++;
      }
    }

    final percentComplete = totalDocuments == 0
        ? 0
        : ((verifiedCount / totalDocuments) * 100).round();
    final allDocumentsVerified =
        totalDocuments > 0 && verifiedCount == totalDocuments;

    String verificationStage;
    String adoptionStatus;
    String backgroundCheck;

    if (finalStatus == 'Verified') {
      verificationStage = 'Verification Completed';
      adoptionStatus = 'Verified';
      backgroundCheck = 'Completed';
    } else if (finalStatus == 'Rejected') {
      verificationStage = 'Rejected';
      adoptionStatus = 'Rejected';
      backgroundCheck = 'Rejected';
    } else if (rejectedCount > 0) {
      verificationStage = 'Changes Requested';
      adoptionStatus = 'Changes Requested';
      backgroundCheck = 'Pending';
    } else if (allDocumentsVerified) {
      verificationStage = 'Awaiting Final Approval';
      adoptionStatus = 'In Review';
      backgroundCheck = 'Completed';
    } else if (totalDocuments > 0) {
      verificationStage = verifiedCount > 0
          ? 'Document Review In Progress'
          : 'Pending Document Review';
      adoptionStatus = verifiedCount > 0 ? 'In Review' : 'Under Review';
      backgroundCheck = 'Pending';
    } else {
      verificationStage = 'Awaiting Uploads';
      adoptionStatus = 'Draft';
      backgroundCheck = 'Pending';
    }

    return {
      'verificationStage': verificationStage,
      'adoptionStatus': adoptionStatus,
      'backgroundCheck': backgroundCheck,
      'verificationSummary': {
        'totalDocuments': totalDocuments,
        'verifiedCount': verifiedCount,
        'rejectedCount': rejectedCount,
        'pendingCount': pendingCount,
        'percentComplete': percentComplete,
        'allDocumentsVerified': allDocumentsVerified,
        'finalApprovalRequired':
            allDocumentsVerified && finalStatus != 'Verified',
      },
    };
  }

  Map<String, dynamic> _canonicalizeChildDocuments(Map<String, dynamic> rawDocuments) {
    final normalized = <String, Map<String, dynamic>>{};

    for (final entry in rawDocuments.entries) {
      final value = Map<String, dynamic>.from(
        entry.value as Map<String, dynamic>? ?? <String, dynamic>{},
      );
      final candidateType = (value['type'] ?? entry.key).toString();
      final key = _normalizeDocumentKey(candidateType);
      final existing = normalized[key];
      if (existing == null) {
        normalized[key] = value;
        continue;
      }

      final existingStatus = (existing['verificationStatus'] ?? 'Pending').toString();
      final incomingStatus = (value['verificationStatus'] ?? 'Pending').toString();
      final incomingIsVerified = incomingStatus.toLowerCase() == 'verified';
      final existingIsVerified = existingStatus.toLowerCase() == 'verified';
      if (incomingIsVerified && !existingIsVerified) {
        normalized[key] = value;
      }
    }

    return normalized;
  }

  String _normalizeDocumentKey(String docType) {
    return docType
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
  }

  String _extractFileName(String filePath) {
    final segments = filePath.split(RegExp(r'[\\/]'));
    return segments.isEmpty ? filePath : segments.last;
  }

  String _extractFileExtension(String filePath) {
    final fileName = _extractFileName(filePath);
    final dotIndex = fileName.lastIndexOf('.');
    if (dotIndex == -1 || dotIndex == fileName.length - 1) {
      return '';
    }
    return fileName.substring(dotIndex + 1).toLowerCase();
  }

  bool _isParentAdoptionProcessCompleted(String adoptionStatus) {
    final normalizedStatus = adoptionStatus.trim().toLowerCase();
    if (normalizedStatus.isEmpty) {
      return false;
    }

    return normalizedStatus == 'child assigned' ||
        normalizedStatus == 'completed' ||
        normalizedStatus == 'closed' ||
        normalizedStatus == 'cancelled' ||
        normalizedStatus == 'rejected';
  }

  // --- Automation: Data Seeding ---

  Future<void> seedInitialData() async {
    // 1. Seed NGOs
    final ngos = [
      {
        'id': 'ngo1',
        'name': 'Pune Mother & Child Welfare',
        'region': 'Pune Central',
        'services': ['Legal', 'Medical', 'Counseling', 'Shelter'],
        'lat': 18.5204,
        'lng': 73.8567,
        'rating': 4.8,
        'capacity': 50,
      },
      {
        'id': 'ngo2',
        'name': 'Hope Guardians Foundation',
        'region': 'Hadapsar',
        'services': ['Counseling', 'Education'],
        'lat': 18.5089,
        'lng': 73.9259,
        'rating': 4.5,
        'capacity': 30,
      },
    ];

    for (var ngo in ngos) {
      await _db.collection('ngos').add(ngo);
    }

    // 2. Seed Mother Requests for Analytics
    final regions = ['Hadapsar', 'Pune Central', 'Aundh', 'Pimpri'];
    final reasonsBase = [
      'Financial Distress',
      'Lack of Support',
      'Social Stigma',
      'Medical Reasons',
      'Career Conflicts',
    ];

    for (int i = 0; i < 20; i++) {
      final region = regions[i % regions.length];
      final reasons = [reasonsBase[i % reasonsBase.length]];
      if (i % 3 == 0) reasons.add(reasonsBase[(i + 1) % reasonsBase.length]);

      await submitMotherRequest(
        reasons: reasons,
        needsCounseling: i % 2 == 0,
        isAnonymous: i % 4 == 0,
        region: region,
      );
    }

    // 3. Seed Adoptive Families
    final families = ['Sharma', 'Deshmukh', 'Patil', 'Iyer', 'Bannerjee'];
    for (int i = 0; i < families.length; i++) {
      await _db.collection('adoptive_families').add({
        'familyName': '${families[i]} Family',
        'region': regions[i % regions.length],
        'annualIncome': (8 + i) * 100000.0,
        'backgroundCheck': i == 0 ? 'Pending' : 'Completed',
        'adoptionStatus': i == 0 ? 'Under Review' : 'Verified',
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }
}
