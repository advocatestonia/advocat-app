import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../models/case_model.dart';
import 'demo_data.dart';
import 'knowledge_base.dart';

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final assistantToolsProvider = Provider<AssistantTools>((ref) {
  return AssistantTools();
});

// ---------------------------------------------------------------------------
// Tool result model
// ---------------------------------------------------------------------------

/// Represents the result of executing a tool, including display text for the
/// chat UI and optional structured data for rendering rich cards.
class ToolResult {
  /// Whether the tool executed successfully.
  final bool success;

  /// Rich formatted text suitable for display in the chat bubble.
  final String displayText;

  /// Optional card type hint for the UI to render a specialised widget.
  ///
  /// Known types: `company_report`, `vehicle_report`, `deadline_list`,
  /// `case_summary`, `document_analysis`, `draft_preview`, `lawyer_list`,
  /// `email_draft`, `language_changed`, `translation`.
  final String? cardType;

  /// Structured data that the UI can use to render a rich card.
  final Map<String, dynamic>? data;

  /// If true, the action requires explicit user approval before proceeding.
  final bool requiresApproval;

  /// Human-readable message explaining what the user is approving.
  final String? approvalMessage;

  const ToolResult({
    required this.success,
    required this.displayText,
    this.cardType,
    this.data,
    this.requiresApproval = false,
    this.approvalMessage,
  });

  /// Convenience constructor for error results.
  factory ToolResult.error(String message) => ToolResult(
        success: false,
        displayText: message,
      );

  /// Serialize to a map (useful for passing back into the AI context).
  Map<String, dynamic> toJson() => {
        'success': success,
        'displayText': displayText,
        if (cardType != null) 'cardType': cardType,
        if (data != null) 'data': data,
        'requiresApproval': requiresApproval,
        if (approvalMessage != null) 'approvalMessage': approvalMessage,
      };
}

// ---------------------------------------------------------------------------
// Tool executor
// ---------------------------------------------------------------------------

/// Maps AI tool calls to actual app functions.
///
/// In demo mode every tool returns realistic mock data. When connected to
/// real services, the tool implementations delegate to the corresponding
/// service classes.
class AssistantTools {
  AssistantTools() : _log = Logger(printer: PrettyPrinter(methodCount: 0));

  final Logger _log;

  // ── Tool registry ──────────────────────────────────────────────────────

  /// Maps tool names to their handler functions.
  late final Map<String, Future<ToolResult> Function(Map<String, dynamic>)>
      _tools = {
    'check_company': _checkCompany,
    'check_vehicle': _checkVehicle,
    'get_deadlines': _getDeadlines,
    'create_case': _createCase,
    'analyze_document': _analyzeDocument,
    'generate_draft': _generateDraft,
    'search_knowledge': _searchKnowledge,
    'find_lawyer': _findLawyer,
    'open_camera': _openCamera,
    'draft_email': _draftEmail,
    'get_case_status': _getCaseStatus,
    'change_language': _changeLanguage,
    'translate_text': _translateText,
  };

  /// Tools that require explicit user approval before the result is acted upon.
  static final Set<String> requiresApproval = {
    'send_email',
    'create_case',
    'generate_draft',
  };

  /// List of all registered tool names.
  List<String> get availableTools => _tools.keys.toList();

  // ── Public API ─────────────────────────────────────────────────────────

  /// Execute a tool by [toolName] with the given [params].
  ///
  /// Returns a [ToolResult] with formatted output for the chat and optional
  /// structured data for card rendering.
  Future<ToolResult> execute(
    String toolName,
    Map<String, dynamic> params,
  ) async {
    final handler = _tools[toolName];
    if (handler == null) {
      _log.w('Unknown tool called: $toolName');
      return ToolResult.error(
        'Unknown tool "$toolName". Available tools: ${_tools.keys.join(", ")}',
      );
    }

    _log.i('Executing tool: $toolName with params: $params');

    try {
      final result = await handler(params);

      // If the tool is in the approval set, mark the result accordingly.
      if (requiresApproval.contains(toolName) && !result.requiresApproval) {
        return ToolResult(
          success: result.success,
          displayText: result.displayText,
          cardType: result.cardType,
          data: result.data,
          requiresApproval: true,
          approvalMessage:
              result.approvalMessage ?? 'Please confirm this action.',
        );
      }

      return result;
    } catch (e, st) {
      _log.e('Tool execution failed: $toolName', error: e, stackTrace: st);
      return ToolResult.error('Tool "$toolName" failed: $e');
    }
  }

