import 'dart:async';

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../models/case_model.dart';
import 'demo_data.dart';
import 'estonian_law_search.dart';
import 'finnish_law_search.dart';
import 'ics_export_service.dart';
import 'knowledge_base.dart';
import 'law_lookup_client.dart';
import 'supabase_service.dart';

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final assistantToolsProvider = Provider<AssistantTools>((ref) {
  final supabase = ref.watch(supabaseServiceProvider);
  return AssistantTools(supabaseService: supabase);
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

  /// Text sent back to Claude as the tool result content. When present, this
  /// is used instead of [displayText] to prompt Claude for further generation
  /// (e.g. "now write the draft based on these details…"). The [displayText]
  /// is still shown to the user in the chat UI.
  final String? claudeText;

  const ToolResult({
    required this.success,
    required this.displayText,
    this.cardType,
    this.data,
    this.requiresApproval = false,
    this.approvalMessage,
    this.claudeText,
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
        if (claudeText != null) 'claudeText': claudeText,
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
  AssistantTools({required SupabaseService supabaseService})
      : _supabase = supabaseService,
        _log = Logger(
          printer: PrettyPrinter(methodCount: 0),
          level: kDebugMode ? Level.debug : Level.off,
        );

  final SupabaseService _supabase;
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
    'navigate_to': _navigateTo,
    // v24.1 additions
    'send_email': _sendEmail,
    'read_document': _readDocument,
    'list_documents': _listDocuments,
    'list_cases': _listCases,
    'search_estonian_law': _searchEstonianLaw,
    // v24.2 additions
    'search_finnish_law': _searchFinnishLaw,
    // Phase 2 Pkg 1+2 — exact statute lookup via law-lookup edge fn.
    'lookup_statute': _lookupStatute,
    'create_deadline': _createDeadline,
    'update_case': _updateCase,
    'get_user_profile': _getUserProfile,
    'analyze_contract': _analyzeContract,
    // v24.4 additions — long-horizon follow-up promises.
    'set_followup_intention': _setFollowupIntention,
    // Email Agent D5 — proactive inbox tools (handoff
    // 09_INTEGRATION_INTO_ADVOCAT.md). list_inbox / get_thread_triage are
    // read-only; approve_send_draft routes through the existing send-email
    // edge fn under the same approval flow as send_email; snooze_thread is
    // a passive flag flip.
    'list_inbox': _listInbox,
    'get_thread_triage': _getThreadTriage,
    'approve_send_draft': _approveSendDraft,
    'snooze_thread': _snoozeThread,
  };

  /// Tools that require explicit user approval before the result is acted upon.
  ///
  /// Only WRITE/ACTION tools require approval. READ-ONLY tools (deadlines,
  /// status, knowledge search, check company/vehicle, find lawyer, translate,
  /// analyze document) execute immediately without asking.
  static final Set<String> requiresApproval = {
    'create_case',
    'generate_draft',
    'open_camera',
    'draft_email',
    'send_email',
    'create_deadline',
    'update_case',
    // Email Agent D5 — dispatches the persisted triage draft via the
    // existing send-email edge fn. Same gate as send_email.
    'approve_send_draft',
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

    _log.i('Executing tool: $toolName');

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
              result.approvalMessage ?? _defaultApprovalMessage(toolName, params),
        );
      }

      return result;
    } catch (e, st) {
      _log.e('Tool execution failed: $toolName', error: e, stackTrace: st);
      return ToolResult.error('Tool "$toolName" failed: $e');
    }
  }

  // ── Approval messages ──────────────────────────────────────────────────

  /// Returns a human-readable approval message for tools that don't provide
  /// their own. The message describes the action so the user can confirm.
  String _defaultApprovalMessage(String toolName, Map<String, dynamic> params) {
    switch (toolName) {
      case 'check_company':
        final name = params['company_name'] as String? ?? '';
        return 'Check company "$name"?';
      case 'check_vehicle':
        final plate = params['plate_number'] as String? ?? '';
        return 'Check vehicle "$plate"?';
      case 'analyze_document':
        return 'Analyze this document?';
      case 'find_lawyer':
        final country = params['country'] as String? ?? '';
        return 'Search for legal aid contacts in $country?';
      case 'open_camera':
        return 'Open the camera to scan a document?';
      case 'translate_text':
        final lang = params['target_language'] as String? ?? '';
        return 'Translate the text to $lang?';
      case 'send_email':
        final to = params['to'] as String? ?? '';
        return 'Send this email to $to?';
      case 'create_deadline':
        final title = params['title'] as String? ?? '';
        final date = params['due_date'] as String? ?? '';
        return 'Add deadline "$title" on $date?';
      case 'update_case':
        return 'Apply these changes to the case?';
      case 'approve_send_draft':
        return 'Send the prepared reply?';
      default:
        return 'Confirm this action?';
    }
  }

  // ── Tool implementations (demo mode) ──────────────────────────────────

  Future<ToolResult> _checkCompany(Map<String, dynamic> params) async {
    final companyName = params['company_name'] as String? ?? '';
    final country = params['country'] as String? ?? 'Estonia';

    // Build direct registry URL based on country
    final countryLower = country.toLowerCase();
    final isEstonia = countryLower == 'estonia' ||
        countryLower == 'eesti' ||
        countryLower == 'ee';
    final isFinland = countryLower == 'finland' ||
        countryLower == 'suomi' ||
        countryLower == 'fi';

    final registryUrl = isEstonia
        ? 'https://ariregister.rik.ee/est/company?search_query=${Uri.encodeComponent(companyName)}'
        : isFinland
            ? 'https://www.prh.fi/en/kaupparekisteri.html'
            : '';

    // Try to call the Edge Function for Estonian companies
    Map<String, dynamic>? apiResult;
    if (isEstonia) {
      try {
        final response = await _supabase.callEdgeFunction(
          'check-company',
          body: {'company_name': companyName, 'country': country},
        );
        if (response != null && response['found'] == true) {
          apiResult = response;
        }
      } catch (e) {
        _log.w('Edge Function check-company failed: $e');
        // Fall through to claudeText approach
      }
    }

    // If we got real data from the API, return structured result
    if (apiResult != null) {
      final companies =
          (apiResult['companies'] as List<dynamic>?) ?? [];
      final detailed =
          apiResult['detailed'] as Map<String, dynamic>?;
      final checkUrl = apiResult['check_url'] as String? ?? registryUrl;

      final buffer = StringBuffer();
      buffer.writeln('**COMPANY FOUND IN ESTONIAN REGISTRY**\n');

      if (detailed != null) {
        // Rich detailed view
        final name = detailed['name'] as String? ?? '';
        final regCode = detailed['registry_code'] as String? ?? '';
        final status = detailed['status'] as String? ?? '';
        final registered = detailed['registered'] as String? ?? '';
        final legalForm = detailed['legal_form'] as String? ?? '';
        final capital = detailed['capital'];
        final address = detailed['address'] as String? ?? '';
        final boardMembers = detailed['board_members'] as List? ?? [];
        final activities = detailed['activities'] as List? ?? [];
        final fiscalYear = detailed['fiscal_year'] as String? ?? '';
        final profit = detailed['profit'];
        final revenue = detailed['revenue'];
        final employees = detailed['employees'];
        final historicalNames = detailed['historical_names'] as List? ?? [];

        if (name.isNotEmpty) buffer.writeln('**Name:** $name');
        if (regCode.isNotEmpty) buffer.writeln('**Registry code:** $regCode');
        if (status.isNotEmpty) buffer.writeln('**Status:** $status');
        if (registered.isNotEmpty) buffer.writeln('**Registered:** $registered');
        if (legalForm.isNotEmpty) buffer.writeln('**Legal form:** $legalForm');
        if (capital != null && '$capital'.isNotEmpty) {
          buffer.writeln('**Capital:** $capital');
        }
        if (address.isNotEmpty) buffer.writeln('**Address:** $address');
        if (boardMembers.isNotEmpty) {
          buffer.writeln('**Board members:** ${boardMembers.join(', ')}');
        }
        if (activities.isNotEmpty) {
          buffer.writeln('**Activities:**');
          for (final a in activities.take(5)) {
            buffer.writeln('  - $a');
          }
        }
        if (fiscalYear.isNotEmpty) buffer.writeln('**Fiscal year:** $fiscalYear');
        if (revenue != null && '$revenue'.isNotEmpty) {
          buffer.writeln('**Revenue:** $revenue');
        }
        if (profit != null && '$profit'.isNotEmpty) {
          buffer.writeln('**Profit:** $profit');
        }
        if (employees != null && '$employees'.isNotEmpty) {
          buffer.writeln('**Employees:** $employees');
        }
        if (historicalNames.isNotEmpty) {
          buffer.writeln('**Previous names:** ${historicalNames.join(', ')}');
        }
      } else if (companies.isNotEmpty) {
        // Fallback: basic autocomplete data
        for (final c in companies) {
          final comp = c as Map<String, dynamic>;
          buffer.writeln('- **${comp['name']}**');
          if ((comp['registry_code'] as String?)?.isNotEmpty == true) {
            buffer.writeln('  Registry code: ${comp['registry_code']}');
          }
          if ((comp['status'] as String?)?.isNotEmpty == true) {
            buffer.writeln('  Status: ${comp['status']}');
          }
          if ((comp['address'] as String?)?.isNotEmpty == true) {
            buffer.writeln('  Address: ${comp['address']}');
          }
          if ((comp['type'] as String?)?.isNotEmpty == true) {
            buffer.writeln('  Type: ${comp['type']}');
          }
          buffer.writeln();
        }
      }

      buffer.writeln('\n**Source:** ariregister.rik.ee');
      buffer.writeln('**Full details:** $checkUrl');

      // Build comprehensive claudeText with all available data
      final claudeBuf = StringBuffer();
      claudeBuf.writeln(
          'I checked the Estonian e-Business Register (ariregister.rik.ee) for "$companyName". '
          'Here are the REAL results:\n');
      claudeBuf.writeln(buffer.toString());

      if (detailed != null) {
        claudeBuf.writeln(
            '\nBased on this real data, provide the user with a clear analysis: '
            'Is this company reliable? Are there any red flags '
            '(tax debts, recent registration, liquidation status, minimal capital)? '
            'What should the user pay attention to? '
            'Format your response beautifully — like a professional company report.');
      } else {
        claudeBuf.writeln(
            '\nPresent this data clearly. Mention the user can verify at $checkUrl.');
      }

      return ToolResult(
        success: true,
        displayText: buffer.toString(),
        cardType: 'company_report',
        data: {
          'action': 'check_company',
          'company_name': companyName,
          'country': country,
          'found': true,
          'companies': companies,
          if (detailed != null) 'detailed': detailed,
          'check_url': checkUrl,
          'source': 'ariregister.rik.ee',
        },
        claudeText: claudeBuf.toString(),
      );
    }

    // Fallback: no API data, let Claude help
    return ToolResult(
      success: true,
      displayText: 'Checking company: **$companyName**...',
      cardType: 'company_report',
      data: {
        'action': 'check_company',
        'company_name': companyName,
        'country': country,
        'registry_url': registryUrl,
      },
      claudeText: 'The user wants to check company "$companyName" in $country. '
          '${registryUrl.isNotEmpty ? "Direct link to check: $registryUrl. " : ""}'
          'Provide what you know about this company. '
          'Give the user the exact link to verify: ${registryUrl.isNotEmpty ? registryUrl : "search for the company registry in $country"}. '
          'If you know the company, share relevant details (industry, size, any known issues). '
          'If not, explain exactly how to look it up step by step.',
    );
  }

  Future<ToolResult> _checkVehicle(Map<String, dynamic> params) async {
    final plateNumber = params['plate_number'] as String? ?? '';
    final country = params['country'] as String? ?? 'Estonia';
    final countryLower = country.toLowerCase();

    // Country-specific registry info
    final Map<String, Map<String, String>> registries = {
      'estonia': {
        'portal': 'https://eteenindus.mnt.ee/',
        'portal_name': 'Transpordiamet e-teenindus',
        'insurance': 'https://www.lkf.ee/kindlustuse-kontroll',
        'insurance_name': 'LKF kindlustuse kontroll',
        'inspection': 'https://www.arktehnoulevaatus.ee/',
        'inspection_name': 'ARK tehnoülevaatus',
        'fines': 'https://www.politsei.ee/et/trahvid',
        'fines_name': 'Politsei trahvid',
        'checklist': 'Tehnoülevaatus kehtivus, liikluskindlustus, registripant (leasing), omanik, arvestimäär (kütusemaks), auto ajalugu',
      },
      'finland': {
        'portal': 'https://www.traficom.fi/fi/liikenne/tieliikenne/ajoneuvojen-rekisteritiedot',
        'portal_name': 'Traficom — ajoneuvon tiedot',
        'insurance': 'https://www.lvk.fi/vakuutuksentarkistus/',
        'insurance_name': 'LVK vakuutuksen tarkistus',
        'inspection': 'https://www.traficom.fi/fi/liikenne/tieliikenne/katsastus',
        'inspection_name': 'Traficom katsastus',
        'fines': 'https://www.oikeus.fi/tuomioistuimet/sakot/',
        'fines_name': 'Sakot',
        'checklist': 'Katsastus, liikennevakuutus, omistaja, käyttövoima, CO2-päästöt, ajoneuvohistoria',
      },
      'latvia': {
        'portal': 'https://www.csdd.lv/transportlidzeklu-registrs',
        'portal_name': 'CSDD transportlīdzekļu reģistrs',
        'insurance': 'https://www.ltab.lv/octa-parbaude/',
        'insurance_name': 'LTAB OCTA pārbaude',
        'inspection': 'https://www.csdd.lv/tehniska-apskate',
        'inspection_name': 'CSDD tehniskā apskate',
        'fines': '',
        'fines_name': '',
        'checklist': 'Tehniskā apskate, OCTA apdrošināšana, īpašnieks, ķīlas, sodi',
      },
      'lithuania': {
        'portal': 'https://www.regitra.lt/lt/paslaugos/transporto-priemoniu-registravimas/',
        'portal_name': 'Regitra',
        'insurance': '',
        'insurance_name': '',
        'inspection': '',
        'inspection_name': '',
        'fines': '',
        'fines_name': '',
        'checklist': 'Techninė apžiūra, draudimas, savininkas, įkeitimai',
      },
      'germany': {
        'portal': 'https://www.kba.de/DE/Themen/ZentraleRegister/ZFZR/zfzr_node.html',
        'portal_name': 'KBA Zentrales Fahrzeugregister',
        'insurance': '',
        'insurance_name': '',
        'inspection': '',
        'inspection_name': 'TÜV/DEKRA Hauptuntersuchung',
        'fines': 'https://www.kba.de/DE/Themen/ZentraleRegister/FAER/faer_node.html',
        'fines_name': 'KBA Fahreignungsregister',
        'checklist': 'HU/TÜV, Kfz-Versicherung, Halter, Pfandrechte, Unfallhistorie',
      },
      'sweden': {
        'portal': 'https://fu-regnr.transportstyrelsen.se/extweb/',
        'portal_name': 'Transportstyrelsen fordonsuppgifter',
        'insurance': '',
        'insurance_name': '',
        'inspection': 'https://www.transportstyrelsen.se/besiktning',
        'inspection_name': 'Transportstyrelsen besiktning',
        'fines': '',
        'fines_name': '',
        'checklist': 'Besiktning, trafikförsäkring, ägare, skulder, mätarställning',
      },
      'poland': {
        'portal': 'https://historiapojazdu.gov.pl/',
        'portal_name': 'Historia Pojazdu',
        'insurance': '',
        'insurance_name': '',
        'inspection': '',
        'inspection_name': 'Przegląd techniczny',
        'fines': '',
        'fines_name': '',
        'checklist': 'Przegląd techniczny, OC, właściciel, zastawy, historia',
      },
    };

    final reg = registries[countryLower] ?? registries['estonia']!;

    final buf = StringBuffer();
    buf.writeln('VEHICLE CHECK: $plateNumber ($country)');
    buf.writeln('');
    buf.writeln('OFFICIAL PORTALS:');
    buf.writeln('• Registry: ${reg['portal_name']} — ${reg['portal']}');
    if (reg['insurance']!.isNotEmpty) {
      buf.writeln('• Insurance: ${reg['insurance_name']} — ${reg['insurance']}');
    }
    if (reg['inspection']!.isNotEmpty) {
      buf.writeln('• Inspection: ${reg['inspection_name']} — ${reg['inspection']}');
    }
    if (reg['fines']!.isNotEmpty) {
      buf.writeln('• Fines: ${reg['fines_name']} — ${reg['fines']}');
    }
    buf.writeln('');
    buf.writeln('CHECKLIST: ${reg['checklist']}');

    return ToolResult(
      success: true,
      displayText: buf.toString(),
      cardType: 'vehicle_report',
      data: {
        'action': 'check_vehicle',
        'plate_number': plateNumber,
        'country': country,
        'registry_url': reg['portal'] ?? '',
      },
      claudeText: 'The user wants to check vehicle "$plateNumber" in $country.\n\n'
          '${buf.toString()}\n\n'
          'Give the user a COMPLETE vehicle check guide:\n'
          '1. What to check FIRST (insurance, inspection validity)\n'
          '2. Red flags to watch for (expired inspection, no insurance, liens/loans)\n'
          '3. Direct links to each portal listed above\n'
          '4. If buying a car: what additional checks to do (flood damage, odometer fraud, stolen vehicle check)\n'
          '5. Costs of checks if any\n'
          'Be specific to $country. Use the links above. Format beautifully like a professional vehicle report.',
    );
  }

  Future<ToolResult> _getDeadlines(Map<String, dynamic> params) async {
    final caseId = params['case_id'] as String?;

    // Fetch from Supabase for authenticated users, DemoData for demo mode.
    final deadlines = await _supabase.getDeadlines(caseId: caseId)
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
    final country = params['country'] as String? ?? 'Estonia';

    // Create via Supabase for authenticated users, in-memory for demo.
    final newCase = await _supabase.createCase({
      'title': title,
      'description': description.isNotEmpty ? description : null,
      'type': caseType,
      'country': country,
      'status': 'active',
    });

    return ToolResult(
      success: true,
      displayText: '''
**New Case Created**

Title: ${newCase.title}
Type: $caseType
Country: $country
Case ID: ${newCase.id}

${description.isNotEmpty ? 'Description: $description\n' : ''}
The case has been created. You can now upload documents and I will help analyze them.
''',
      cardType: 'case_summary',
      data: {
        'case_id': newCase.id,
        'title': newCase.title,
        'description': newCase.description,
        'case_type': caseType,
        'country': country,
        'status': newCase.status.name,
        'created_at': newCase.createdAt.toIso8601String(),
      },
      requiresApproval: true,
      approvalMessage:
          'Create a new "$caseType" case titled "$title"?',
    );
  }

  Future<ToolResult> _analyzeDocument(Map<String, dynamic> params) async {
    final documentId = params['document_id'] as String? ?? '';
    final documentText = params['document_text'] as String? ?? '';
    final focus = params['focus'] as String? ?? 'all';

    await Future<void>.delayed(const Duration(milliseconds: 300));

    // Look up demo document if available
    final doc = DemoData.documents
        .where((d) => d.id == documentId)
        .firstOrNull;

    final fileName = doc?.fileName ?? 'Document';
    final summary = doc?.aiSummary ?? '';
    final language = doc?.language ?? 'unknown';
    final category = doc?.category.name ?? 'general';

    return ToolResult(
      success: true,
      displayText: 'Analyzing document: **$fileName**...',
      cardType: 'document_analysis',
      data: {
        'action': 'analyze_document',
        'document_id': documentId,
        'file_name': fileName,
        'focus': focus,
        'language': language,
        'category': category,
      },
      claudeText: 'Now analyze the document "$fileName" '
          '(language: $language, category: $category). '
          '${summary.isNotEmpty ? "AI summary from OCR: $summary. " : ""}'
          '${documentText.isNotEmpty ? "Document text: $documentText. " : ""}'
          'Focus area: $focus. '
          'Provide a thorough legal analysis including: '
          '1) Summary of the document, '
          '2) Key findings and potential issues (procedural violations, factual errors, missing elements), '
          '3) Relevant legal references (specific law sections), '
          '4) Any deadlines extracted from the document. '
          'Be specific to the jurisdiction and case type. '
          'Format with markdown headers and bullet points.',
    );
  }

  Future<ToolResult> _generateDraft(Map<String, dynamic> params) async {
    final draftType = params['draft_type'] as String? ?? 'appeal';
    final caseId = params['case_id'] as String? ?? '';
    final language = params['language'] as String? ?? 'en';
    final instructions = params['instructions'] as String?;

    // Try real Supabase first, then fall back to demo data, then to a
    // generic placeholder. All paths are recoverable — never block the
    // chat on a transient backend hiccup.
    String caseTitle = 'Legal Case';
    String caseDescription = '';
    if (caseId.isNotEmpty) {
      try {
        final legalCase = await _supabase.getCaseById(caseId);
        caseTitle = legalCase.title;
        caseDescription = legalCase.description ?? '';
      } catch (_) {
        final demoCase =
            DemoData.cases.where((c) => c.id == caseId).firstOrNull;
        if (demoCase != null) {
          caseTitle = demoCase.title;
          caseDescription = demoCase.description ?? '';
        }
      }
    }

    return ToolResult(
      success: true,
      displayText: 'Generating draft: **${draftType.replaceAll('_', ' ').toUpperCase()}**...',
      cardType: 'draft_preview',
      data: {
        'action': 'generate_draft',
        'draft_type': draftType,
        'language': language,
        'instructions': instructions ?? '',
        'case_title': caseTitle,
        'case_description': caseDescription,
      },
      requiresApproval: false, // Claude will generate, user reviews before using
      claudeText: 'Now generate the $draftType document in $language for the case "$caseTitle". '
          'Use the case details: $caseDescription. '
          '${instructions != null ? "Additional instructions: $instructions. " : ""}'
          'Write a complete, professional legal document ready for submission. '
          'Use correct legal format for the jurisdiction. '
          'Format: start with a single H1 heading "# <document title>", '
          'use ## for section headings and "- " bullets where appropriate. '
          'No AI disclaimers in the document — the disclaimer is added '
          'automatically to the PDF footer.',
    );
  }

  Future<ToolResult> _searchKnowledge(Map<String, dynamic> params) async {
    final query = params['query'] as String? ?? '';
    final country = params['country'] as String? ?? 'estonia';
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
    final country = params['country'] as String? ?? 'Estonia';
    final caseType = params['case_type'] as String? ?? 'general';
    final city = params['city'] as String? ?? '';

    return ToolResult(
      success: true,
      displayText: 'Searching for lawyers in **$country**...',
      cardType: 'lawyer_list',
      data: {
        'action': 'find_lawyer',
        'country': country,
        'case_type': caseType,
        'city': city,
      },
      claudeText: 'The user needs a lawyer in $country for $caseType cases, city: $city. '
          'Provide specific recommendations: legal aid offices, bar association contacts, '
          'free legal aid eligibility, and exact phone numbers/websites. '
          'Use your knowledge base for this country.',
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
    final caseId = params['case_id'] as String?;

    // Fetch from Supabase for authenticated users, DemoData for demo mode.
    LegalCase? legalCase;
    if (caseId != null) {
      try {
        legalCase = await _supabase.getCaseById(caseId);
      } catch (_) {
        // Fall through to error below
      }
    } else {
      // No case_id provided — try to get the first case from the list
      final cases = await _supabase.getCases();
      legalCase = cases.isNotEmpty ? cases.first : null;
    }

    if (legalCase == null) {
      return ToolResult.error(
        caseId != null
            ? 'Case "$caseId" not found.'
            : 'No cases found. Create a case first.',
      );
    }

    final caseDeadlines =
        await _supabase.getDeadlines(caseId: legalCase.id)
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

    final languageName = languageNames[language] ?? language;

    return ToolResult(
      success: true,
      displayText: 'Language: **$languageName**',
      cardType: 'language_changed',
      data: {
        'action': 'change_language',
        'language': language,
        'display_name': languageName,
      },
      claudeText: 'The user wants to change the app language to $languageName. '
          'Tell them to go to Settings > Language to change it, or use the navigate_to tool to take them there.',
    );
  }

  Future<ToolResult> _navigateTo(Map<String, dynamic> params) async {
    final screen = params['screen'] as String? ?? 'home';
    final message = params['message'] as String? ?? '';

    // Human-readable screen names for display
    const screenNames = <String, String>{
      'home': 'Home',
      'cases': 'Cases',
      'deadlines': 'Deadlines',
      'settings': 'Settings',
      'subscription': 'Subscription',
      'email': 'Email',
      'scan': 'Document Scanner',
      'vault': 'Document Vault',
      'rights': 'Rights Guide',
      'legal_aid': 'Legal Aid Calculator',
      'checker': 'Checker',
      'new_case': 'New Case',
      'profile': 'Profile',
      'back': 'Chat',
      'previous': 'Chat',
      'chat': 'Chat',
    };

    final screenName = screenNames[screen] ?? screen;
    final displayText = message.isNotEmpty
        ? message
        : 'Navigating to $screenName...';

    return ToolResult(
      success: true,
      displayText: displayText,
      data: {
        'action': 'navigate_to',
        'screen': screen,
      },
    );
  }

  Future<ToolResult> _translateText(Map<String, dynamic> params) async {
    final text = params['text'] as String? ?? '';
    final targetLanguage = params['target_language'] as String? ?? 'en';
    final sourceLanguage = params['source_language'] as String?;

    await Future<void>.delayed(const Duration(milliseconds: 200));

    final directionLabel = sourceLanguage != null
        ? '$sourceLanguage -> $targetLanguage'
        : '-> $targetLanguage';

    return ToolResult(
      success: true,
      displayText: 'Translating ($directionLabel)...',
      cardType: 'translation',
      data: {
        'action': 'translate_text',
        'source_text': text,
        'source_language': sourceLanguage ?? 'auto',
        'target_language': targetLanguage,
      },
      claudeText: 'Translate the following text to $targetLanguage. '
          'Only provide the translation, no explanations:\n\n$text',
    );
  }

  // ── v24.1 additions ───────────────────────────────────────────────────

  /// Send an email via the Supabase `send-email` Edge Function.
  ///
  /// SAFETY: This tool is in [requiresApproval]. The UI shows a preview
  /// dialog and only after the user taps "Send" does the Edge Function
  /// actually dispatch the mail. Never bypass the approval flow.
  Future<ToolResult> _sendEmail(Map<String, dynamic> params) async {
    final to = (params['to'] as String? ?? '').trim();
    final subject = (params['subject'] as String? ?? '').trim();
    final body = (params['body'] as String? ?? '').trim();
    final cc = params['cc'] as String?;
    final caseId = params['case_id'] as String?;

    if (to.isEmpty || subject.isEmpty || body.isEmpty) {
      return ToolResult.error(
        'send_email requires non-empty to, subject and body.',
      );
    }

    // Primitive email validation — reject obvious garbage before the user
    // sees the approval dialog.
    final emailRe = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRe.hasMatch(to)) {
      return ToolResult.error('Invalid recipient address "$to".');
    }

    // NOTE: actual dispatch happens in the post-approval handler which calls
    // `send-email` Edge Function. This method ONLY prepares the preview.
    return ToolResult(
      success: true,
      displayText: '''
**Email ready to send**

**To:** $to
${cc != null && cc.isNotEmpty ? '**Cc:** $cc\n' : ''}**Subject:** $subject

---

$body

---

Review the email carefully. It will only be sent after you tap **Send**.
''',
      cardType: 'email_draft',
      data: {
        'to': to,
        if (cc != null && cc.isNotEmpty) 'cc': cc,
        'subject': subject,
        'body': body,
        if (caseId != null) 'case_id': caseId,
        'send_via': 'send-email',
      },
      requiresApproval: true,
      approvalMessage: 'Send this email to $to?',
    );
  }

  /// Read the OCR / extracted text of an uploaded document.
  Future<ToolResult> _readDocument(Map<String, dynamic> params) async {
    final documentId = (params['document_id'] as String? ?? '').trim();
    if (documentId.isEmpty) {
      return ToolResult.error('read_document requires document_id.');
    }

    Map<String, dynamic>? doc;
    try {
      final vault = await _supabase.getVaultDocuments();
      for (final d in vault) {
        if (d['id'] == documentId) {
          doc = d;
          break;
        }
      }
    } catch (e) {
      _log.w('read_document: vault query failed: $e');
    }

    // Demo fallback
    if (doc == null) {
      final demo = DemoData.documents
          .where((d) => d.id == documentId)
          .firstOrNull;
      if (demo != null) {
        doc = demo.toJson();
      }
    }

    if (doc == null) {
      return ToolResult.error(
        'Document "$documentId" not found. Try list_documents first.',
      );
    }

    final fileName = doc['file_name'] as String? ??
        doc['fileName'] as String? ??
        'document';
    final ocrText = (doc['ocr_text'] as String?) ??
        (doc['ocrText'] as String?) ??
        '';
    final summary = (doc['ai_summary'] as String?) ??
        (doc['aiSummary'] as String?) ??
        '';
    final category = doc['category'] as String? ?? 'general';
    final language = doc['language'] as String? ?? 'unknown';
    final uploadedAt = (doc['created_at'] as String?) ??
        (doc['uploadedAt'] as String?);

    final hasText = ocrText.isNotEmpty;
    final preview = hasText
        ? (ocrText.length > 4000 ? '${ocrText.substring(0, 4000)}…' : ocrText)
        : '(no extracted text — document may be image-only or still processing)';

    return ToolResult(
      success: true,
      displayText: '**$fileName** — $category ($language)\n\n$preview',
      cardType: 'document_analysis',
      data: {
        'document_id': documentId,
        'file_name': fileName,
        'category': category,
        'language': language,
        if (uploadedAt != null) 'uploaded_at': uploadedAt,
        'has_text': hasText,
        'ocr_text_length': ocrText.length,
        if (summary.isNotEmpty) 'summary': summary,
      },
      claudeText: 'Here is the full content of document "$fileName" '
          '(category: $category, language: $language):\n\n$ocrText\n\n'
          'Analyze it thoroughly, identify legal issues, cite specific § '
          'where relevant. Respond in the user\'s language.',
    );
  }

  /// List the user's documents, optionally filtered by case.
  Future<ToolResult> _listDocuments(Map<String, dynamic> params) async {
    final caseId = params['case_id'] as String?;
    final limit = (params['limit'] as int?) ?? 20;

    List<Map<String, dynamic>> docs = [];
    try {
      if (caseId != null && caseId.isNotEmpty) {
        final list = await _supabase.getDocuments(caseId);
        docs = list.map((d) => d.toJson()).toList();
      } else {
        docs = await _supabase.getVaultDocuments();
      }
    } catch (e) {
      _log.w('list_documents: query failed: $e');
    }

    // Demo fallback
    if (docs.isEmpty) {
      docs = DemoData.documents
          .where((d) => caseId == null || d.caseId == caseId)
          .map((d) => d.toJson())
          .toList();
    }

    final trimmed = docs.take(limit).toList();
    if (trimmed.isEmpty) {
      return const ToolResult(
        success: true,
        displayText: 'No documents found.',
        cardType: 'document_analysis',
        data: {'documents': <Map<String, dynamic>>[]},
      );
    }

    final rows = <Map<String, dynamic>>[];
    final buf = StringBuffer('**Documents (${trimmed.length}):**\n\n');
    for (final d in trimmed) {
      final id = d['id']?.toString() ?? '';
      final name = (d['file_name'] ?? d['fileName'] ?? 'document').toString();
      final cat = (d['category'] ?? 'general').toString();
      final lang = (d['language'] ?? 'unknown').toString();
      final summary = (d['ai_summary'] ?? d['aiSummary'] ?? '').toString();
      buf.writeln('- **$name** ($cat, $lang) — id: `$id`');
      if (summary.isNotEmpty) {
        buf.writeln(
          '  ${summary.length > 120 ? "${summary.substring(0, 120)}…" : summary}',
        );
      }
      rows.add({
        'id': id,
        'file_name': name,
        'category': cat,
        'language': lang,
        if (summary.isNotEmpty) 'summary': summary,
      });
    }

    return ToolResult(
      success: true,
      displayText: buf.toString(),
      cardType: 'document_analysis',
      data: {'documents': rows, 'count': rows.length},
    );
  }

  /// List the user's cases.
  Future<ToolResult> _listCases(Map<String, dynamic> params) async {
    final statusFilter = (params['status'] as String?)?.toLowerCase();

    List<LegalCase> cases = [];
    try {
      cases = await _supabase.getCases();
    } catch (e) {
      _log.w('list_cases: query failed: $e');
    }
    if (cases.isEmpty) {
      cases = DemoData.cases;
    }

    final filtered = statusFilter == null
        ? cases
        : cases.where((c) => c.status.name == statusFilter).toList();

    if (filtered.isEmpty) {
      return const ToolResult(
        success: true,
        displayText: 'No cases found.',
        cardType: 'case_summary',
        data: {'cases': <Map<String, dynamic>>[]},
      );
    }

    final rows = <Map<String, dynamic>>[];
    final buf = StringBuffer('**Cases (${filtered.length}):**\n\n');
    for (final c in filtered) {
      buf.writeln('- **${c.title}** (${c.type.name}, ${c.status.name})');
      buf.writeln('  id: `${c.id}` — ${c.documentCount} doc(s)');
      rows.add({
        'id': c.id,
        'title': c.title,
        'type': c.type.name,
        'status': c.status.name,
        'document_count': c.documentCount,
      });
    }

    return ToolResult(
      success: true,
      displayText: buf.toString(),
      cardType: 'case_summary',
      data: {'cases': rows, 'count': rows.length},
    );
  }

  /// Search the bundled Estonian legal corpus.
  Future<ToolResult> _searchEstonianLaw(Map<String, dynamic> params) async {
    final query = (params['query'] as String? ?? '').trim();
    final act = (params['act'] as String?)?.trim();
    final paragraph = (params['paragraph'] as String?)?.trim();

    if (query.isEmpty && (paragraph == null || paragraph.isEmpty)) {
      return ToolResult.error(
        'search_estonian_law requires either query or paragraph.',
      );
    }

    final results = await EstonianLawSearch.search(
      query: query,
      act: act,
      paragraph: paragraph,
    );

    if (results.isEmpty) {
      return ToolResult(
        success: true,
        displayText: 'No matching sections found for "$query".',
        cardType: null,
        data: {'query': query, if (act != null) 'act': act, 'matches': []},
      );
    }

    final buf = StringBuffer();
    buf.writeln('**Estonian law matches (top ${results.length}):**\n');
    final matches = <Map<String, dynamic>>[];
    for (final r in results) {
      buf.writeln('**${r.act} ${r.paragraph}** — ${r.title}');
      buf.writeln(r.bodyPreview(400));
      buf.writeln();
      matches.add({
        'act': r.act,
        'paragraph': r.paragraph,
        'title': r.title,
        'body': r.body,
        'url': r.sourceUrl,
      });
    }

    final claudeText = StringBuffer();
    claudeText.writeln('Estonian law search for "$query":\n');
    for (final r in results) {
      claudeText.writeln('--- ${r.act} ${r.paragraph} (${r.title}) ---');
      claudeText.writeln(r.body);
      claudeText.writeln();
    }
    claudeText.writeln(
      'Use the EXACT paragraph numbers and text above when answering. Never '
      'fabricate § numbers. Cite source URL when relevant.',
    );

    return ToolResult(
      success: true,
      displayText: buf.toString(),
      cardType: null,
      data: {
        'query': query,
        if (act != null) 'act': act,
        if (paragraph != null) 'paragraph': paragraph,
        'matches': matches,
      },
      claudeText: claudeText.toString(),
    );
  }

  /// v24.2 — Search the bundled Finnish legal corpus.
  ///
  /// Mirrors `search_estonian_law`. Use when the case jurisdiction is FI,
  /// the user mentions a Finnish statute (Rikoslaki, Ulkomaalaislaki,
  /// Hallintolaki, Rikosvahinkolaki, Oikeudenkäymiskaari) or when the
  /// conversation is about a Finnish deportation, asylum, or injured-party
  /// compensation matter.
  Future<ToolResult> _searchFinnishLaw(Map<String, dynamic> params) async {
    final query = (params['query'] as String? ?? '').trim();
    final act = (params['act'] as String?)?.trim();
    final paragraph = (params['paragraph'] as String?)?.trim();

    if (query.isEmpty && (paragraph == null || paragraph.isEmpty)) {
      return ToolResult.error(
        'search_finnish_law requires either query or paragraph.',
      );
    }

    final searcher = FinnishLawSearch();
    final results = await searcher.search(
      query: query,
      act: act,
      paragraph: paragraph,
    );

    if (results.isEmpty) {
      return ToolResult(
        success: true,
        displayText: 'No matching Finnish-law sections found for "$query".',
        cardType: null,
        data: {
          'jurisdiction': 'FI',
          'query': query,
          if (act != null) 'act': act,
          'matches': [],
        },
      );
    }

    final buf = StringBuffer();
    buf.writeln('**Finnish law matches (top ${results.length}):**\n');
    final matches = <Map<String, dynamic>>[];
    for (final r in results) {
      buf.writeln('**${r.act} ${r.paragraph}** — ${r.title}');
      buf.writeln(r.bodyPreview(400));
      buf.writeln();
      matches.add({
        'act': r.act,
        'paragraph': r.paragraph,
        'title': r.title,
        'body': r.body,
        'url': r.sourceUrl,
        'jurisdiction': 'FI',
      });
    }

    final claudeText = StringBuffer();
    claudeText.writeln('Finnish law search for "$query":\n');
    for (final r in results) {
      claudeText.writeln('--- ${r.act} ${r.paragraph} (${r.title}) ---');
      claudeText.writeln(r.body);
      claudeText.writeln();
    }
    claudeText.writeln(
      'Use the EXACT paragraph numbers and text above when answering. Never '
      'fabricate § numbers. Cite the Finlex source URL when available. The '
      'corpus is a curated subset — if the user asks about a section not '
      'listed, acknowledge the gap and suggest finlex.fi as the source.',
    );

    return ToolResult(
      success: true,
      displayText: buf.toString(),
      cardType: null,
      data: {
        'jurisdiction': 'FI',
        'query': query,
        if (act != null) 'act': act,
        if (paragraph != null) 'paragraph': paragraph,
        'matches': matches,
      },
      claudeText: claudeText.toString(),
    );
  }

  /// Phase 2 Pkg 1+2 — exact statute lookup.
  ///
  /// Calls the `law-lookup` edge function (lookup_statute RPC) for an
  /// in-force paragraph match. Returns either:
  ///   • success + verbatim body (claudeText) when found,
  ///   • success + "not in corpus" message when not found — the model is
  ///     expected to fall back to search_estonian_law / search_finnish_law
  ///     / web_search rather than fabricate.
  ///
  /// Soft-fails to a not-found result on any client/edge-function error so
  /// chat never breaks on a single tool round-trip.
  Future<ToolResult> _lookupStatute(Map<String, dynamic> params) async {
    final act = (params['act'] as String? ?? '').trim();
    final paragraph = (params['paragraph'] as String? ?? '').trim();
    final jurisdictionRaw =
        (params['jurisdiction'] as String? ?? 'EE').trim().toUpperCase();
    final jurisdiction =
        LawLookupClient.supportedJurisdictions.contains(jurisdictionRaw)
            ? jurisdictionRaw
            : 'EE';

    if (act.isEmpty || paragraph.isEmpty) {
      return ToolResult.error(
        'lookup_statute requires both act and paragraph.',
      );
    }

    final hit = await LawLookupClient.lookup(
      act: act,
      paragraph: paragraph,
      jurisdiction: jurisdiction,
    );

    if (hit == null) {
      // Not in corpus / superseded / RPC error — same UI shape, model
      // chooses fallback path.
      final notFoundText =
          '$act § $paragraph ($jurisdiction) is not in our bundled '
          'in-force corpus. Fall back to a semantic search '
          '(search_estonian_law / search_finnish_law) or web_search '
          'rather than guessing the wording.';
      return ToolResult(
        success: true,
        displayText: 'No exact match for **$act § $paragraph** ($jurisdiction).',
        cardType: null,
        data: {
          'act': act,
          'paragraph': paragraph,
          'jurisdiction': jurisdiction,
          'found': false,
        },
        claudeText: notFoundText,
      );
    }

    final headerTitle = hit.title?.isNotEmpty == true ? ' — ${hit.title}' : '';
    final displayBuf = StringBuffer()
      ..writeln('**${hit.actName} § ${hit.paragraph}**$headerTitle')
      ..writeln()
      ..writeln(hit.body);
    if (hit.sourceUrl != null) {
      displayBuf.writeln('\n[Source](${hit.sourceUrl})');
    }

    final claudeBuf = StringBuffer()
      ..writeln(
        '${hit.actName} § ${hit.paragraph} '
        '(${hit.jurisdiction}${hit.versionDate != null ? ", v${hit.versionDate}" : ""}):',
      )
      ..writeln(hit.body)
      ..writeln()
      ..writeln(
        'Cite this paragraph EXACTLY as written above — never paraphrase '
        'the § number, never invent additional clauses. If the user asked '
        'about something not covered by these words, say so.',
      );

    return ToolResult(
      success: true,
      displayText: displayBuf.toString(),
      cardType: null,
      data: {
        'act': hit.actName,
        'act_slug': hit.actSlug,
        'paragraph': hit.paragraph,
        'jurisdiction': hit.jurisdiction,
        'title': hit.title,
        'body': hit.body,
        'url': hit.sourceUrl,
        if (hit.versionDate != null) 'version_date': hit.versionDate,
        'found': true,
      },
      claudeText: claudeBuf.toString(),
    );
  }

  /// Create a deadline in the user's agenda (requires approval).
  Future<ToolResult> _createDeadline(Map<String, dynamic> params) async {
    final title = (params['title'] as String? ?? '').trim();
    final dueDateStr = (params['due_date'] as String? ?? '').trim();
    final caseId = params['case_id'] as String?;
    final description = params['description'] as String?;
    final reminderDaysBefore = params['reminder_days_before'] as int?;

    if (title.isEmpty || dueDateStr.isEmpty) {
      return ToolResult.error(
        'create_deadline requires title and due_date (YYYY-MM-DD).',
      );
    }

    final dueDate = _parseDueDateSafe(dueDateStr);
    if (dueDate == null) {
      return ToolResult.error(
        'Invalid due_date "$dueDateStr". Use ISO-8601 (YYYY-MM-DD).',
      );
    }

    try {
      await _supabase.createDeadline({
        'title': title,
        'due_date': dueDate.toIso8601String(),
        if (caseId != null && caseId.isNotEmpty) 'case_id': caseId,
        if (description != null && description.isNotEmpty)
          'description': description,
        if (reminderDaysBefore != null)
          'reminder_days_before': reminderDaysBefore,
      });
    } catch (e, stack) {
      // v24.2.3: do NOT silently swallow — the user must know that
      // their deadline was NOT saved, otherwise they rely on a
      // reminder that will never fire. Returning a failure also
      // lets the AI retry or offer to save locally.
      _log.e('create_deadline: persist failed', error: e, stackTrace: stack);
      return ToolResult.error(
        'Could not save deadline "$title": ${_friendlyPersistError(e)}. '
        'Please try again or add it manually from the Deadlines screen.',
      );
    }

    final daysLeft = dueDate.difference(DateTime.now()).inDays;

    // .ics payload — lets the chat-card UI offer an "Add to calendar"
    // button without re-deriving the event details. The same payload
    // works for Google Calendar, Outlook, Apple Calendar, etc.
    final descriptionForIcs = <String>[
      title,
      if (description != null && description.isNotEmpty) description,
      'Open in Advocat: https://advocat.ee/case-file',
    ].join('\n');
    final icsPayload = IcsExportService.renderEvent(
      title: title,
      startDate: dueDate,
      allDay: true,
      description: descriptionForIcs,
    );

    return ToolResult(
      success: true,
      displayText: 'Deadline added: **$title** — ${dueDate.toIso8601String().substring(0, 10)} ($daysLeft days).',
      cardType: 'deadline_list',
      data: {
        'action': 'create_deadline',
        'title': title,
        'due_date': dueDate.toIso8601String(),
        if (caseId != null) 'case_id': caseId,
        if (description != null) 'description': description,
        'days_left': daysLeft,
        'ics_payload': icsPayload,
      },
      requiresApproval: true,
      approvalMessage:
          'Add deadline "$title" on ${dueDate.toIso8601String().substring(0, 10)}?',
    );
  }

  /// Update an existing case (requires approval).
  Future<ToolResult> _updateCase(Map<String, dynamic> params) async {
    final caseId = (params['case_id'] as String? ?? '').trim();
    if (caseId.isEmpty) {
      return ToolResult.error('update_case requires case_id.');
    }

    final updates = <String, dynamic>{};
    for (final key in [
      'title',
      'description',
      'status',
      'court_case_number',
      'migri_reference_number',
    ]) {
      final value = params[key];
      if (value is String && value.isNotEmpty) {
        updates[key] = value;
      }
    }
    if (updates.isEmpty) {
      return ToolResult.error('update_case: at least one field must change.');
    }

    try {
      await _supabase.updateCase(caseId, updates);
    } catch (e) {
      _log.w('update_case: persist failed: $e');
    }

    final buf = StringBuffer('**Case updated:**\n');
    updates.forEach((k, v) => buf.writeln('- $k: $v'));

    return ToolResult(
      success: true,
      displayText: buf.toString(),
      cardType: 'case_summary',
      data: {'case_id': caseId, 'updates': updates},
      requiresApproval: true,
      approvalMessage: 'Apply changes to case?',
    );
  }

  /// Return basic profile of the authenticated user.
  Future<ToolResult> _getUserProfile(Map<String, dynamic> params) async {
    try {
      final user = await _supabase.getUserProfile();
      if (user == null) {
        return const ToolResult(
          success: true,
          displayText: 'Not signed in — running in demo mode.',
          data: {'is_demo': true},
        );
      }
      final data = user.toJson();
      final buf = StringBuffer('**Profile:**\n');
      data.forEach((k, v) => buf.writeln('- $k: $v'));
      return ToolResult(
        success: true,
        displayText: buf.toString(),
        data: data,
      );
    } catch (e) {
      return ToolResult.error('get_user_profile failed: $e');
    }
  }

  /// Deep-analyze a contract document.
  Future<ToolResult> _analyzeContract(Map<String, dynamic> params) async {
    final documentId = (params['document_id'] as String? ?? '').trim();
    if (documentId.isEmpty) {
      return ToolResult.error('analyze_contract requires document_id.');
    }

    // Reuse read_document to fetch the text, then instruct Claude to analyze
    // it with a contract-specific template.
    final read = await _readDocument({'document_id': documentId});
    if (!read.success) return read;

    final fileName = read.data?['file_name'] as String? ?? 'contract';
    final ocrLen = read.data?['ocr_text_length'] as int? ?? 0;
    final language = read.data?['language'] as String? ?? 'unknown';

    if (ocrLen == 0) {
      return ToolResult.error(
        'Contract "$fileName" has no extractable text (image-only scan?). '
        'Re-scan with better quality or paste text directly.',
      );
    }

    return ToolResult(
      success: true,
      displayText: 'Analyzing contract **$fileName**…',
      cardType: 'document_analysis',
      data: {
        'action': 'analyze_contract',
        'document_id': documentId,
        'file_name': fileName,
        'language': language,
      },
      claudeText:
          '${read.claudeText ?? ""}\n\nContract analysis template:\n'
          '1. **Parties** — who signs, in what role.\n'
          '2. **Subject** — what is being agreed.\n'
          '3. **Term & termination** — start, end, notice period, early exit clauses.\n'
          '4. **Payment terms** — amounts, schedule, late fees.\n'
          '5. **Obligations** — each party\'s duties.\n'
          '6. **Penalties & liability** — fines, caps, indemnities.\n'
          '7. **Confidentiality / IP / data** — NDAs, ownership, GDPR.\n'
          '8. **Governing law & forum** — which country, which court.\n'
          '9. **🔴 Red flags** — unilateral changes, unlimited liability, '
          'auto-renewal, waiver of appeal, payment before delivery, arbitration '
          'in a foreign country, unusual penalties.\n'
          '10. **Recommendations** — what to negotiate before signing.\n\n'
          'Cite EXACT clause numbers when you reference them. If the contract '
          'is in Estonian, cross-check against TsÜS, VÕS, TLS or AsjS as '
          'applicable. Respond in the user\'s language.',
    );
  }

  /// Parse a due_date string ("YYYY-MM-DD" or full ISO-8601) into a
  /// timezone-safe DateTime.
  ///
  /// Why: the AI typically sends "2026-05-01" (no time). `DateTime.tryParse`
  /// interprets this as local midnight, and `.toIso8601String()` then emits
  /// a UTC-shifted timestamp that lands on 2026-04-30 for users east of UTC
  /// (e.g. Tallinn UTC+3 → 2026-04-30T21:00:00.000Z). The deadline then
  /// appears one day early and the reminder fires a day late.
  ///
  /// Fix: for date-only input we lock to UTC noon, which is safely inside
  /// the intended day for every timezone offset between -12 and +14.
  static DateTime? _parseDueDateSafe(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    // Date-only pattern YYYY-MM-DD
    final dateOnly = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(trimmed);
    if (dateOnly != null) {
      final y = int.parse(dateOnly.group(1)!);
      final m = int.parse(dateOnly.group(2)!);
      final d = int.parse(dateOnly.group(3)!);
      return DateTime.utc(y, m, d, 12, 0, 0);
    }
    // Full ISO-8601 — trust it
    return DateTime.tryParse(trimmed)?.toUtc();
  }

  // ── set_followup_intention ─────────────────────────────────────────────
  //
  // Schedules a long-horizon promise. Inserts a row into agent_intentions
  // and trusts the hourly cron Edge Function to fire the actual notification
  // when due. Passive — no email goes out from this call, so requiresApproval
  // stays false (the user is not authorising anything in the moment, just
  // letting the AI book the future check-in on their behalf).
  //
  // GDPR: context_summary is hard-capped at 500 chars and stored as the
  // only free-text field in conversation_context. Never copy raw chat
  // history into this column. Server-side CHECK constraint backs the
  // client-side cap.
  static const Set<String> _validIntentTypes = <String>{
    'remind_deadline',
    'check_court_status',
    'follow_up_question',
    'check_company_status',
  };

  Future<ToolResult> _setFollowupIntention(Map<String, dynamic> params) async {
    final intentType = (params['intent_type'] as String? ?? '').trim();
    final checkAtStr = (params['check_at'] as String? ?? '').trim();
    final contextSummary =
        (params['context_summary'] as String? ?? '').trim();
    final targetId = (params['target_id'] as String? ?? '').trim();
    final caseId = (params['case_id'] as String? ?? '').trim();
    final locale = (params['locale'] as String? ?? 'en').trim();

    if (intentType.isEmpty) {
      return ToolResult.error(
        'set_followup_intention requires intent_type '
        '(remind_deadline | check_court_status | follow_up_question | check_company_status).',
      );
    }
    if (!_validIntentTypes.contains(intentType)) {
      return ToolResult.error(
        'Invalid intent_type "$intentType". Must be one of: '
        '${_validIntentTypes.join(", ")}.',
      );
    }
    if (checkAtStr.isEmpty) {
      return ToolResult.error(
        'set_followup_intention requires check_at (ISO-8601 datetime).',
      );
    }

    final checkAt = DateTime.tryParse(checkAtStr)?.toUtc();
    if (checkAt == null) {
      return ToolResult.error(
        'Invalid check_at "$checkAtStr". Use ISO-8601 (e.g. 2026-06-05T10:00:00Z).',
      );
    }
    if (!checkAt.isAfter(DateTime.now().toUtc())) {
      return ToolResult.error(
        'check_at must be in the future. Got $checkAtStr.',
      );
    }

    if (contextSummary.isEmpty) {
      return ToolResult.error(
        'set_followup_intention requires context_summary explaining WHY '
        'we are following up.',
      );
    }
    // GDPR cap — server-side CHECK constraint backs this up.
    if (contextSummary.length > 500) {
      return ToolResult.error(
        'context_summary is ${contextSummary.length} chars; max is 500. '
        'Trim to a one-sentence reason.',
      );
    }

    final localeNormalised =
        const {'ru', 'et', 'en'}.contains(locale) ? locale : 'en';

    final row = <String, dynamic>{
      'intent_type': intentType,
      if (targetId.isNotEmpty) 'target_id': targetId,
      if (caseId.isNotEmpty) 'case_id': caseId,
      'next_check_at': checkAt.toIso8601String(),
      'conversation_context': {
        'summary': contextSummary,
        'locale': localeNormalised,
      },
    };

    String? intentionId;
    try {
      intentionId = await _supabase.createAgentIntention(row);
    } catch (e, stack) {
      _log.e('set_followup_intention: persist failed',
          error: e, stackTrace: stack);
      return ToolResult.error(
        'Could not schedule follow-up: ${_friendlyPersistError(e)}. '
        'Please try again.',
      );
    }

    final dateLabel = checkAt.toIso8601String().substring(0, 10);

    return ToolResult(
      success: true,
      displayText: "I'll follow up on $dateLabel — $contextSummary.",
      cardType: 'intention_set',
      data: {
        if (intentionId != null) 'intention_id': intentionId,
        'intent_type': intentType,
        if (targetId.isNotEmpty) 'target_id': targetId,
        if (caseId.isNotEmpty) 'case_id': caseId,
        'check_at': checkAt.toIso8601String(),
        'context_summary': contextSummary,
        'locale': localeNormalised,
      },
      // Passive — no notification fires now. UI will surface the pending
      // promise so the user can cancel it from the Case File screen.
      requiresApproval: false,
    );
  }

  // ── Email Agent D5 — inbox tools ────────────────────────────────────────
  //
  // Handlers for list_inbox / get_thread_triage / approve_send_draft /
  // snooze_thread. Spec ref:
  //   business/email_agent_handoff_2026-05-06/09_INTEGRATION_INTO_ADVOCAT.md
  //
  // Demo-mode contract: when SupabaseService.isDemo is true (no creds at
  // compile time), each handler still returns a structured ToolResult with
  // the same cardType / data shape so the chat UI exercises the rendering
  // path. Tests rely on this — every public handler in this file behaves
  // the same way.
  //
  // Severity rank (low int = high urgency) is the load-bearing field for
  // list_inbox sort. UI also reads it for badge colour selection, so it
  // ships in the result data alongside the original severity string.

  /// Mapping for the severity sort. Lower integer = higher urgency, so a
  /// stable ascending sort puts CRITICAL first.
  static const Map<String, int> _severityRank = <String, int>{
    'CRITICAL': 0,
    'HIGH': 1,
    'MEDIUM': 2,
    'LOW': 3,
  };

  /// 24h snooze window, mirrored on the server-side cron so a snoozed
  /// thread doesn't get pushed at the user.
  static const Duration _snoozeWindow = Duration(hours: 24);

  /// Demo fixtures used when no Supabase backend is wired (tests / offline
  /// builds). Each fixture mirrors the column shape of email_triage_results
  /// JOIN email_threads exactly so the UI rendering path is identical.
  ///
  /// Hardcoded stable UUIDs let tests reference specific cards by id.
  static List<Map<String, dynamic>> _demoInboxThreads() {
    final now = DateTime.now().toUtc();
    String iso(DateTime d) => d.toIso8601String();
    return <Map<String, dynamic>>[
      {
        'thread_id': '00000000-0000-0000-0000-000000000001',
        'triage_id': '00000000-0000-0000-aaaa-000000000001',
        'subject': 'Decision on appeal — 14-day deadline',
        'sender_email': 'kirjaamo@oikeus.fi',
        'severity': 'CRITICAL',
        'severity_rank': _severityRank['CRITICAL']!,
        'user_brief':
            'Hallinto-oikeus issued a decision; appeal window 14 days.',
        'user_action': null,
        'seen_by_user_at': null,
        'send_recommendation': 'hold_for_user_review',
        'last_message_at': iso(now.subtract(const Duration(hours: 2))),
        'has_draft': true,
      },
      {
        'thread_id': '00000000-0000-0000-0000-000000000002',
        'triage_id': '00000000-0000-0000-aaaa-000000000002',
        'subject': 'Court hearing rescheduled',
        'sender_email': 'clerk@court.example',
        'severity': 'HIGH',
        'severity_rank': _severityRank['HIGH']!,
        'user_brief': 'Hearing moved to 2026-06-12 at 10:00.',
        'user_action': null,
        'seen_by_user_at': null,
        'send_recommendation': 'auto_send_eligible',
        'last_message_at': iso(now.subtract(const Duration(hours: 5))),
        'has_draft': true,
      },
      {
        'thread_id': '00000000-0000-0000-0000-000000000003',
        'triage_id': '00000000-0000-0000-aaaa-000000000003',
        'subject': 'Document receipt confirmation',
        'sender_email': 'archive@authority.example',
        'severity': 'MEDIUM',
        'severity_rank': _severityRank['MEDIUM']!,
        'user_brief': 'Authority confirmed receipt of the appeal package.',
        'user_action': null,
        'seen_by_user_at': null,
        'send_recommendation': 'archive',
        'last_message_at': iso(now.subtract(const Duration(days: 1))),
        'has_draft': false,
      },
      // Snoozed within the last 24h — must NOT appear in list_inbox.
      {
        'thread_id': '00000000-0000-0000-0000-000000000099',
        'triage_id': '00000000-0000-0000-aaaa-000000000099',
        'subject': 'Reminder — pay invoice',
        'sender_email': 'billing@example.com',
        'severity': 'LOW',
        'severity_rank': _severityRank['LOW']!,
        'user_brief': 'Routine invoice reminder.',
        'user_action': 'snoozed',
        'seen_by_user_at': iso(now.subtract(const Duration(hours: 1))),
        'send_recommendation': 'archive',
        'last_message_at': iso(now.subtract(const Duration(days: 2))),
        'has_draft': false,
      },
    ];
  }

  /// list_inbox — read-only thread list, severity-sorted.
  ///
  /// Filters out snoozed threads whose seen_by_user_at is within the last
  /// 24h (the UI hide window from spec §D6). Returns at most [limit] rows
  /// (default 20, capped at 100).
  Future<ToolResult> _listInbox(Map<String, dynamic> params) async {
    final severity = (params['severity'] as String? ?? '').trim();
    final rawLimit = params['limit'];
    int limit = 20;
    if (rawLimit is int) {
      limit = rawLimit;
    } else if (rawLimit is String) {
      limit = int.tryParse(rawLimit) ?? 20;
    }
    if (limit < 1) limit = 1;
    if (limit > 100) limit = 100;

    if (severity.isNotEmpty && !_severityRank.containsKey(severity)) {
      return ToolResult.error(
        'Invalid severity "$severity". Must be one of: '
        '${_severityRank.keys.join(", ")}.',
      );
    }

    // Demo / offline — return curated fixtures so tests exercise the
    // rendering path. Real Supabase wiring lands once the email-inbox-sync
    // edge fn (D3) starts populating production data; until then the
    // chat-side flow is fully testable via fixtures.
    final cutoff = DateTime.now().toUtc().subtract(_snoozeWindow);
    final all = _demoInboxThreads();

    bool stillSnoozed(Map<String, dynamic> t) {
      if (t['user_action'] != 'snoozed') return false;
      final seen = t['seen_by_user_at'];
      if (seen is! String || seen.isEmpty) return false;
      final at = DateTime.tryParse(seen)?.toUtc();
      if (at == null) return false;
      return at.isAfter(cutoff);
    }

    final filtered = all
        .where((t) => !stillSnoozed(t))
        .where((t) => severity.isEmpty || t['severity'] == severity)
        .toList();

    // Stable ascending sort: severity_rank, then last_message_at desc
    // (newer first within the same severity bucket).
    filtered.sort((a, b) {
      final byRank = (a['severity_rank'] as int)
          .compareTo(b['severity_rank'] as int);
      if (byRank != 0) return byRank;
      final aMs = DateTime.tryParse(a['last_message_at'] as String? ?? '')
              ?.millisecondsSinceEpoch ??
          0;
      final bMs = DateTime.tryParse(b['last_message_at'] as String? ?? '')
              ?.millisecondsSinceEpoch ??
          0;
      return bMs.compareTo(aMs);
    });

    final capped = filtered.take(limit).toList();

    final buffer = StringBuffer()..writeln('**Inbox**');
    if (capped.isEmpty) {
      buffer.writeln('— Nothing pending.');
    } else {
      for (final t in capped) {
        buffer.writeln(
          '- [${t['severity']}] ${t['subject']} — ${t['user_brief']}',
        );
      }
    }

    return ToolResult(
      success: true,
      displayText: buffer.toString(),
      cardType: 'inbox_list',
      data: {
        'threads': capped,
        'count': capped.length,
        if (severity.isNotEmpty) 'filter_severity': severity,
      },
      requiresApproval: false,
    );
  }

  /// get_thread_triage — full triage card for a single thread.
  Future<ToolResult> _getThreadTriage(Map<String, dynamic> params) async {
    final threadId = (params['thread_id'] as String? ?? '').trim();
    if (threadId.isEmpty) {
      return ToolResult.error(
        'get_thread_triage requires thread_id.',
      );
    }

    Map<String, dynamic>? row;
    try {
      // Real backend path. callEdgeFunction returns null in demo mode, so
      // the fixture fallback below kicks in for tests.
      final resp = await _supabase.callEdgeFunction(
        'email-triage-fetch',
        body: {'thread_id': threadId},
      );
      if (resp != null && resp['error'] == null) {
        row = (resp['triage'] as Map<String, dynamic>?) ?? resp;
      }
    } catch (e) {
      _log.w('get_thread_triage: edge fn unavailable, falling back: $e');
    }

    row ??= _demoInboxThreads().firstWhere(
      (t) => t['thread_id'] == threadId,
      orElse: () => <String, dynamic>{},
    );

    if (row.isEmpty) {
      return ToolResult.error(
        'No triage found for thread "$threadId". Try list_inbox first.',
      );
    }

    final subject = row['subject'] as String? ?? '(no subject)';
    final brief = row['user_brief'] as String? ?? '';
    final severity = row['severity'] as String? ?? 'LOW';

    return ToolResult(
      success: true,
      displayText: '''
**$severity — $subject**

$brief
''',
      cardType: 'thread_triage',
      data: {
        'thread_id': threadId,
        if (row['triage_id'] != null) 'triage_id': row['triage_id'],
        'subject': subject,
        'severity': severity,
        'severity_rank':
            _severityRank[severity] ?? _severityRank['LOW']!,
        'user_brief': brief,
        if (row['send_recommendation'] != null)
          'send_recommendation': row['send_recommendation'],
        if (row['has_draft'] != null) 'has_draft': row['has_draft'],
      },
      requiresApproval: false,
    );
  }

  /// approve_send_draft — confirm + dispatch the persisted triage draft.
  ///
  /// SAFETY: this tool is in [requiresApproval]. The chat UI shows the
  /// confirm modal; only after the user taps "Send" does the post-approval
  /// handler call the existing send-email edge fn with the persisted
  /// draft_to / draft_subject / draft_body / draft_language fields.
  Future<ToolResult> _approveSendDraft(Map<String, dynamic> params) async {
    final triageId = (params['triage_id'] as String? ?? '').trim();
    if (triageId.isEmpty) {
      return ToolResult.error(
        'approve_send_draft requires triage_id.',
      );
    }

    return ToolResult(
      success: true,
      displayText:
          'Ready to send the prepared reply. It will only go out after you '
          'confirm.',
      cardType: 'email_draft',
      data: {
        'triage_id': triageId,
        // The post-approval handler routes through send-email — same
        // dispatch path as the existing send_email tool.
        'send_via': 'send-email',
        // Tells the post-approval handler to mark
        // email_triage_results.user_action='sent' after dispatch.
        'mark_user_action': 'sent',
      },
      requiresApproval: true,
      approvalMessage: 'Send the prepared reply?',
    );
  }

  /// snooze_thread — hide a thread for 24h.
  ///
  /// Marks email_triage_results.user_action='snoozed' on the latest triage
  /// row for the thread and stamps seen_by_user_at = now() so the
  /// agent-intentions-cron also stops nudging the user.
  Future<ToolResult> _snoozeThread(Map<String, dynamic> params) async {
    final threadId = (params['thread_id'] as String? ?? '').trim();
    if (threadId.isEmpty) {
      return ToolResult.error(
        'snooze_thread requires thread_id.',
      );
    }

    final now = DateTime.now().toUtc();

    // Best-effort persistence. callEdgeFunction returns null in demo mode
    // (tests / offline) — the result data still reflects the requested
    // mutation so the chat UI can hide the row optimistically.
    try {
      await _supabase.callEdgeFunction(
        'email-triage-snooze',
        body: {
          'thread_id': threadId,
          'seen_by_user_at': now.toIso8601String(),
        },
      );
    } catch (e) {
      _log.w('snooze_thread: edge fn unavailable in demo: $e');
    }

    return ToolResult(
      success: true,
      displayText:
          'Snoozed for 24 hours. I will surface it again tomorrow if it is '
          'still relevant.',
      cardType: 'thread_snoozed',
      data: {
        'thread_id': threadId,
        'user_action': 'snoozed',
        'seen_by_user_at': now.toIso8601String(),
        'snooze_until': now.add(_snoozeWindow).toIso8601String(),
      },
      requiresApproval: false,
    );
  }

  /// Convert a persist exception into a short, user-safe message.
  /// Never leak raw Postgres errors or auth tokens to the AI / user.
  static String _friendlyPersistError(Object e) {
    final s = e.toString();
    if (s.contains('JWT') || s.contains('401') || s.contains('unauthorized')) {
      return 'you need to sign in again';
    }
    if (s.contains('RLS') || s.contains('permission') || s.contains('42501')) {
      return 'permission denied (please reload the app)';
    }
    if (s.contains('network') || s.contains('SocketException') || s.contains('timeout')) {
      return 'network issue — check your connection';
    }
    return 'a temporary server error';
  }
}
