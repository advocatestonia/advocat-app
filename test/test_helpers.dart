/// Common test fixtures and helpers for Advocat unit tests.
library test_helpers;

import 'package:advocat/models/case_model.dart';
import 'package:advocat/models/correspondence.dart';
import 'package:advocat/models/deadline.dart';
import 'package:advocat/models/document.dart';
import 'package:advocat/models/user.dart';

// ---------------------------------------------------------------------------
// Fixture dates — deterministic, timezone-independent
// ---------------------------------------------------------------------------

final fixtureNow = DateTime.utc(2026, 4, 15, 12, 0, 0);
final fixturePast = DateTime.utc(2025, 1, 1, 0, 0, 0);
final fixtureFuture = DateTime.utc(2027, 12, 31, 23, 59, 59);

// ---------------------------------------------------------------------------
// AppUser fixtures
// ---------------------------------------------------------------------------

AppUser makeUser({
  String id = 'user-001',
  String email = 'test@advocat.ee',
  String fullName = 'Test User',
  String? phone,
  String? avatarUrl,
  String preferredLanguage = 'et',
  bool? isPro,
  SubscriptionTier subscriptionTier = SubscriptionTier.free,
  DateTime? subscriptionExpiresAt,
  DateTime? createdAt,
  DateTime? updatedAt,
  DateTime? gdprConsentAt,
}) {
  // Default isPro to mirror legacy tier-based behaviour so pre-existing
  // fixtures keep their semantics: anything non-free was implicitly Pro.
  final resolvedIsPro = isPro ?? (subscriptionTier != SubscriptionTier.free);
  return AppUser(
    id: id,
    email: email,
    fullName: fullName,
    phone: phone,
    avatarUrl: avatarUrl,
    preferredLanguage: preferredLanguage,
    isPro: resolvedIsPro,
    subscriptionTier: subscriptionTier,
    subscriptionExpiresAt: subscriptionExpiresAt,
    createdAt: createdAt ?? fixtureNow,
    updatedAt: updatedAt,
    gdprConsentAt: gdprConsentAt,
  );
}

Map<String, dynamic> makeUserJson({
  String id = 'user-001',
  String email = 'test@advocat.ee',
  String fullName = 'Test User',
  String? phone,
  String? avatarUrl,
  String preferredLanguage = 'et',
  String subscriptionTier = 'free',
  String? subscriptionExpiresAt,
  String? createdAt,
  String? updatedAt,
  String? gdprConsentAt,
}) {
  return {
    'id': id,
    'email': email,
    'full_name': fullName,
    if (phone != null) 'phone': phone,
    if (avatarUrl != null) 'avatar_url': avatarUrl,
    'preferred_language': preferredLanguage,
    'subscription_tier': subscriptionTier,
    if (subscriptionExpiresAt != null)
      'subscription_expires_at': subscriptionExpiresAt,
    'created_at': createdAt ?? fixtureNow.toIso8601String(),
    if (updatedAt != null) 'updated_at': updatedAt,
    if (gdprConsentAt != null) 'gdpr_consent_at': gdprConsentAt,
  };
}

// ---------------------------------------------------------------------------
// LegalCase fixtures
// ---------------------------------------------------------------------------

LegalCase makeCase({
  String id = 'case-001',
  String userId = 'user-001',
  String title = 'Test Case',
  String? description,
  CaseType type = CaseType.deportation,
  CaseStatus status = CaseStatus.active,
  String? migriReferenceNumber,
  String? courtCaseNumber,
  String? nationality,
  DateTime? decisionDate,
  DateTime? appealDeadline,
  DateTime? hearingDate,
  DateTime? createdAt,
  DateTime? updatedAt,
  int documentCount = 0,
  int unreadMessages = 0,
}) {
  return LegalCase(
    id: id,
    userId: userId,
    title: title,
    description: description,
    type: type,
    status: status,
    migriReferenceNumber: migriReferenceNumber,
    courtCaseNumber: courtCaseNumber,
    nationality: nationality,
    decisionDate: decisionDate,
    appealDeadline: appealDeadline,
    hearingDate: hearingDate,
    createdAt: createdAt ?? fixtureNow,
    updatedAt: updatedAt,
    documentCount: documentCount,
    unreadMessages: unreadMessages,
  );
}