  // ── Tool implementations (demo mode) ──────────────────────────────────

  Future<ToolResult> _checkCompany(Map<String, dynamic> params) async {
    final companyName = params['company_name'] as String? ?? '';
    final country = params['country'] as String? ?? 'fi';

    // Simulate network delay
    await Future<void>.delayed(const Duration(milliseconds: 500));

    return ToolResult(
      success: true,
      displayText: '''
**Company Report: $companyName**

Registration: Active (${country.toUpperCase()})
Tax ID: ${country.toUpperCase()}-${companyName.hashCode.abs() % 9000000 + 1000000}
Founded: 2018-03-15
Status: Active

**Tax Information:**
- Tax debts: EUR 0.00
- VAT registered: Yes
- Last filing: 2025-12-31

**Court Cases:** None found

**Risk Level:** LOW
No negative indicators found. Company appears to be in good standing.
''',
      cardType: 'company_report',
      data: {
        'company_name': companyName,
        'country': country,
        'registration_status': 'active',
        'tax_id': '${country.toUpperCase()}-${companyName.hashCode.abs() % 9000000 + 1000000}',
        'founded': '2018-03-15',
        'tax_debts': 0.0,
        'vat_registered': true,
        'court_cases': 0,
        'risk_level': 'low',
      },
    );
  }

  Future<ToolResult> _checkVehicle(Map<String, dynamic> params) async {
    final plate = params['plate_number'] as String? ?? '';
    final country = params['country'] as String? ?? 'fi';

    await Future<void>.delayed(const Duration(milliseconds: 500));

    return ToolResult(
      success: true,
      displayText: '''
**Vehicle Report: $plate**

Make: Volkswagen
Model: Golf
Year: 2019
Color: Silver
Country: ${country.toUpperCase()}

**Registration:** Valid until 2026-06-30
**Insurance:** Active (Liability + Comprehensive)
**Inspection:** Passed (last: 2025-08-15, next due: 2026-08-15)

**Ownership History:**
1. Current owner since 2022-04-10
2. Previous owner: 2019-01-20 to 2022-04-09

**Liens/Restrictions:** None
**Reported Stolen:** No
**Odometer (last recorded):** 87,450 km
''',
      cardType: 'vehicle_report',
      data: {
        'plate_number': plate,
        'country': country,
        'make': 'Volkswagen',
        'model': 'Golf',
        'year': 2019,
        'color': 'Silver',
        'registration_valid': true,
        'registration_expires': '2026-06-30',
        'insurance_active': true,
        'inspection_passed': true,
        'inspection_next': '2026-08-15',
        'liens': false,
        'stolen': false,
        'odometer_km': 87450,
      },
    );
  }

