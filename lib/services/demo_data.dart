import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/case_model.dart';
import '../models/correspondence.dart';
import '../models/deadline.dart';
import '../models/document.dart';
import '../models/user.dart';

// ---------------------------------------------------------------------------
// Demo mode state — global flag checked by providers
// ---------------------------------------------------------------------------

/// Whether the app is running in demo mode (no backend).
final isDemoModeProvider = StateProvider<bool>((ref) => false);

// ---------------------------------------------------------------------------
// Demo data for the Finland deportation case
// ---------------------------------------------------------------------------

abstract final class DemoData {
  // ── User ──────────────────────────────────────────────────────────────

  static final AppUser user = AppUser(
    id: 'demo-user-001',
    email: 'dmitri.sulga@example.com',
    fullName: 'Dmitri Sulga',
    phone: '+358 40 123 4567',
    preferredLanguage: 'en',
    subscriptionTier: SubscriptionTier.premium,
    subscriptionExpiresAt: DateTime.now().add(const Duration(days: 365)),
    createdAt: DateTime(2025, 1, 15),
    updatedAt: DateTime.now(),
  );

  // ── Cases ──────────────────────────────────────────────────────────────

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
      decisionDate: DateTime(2025, 3, 1),
      appealDeadline: DateTime(2025, 4, 15),
      hearingDate: DateTime(2025, 5, 20),
      createdAt: DateTime(2025, 3, 5),
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
      createdAt: DateTime(2025, 2, 10),
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
          'Employer failed to follow Kündigungsschutzgesetz (Employment Protection Act) '
          'requirements. No prior warning was given and the works council was not consulted.',
      type: CaseType.laborDispute,
      status: CaseStatus.active,
      nationality: 'Estonian',
      createdAt: DateTime(2025, 4, 1),
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
      createdAt: DateTime(2025, 4, 10),
      updatedAt: DateTime.now().subtract(const Duration(hours: 12)),
      documentCount: 1,
      unreadMessages: 1,
    ),
  ];

  // ── Documents ─────────────────────────────────────────────────────────

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
      createdAt: DateTime(2025, 3, 5),
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
      createdAt: DateTime(2025, 3, 8),
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
      createdAt: DateTime(2025, 3, 10),
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
      createdAt: DateTime(2025, 3, 12),
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
      createdAt: DateTime(2025, 3, 14),
    ),
  ];

  // ── Deadlines ─────────────────────────────────────────────────────────

  static final List<Deadline> deadlines = [
    Deadline(
      id: 'dl-001',
      caseId: mainCaseId,
      userId: 'demo-user-001',
      title: 'Lawyer consultation call',
      description: 'Scheduled call with legal aid lawyer to review appeal strategy.',
      dueDate: DateTime.now().add(const Duration(days: 7)),
      type: DeadlineType.other,
      priority: DeadlinePriority.high,
      status: DeadlineStatus.upcoming,
      source: DeadlineSource.manual,
      createdAt: DateTime(2025, 3, 20),
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
      createdAt: DateTime(2025, 3, 5),
    ),
    Deadline(
      id: 'dl-003',
      caseId: mainCaseId,
      userId: 'demo-user-001',
      title: 'Appeal filing deadline',
      description:
          'Last day to file the appeal with Helsinki Administrative Court. '
          '30 days from the date of the deportation decision.',
      dueDate: DateTime(2025, 4, 15),
      type: DeadlineType.appeal,
      priority: DeadlinePriority.critical,
      status: DeadlineStatus.upcoming,
      source: DeadlineSource.aiExtracted,
      sourceDocumentId: 'doc-001',
      createdAt: DateTime(2025, 3, 5),
    ),
    Deadline(
      id: 'dl-004',
      caseId: mainCaseId,
      userId: 'demo-user-001',
      title: 'Court hearing',
      description:
          'Oral hearing at Helsinki Administrative Court regarding the '
          'deportation appeal.',
      dueDate: DateTime(2025, 5, 20),
      type: DeadlineType.hearing,
      priority: DeadlinePriority.critical,
      status: DeadlineStatus.upcoming,
      source: DeadlineSource.manual,
      createdAt: DateTime(2025, 3, 15),
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
      createdAt: DateTime(2025, 2, 28),
    ),
  ];

  // ── Correspondence ───────────────────────────────────────────────────

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
      sentAt: DateTime(2025, 3, 1),
      createdAt: DateTime(2025, 3, 1),
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
      sentAt: DateTime(2025, 3, 10),
      createdAt: DateTime(2025, 3, 10),
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
      sentAt: DateTime(2025, 3, 15),
      createdAt: DateTime(2025, 3, 15),
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
      sentAt: DateTime(2025, 3, 18),
      createdAt: DateTime(2025, 3, 18),
    ),
  ];

  // ── Chat messages ────────────────────────────────────────────────────

  static final List<Map<String, dynamic>> chatMessages = [
    {
      'id': 'msg-001',
      'role': 'assistant',
      'content':
          'Welcome, Dmitri. I have analyzed your deportation case '
          '(UMA/2025/00431). I found 3 critical procedural errors in the '
          'police decision that strengthen your appeal significantly.',
      'created_at': DateTime(2025, 3, 5, 10, 0).toIso8601String(),
    },
    {
      'id': 'msg-002',
      'role': 'user',
      'content': 'What errors did you find?',
      'created_at': DateTime(2025, 3, 5, 10, 1).toIso8601String(),
    },
    {
      'id': 'msg-003',
      'role': 'assistant',
      'content':
          'I found 3 critical errors in the police decision:\n\n'
          '1. WRONG LANGUAGE: The decision was issued in Russian only. '
          'Under Hallintolaki \u00A726 and Ulkomaalaislaki \u00A7203, '
          'decisions must be provided in Finnish, Swedish, or a language '
          'the person understands, with proper translation.\n\n'
          '2. UNAUTHORIZED SIGNATURE: The decision was signed by an officer '
          'who does not have the legal authority to issue deportation orders. '
          'Under Ulkomaalaislaki \u00A7152, only specifically authorized '
          'officials can sign such decisions.\n\n'
          '3. WRONG COUNTRY: The decision references "Soviet Union" as your '
          'country of origin. The Soviet Union ceased to exist in 1991. '
          'Your nationality is Estonian. This is a factual error that '
          'invalidates the basis of the decision.',
      'created_at': DateTime(2025, 3, 5, 10, 2).toIso8601String(),
    },
    {
      'id': 'msg-004',
      'role': 'user',
      'content': 'Can you help me draft an appeal?',
      'created_at': DateTime(2025, 3, 5, 10, 5).toIso8601String(),
    },
    {
      'id': 'msg-005',
      'role': 'assistant',
      'content':
          'Yes, I can help you draft an appeal. Based on the 3 errors found, '
          'your appeal has strong legal grounds. Here is what I recommend:\n\n'
          '- File with Helsinki Administrative Court (Helsingin hallinto-oikeus)\n'
          '- Reference all 3 procedural violations\n'
          '- Include your medical certificate and employment contract as evidence\n'
          '- Request an oral hearing\n\n'
          'The appeal deadline is April 15, 2025 (30 days from the decision). '
          'I have drafted an appeal document that you can review in the Documents section.\n\n'
          'Important: This is AI-generated legal guidance. Please consult with '
          'a licensed attorney before submitting any legal documents.',
      'created_at': DateTime(2025, 3, 5, 10, 6).toIso8601String(),
    },
  ];

  // ── Mock AI responses for chat ────────────────────────────────────────

  static const Map<String, String> chatResponses = {
    'default':
        'Based on your case file, I can see this is a deportation appeal '
        'with strong grounds due to procedural errors. How can I help you '
        'further? I can analyze documents, check deadlines, draft appeals, '
        'or explain your legal options.',
    'analyze':
        'I have re-analyzed your case. The 3 key issues remain:\n\n'
        '1. Language violation (Hallintolaki \u00A726)\n'
        '2. Unauthorized signature (Ulkomaalaislaki \u00A7152)\n'
        '3. Factual error — "Soviet Union" (country ceased to exist 1991)\n\n'
        'These procedural errors give you strong grounds for appeal. '
        'The court must consider whether the decision was lawfully made.',
    'options':
        'Your legal options are:\n\n'
        '- Appeal to Helsinki Administrative Court (recommended, deadline April 15)\n'
        '- Request legal aid from the State Legal Aid Office\n'
        '- Contact RIKU for victim support services\n'
        '- Request a stay of execution while the appeal is pending\n'
        '- File a complaint with the Parliamentary Ombudsman about procedural violations\n\n'
        'I recommend filing the appeal as the primary action.',
    'appeal':
        'I have prepared a draft appeal for your review. It covers:\n\n'
        '- All 3 procedural violations\n'
        '- References to applicable Finnish law\n'
        '- Request for oral hearing\n'
        '- Supporting evidence list\n\n'
        'You can find the draft in the Documents section. '
        'Please have a lawyer review it before filing.',
    'deadlines':
        'Here are your upcoming deadlines:\n\n'
        '- Lawyer consultation: in 7 days\n'
        '- Court response expected: in 14 days\n'
        '- Appeal deadline: April 15, 2025\n'
        '- Court hearing: May 20, 2025\n\n'
        'The most critical is the appeal deadline. Make sure to file before April 15.',
  };

  // ── Mock analysis issues (the 3 real errors from Finland case) ────────

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

  // ── OCR mock text from police decision ───────────────────────────────

  static const String _policeDecisionOcrText =
      'HELSINGIN POLIISILAITOS\n'
      'РЕШЕНИЕ О ВЫСЫЛКЕ\n\n'
      'Дело: UMA/2025/00431\n'
      'Дата: 01.03.2025\n\n'
      'Лицо: Сулга Дмитрий\n'
      'Гражданство: Советский Союз\n\n'
      'РЕШЕНИЕ:\n'
      'На основании Закона об иностранцах (Ulkomaalaislaki) \u00A7 143 '
      'принято решение о высылке вышеуказанного лица из Финляндии.\n\n'
      'ОБОСНОВАНИЕ:\n'
      'Лицо не имеет действующего вида на жительство...\n\n'
      'Подпись: К. Виртанен\n'
      'Старший констебль\n'
      'Отдел по делам иностранцев';
}