Map<String, dynamic> makeCaseJson({
  String id = 'case-001',
  String userId = 'user-001',
  String title = 'Test Case',
  String? description,
  String type = 'deportation',
  String status = 'active',
  String? migriReferenceNumber,
  String? courtCaseNumber,
  String? nationality,
  String? decisionDate,
  String? appealDeadline,
  String? hearingDate,
  String? createdAt,
  String? updatedAt,
  int documentCount = 0,
  int unreadMessages = 0,
}) {
  return {
    'id': id,
    'user_id': userId,
    'title': title,
    'description': description,
    'type': type,
    'status': status,
    'migri_reference_number': migriReferenceNumber,
    'court_case_number': courtCaseNumber,
    'nationality': nationality,
    'decision_date': decisionDate,
    'appeal_deadline': appealDeadline,
    'hearing_date': hearingDate,
    'created_at': createdAt ?? fixtureNow.toIso8601String(),
    'updated_at': updatedAt,
    'document_count': documentCount,
    'unread_messages': unreadMessages,
  };
}

// ---------------------------------------------------------------------------
// CaseDocument fixtures
// ---------------------------------------------------------------------------

CaseDocument makeDocument({
  String id = 'doc-001',
  String caseId = 'case-001',
  String userId = 'user-001',
  String fileName = 'test.pdf',
  String storagePath = 'user-001/case-001/test.pdf',
  String mimeType = 'application/pdf',
  int fileSizeBytes = 1024,
  DocumentCategory category = DocumentCategory.other,
  String? language,
  String? ocrText,
  String? aiSummary,
  Map<String, dynamic> extractedEntities = const {},
  DocumentProcessingStatus processingStatus = DocumentProcessingStatus.pending,
  DateTime? createdAt,
  DateTime? updatedAt,
}) {
  return CaseDocument(
    id: id,
    caseId: caseId,
    userId: userId,
    fileName: fileName,
    storagePath: storagePath,
    mimeType: mimeType,
    fileSizeBytes: fileSizeBytes,
    category: category,
    language: language,
    ocrText: ocrText,
    aiSummary: aiSummary,
    extractedEntities: extractedEntities,
    processingStatus: processingStatus,
    createdAt: createdAt ?? fixtureNow,
    updatedAt: updatedAt,
  );
}

Map<String, dynamic> makeDocumentJson({
  String id = 'doc-001',
  String caseId = 'case-001',
  String userId = 'user-001',
  String fileName = 'test.pdf',
  String storagePath = 'user-001/case-001/test.pdf',
  String mimeType = 'application/pdf',
  int fileSizeBytes = 1024,
  String? category,
  String? language,
  String? ocrText,
  String? aiSummary,
  Map<String, dynamic>? extractedEntities,
  String? processingStatus,
  String? createdAt,
  String? updatedAt,
}) {
  return {
    'id': id,
    'case_id': caseId,
    'user_id': userId,
    'file_name': fileName,
    'storage_path': storagePath,
    'mime_type': mimeType,
    'file_size_bytes': fileSizeBytes,
    'category': category,
    'language': language,
    'ocr_text': ocrText,
    'ai_summary': aiSummary,
    'extracted_entities': extractedEntities,
    'processing_status': processingStatus,
    'created_at': createdAt ?? fixtureNow.toIso8601String(),
    'updated_at': updatedAt,
  };
}

// ---------------------------------------------------------------------------
// Deadline fixtures
// ---------------------------------------------------------------------------