  Future<ToolResult> _getDeadlines(Map<String, dynamic> params) async {
    final caseId = params['case_id'] as String?;

    await Future<void>.delayed(const Duration(milliseconds: 300));

    final deadlines = DemoData.deadlines
        .where((d) => caseId == null || d.caseId == caseId)
        .toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));

    if (deadlines.isEmpty) {
      return const ToolResult(
        success: true,
        displayText: 'No upcoming deadlines found.',
        cardType: 'deadline_list',
        data: {'deadlines': []},
      );
    }

    final buffer = StringBuffer('**Upcoming Deadlines:**\n\n');
    final deadlineData = <Map<String, dynamic>>[];

    for (final d in deadlines) {
      final daysLeft = d.dueDate.difference(DateTime.now()).inDays;
      final urgency = daysLeft <= 7
          ? 'URGENT'
          : daysLeft <= 14
              ? 'Soon'
              : 'Upcoming';

      buffer.writeln(
        '- **${d.title}** — '
        '${d.dueDate.toIso8601String().substring(0, 10)} '
        '($daysLeft days, $urgency)',
      );
      if (d.description != null) {
        buffer.writeln('  ${d.description}');
      }
      buffer.writeln();

      deadlineData.add({
        'id': d.id,
        'title': d.title,
        'due_date': d.dueDate.toIso8601String(),
        'days_left': daysLeft,
        'urgency': urgency,
        'description': d.description,
        'case_id': d.caseId,
      });
    }

    return ToolResult(
      success: true,
      displayText: buffer.toString(),
      cardType: 'deadline_list',
      data: {'deadlines': deadlineData},
    );
  }

  Future<ToolResult> _createCase(Map<String, dynamic> params) async {
    final title = params['title'] as String? ?? 'New Case';
    final description = params['description'] as String? ?? '';
    final caseType = params['case_type'] as String? ?? 'other';
    final country = params['country'] as String? ?? 'Finland';

    await Future<void>.delayed(const Duration(milliseconds: 400));

    final newCaseId = 'case-new-${DateTime.now().millisecondsSinceEpoch}';

    return ToolResult(
      success: true,
      displayText: '''
**New Case Created**

Title: $title
Type: $caseType
Country: $country
Case ID: $newCaseId

${description.isNotEmpty ? 'Description: $description\n' : ''}
The case has been created. You can now upload documents and I will help analyze them.
''',
      cardType: 'case_summary',
      data: {
        'case_id': newCaseId,
        'title': title,
        'description': description,
        'case_type': caseType,
        'country': country,
        'status': 'active',
        'created_at': DateTime.now().toIso8601String(),
      },
      requiresApproval: true,
      approvalMessage:
          'Create a new "$caseType" case titled "$title"?',
    );
  }

  Future<ToolResult> _analyzeDocument(Map<String, dynamic> params) async {
    final documentId = params['document_id'] as String? ?? '';
    final focus = params['focus'] as String? ?? 'all';

    await Future<void>.delayed(const Duration(milliseconds: 600));

    // Look up demo document if available
    final doc = DemoData.documents
        .where((d) => d.id == documentId)
        .firstOrNull;

    final fileName = doc?.fileName ?? 'Document';
    final summary = doc?.aiSummary ?? 'Document analysis completed.';

    return ToolResult(
      success: true,
      displayText: '''
**Document Analysis: $fileName**

**Summary:**
$summary

**Key Findings:**
- Language: ${doc?.language ?? 'auto-detected'}
- Category: ${doc?.category.name ?? 'general'}

**Procedural Issues Found:** 3
1. Document issued in wrong language (Russian instead of Finnish/English)
2. Signed by unauthorized officer (Sergeant, not Inspector-level or above)
3. References "Soviet Union" — a non-existent country since 1991

**Legal References:**
- Hallintolaki Section 44-45 (Administrative Procedure Act)
- Ulkomaalaislaki Section 150 (Right to be heard)
- Ulkomaalaislaki Section 203 (Language requirements)

**Deadlines Extracted:**
- Appeal deadline: 30 days from decision date
''',
      cardType: 'document_analysis',
      data: {
        'document_id': documentId,
        'file_name': fileName,
        'summary': summary,
        'focus': focus,
        'language': doc?.language ?? 'unknown',
        'issues_count': 3,
        'issues': [
          'Wrong language (Russian instead of Finnish/English)',
          'Signed by unauthorized officer',
          'References non-existent country "Soviet Union"',
        ],
        'legal_references': [
          'Hallintolaki Section 44-45',
          'Ulkomaalaislaki Section 150',
          'Ulkomaalaislaki Section 203',
        ],
      },
    );
  }

  Future<ToolResult> _generateDraft(Map<String, dynamic> params) async {
    final draftType = params['draft_type'] as String? ?? 'appeal';
    final caseId = params['case_id'] as String? ?? '';
    final language = params['language'] as String? ?? 'en';

    await Future<void>.delayed(const Duration(milliseconds: 800));

    final legalCase = DemoData.cases
        .where((c) => c.id == caseId)
        .firstOrNull;

    final caseTitle = legalCase?.title ?? 'Legal Case';

    return ToolResult(
      success: true,
      displayText: '''
**Draft Generated: ${draftType.replaceAll('_', ' ').toUpperCase()}**

Re: $caseTitle

---

[DRAFT - REQUIRES REVIEW]

To: Helsinki Administrative Court (Hallinto-oikeus)
From: [Client Name]
Date: ${DateTime.now().toIso8601String().substring(0, 10)}
Re: Appeal against deportation decision UMA/2025/00431

Dear Administrative Court,

I hereby appeal the deportation decision issued on 2025-03-01 by the Helsinki Police Department on the following grounds:

1. **Procedural violation — Language requirement (Hallintolaki Section 45; Ulkomaalaislaki Section 203):** The decision was issued exclusively in Russian. The applicant's registered communication language is English, and Finnish law requires decisions to be provided in a language the person understands.

2. **Procedural violation — Unauthorized signatory (Hallintolaki Section 44):** The decision was signed by an officer without the required authority level to issue deportation decisions.

3. **Factual error — Country of origin:** The decision references "Soviet Union" as the country of origin, which ceased to exist in 1991.

I respectfully request that the Court:
a) Annul the deportation decision due to the above procedural violations
b) Grant a stay of execution pending the outcome of this appeal

Respectfully submitted,
[Client Name]

---

*This is an AI-generated draft. It must be reviewed by a qualified attorney before submission.*
''',
      cardType: 'draft_preview',
      data: {
        'draft_type': draftType,
        'case_id': caseId,
        'language': language,
        'case_title': caseTitle,
        'generated_at': DateTime.now().toIso8601String(),
      },
      requiresApproval: true,
      approvalMessage:
          'Review the generated $draftType draft for "$caseTitle". '
          'Would you like to save or edit it?',
    );
  }

  Future<ToolResult> _searchKnowledge(Map<String, dynamic> params) async {
    final query = params['query'] as String? ?? '';
    final country = params['country'] as String? ?? 'finland';
    final caseType = params['case_type'] as String?;

    await Future<void>.delayed(const Duration(milliseconds: 400));

    // Parse case type if provided
    CaseType? parsedCaseType;
    if (caseType != null) {
      switch (caseType) {
        case 'deportation':
          parsedCaseType = CaseType.deportation;
        case 'labor_dispute':
          parsedCaseType = CaseType.laborDispute;
        case 'tenant_rights':
          parsedCaseType = CaseType.tenantRights;
        default:
          parsedCaseType = null;
      }
    }

    // Use the real KnowledgeBase for context
    final context = KnowledgeBase.buildContext(
      caseType: parsedCaseType,
      country: country,
    );

    // Return a summary rather than the full knowledge base
    return ToolResult(
      success: true,
      displayText:
          '**Legal Knowledge Search:** "$query"\n\n'
          'Found relevant information for $country. '
          'The knowledge base contains applicable laws, procedures, '
          'and rights relevant to your query.\n\n'
          '_Context loaded: ${context.length} characters of legal reference material._',
      cardType: null, // Knowledge results are rendered inline
      data: {
        'query': query,
        'country': country,
        'case_type': caseType,
        'context_length': context.length,
        'context_preview':
            context.length > 500 ? '${context.substring(0, 500)}...' : context,
      },
    );
  }

  Future<ToolResult> _findLawyer(Map<String, dynamic> params) async {
    final country = params['country'] as String? ?? 'finland';
    final caseType = params['case_type'] as String?;
    final city = params['city'] as String?;

    await Future<void>.delayed(const Duration(milliseconds: 500));

    final countryLower = country.toLowerCase();
    final List<Map<String, dynamic>> contacts;

    if (countryLower.contains('finland') || countryLower == 'fi') {
      contacts = [
        {
          'name': 'Oikeusaputoimisto (Legal Aid Office)',
          'type': 'Legal Aid',
          'phone': '0295 530 300',
          'website': 'https://oikeus.fi/oikeusapu/',
          'description':
              'Free or subsidized legal assistance based on income. '
                  'Covers all legal matters.',
          'cost': 'Free / means-tested',
        },
        {
          'name': 'Pakolaisneuvonta (Refugee Advice Centre)',
          'type': 'NGO',
          'phone': '09 2313 9300',
          'website': 'https://www.pakolaisneuvonta.fi/',
          'description':
              'Free legal advice for asylum seekers and refugees.',
          'cost': 'Free',
        },
        {
          'name': 'RIKU — Victim Support Finland',
          'type': 'NGO',
          'phone': '116 006',
          'website': 'https://www.riku.fi/',
          'description':
              'Support and legal guidance for crime victims.',
          'cost': 'Free',
        },
        {
          'name': 'Finnish Bar Association Lawyer Search',
          'type': 'Directory',
          'phone': '09 6866 120',
          'website': 'https://www.asianajajaliitto.fi/en/',
          'description':
              'Find a licensed lawyer specializing in your case type.',
          'cost': 'Varies',
        },
      ];
    } else if (countryLower.contains('germany') || countryLower == 'de') {
      contacts = [
        {
          'name': 'Beratungshilfe (Advisory Assistance)',
          'type': 'Legal Aid',
          'phone': 'Local court (Amtsgericht)',
          'website': 'https://www.bmj.de/',
          'description':
              'Free legal advice voucher from local court for low-income persons.',
          'cost': 'EUR 15 flat fee',
        },
        {
          'name': 'Prozesskostenhilfe (Legal Aid for Court)',
          'type': 'Legal Aid',
          'description':
              'Covers court and lawyer fees for those who cannot afford them.',
          'cost': 'Free / means-tested',
        },
        {
          'name': 'Migrationsberatung (Migration Counseling)',
          'type': 'NGO',
          'website': 'https://www.bamf.de/',
          'description':
              'Free migration advice services funded by the federal government.',
          'cost': 'Free',
        },
      ];
    } else if (countryLower.contains('estonia') || countryLower == 'ee') {
      contacts = [
        {
          'name': 'Riigi Oigusabi (State Legal Aid)',
          'type': 'Legal Aid',
          'website': 'https://www.juristaitab.ee/',
          'description':
              'State-funded legal aid for those who cannot afford a lawyer.',
          'cost': 'Free / means-tested',
        },
        {
          'name': 'Estonian Human Rights Centre',
          'type': 'NGO',
          'website': 'https://humanrights.ee/',
          'description':
              'Legal advice on discrimination and human rights issues.',
          'cost': 'Free',
        },
      ];
    } else {
      contacts = [
        {
          'name': 'Local Legal Aid Office',
          'type': 'Legal Aid',
          'description':
              'Contact your local legal aid office for free or subsidized '
                  'legal assistance. Most EU countries provide means-tested '
                  'legal aid.',
          'cost': 'Varies by country',
        },
      ];
    }

    final buffer = StringBuffer(
      '**Legal Aid & Lawyer Contacts ($country)**\n\n',
    );

    for (final c in contacts) {
      buffer.writeln('**${c['name']}** (${c['type']})');
      if (c['phone'] != null) buffer.writeln('Phone: ${c['phone']}');
      if (c['website'] != null) buffer.writeln('Web: ${c['website']}');
      buffer.writeln('${c['description']}');
      buffer.writeln('Cost: ${c['cost']}');
      buffer.writeln();
    }

    return ToolResult(
      success: true,
      displayText: buffer.toString(),
      cardType: 'lawyer_list',
      data: {
        'country': country,
        'case_type': caseType,
        'city': city,
        'contacts': contacts,
      },
    );
  }

  Future<ToolResult> _openCamera(Map<String, dynamic> params) async {
    final mode = params['mode'] as String? ?? 'document_scan';

    return ToolResult(
      success: true,
      displayText: mode == 'document_scan'
          ? 'Opening document scanner. Please position the document within the '
              'frame and take a photo. The text will be automatically extracted.'
          : 'Opening camera. Take a photo of the document.',
      cardType: null,
      data: {
        'action': 'open_camera',
        'mode': mode,
      },
    );
  }

  Future<ToolResult> _draftEmail(Map<String, dynamic> params) async {
    final to = params['to'] as String? ?? '';
    final subject = params['subject'] as String? ?? '';
    final body = params['body'] as String? ?? '';

    await Future<void>.delayed(const Duration(milliseconds: 300));

    return ToolResult(
      success: true,
      displayText: '''
**Email Draft**

**To:** $to
**Subject:** $subject

---

$body

---

_Review the email above. Tap "Send" to send or "Edit" to modify._
''',
      cardType: 'email_draft',
      data: {
        'to': to,
        'subject': subject,
        'body': body,
        'case_id': params['case_id'],
      },
      requiresApproval: true,
      approvalMessage: 'Send this email to $to?',
    );
  }

  Future<ToolResult> _getCaseStatus(Map<String, dynamic> params) async {
    final caseId = params['case_id'] as String? ?? DemoData.mainCaseId;

    await Future<void>.delayed(const Duration(milliseconds: 300));

    final legalCase = DemoData.cases
        .where((c) => c.id == caseId)
        .firstOrNull;

    if (legalCase == null) {
      return ToolResult.error('Case "$caseId" not found.');
    }

    final caseDeadlines = DemoData.deadlines
        .where((d) => d.caseId == caseId)
        .toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));

    final nextDeadline = caseDeadlines.isNotEmpty
        ? '${caseDeadlines.first.title} — '
            '${caseDeadlines.first.dueDate.toIso8601String().substring(0, 10)}'
        : 'No upcoming deadlines';

    return ToolResult(
      success: true,
      displayText: '''
**Case Status: ${legalCase.title}**

Case ID: ${legalCase.id}
Type: ${legalCase.type.name}
Status: ${legalCase.status.name}
${legalCase.migriReferenceNumber != null ? 'Migri Ref: ${legalCase.migriReferenceNumber}\n' : ''}${legalCase.courtCaseNumber != null ? 'Court Case: ${legalCase.courtCaseNumber}\n' : ''}
Documents: ${legalCase.documentCount}
Unread Messages: ${legalCase.unreadMessages}

**Next Deadline:** $nextDeadline

**Description:**
${legalCase.description ?? 'No description available.'}
''',
      cardType: 'case_summary',
      data: {
        'case_id': legalCase.id,
        'title': legalCase.title,
        'type': legalCase.type.name,
        'status': legalCase.status.name,
        'migri_ref': legalCase.migriReferenceNumber,
        'court_case': legalCase.courtCaseNumber,
        'document_count': legalCase.documentCount,
        'unread_messages': legalCase.unreadMessages,
        'next_deadline': nextDeadline,
        'description': legalCase.description,
      },
    );
  }

  Future<ToolResult> _changeLanguage(Map<String, dynamic> params) async {
    final language = params['language'] as String? ?? 'en';

    final languageNames = <String, String>{
      'en': 'English',
      'fi': 'Suomi (Finnish)',
      'de': 'Deutsch (German)',
      'sv': 'Svenska (Swedish)',
      'ru': 'Русский (Russian)',
      'et': 'Eesti (Estonian)',
      'lv': 'Latviešu (Latvian)',
      'lt': 'Lietuvių (Lithuanian)',
      'ar': 'العربية (Arabic)',
      'fr': 'Français (French)',
    };

    final displayName = languageNames[language] ?? language;

    return ToolResult(
      success: true,
      displayText: 'Language changed to **$displayName**.',
      cardType: 'language_changed',
      data: {
        'action': 'change_language',
        'language': language,
        'display_name': displayName,
      },
    );
  }

  Future<ToolResult> _translateText(Map<String, dynamic> params) async {
    final text = params['text'] as String? ?? '';
    final targetLanguage = params['target_language'] as String? ?? 'en';
    final sourceLanguage = params['source_language'] as String?;

    await Future<void>.delayed(const Duration(milliseconds: 400));

    // In demo mode, return a placeholder. In production, this would call
    // a translation API or use Claude for translation.
    final translatedText = '[Translated to $targetLanguage] $text';

    return ToolResult(
      success: true,
      displayText: '''
**Translation${sourceLanguage != null ? ' ($sourceLanguage -> $targetLanguage)' : ' (-> $targetLanguage)'}:**

$translatedText
''',
      cardType: 'translation',
      data: {
        'source_text': text,
        'translated_text': translatedText,
        'source_language': sourceLanguage ?? 'auto',
        'target_language': targetLanguage,
      },
    );
  }
}
