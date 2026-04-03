import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/case_model.dart';
import '../models/correspondence.dart';
import '../models/deadline.dart';
import '../models/document.dart';
import '../models/user.dart';

// ---------------------------------------------------------------------------
// Demo mode state -- global flag checked by providers
// ---------------------------------------------------------------------------

/// Whether the app is running in demo mode (no backend).
final isDemoModeProvider = StateProvider<bool>((ref) => false);

// ---------------------------------------------------------------------------
// Demo data for the Finland deportation case
// ---------------------------------------------------------------------------

abstract final class DemoData {
  // -- User --

  static final AppUser user = AppUser(
    id: 'demo-user-001',
    email: 'dmitri.sulga@example.com',
    fullName: 'Dmitri Sulga',
    phone: '+358 40 123 4567',
    preferredLanguage: 'en',
    subscriptionTier: SubscriptionTier.premium,
    subscriptionExpiresAt: DateTime.now().add(const Duration(days: 365)),
    createdAt: DateTime.now().subtract(const Duration(days: 90)),
    updatedAt: DateTime.now(),
  );

  // -- Cases --

  static const String mainCaseId = 'case-finland-001';

  static final List<LegalCase> cases = [
    LegalCase(
      id: mainCaseId,
      userId: 'demo-user-001',
      title: 'Deportation Order Appeal — Finland',
      description:
          'Appeal against deportation decision by Migri. Police issued the '
          'decision in Russian only, signed by wrong officer, and referenced '
          '"Soviet Union" as country of origin. Multiple procedural violations '
          'detected by AI analysis.',
      type: CaseType.deportation,
      status: CaseStatus.appealFiled,
      migriReferenceNumber: 'UMA/2025/00431',
      courtCaseNumber: 'HAO 2025/1234',
      nationality: 'Estonian',
      decisionDate: DateTime.now().subtract(const Duration(days: 35)),
      appealDeadline: DateTime.now().add(const Duration(days: 10)),
      hearingDate: DateTime.now().add(const Duration(days: 45)),
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 3)),
      documentCount: 5,
      unreadMessages: 2,
    ),
    LegalCase(
      id: 'case-finland-002',
      userId: 'demo-user-001',
      title: 'Residence Permit Renewal',
      description:
          'Application for extended residence permit based on employment in Finland.',
      type: CaseType.residencePermit,
      status: CaseStatus.pendingDecision,
      migriReferenceNumber: 'UMA/2025/00589',
      nationality: 'Estonian',
      createdAt: DateTime.now().subtract(const Duration(days: 55)),
      updatedAt: DateTime.now().subtract(const Duration(days: 2)),
      documentCount: 3,
      unreadMessages: 0,
    ),
    LegalCase(
      id: 'case-germany-003',
      userId: 'demo-user-001',
      title: 'Unfair Dismissal — Germany',
      description:
          'Wrongful termination from employment without proper notice period. '
          'Employer failed to follow K\u00FCndigungsschutzgesetz (Employment Protection Act) '
          'requirements. No prior warning was given and the works council was not consulted.',
      type: CaseType.laborDispute,
      status: CaseStatus.active,
      nationality: 'Estonian',
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
      updatedAt: DateTime.now().subtract(const Duration(days: 1)),
      documentCount: 2,
      unreadMessages: 1,
    ),
    LegalCase(
      id: 'case-finland-004',
      userId: 'demo-user-001',
      title: 'Illegal Eviction Notice — Finland',
      description:
          'Landlord issued an eviction notice without valid legal grounds '
          'and with insufficient notice period. The notice violates the Finnish '
          'Act on Residential Leases (Laki asuinhuoneiston vuokrauksesta) '
          'regarding tenant protections and required notice periods.',
      type: CaseType.tenantRights,
      status: CaseStatus.active,
      nationality: 'Estonian',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 12)),
      documentCount: 1,
      unreadMessages: 1,
    ),
  ];

  // -- Documents --

  static final List<CaseDocument> documents = [
    CaseDocument(
      id: 'doc-001',
      caseId: mainCaseId,
      userId: 'demo-user-001',
      fileName: 'Police_Decision_Deportation.pdf',
      storagePath: 'demo/doc-001.pdf',
      mimeType: 'application/pdf',
      fileSizeBytes: 245000,
      category: DocumentCategory.decision,
      language: 'ru',
      ocrText: _policeDecisionOcrText,
      aiSummary:
          'Deportation decision issued by Helsinki Police. Contains 3 critical '
          'procedural errors: wrong language (Russian instead of Finnish/English), '
          'signed by unauthorized officer, references non-existent country '
          '"Soviet Union".',
      extractedEntities: {
        'authority': 'Helsinki Police Department',
        'decision_date': '2025-03-01',
        'appeal_deadline': '2025-04-15',
      },
      processingStatus: DocumentProcessingStatus.completed,
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
    ),
    CaseDocument(
      id: 'doc-002',
      caseId: mainCaseId,
      userId: 'demo-user-001',
      fileName: 'Appeal_Draft_v2.pdf',
      storagePath: 'demo/doc-002.pdf',
      mimeType: 'application/pdf',
      fileSizeBytes: 189000,
      category: DocumentCategory.appeal,
      language: 'fi',
      aiSummary:
          'Draft appeal document addressing the three procedural violations '
          'found in the police decision. References Hallintolaki and '
          'Ulkomaalaislaki.',
      processingStatus: DocumentProcessingStatus.completed,
      createdAt: DateTime.now().subtract(const Duration(days: 27)),
    ),
    CaseDocument(
      id: 'doc-003',
      caseId: mainCaseId,
      userId: 'demo-user-001',
      fileName: 'Medical_Certificate_2025.pdf',
      storagePath: 'demo/doc-003.pdf',
      mimeType: 'application/pdf',
      fileSizeBytes: 98000,
      category: DocumentCategory.medical,
      language: 'fi',
      aiSummary:
          'Medical certificate from Helsinki University Hospital confirming '
          'ongoing medical treatment. Relevant for humanitarian grounds.',
      processingStatus: DocumentProcessingStatus.completed,
      createdAt: DateTime.now().subtract(const Duration(days: 25)),
    ),
    CaseDocument(
      id: 'doc-004',
      caseId: mainCaseId,
      userId: 'demo-user-001',
      fileName: 'Employment_Contract.pdf',
      storagePath: 'demo/doc-004.pdf',
      mimeType: 'application/pdf',
      fileSizeBytes: 156000,
      category: DocumentCategory.employment,
      language: 'en',
      aiSummary:
          'Full-time employment contract with a Finnish company. '
          'Supports the case for continued residency.',
      processingStatus: DocumentProcessingStatus.completed,
      createdAt: DateTime.now().subtract(const Duration(days: 23)),
    ),
    CaseDocument(
      id: 'doc-005',
      caseId: mainCaseId,
      userId: 'demo-user-001',
      fileName: 'RIKU_Support_Letter.pdf',
      storagePath: 'demo/doc-005.pdf',
      mimeType: 'application/pdf',
      fileSizeBytes: 67000,
      category: DocumentCategory.evidence,
      language: 'fi',
      aiSummary:
          'Support letter from RIKU (Victim Support Finland) confirming '
          'participation in their program.',
      processingStatus: DocumentProcessingStatus.completed,
      createdAt: DateTime.now().subtract(const Duration(days: 21)),
    ),
  ];

  // -- Deadlines --

  static final List<Deadline> deadlines = [
    Deadline(
      id: 'dl-001',
      caseId: mainCaseId,
      userId: 'demo-user-001',
      title: 'Lawyer consultation call',
      description:
          'Scheduled call with legal aid lawyer to review appeal strategy.',
      dueDate: DateTime.now().add(const Duration(days: 7)),
      type: DeadlineType.other,
      priority: DeadlinePriority.high,
      status: DeadlineStatus.upcoming,
      source: DeadlineSource.manual,
      createdAt: DateTime.now().subtract(const Duration(days: 15)),
    ),
    Deadline(
      id: 'dl-002',
      caseId: mainCaseId,
      userId: 'demo-user-001',
      title: 'Court response to appeal',
      description:
          'Expected date for Helsinki Administrative Court to acknowledge '
          'receipt of appeal and provide case number.',
      dueDate: DateTime.now().add(const Duration(days: 14)),
      type: DeadlineType.responseRequired,
      priority: DeadlinePriority.high,
      status: DeadlineStatus.upcoming,
      source: DeadlineSource.aiExtracted,
      sourceDocumentId: 'doc-001',
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
    ),
    Deadline(
      id: 'dl-003',
      caseId: mainCaseId,
      userId: 'demo-user-001',
      title: 'Appeal filing deadline',
      description:
          'Last day to file the appeal with Helsinki Administrative Court. '
          '30 days from the date of the deportation decision.',
      dueDate: DateTime.now().add(const Duration(days: 10)),
      type: DeadlineType.appeal,
      priority: DeadlinePriority.critical,
      status: DeadlineStatus.upcoming,
      source: DeadlineSource.aiExtracted,
      sourceDocumentId: 'doc-001',
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
    ),
    Deadline(
      id: 'dl-004',
      caseId: mainCaseId,
      userId: 'demo-user-001',
      title: 'Court hearing',
      description:
          'Oral hearing at Helsinki Administrative Court regarding the '
          'deportation appeal.',
      dueDate: DateTime.now().add(const Duration(days: 45)),
      type: DeadlineType.hearing,
      priority: DeadlinePriority.critical,
      status: DeadlineStatus.upcoming,
      source: DeadlineSource.manual,
      createdAt: DateTime.now().subtract(const Duration(days: 20)),
    ),
    Deadline(
      id: 'dl-005',
      caseId: 'case-finland-002',
      userId: 'demo-user-001',
      title: 'Residence permit interview',
      description: 'Interview at Migri Helsinki office.',
      dueDate: DateTime.now().add(const Duration(days: 21)),
      type: DeadlineType.hearing,
      priority: DeadlinePriority.medium,
      status: DeadlineStatus.upcoming,
      source: DeadlineSource.manual,
      createdAt: DateTime.now().subtract(const Duration(days: 37)),
    ),
  ];

  // -- Correspondence --

  static final List<Correspondence> correspondence = [
    Correspondence(
      id: 'corr-001',
      caseId: mainCaseId,
      userId: 'demo-user-001',
      subject: 'Deportation decision — Notification',
      body:
          'Dear Mr. Sulga,\n\nPlease find attached the decision regarding '
          'your deportation case (UMA/2025/00431).\n\nYou have the right to '
          'appeal this decision within 30 days.\n\nHelsinki Police Department',
      sender: 'helsinki.poliisi@poliisi.fi',
      recipient: 'dmitri.sulga@example.com',
      direction: CorrespondenceDirection.incoming,
      channel: CorrespondenceChannel.email,
      aiSummary:
          'Official notification of deportation decision. Contains 30-day '
          'appeal deadline.',
      extractedActionItems: [
        'File appeal within 30 days',
        'Contact legal aid',
      ],
      isRead: true,
      sentAt: DateTime.now().subtract(const Duration(days: 35)),
      createdAt: DateTime.now().subtract(const Duration(days: 35)),
    ),
    Correspondence(
      id: 'corr-002',
      caseId: mainCaseId,
      userId: 'demo-user-001',
      subject: 'Appeal against deportation decision UMA/2025/00431',
      body:
          'To: Helsinki Administrative Court\n\nI hereby appeal the deportation '
          'decision UMA/2025/00431 issued on 01.03.2025 by the Helsinki Police '
          'Department.\n\nThe decision contains multiple procedural errors...',
      sender: 'dmitri.sulga@example.com',
      recipient: 'helsinki.hao@oikeus.fi',
      direction: CorrespondenceDirection.outgoing,
      channel: CorrespondenceChannel.email,
      aiSummary: 'Appeal filing sent to Helsinki Administrative Court.',
      isRead: true,
      sentAt: DateTime.now().subtract(const Duration(days: 25)),
      createdAt: DateTime.now().subtract(const Duration(days: 25)),
    ),
    Correspondence(
      id: 'corr-003',
      caseId: mainCaseId,
      userId: 'demo-user-001',
      subject: 'Case HAO 2025/1234 — Appeal received',
      body:
          'Dear Mr. Sulga,\n\nYour appeal regarding deportation decision '
          'UMA/2025/00431 has been received and registered under case number '
          'HAO 2025/1234.\n\nYou will be notified of the hearing date.\n\n'
          'Helsinki Administrative Court',
      sender: 'helsinki.hao@oikeus.fi',
      recipient: 'dmitri.sulga@example.com',
      direction: CorrespondenceDirection.incoming,
      channel: CorrespondenceChannel.email,
      aiSummary:
          'Court confirmed receipt of appeal. Case number HAO 2025/1234 assigned.',
      extractedActionItems: ['Wait for hearing date notification'],
      isRead: true,
      sentAt: DateTime.now().subtract(const Duration(days: 20)),
      createdAt: DateTime.now().subtract(const Duration(days: 20)),
    ),
    Correspondence(
      id: 'corr-004',
      caseId: mainCaseId,
      userId: 'demo-user-001',
      subject: 'RIKU victim support — Case referral',
      body:
          'Dear Mr. Sulga,\n\nWe are writing to confirm your participation '
          'in the RIKU victim support program. We have provided a support letter '
          'to your legal representative.\n\nRIKU Finland',
      sender: 'support@riku.fi',
      recipient: 'dmitri.sulga@example.com',
      direction: CorrespondenceDirection.incoming,
      channel: CorrespondenceChannel.email,
      aiSummary: 'RIKU confirms support program participation.',
      isRead: false,
      sentAt: DateTime.now().subtract(const Duration(days: 17)),
      createdAt: DateTime.now().subtract(const Duration(days: 17)),
    ),
  ];

  // -- Chat messages (realistic conversation) --

  static final List<Map<String, dynamic>> chatMessages = [
    {
      'id': 'msg-001',
      'role': 'assistant',
      'content':
          '\u041F\u0440\u0438\u0432\u0435\u0442! \u042F \u0432\u0430\u0448 \u044E\u0440\u0438\u0434\u0438\u0447\u0435\u0441\u043A\u0438\u0439 \u043F\u043E\u043C\u043E\u0449\u043D\u0438\u043A. \u0420\u0430\u0441\u0441\u043A\u0430\u0436\u0438\u0442\u0435, '
          '\u0447\u0442\u043E \u0443 \u0432\u0430\u0441 \u0441\u043B\u0443\u0447\u0438\u043B\u043E\u0441\u044C \u2014 \u044F \u043F\u0440\u043E\u0430\u043D\u0430\u043B\u0438\u0437\u0438\u0440\u0443\u044E \u0441\u0438\u0442\u0443\u0430\u0446\u0438\u044E '
          '\u0438 \u043F\u043E\u0434\u0441\u043A\u0430\u0436\u0443 \u0447\u0442\u043E \u0434\u0435\u043B\u0430\u0442\u044C.',
      'created_at': DateTime.now().subtract(const Duration(days: 30, hours: 2)).toIso8601String(),
    },
    {
      'id': 'msg-002',
      'role': 'user',
      'content':
          '\u041C\u0435\u043D\u044F \u0434\u0435\u043F\u043E\u0440\u0442\u0438\u0440\u043E\u0432\u0430\u043B\u0438 \u0438\u0437 \u0424\u0438\u043D\u043B\u044F\u043D\u0434\u0438\u0438, '
          '\u043F\u043E\u043B\u0438\u0446\u0438\u044F \u0441\u043A\u0430\u0437\u0430\u043B\u0430 \u0447\u0442\u043E \u044F \u0443\u043A\u0440\u0430\u043B \u0432 \u043C\u0430\u0433\u0430\u0437\u0438\u043D\u0435',
      'created_at': DateTime.now().subtract(const Duration(days: 30, hours: 1, minutes: 59)).toIso8601String(),
    },
    {
      'id': 'msg-003',
      'role': 'assistant',
      'content':
          '\u041F\u043E\u043D\u044F\u043B \u0432\u0430\u0448\u0443 \u0441\u0438\u0442\u0443\u0430\u0446\u0438\u044E. \u0412\u043E\u0442 \u0447\u0442\u043E \u044F \u0432\u0438\u0436\u0443:\n'
          '\n'
          '\u26A0\uFE0F \u0414\u0435\u043F\u043E\u0440\u0442\u0430\u0446\u0438\u044F \u0437\u0430 \u043A\u0440\u0430\u0436\u0443 \u0432 \u043C\u0430\u0433\u0430\u0437\u0438\u043D\u0435 \u2014 '
          '\u044D\u0442\u043E **\u043E\u0447\u0435\u043D\u044C \u0441\u0442\u0440\u043E\u0433\u0430\u044F \u043C\u0435\u0440\u0430**. '
          '\u041E\u0431\u044B\u0447\u043D\u043E \u0437\u0430 \u043C\u0435\u043B\u043A\u0443\u044E \u043A\u0440\u0430\u0436\u0443 \u043D\u0435 \u0434\u0435\u043F\u043E\u0440\u0442\u0438\u0440\u0443\u044E\u0442. '
          '\u042D\u0442\u043E \u0437\u043D\u0430\u0447\u0438\u0442, \u0447\u0442\u043E \u0440\u0435\u0448\u0435\u043D\u0438\u0435 \u043C\u043E\u0433\u043B\u043E \u0431\u044B\u0442\u044C '
          '\u043F\u0440\u0438\u043D\u044F\u0442\u043E \u0441 \u043D\u0430\u0440\u0443\u0448\u0435\u043D\u0438\u044F\u043C\u0438.\n'
          '\n'
          '\u041C\u043D\u0435 \u043D\u0443\u0436\u043D\u043E \u043F\u0440\u043E\u0432\u0435\u0440\u0438\u0442\u044C \u043D\u0435\u0441\u043A\u043E\u043B\u044C\u043A\u043E \u0432\u0435\u0449\u0435\u0439:\n'
          '\n'
          '[ ] \u041D\u0430 \u043A\u0430\u043A\u043E\u043C \u044F\u0437\u044B\u043A\u0435 \u0432\u044B\u0434\u0430\u043D\u043E \u0440\u0435\u0448\u0435\u043D\u0438\u0435?\n'
          '[ ] \u041A\u0442\u043E \u043F\u043E\u0434\u043F\u0438\u0441\u0430\u043B \u0440\u0435\u0448\u0435\u043D\u0438\u0435?\n'
          '[ ] \u041F\u0440\u0430\u0432\u0438\u043B\u044C\u043D\u043E \u043B\u0438 \u0443\u043A\u0430\u0437\u0430\u043D\u044B \u0432\u0430\u0448\u0438 \u0434\u0430\u043D\u043D\u044B\u0435?\n'
          '[ ] \u0421\u043E\u0431\u043B\u044E\u0434\u0435\u043D\u044B \u043B\u0438 \u0441\u0440\u043E\u043A\u0438?\n'
          '\n'
          '\u041C\u043E\u0436\u0435\u0442\u0435 \u0441\u0444\u043E\u0442\u043E\u0433\u0440\u0430\u0444\u0438\u0440\u043E\u0432\u0430\u0442\u044C \u0440\u0435\u0448\u0435\u043D\u0438\u0435 \u043F\u043E\u043B\u0438\u0446\u0438\u0438? '
          '\u042F \u043F\u0440\u043E\u0430\u043D\u0430\u043B\u0438\u0437\u0438\u0440\u0443\u044E \u0435\u0433\u043E \u043D\u0430 \u043E\u0448\u0438\u0431\u043A\u0438.',
      'created_at': DateTime.now().subtract(const Duration(days: 30, hours: 1, minutes: 58)).toIso8601String(),
    },
    {
      'id': 'msg-004',
      'role': 'user',
      'content':
          '\u0412\u043E\u0442 \u0440\u0435\u0448\u0435\u043D\u0438\u0435',
      'created_at': DateTime.now().subtract(const Duration(days: 30, hours: 1, minutes: 55)).toIso8601String(),
      'has_attachment': true,
    },
    {
      'id': 'msg-005',
      'role': 'assistant',
      'content':
          '\u041F\u0440\u043E\u0430\u043D\u0430\u043B\u0438\u0437\u0438\u0440\u043E\u0432\u0430\u043B \u0434\u043E\u043A\u0443\u043C\u0435\u043D\u0442. '
          '**\u041D\u0430\u0448\u0451\u043B 3 \u0441\u0435\u0440\u044C\u0451\u0437\u043D\u044B\u0435 \u043E\u0448\u0438\u0431\u043A\u0438:**\n'
          '\n'
          '\uD83D\uDD34 \u0420\u0435\u0448\u0435\u043D\u0438\u0435 \u0432\u044B\u0434\u0430\u043D\u043E \u0442\u043E\u043B\u044C\u043A\u043E \u043D\u0430 \u0440\u0443\u0441\u0441\u043A\u043E\u043C \u044F\u0437\u044B\u043A\u0435. '
          '\u041F\u043E \u0437\u0430\u043A\u043E\u043D\u0443 \u0434\u043E\u043B\u0436\u043D\u043E \u0431\u044B\u0442\u044C \u043D\u0430 \u0444\u0438\u043D\u0441\u043A\u043E\u043C \u0438\u043B\u0438 \u0448\u0432\u0435\u0434\u0441\u043A\u043E\u043C '
          '\u0441 \u043F\u0435\u0440\u0435\u0432\u043E\u0434\u043E\u043C (**Hallintolaki \u00A726**). '
          '\u042D\u0442\u043E \u043C\u043E\u0436\u0435\u0442 **\u043F\u043E\u043B\u043D\u043E\u0441\u0442\u044C\u044E \u043E\u0442\u043C\u0435\u043D\u0438\u0442\u044C** \u0440\u0435\u0448\u0435\u043D\u0438\u0435.\n'
          '\n'
          '\uD83D\uDD34 \u041F\u043E\u0434\u043F\u0438\u0441\u0430\u043B \u0441\u0442\u0430\u0440\u0448\u0438\u0439 \u043A\u043E\u043D\u0441\u0442\u0435\u0431\u043B\u044C, '
          '\u0430 \u0440\u0435\u0448\u0435\u043D\u0438\u0435 \u043E \u0434\u0435\u043F\u043E\u0440\u0442\u0430\u0446\u0438\u0438 \u043C\u043E\u0436\u0435\u0442 \u043F\u043E\u0434\u043F\u0438\u0441\u0430\u0442\u044C '
          '\u0442\u043E\u043B\u044C\u043A\u043E \u0443\u043F\u043E\u043B\u043D\u043E\u043C\u043E\u0447\u0435\u043D\u043D\u044B\u0439 \u043E\u0444\u0438\u0446\u0435\u0440 (**Ulkomaalaislaki \u00A7152**). '
          '\u041D\u0435\u043F\u0440\u0430\u0432\u0438\u043B\u044C\u043D\u0430\u044F \u043F\u043E\u0434\u043F\u0438\u0441\u044C = **\u0440\u0435\u0448\u0435\u043D\u0438\u0435 \u043D\u0435\u0434\u0435\u0439\u0441\u0442\u0432\u0438\u0442\u0435\u043B\u044C\u043D\u043E**.\n'
          '\n'
          '\uD83D\uDFE1 \u0412 \u0433\u0440\u0430\u0444\u0435 \u0433\u0440\u0430\u0436\u0434\u0430\u043D\u0441\u0442\u0432\u043E \u043D\u0430\u043F\u0438\u0441\u0430\u043D\u043E '
          '"\u0421\u043E\u0432\u0435\u0442\u0441\u043A\u0438\u0439 \u0421\u043E\u044E\u0437" \u2014 \u044D\u0442\u0430 \u0441\u0442\u0440\u0430\u043D\u0430 \u043D\u0435 \u0441\u0443\u0449\u0435\u0441\u0442\u0432\u0443\u0435\u0442 \u0441 1991 \u0433\u043E\u0434\u0430. '
          '\u0412\u044B \u0433\u0440\u0430\u0436\u0434\u0430\u043D\u0438\u043D \u042D\u0441\u0442\u043E\u043D\u0438\u0438 (\u0415\u0421!). '
          '\u042D\u0442\u043E \u043F\u043E\u043A\u0430\u0437\u044B\u0432\u0430\u0435\u0442, \u0447\u0442\u043E \u0434\u0435\u043B\u043E \u043D\u0435 \u0431\u044B\u043B\u043E \u043D\u043E\u0440\u043C\u0430\u043B\u044C\u043D\u043E \u0438\u0437\u0443\u0447\u0435\u043D\u043E.\n'
          '\n'
          '\u0421\u0438\u0442\u0443\u0430\u0446\u0438\u044F \u0441\u0435\u0440\u044C\u0451\u0437\u043D\u0430\u044F, \u043D\u043E **\u0443 \u0432\u0430\u0441 \u043E\u0447\u0435\u043D\u044C \u0441\u0438\u043B\u044C\u043D\u044B\u0435 \u043E\u0441\u043D\u043E\u0432\u0430\u043D\u0438\u044F \u0434\u043B\u044F \u043E\u0431\u0436\u0430\u043B\u043E\u0432\u0430\u043D\u0438\u044F**.\n'
          '\n'
          '\uD83D\uDCCB \u0412\u043E\u0442 \u0447\u0442\u043E \u043D\u0443\u0436\u043D\u043E \u0441\u0434\u0435\u043B\u0430\u0442\u044C \u0434\u0430\u043B\u044C\u0448\u0435:\n'
          '1. \u041F\u043E\u0434\u0430\u0442\u044C \u0436\u0430\u043B\u043E\u0431\u0443 \u0432 **Helsinki Administrative Court** (\u0441\u0440\u043E\u043A \u2014 30 \u0434\u043D\u0435\u0439 \u043E\u0442 \u0440\u0435\u0448\u0435\u043D\u0438\u044F)\n'
          '2. \u041E\u0431\u0440\u0430\u0442\u0438\u0442\u044C\u0441\u044F \u0437\u0430 **\u0431\u0435\u0441\u043F\u043B\u0430\u0442\u043D\u043E\u0439 \u044E\u0440\u0438\u0434\u0438\u0447\u0435\u0441\u043A\u043E\u0439 \u043F\u043E\u043C\u043E\u0449\u044C\u044E** (oikeusapu)\n'
          '3. \u042F \u043C\u043E\u0433\u0443 \u043F\u043E\u0434\u0433\u043E\u0442\u043E\u0432\u0438\u0442\u044C \u0447\u0435\u0440\u043D\u043E\u0432\u0438\u043A \u0436\u0430\u043B\u043E\u0431\u044B \u043F\u0440\u044F\u043C\u043E \u0441\u0435\u0439\u0447\u0430\u0441\n'
          '\n'
          '\u26A0\uFE0F \u042D\u0442\u043E \u0438\u043D\u0444\u043E\u0440\u043C\u0430\u0446\u0438\u044F, \u043D\u0435 \u044E\u0440\u0438\u0434\u0438\u0447\u0435\u0441\u043A\u0430\u044F \u043A\u043E\u043D\u0441\u0443\u043B\u044C\u0442\u0430\u0446\u0438\u044F. \u041F\u0440\u043E\u0432\u0435\u0440\u044C\u0442\u0435 \u0441 \u0430\u0434\u0432\u043E\u043A\u0430\u0442\u043E\u043C.',
      'created_at': DateTime.now().subtract(const Duration(days: 30, hours: 1, minutes: 54)).toIso8601String(),
    },
  ];

  // -- Mock AI responses for chat --

  static const Map<String, String> chatResponses = {
    'default':
        '\u041F\u043E\u043D\u044F\u043B. \u0412\u043E\u0442 \u0447\u0442\u043E \u044F \u0440\u0435\u043A\u043E\u043C\u0435\u043D\u0434\u0443\u044E \u0441\u0434\u0435\u043B\u0430\u0442\u044C:\n\n'
        '1. \u0421\u0444\u043E\u0442\u043E\u0433\u0440\u0430\u0444\u0438\u0440\u0443\u0439\u0442\u0435 \u0432\u0441\u0435 \u0434\u043E\u043A\u0443\u043C\u0435\u043D\u0442\u044B \u043F\u043E \u0434\u0435\u043B\u0443 \u2014 \u044F \u043F\u0440\u043E\u0430\u043D\u0430\u043B\u0438\u0437\u0438\u0440\u0443\u044E \u0438\u0445 \u043D\u0430 \u043E\u0448\u0438\u0431\u043A\u0438\n'
        '2. \u0417\u0430\u043F\u0438\u0448\u0438\u0442\u0435 \u0432\u0441\u0435 \u0434\u0430\u0442\u044B \u2014 \u0441\u0440\u043E\u043A\u0438 \u043E\u0431\u0436\u0430\u043B\u043E\u0432\u0430\u043D\u0438\u044F \u043E\u0433\u0440\u0430\u043D\u0438\u0447\u0435\u043D\u044B\n'
        '3. \u041D\u0435 \u043F\u043E\u0434\u043F\u0438\u0441\u044B\u0432\u0430\u0439\u0442\u0435 \u043D\u0438\u0447\u0435\u0433\u043E, \u043F\u043E\u043A\u0430 \u043D\u0435 \u0440\u0430\u0437\u043E\u0431\u0440\u0430\u043B\u0438\u0441\u044C\n\n'
        '\u0427\u0442\u043E \u0438\u043C\u0435\u043D\u043D\u043E \u0432\u0430\u0441 \u0431\u0435\u0441\u043F\u043E\u043A\u043E\u0438\u0442 \u0431\u043E\u043B\u044C\u0448\u0435 \u0432\u0441\u0435\u0433\u043E?',
    'situation':
        '\u041F\u043E\u043D\u044F\u043B \u0432\u0430\u0448\u0443 \u0441\u0438\u0442\u0443\u0430\u0446\u0438\u044E. \u0412\u043E\u0442 \u0447\u0442\u043E \u044F \u0432\u0438\u0436\u0443:\n\n'
        '\u26A0\uFE0F \u0414\u0435\u043F\u043E\u0440\u0442\u0430\u0446\u0438\u044F \u0437\u0430 \u043A\u0440\u0430\u0436\u0443 \u0432 \u043C\u0430\u0433\u0430\u0437\u0438\u043D\u0435 \u2014 '
        '\u044D\u0442\u043E **\u043E\u0447\u0435\u043D\u044C \u0441\u0442\u0440\u043E\u0433\u0430\u044F \u043C\u0435\u0440\u0430**. '
        '\u041E\u0431\u044B\u0447\u043D\u043E \u0437\u0430 \u043C\u0435\u043B\u043A\u0443\u044E \u043A\u0440\u0430\u0436\u0443 \u043D\u0435 \u0434\u0435\u043F\u043E\u0440\u0442\u0438\u0440\u0443\u044E\u0442. '
        '\u042D\u0442\u043E \u0437\u043D\u0430\u0447\u0438\u0442, \u0447\u0442\u043E \u0440\u0435\u0448\u0435\u043D\u0438\u0435 \u043C\u043E\u0433\u043B\u043E \u0431\u044B\u0442\u044C '
        '\u043F\u0440\u0438\u043D\u044F\u0442\u043E \u0441 \u043D\u0430\u0440\u0443\u0448\u0435\u043D\u0438\u044F\u043C\u0438.\n\n'
        '\u041C\u043D\u0435 \u043D\u0443\u0436\u043D\u043E \u043F\u0440\u043E\u0432\u0435\u0440\u0438\u0442\u044C \u043D\u0435\u0441\u043A\u043E\u043B\u044C\u043A\u043E \u0432\u0435\u0449\u0435\u0439:\n\n'
        '[ ] \u041D\u0430 \u043A\u0430\u043A\u043E\u043C \u044F\u0437\u044B\u043A\u0435 \u0432\u044B\u0434\u0430\u043D\u043E \u0440\u0435\u0448\u0435\u043D\u0438\u0435?\n'
        '[ ] \u041A\u0442\u043E \u043F\u043E\u0434\u043F\u0438\u0441\u0430\u043B \u0440\u0435\u0448\u0435\u043D\u0438\u0435?\n'
        '[ ] \u041F\u0440\u0430\u0432\u0438\u043B\u044C\u043D\u043E \u043B\u0438 \u0443\u043A\u0430\u0437\u0430\u043D\u044B \u0432\u0430\u0448\u0438 \u0434\u0430\u043D\u043D\u044B\u0435?\n'
        '[ ] \u0421\u043E\u0431\u043B\u044E\u0434\u0435\u043D\u044B \u043B\u0438 \u0441\u0440\u043E\u043A\u0438?\n\n'
        '\u041C\u043E\u0436\u0435\u0442\u0435 \u0441\u0444\u043E\u0442\u043E\u0433\u0440\u0430\u0444\u0438\u0440\u043E\u0432\u0430\u0442\u044C \u0440\u0435\u0448\u0435\u043D\u0438\u0435 \u043F\u043E\u043B\u0438\u0446\u0438\u0438? '
        '\u042F \u043F\u0440\u043E\u0430\u043D\u0430\u043B\u0438\u0437\u0438\u0440\u0443\u044E \u0435\u0433\u043E \u043D\u0430 \u043E\u0448\u0438\u0431\u043A\u0438.',
    'document_analysis':
        '\u041F\u0440\u043E\u0430\u043D\u0430\u043B\u0438\u0437\u0438\u0440\u043E\u0432\u0430\u043B \u0434\u043E\u043A\u0443\u043C\u0435\u043D\u0442. '
        '**\u041D\u0430\u0448\u0451\u043B 3 \u0441\u0435\u0440\u044C\u0451\u0437\u043D\u044B\u0435 \u043E\u0448\u0438\u0431\u043A\u0438:**\n\n'
        '\uD83D\uDD34 \u0420\u0435\u0448\u0435\u043D\u0438\u0435 \u0432\u044B\u0434\u0430\u043D\u043E \u0442\u043E\u043B\u044C\u043A\u043E \u043D\u0430 \u0440\u0443\u0441\u0441\u043A\u043E\u043C \u044F\u0437\u044B\u043A\u0435. '
        '\u041F\u043E \u0437\u0430\u043A\u043E\u043D\u0443 \u0434\u043E\u043B\u0436\u043D\u043E \u0431\u044B\u0442\u044C \u043D\u0430 \u0444\u0438\u043D\u0441\u043A\u043E\u043C/\u0448\u0432\u0435\u0434\u0441\u043A\u043E\u043C '
        '\u0441 \u043F\u0435\u0440\u0435\u0432\u043E\u0434\u043E\u043C (**Hallintolaki \u00A726**). '
        '\u042D\u0442\u043E \u043C\u043E\u0436\u0435\u0442 **\u043F\u043E\u043B\u043D\u043E\u0441\u0442\u044C\u044E \u043E\u0442\u043C\u0435\u043D\u0438\u0442\u044C** \u0440\u0435\u0448\u0435\u043D\u0438\u0435.\n\n'
        '\uD83D\uDD34 \u041F\u043E\u0434\u043F\u0438\u0441\u0430\u043B \u0441\u0442\u0430\u0440\u0448\u0438\u0439 \u043A\u043E\u043D\u0441\u0442\u0435\u0431\u043B\u044C \u2014 \u043D\u0435 \u0438\u043C\u0435\u0435\u0442 \u043F\u0440\u0430\u0432\u0430 '
        '\u043F\u043E\u0434\u043F\u0438\u0441\u044B\u0432\u0430\u0442\u044C \u0442\u0430\u043A\u0438\u0435 \u0440\u0435\u0448\u0435\u043D\u0438\u044F (**Ulkomaalaislaki \u00A7152**). '
        '\u041D\u0435\u043F\u0440\u0430\u0432\u0438\u043B\u044C\u043D\u0430\u044F \u043F\u043E\u0434\u043F\u0438\u0441\u044C = **\u0440\u0435\u0448\u0435\u043D\u0438\u0435 \u043D\u0435\u0434\u0435\u0439\u0441\u0442\u0432\u0438\u0442\u0435\u043B\u044C\u043D\u043E**.\n\n'
        '\uD83D\uDFE1 \u0413\u0440\u0430\u0436\u0434\u0430\u043D\u0441\u0442\u0432\u043E \u0443\u043A\u0430\u0437\u0430\u043D\u043E "\u0421\u043E\u0432\u0435\u0442\u0441\u043A\u0438\u0439 \u0421\u043E\u044E\u0437" \u2014 \u0441\u0442\u0440\u0430\u043D\u0430 \u043D\u0435 \u0441\u0443\u0449\u0435\u0441\u0442\u0432\u0443\u0435\u0442 \u0441 1991. '
        '\u0412\u044B \u0433\u0440\u0430\u0436\u0434\u0430\u043D\u0438\u043D \u042D\u0441\u0442\u043E\u043D\u0438\u0438 (\u0415\u0421!). '
        '\u0414\u0435\u043B\u043E \u043D\u0435 \u0438\u0437\u0443\u0447\u0435\u043D\u043E \u043D\u043E\u0440\u043C\u0430\u043B\u044C\u043D\u043E.\n\n'
        '**\u0423 \u0432\u0430\u0441 \u043E\u0447\u0435\u043D\u044C \u0441\u0438\u043B\u044C\u043D\u044B\u0435 \u043E\u0441\u043D\u043E\u0432\u0430\u043D\u0438\u044F \u0434\u043B\u044F \u043E\u0431\u0436\u0430\u043B\u043E\u0432\u0430\u043D\u0438\u044F.**\n\n'
        '\uD83D\uDCCB \u0412\u043E\u0442 \u0447\u0442\u043E \u043D\u0443\u0436\u043D\u043E \u0441\u0434\u0435\u043B\u0430\u0442\u044C \u0434\u0430\u043B\u044C\u0448\u0435:\n'
        '1. \u041F\u043E\u0434\u0430\u0442\u044C \u0436\u0430\u043B\u043E\u0431\u0443 \u0432 **Helsinki Administrative Court** (\u0441\u0440\u043E\u043A \u2014 30 \u0434\u043D\u0435\u0439)\n'
        '2. \u041E\u0431\u0440\u0430\u0442\u0438\u0442\u044C\u0441\u044F \u0437\u0430 **\u0431\u0435\u0441\u043F\u043B\u0430\u0442\u043D\u043E\u0439 \u044E\u0440\u0438\u0434\u0438\u0447\u0435\u0441\u043A\u043E\u0439 \u043F\u043E\u043C\u043E\u0449\u044C\u044E** (oikeusapu)\n'
        '3. \u042F \u043C\u043E\u0433\u0443 \u043F\u043E\u0434\u0433\u043E\u0442\u043E\u0432\u0438\u0442\u044C \u0447\u0435\u0440\u043D\u043E\u0432\u0438\u043A \u0436\u0430\u043B\u043E\u0431\u044B \u043F\u0440\u044F\u043C\u043E \u0441\u0435\u0439\u0447\u0430\u0441\n\n'
        '\u0425\u043E\u0442\u0438\u0442\u0435, \u0447\u0442\u043E\u0431\u044B \u044F \u043D\u0430\u0447\u0430\u043B \u0441\u043E\u0441\u0442\u0430\u0432\u043B\u044F\u0442\u044C \u0436\u0430\u043B\u043E\u0431\u0443?',
    'analyze':
        '\u041F\u0440\u043E\u0432\u0435\u0440\u0438\u043B \u0435\u0449\u0451 \u0440\u0430\u0437. 3 \u043E\u0448\u0438\u0431\u043A\u0438 \u043F\u043E\u0434\u0442\u0432\u0435\u0440\u0436\u0434\u0430\u044E\u0442\u0441\u044F:\n\n'
        '\uD83D\uDD34 **\u042F\u0437\u044B\u043A** \u2014 \u0440\u0435\u0448\u0435\u043D\u0438\u0435 \u0442\u043E\u043B\u044C\u043A\u043E \u043D\u0430 \u0440\u0443\u0441\u0441\u043A\u043E\u043C, \u043D\u0430\u0440\u0443\u0448\u0430\u0435\u0442 '
        '**Hallintolaki \u00A726** \u0438 **Ulkomaalaislaki \u00A7203**\n'
        '\uD83D\uDD34 **\u041F\u043E\u0434\u043F\u0438\u0441\u044C** \u2014 \u043D\u0435\u0443\u043F\u043E\u043B\u043D\u043E\u043C\u043E\u0447\u0435\u043D\u043D\u044B\u0439 \u043E\u0444\u0438\u0446\u0435\u0440, '
        '\u043D\u0430\u0440\u0443\u0448\u0430\u0435\u0442 **Ulkomaalaislaki \u00A7152**\n'
        '\uD83D\uDFE1 **\u0421\u0442\u0440\u0430\u043D\u0430** \u2014 "\u0421\u043E\u0432\u0435\u0442\u0441\u043A\u0438\u0439 \u0421\u043E\u044E\u0437" \u0432\u043C\u0435\u0441\u0442\u043E \u042D\u0441\u0442\u043E\u043D\u0438\u0438, '
        '\u043D\u0430\u0440\u0443\u0448\u0430\u0435\u0442 **Hallintolaki \u00A731**\n\n'
        '\u0421\u0443\u0434 \u0434\u043E\u043B\u0436\u0435\u043D \u043F\u0440\u043E\u0432\u0435\u0440\u0438\u0442\u044C, \u0431\u044B\u043B\u043E \u043B\u0438 \u0440\u0435\u0448\u0435\u043D\u0438\u0435 \u043F\u0440\u0438\u043D\u044F\u0442\u043E \u0437\u0430\u043A\u043E\u043D\u043D\u043E. '
        '\u0421 \u0442\u0430\u043A\u0438\u043C\u0438 \u043E\u0448\u0438\u0431\u043A\u0430\u043C\u0438 \u2014 \u0448\u0430\u043D\u0441\u044B \u043D\u0430 \u043E\u0442\u043C\u0435\u043D\u0443 **\u0432\u044B\u0441\u043E\u043A\u0438\u0435**.\n\n'
        '\u26A0\uFE0F \u042D\u0442\u043E \u0438\u043D\u0444\u043E\u0440\u043C\u0430\u0446\u0438\u044F, \u043D\u0435 \u044E\u0440\u0438\u0434\u0438\u0447\u0435\u0441\u043A\u0430\u044F \u043A\u043E\u043D\u0441\u0443\u043B\u044C\u0442\u0430\u0446\u0438\u044F. \u041F\u0440\u043E\u0432\u0435\u0440\u044C\u0442\u0435 \u0441 \u0430\u0434\u0432\u043E\u043A\u0430\u0442\u043E\u043C.',
    'options':
        '\u0412\u0430\u0448\u0438 \u043F\u0440\u0430\u0432\u0430 \u0432 \u044D\u0442\u043E\u0439 \u0441\u0438\u0442\u0443\u0430\u0446\u0438\u0438:\n\n'
        '\u2705 **\u041F\u0440\u0430\u0432\u043E \u043D\u0430 \u043E\u0431\u0436\u0430\u043B\u043E\u0432\u0430\u043D\u0438\u0435** \u2014 30 \u0434\u043D\u0435\u0439 \u0432 Helsinki Administrative Court\n'
        '\u2705 **\u041F\u0440\u0430\u0432\u043E \u043D\u0430 \u0431\u0435\u0441\u043F\u043B\u0430\u0442\u043D\u043E\u0433\u043E \u0430\u0434\u0432\u043E\u043A\u0430\u0442\u0430** \u2014 oikeusapu, \u0433\u043E\u0441\u0443\u0434\u0430\u0440\u0441\u0442\u0432\u0435\u043D\u043D\u0430\u044F \u044E\u0440\u043F\u043E\u043C\u043E\u0449\u044C\n'
        '\u2705 **\u041F\u0440\u0430\u0432\u043E \u043D\u0430 \u043F\u0435\u0440\u0435\u0432\u043E\u0434\u0447\u0438\u043A\u0430** \u2014 \u0432\u043E \u0432\u0440\u0435\u043C\u044F \u0432\u0441\u0435\u0445 \u043F\u0440\u043E\u0446\u0435\u0434\u0443\u0440\n'
        '\u2705 **\u041F\u0440\u0430\u0432\u043E \u043E\u0441\u0442\u0430\u0442\u044C\u0441\u044F** \u043F\u043E\u043A\u0430 \u0441\u0443\u0434 \u0440\u0430\u0441\u0441\u043C\u0430\u0442\u0440\u0438\u0432\u0430\u0435\u0442 \u0436\u0430\u043B\u043E\u0431\u0443\n'
        '\u2705 **\u041F\u0440\u0430\u0432\u043E \u043D\u0430 RIKU** \u2014 \u043F\u043E\u0434\u0434\u0435\u0440\u0436\u043A\u0443 \u0436\u0435\u0440\u0442\u0432 \u043F\u0440\u0430\u0432\u043E\u043D\u0430\u0440\u0443\u0448\u0435\u043D\u0438\u0439\n\n'
        '\uD83D\uDCCB \u0421\u0430\u043C\u043E\u0435 \u0432\u0430\u0436\u043D\u043E\u0435 \u0441\u0435\u0439\u0447\u0430\u0441 \u2014 **\u043D\u0435 \u043F\u0440\u043E\u043F\u0443\u0441\u0442\u0438\u0442\u044C \u0441\u0440\u043E\u043A \u043E\u0431\u0436\u0430\u043B\u043E\u0432\u0430\u043D\u0438\u044F**. '
        '\u041A\u043E\u0433\u0434\u0430 \u0432\u044B \u043F\u043E\u043B\u0443\u0447\u0438\u043B\u0438 \u0440\u0435\u0448\u0435\u043D\u0438\u0435? \u042D\u0442\u043E \u0432\u0430\u0436\u043D\u043E \u0434\u043B\u044F \u0441\u0440\u043E\u043A\u043E\u0432.',
    'appeal':
        '\u041F\u043E\u0434\u0433\u043E\u0442\u043E\u0432\u0438\u043B \u0447\u0435\u0440\u043D\u043E\u0432\u0438\u043A \u0436\u0430\u043B\u043E\u0431\u044B. \u0412 \u043D\u0435\u0451 \u0432\u043A\u043B\u044E\u0447\u0435\u043D\u043E:\n\n'
        '- \u0412\u0441\u0435 3 \u043F\u0440\u043E\u0446\u0435\u0434\u0443\u0440\u043D\u044B\u0445 \u043D\u0430\u0440\u0443\u0448\u0435\u043D\u0438\u044F \u0441\u043E \u0441\u0441\u044B\u043B\u043A\u0430\u043C\u0438 \u043D\u0430 \u0437\u0430\u043A\u043E\u043D\u044B\n'
        '- \u0417\u0430\u043F\u0440\u043E\u0441 \u043D\u0430 \u0443\u0441\u0442\u043D\u043E\u0435 \u0441\u043B\u0443\u0448\u0430\u043D\u0438\u0435\n'
        '- \u0421\u043F\u0438\u0441\u043E\u043A \u043F\u0440\u0438\u043B\u043E\u0436\u0435\u043D\u0438\u0439 (\u043C\u0435\u0434\u0441\u043F\u0440\u0430\u0432\u043A\u0430, \u0442\u0440\u0443\u0434\u043E\u0432\u043E\u0439 \u0434\u043E\u0433\u043E\u0432\u043E\u0440)\n\n'
        '\u041E\u043D \u0443\u0436\u0435 \u0432 \u0440\u0430\u0437\u0434\u0435\u043B\u0435 **\u0414\u043E\u043A\u0443\u043C\u0435\u043D\u0442\u044B**. \u041E\u0431\u044F\u0437\u0430\u0442\u0435\u043B\u044C\u043D\u043E \u043F\u043E\u043A\u0430\u0436\u0438\u0442\u0435 \u0430\u0434\u0432\u043E\u043A\u0430\u0442\u0443 \u043F\u0435\u0440\u0435\u0434 \u043F\u043E\u0434\u0430\u0447\u0435\u0439.\n\n'
        '\u26A0\uFE0F \u042D\u0442\u043E \u0438\u043D\u0444\u043E\u0440\u043C\u0430\u0446\u0438\u044F, \u043D\u0435 \u044E\u0440\u0438\u0434\u0438\u0447\u0435\u0441\u043A\u0430\u044F \u043A\u043E\u043D\u0441\u0443\u043B\u044C\u0442\u0430\u0446\u0438\u044F. \u041F\u0440\u043E\u0432\u0435\u0440\u044C\u0442\u0435 \u0441 \u0430\u0434\u0432\u043E\u043A\u0430\u0442\u043E\u043C.',
    'deadlines':
        '\u0412\u0430\u0448\u0438 \u0441\u0440\u043E\u043A\u0438:\n\n'
        '\uD83D\uDD34 **\u041A\u0440\u0438\u0442\u0438\u0447\u0435\u0441\u043A\u0438\u0439:** \u0421\u0440\u043E\u043A \u043F\u043E\u0434\u0430\u0447\u0438 \u0436\u0430\u043B\u043E\u0431\u044B \u2014 **15 \u0430\u043F\u0440\u0435\u043B\u044F 2025** (30 \u0434\u043D\u0435\u0439 \u043E\u0442 \u0440\u0435\u0448\u0435\u043D\u0438\u044F)\n'
        '\uD83D\uDFE1 \u041A\u043E\u043D\u0441\u0443\u043B\u044C\u0442\u0430\u0446\u0438\u044F \u0441 \u0430\u0434\u0432\u043E\u043A\u0430\u0442\u043E\u043C \u2014 \u0447\u0435\u0440\u0435\u0437 7 \u0434\u043D\u0435\u0439\n'
        '\uD83D\uDD35 \u041E\u0442\u0432\u0435\u0442 \u0441\u0443\u0434\u0430 \u2014 \u043E\u0436\u0438\u0434\u0430\u0435\u0442\u0441\u044F \u0447\u0435\u0440\u0435\u0437 14 \u0434\u043D\u0435\u0439\n'
        '\uD83D\uDD35 \u0421\u0443\u0434\u0435\u0431\u043D\u043E\u0435 \u0437\u0430\u0441\u0435\u0434\u0430\u043D\u0438\u0435 \u2014 **20 \u043C\u0430\u044F 2025**\n\n'
        '\u0421\u0430\u043C\u043E\u0435 \u0432\u0430\u0436\u043D\u043E\u0435 \u2014 **\u043D\u0435 \u043F\u0440\u043E\u043F\u0443\u0441\u0442\u0438\u0442\u0435 15 \u0430\u043F\u0440\u0435\u043B\u044F**. \u041F\u043E\u0441\u043B\u0435 \u044D\u0442\u043E\u0439 \u0434\u0430\u0442\u044B \u043E\u0431\u0436\u0430\u043B\u043E\u0432\u0430\u0442\u044C \u0431\u0443\u0434\u0435\u0442 \u043D\u0435\u0432\u043E\u0437\u043C\u043E\u0436\u043D\u043E.',
  };

  // -- Mock analysis issues (the 3 real errors from Finland case) --

  static const List<Map<String, dynamic>> analysisIssues = [
    {
      'id': 'issue-001',
      'severity': 'critical',
      'title': 'Wrong Language — Decision in Russian Only',
      'explanation':
          'The deportation decision was issued entirely in Russian. Under '
          'Hallintolaki (Administrative Procedure Act) \u00A726 and '
          'Ulkomaalaislaki (Aliens Act) \u00A7203, official decisions must '
          'be provided in Finnish, Swedish, or a language the person '
          'understands, with certified translation. Issuing the decision '
          'only in Russian violates the right to understand the decision '
          'and its legal consequences.',
      'legal_basis': 'Hallintolaki \u00A726, Ulkomaalaislaki \u00A7203',
      'detailed_analysis':
          'The language requirement is a fundamental procedural safeguard. '
          'A decision issued in the wrong language can be deemed invalid by '
          'the Administrative Court. The European Convention on Human Rights '
          'Article 6 also requires that individuals understand proceedings '
          'affecting their rights.',
    },
    {
      'id': 'issue-002',
      'severity': 'critical',
      'title': 'Unauthorized Signature — Wrong Officer',
      'explanation':
          'The decision was signed by an officer who lacks the legal '
          'authority to issue deportation orders. Under Ulkomaalaislaki '
          '\u00A7152, only specifically designated officials within Migri '
          'or police departments with explicit authorization can sign '
          'deportation decisions. The signing officer\'s credentials do not '
          'match the required authorization level.',
      'legal_basis': 'Ulkomaalaislaki \u00A7152, Hallintolaki \u00A744',
      'detailed_analysis':
          'An unauthorized signature renders the decision procedurally '
          'defective. The Administrative Court has consistently held that '
          'decisions signed by unauthorized officials must be annulled. '
          'This is a non-waivable procedural requirement.',
    },
    {
      'id': 'issue-003',
      'severity': 'critical',
      'title': 'Factual Error — References "Soviet Union"',
      'explanation':
          'The decision states the country of origin as "Soviet Union," '
          'which ceased to exist on December 26, 1991. The applicant is '
          'an Estonian national (Estonia has been an EU member state since '
          '2004). This fundamental factual error indicates the decision '
          'was made based on incorrect information, undermining its '
          'legal validity.',
      'legal_basis': 'Hallintolaki \u00A731, Perustuslaki \u00A721',
      'detailed_analysis':
          'A factual error of this magnitude suggests the decision-maker '
          'did not properly investigate the case. Under Hallintolaki \u00A731, '
          'the authority has a duty to investigate facts before making a '
          'decision. Referencing a non-existent country demonstrates a '
          'fundamental failure in fact-finding that may lead the court to '
          'annul the decision entirely.',
    },
  ];

  // -- OCR mock text from police decision --

  static const String _policeDecisionOcrText =
      'HELSINGIN POLIISILAITOS\n'
      '\u0420\u0415\u0428\u0415\u041D\u0418\u0415 \u041E \u0412\u042B\u0421\u042B\u041B\u041A\u0415\n\n'
      '\u0414\u0435\u043B\u043E: UMA/2025/00431\n'
      '\u0414\u0430\u0442\u0430: 01.03.2025\n\n'
      '\u041B\u0438\u0446\u043E: \u0421\u0443\u043B\u0433\u0430 \u0414\u043C\u0438\u0442\u0440\u0438\u0439\n'
      '\u0413\u0440\u0430\u0436\u0434\u0430\u043D\u0441\u0442\u0432\u043E: \u0421\u043E\u0432\u0435\u0442\u0441\u043A\u0438\u0439 \u0421\u043E\u044E\u0437\n\n'
      '\u0420\u0415\u0428\u0415\u041D\u0418\u0415:\n'
      '\u041D\u0430 \u043E\u0441\u043D\u043E\u0432\u0430\u043D\u0438\u0438 \u0417\u0430\u043A\u043E\u043D\u0430 \u043E\u0431 \u0438\u043D\u043E\u0441\u0442\u0440\u0430\u043D\u0446\u0430\u0445 (Ulkomaalaislaki) \u00A7 143 '
      '\u043F\u0440\u0438\u043D\u044F\u0442\u043E \u0440\u0435\u0448\u0435\u043D\u0438\u0435 \u043E \u0432\u044B\u0441\u044B\u043B\u043A\u0435 \u0432\u044B\u0448\u0435\u0443\u043A\u0430\u0437\u0430\u043D\u043D\u043E\u0433\u043E \u043B\u0438\u0446\u0430 \u0438\u0437 \u0424\u0438\u043D\u043B\u044F\u043D\u0434\u0438\u0438.\n\n'
      '\u041E\u0411\u041E\u0421\u041D\u041E\u0412\u0410\u041D\u0418\u0415:\n'
      '\u041B\u0438\u0446\u043E \u043D\u0435 \u0438\u043C\u0435\u0435\u0442 \u0434\u0435\u0439\u0441\u0442\u0432\u0443\u044E\u0449\u0435\u0433\u043E \u0432\u0438\u0434\u0430 \u043D\u0430 \u0436\u0438\u0442\u0435\u043B\u044C\u0441\u0442\u0432\u043E...\n\n'
      '\u041F\u043E\u0434\u043F\u0438\u0441\u044C: \u041A. \u0412\u0438\u0440\u0442\u0430\u043D\u0435\u043D\n'
      '\u0421\u0442\u0430\u0440\u0448\u0438\u0439 \u043A\u043E\u043D\u0441\u0442\u0435\u0431\u043B\u044C\n'
      '\u041E\u0442\u0434\u0435\u043B \u043F\u043E \u0434\u0435\u043B\u0430\u043C \u0438\u043D\u043E\u0441\u0442\u0440\u0430\u043D\u0446\u0435\u0432';
}