Deadline makeDeadline({
  String id = 'dl-001',
  String caseId = 'case-001',
  String userId = 'user-001',
  String title = 'Appeal deadline',
  String? description,
  DateTime? dueDate,
  DeadlineType type = DeadlineType.appeal,
  DeadlinePriority priority = DeadlinePriority.high,
  DeadlineStatus status = DeadlineStatus.upcoming,
  bool notificationScheduled = false,
  int reminderDaysBefore = 7,
  DeadlineSource source = DeadlineSource.manual,
  String? sourceDocumentId,
  DateTime? createdAt,
  DateTime? updatedAt,
}) {
  return Deadline(
    id: id,
    caseId: caseId,
    userId: userId,
    title: title,
    description: description,
    dueDate: dueDate ?? fixtureFuture,
    type: type,
    priority: priority,
    status: status,
    notificationScheduled: notificationScheduled,
    reminderDaysBefore: reminderDaysBefore,
    source: source,
    sourceDocumentId: sourceDocumentId,
    createdAt: createdAt ?? fixtureNow,
    updatedAt: updatedAt,
  );
}

Map<String, dynamic> makeDeadlineJson({
  String id = 'dl-001',
  String caseId = 'case-001',
  String userId = 'user-001',
  String title = 'Appeal deadline',
  String? description,
  String? dueDate,
  String? type,
  String? priority,
  String? status,
  bool? notificationScheduled,
  int? reminderDaysBefore,
  String? source,
  String? sourceDocumentId,
  String? createdAt,
  String? updatedAt,
}) {
  return {
    'id': id,
    'case_id': caseId,
    'user_id': userId,
    'title': title,
    'description': description,
    'due_date': dueDate ?? fixtureFuture.toIso8601String(),
    'type': type,
    'priority': priority,
    'status': status,
    'notification_scheduled': notificationScheduled,
    'reminder_days_before': reminderDaysBefore,
    'source': source,
    'source_document_id': sourceDocumentId,
    'created_at': createdAt ?? fixtureNow.toIso8601String(),
    'updated_at': updatedAt,
  };
}

// ---------------------------------------------------------------------------
// Correspondence fixtures
// ---------------------------------------------------------------------------

Correspondence makeCorrespondence({
  String id = 'corr-001',
  String caseId = 'case-001',
  String userId = 'user-001',
  String subject = 'Test Subject',
  String body = 'Test body text',
  String sender = 'sender@test.ee',
  String recipient = 'recipient@test.ee',
  CorrespondenceDirection direction = CorrespondenceDirection.incoming,
  CorrespondenceChannel channel = CorrespondenceChannel.email,
  String? aiSummary,
  List<String> extractedActionItems = const [],
  List<String> attachmentIds = const [],
  bool isRead = false,
  DateTime? sentAt,
  DateTime? createdAt,
}) {
  return Correspondence(
    id: id,
    caseId: caseId,
    userId: userId,
    subject: subject,
    body: body,
    sender: sender,
    recipient: recipient,
    direction: direction,
    channel: channel,
    aiSummary: aiSummary,
    extractedActionItems: extractedActionItems,
    attachmentIds: attachmentIds,
    isRead: isRead,
    sentAt: sentAt ?? fixtureNow,
    createdAt: createdAt ?? fixtureNow,
  );
}

Map<String, dynamic> makeCorrespondenceJson({
  String id = 'corr-001',
  String caseId = 'case-001',
  String userId = 'user-001',
  String subject = 'Test Subject',
  String body = 'Test body text',
  String sender = 'sender@test.ee',
  String recipient = 'recipient@test.ee',
  String direction = 'incoming',
  String? channel,
  String? aiSummary,
  List<String>? extractedActionItems,
  List<String>? attachmentIds,
  bool? isRead,
  String? sentAt,
  String? createdAt,
}) {
  return {
    'id': id,
    'case_id': caseId,
    'user_id': userId,
    'subject': subject,
    'body': body,
    'sender': sender,
    'recipient': recipient,
    'direction': direction,
    'channel': channel,
    'ai_summary': aiSummary,
    'extracted_action_items': extractedActionItems,
    'attachment_ids': attachmentIds,
    'is_read': isRead,
    'sent_at': sentAt ?? fixtureNow.toIso8601String(),
    'created_at': createdAt ?? fixtureNow.toIso8601String(),
  };
}
