// ---------------------------------------------------------------------------
// Tool definitions for Claude API tool_use format
// ---------------------------------------------------------------------------

/// Defines all tools available to the AI assistant in the Claude API
/// tool_use format. These definitions tell the AI what functions it can call,
/// their parameters, and when to use them.
abstract final class ToolDefinitions {
  /// All tool definitions in Claude API tool_use format.
  static const List<Map<String, dynamic>> toolDefinitions = [
    {
      'name': 'check_company',
      'description':
          'Check a company\'s registration status, tax debts, court cases, '
              'and overall risk level. Use when the user asks about a company, '
              'employer, or business partner.',
      'input_schema': {
        'type': 'object',
        'properties': {
          'company_name': {
            'type': 'string',
            'description': 'Company name or registration number (Y-tunnus)',
          },
          'country': {
            'type': 'string',
            'description':
                'Country code: ee, fi, lv, lt, de, se, etc. Defaults to fi.',
          },
        },
        'required': ['company_name'],
      },
    },
    {
      'name': 'check_vehicle',
      'description':
          'Look up a vehicle by registration plate to check ownership history, '
              'inspection status, insurance, and any liens or restrictions.',
      'input_schema': {
        'type': 'object',
        'properties': {
          'plate_number': {
            'type': 'string',
            'description': 'Vehicle registration plate number (e.g., 908FBT)',
          },
          'country': {
            'type': 'string',
            'description': 'Country code where the vehicle is registered.',
          },
        },
        'required': ['plate_number'],
      },
    },
    {
      'name': 'get_deadlines',
      'description':
          'Get upcoming legal deadlines and important dates for the user\'s '
              'cases. Use when the user asks about deadlines, dates, or schedule.',
      'input_schema': {
        'type': 'object',
        'properties': {
          'case_id': {
            'type': 'string',
            'description':
                'Specific case ID to get deadlines for. If omitted, returns all.',
          },
          'include_past': {
            'type': 'boolean',
            'description': 'Whether to include past deadlines. Default false.',
          },
        },
        'required': <String>[],
      },
    },
    {
      'name': 'create_case',
      'description':
          'Create a new legal case for the user. Use when the user describes '
              'a new legal problem that should be tracked.',
      'input_schema': {
        'type': 'object',
        'properties': {
          'title': {
            'type': 'string',
            'description': 'Short title for the case.',
          },
          'description': {
            'type': 'string',
            'description': 'Detailed description of the legal issue.',
          },
          'case_type': {
            'type': 'string',
            'description':
                'Type of case: deportation, asylum, residence_permit, '
                    'family_reunification, citizenship, work_permit, '
                    'labor_dispute, tenant_rights, debt_collection, '
                    'discrimination, police_misconduct, social_benefits, other.',
          },
          'country': {
            'type': 'string',
            'description': 'Country where the legal issue occurred.',
          },
        },
        'required': ['title', 'case_type'],
      },
    },
    {
      'name': 'analyze_document',
      'description':
          'Analyze an uploaded document to extract key information, deadlines, '
              'legal references, and potential issues.',
      'input_schema': {
        'type': 'object',
        'properties': {
          'document_id': {
            'type': 'string',
            'description': 'ID of the document to analyze.',
          },
          'case_id': {
            'type': 'string',
            'description': 'Case ID the document belongs to.',
          },
          'focus': {
            'type': 'string',
            'description':
                'What to focus the analysis on: deadlines, errors, '
                    'legal_references, summary, or all.',
          },
        },
        'required': ['document_id'],
      },
    },
    {
      'name': 'generate_draft',
      'description':
          'Generate a draft legal document such as an appeal, complaint, '
              'or response letter. Requires user approval before finalizing.',
      'input_schema': {
        'type': 'object',
        'properties': {
          'draft_type': {
            'type': 'string',
            'description':
                'Type of document: appeal, complaint, response, '
                    'request_extension, freedom_of_information, cover_letter.',
          },
          'case_id': {
            'type': 'string',
            'description': 'Case ID to base the draft on.',
          },
          'language': {
            'type': 'string',
            'description':
                'Language for the draft: en, fi, de, sv, ru, et, lv, lt.',
          },
          'instructions': {
            'type': 'string',
            'description': 'Additional instructions for the draft content.',
          },
        },
        'required': ['draft_type', 'case_id'],
      },
    },
    {
      'name': 'search_knowledge',
      'description':
          'Search the legal knowledge base for information about laws, '
              'procedures, rights, and legal concepts relevant to the user\'s '
              'situation.',
      'input_schema': {
        'type': 'object',
        'properties': {
          'query': {
            'type': 'string',
            'description': 'The legal question or topic to search for.',
          },
          'country': {
            'type': 'string',
            'description': 'Country context for the search.',
          },
          'case_type': {
            'type': 'string',
            'description': 'Case type context for the search.',
          },
        },
        'required': ['query'],
      },
    },
    {
      'name': 'find_lawyer',
      'description':
          'Find legal aid offices, free legal assistance, and lawyer contacts '
              'in the user\'s country. Use when the user needs professional '
              'legal help.',
      'input_schema': {
        'type': 'object',
        'properties': {
          'country': {
            'type': 'string',
            'description': 'Country to search for legal aid in.',
          },
          'case_type': {
            'type': 'string',
            'description': 'Type of case to find a specialist for.',
          },
          'city': {
            'type': 'string',
            'description': 'City or region for local results.',
          },
        },
        'required': ['country'],
      },
    },
    {
      'name': 'open_camera',
      'description':
          'Open the device camera to scan or photograph a document. '
              'Use when the user wants to upload or scan a document.',
      'input_schema': {
        'type': 'object',
        'properties': {
          'mode': {
            'type': 'string',
            'description': 'Camera mode: document_scan or photo. Default: document_scan.',
          },
        },
        'required': <String>[],
      },
    },
    {
      'name': 'draft_email',
      'description':
          'Draft an email to send to an authority, court, or lawyer. '
              'The draft will be shown to the user for approval before sending.',
      'input_schema': {
        'type': 'object',
        'properties': {
          'to': {
            'type': 'string',
            'description': 'Recipient email address.',
          },
          'subject': {
            'type': 'string',
            'description': 'Email subject line.',
          },
          'body': {
            'type': 'string',
            'description': 'Email body text.',
          },
          'case_id': {
            'type': 'string',
            'description': 'Related case ID for context.',
          },
        },
        'required': ['to', 'subject', 'body'],
      },
    },
    {
      'name': 'get_case_status',
      'description':
          'Get the current status and summary of a legal case including '
              'recent activity, next steps, and key information.',
      'input_schema': {
        'type': 'object',
        'properties': {
          'case_id': {
            'type': 'string',
            'description': 'The case ID to get status for.',
          },
        },
        'required': ['case_id'],
      },
    },
    {
      'name': 'change_language',
      'description':
          'Change the interface and conversation language. Use when the user '
              'asks to switch language or speaks in a different language.',
      'input_schema': {
        'type': 'object',
        'properties': {
          'language': {
            'type': 'string',
            'description':
                'Target language code: en, fi, de, sv, ru, et, lv, lt, ar, fr.',
          },
        },
        'required': ['language'],
      },
    },
    {
      'name': 'translate_text',
      'description':
          'Translate a piece of text to another language. Use when the user '
              'asks to translate a document excerpt, message, or legal term.',
      'input_schema': {
        'type': 'object',
        'properties': {
          'text': {
            'type': 'string',
            'description': 'The text to translate.',
          },
          'target_language': {
            'type': 'string',
            'description': 'Target language code: en, fi, de, sv, ru, et, lv, lt.',
          },
          'source_language': {
            'type': 'string',
            'description':
                'Source language code. If omitted, auto-detected.',
          },
        },
        'required': ['text', 'target_language'],
      },
    },
    {
      'name': 'navigate_to',
      'description':
          'Navigate the user to a specific screen in the app. Use this when '
              'the user asks to go somewhere, see something, or needs to access '
              'a feature. For example: "покажи мои дедлайны", "näita mulle seadeid", '
              '"show me my cases", "хочу подписаться", "помоги сфотографировать документ". '
              'Available screens: home, cases, deadlines, settings, subscription, '
              'email, scan, vault, rights, legal_aid, checker, new_case, profile.',
      'input_schema': {
        'type': 'object',
        'properties': {
          'screen': {
            'type': 'string',
            'description': 'The screen to navigate to.',
            'enum': [
              'home',
              'cases',
              'deadlines',
              'settings',
              'subscription',
              'email',
              'scan',
              'vault',
              'rights',
              'legal_aid',
              'checker',
              'new_case',
              'profile',
            ],
          },
          'message': {
            'type': 'string',
            'description':
                'Brief message to show the user about why we are navigating.',
          },
        },
        'required': ['screen'],
      },
    },
    // ── v24.1 additions: Claude-Code-parity tools ─────────────────────────
    {
      'name': 'send_email',
      'description':
          'Send an email on behalf of the user. ALWAYS requires explicit user '
              'approval — a preview dialog is shown and the user must tap '
              '"Send" before the email is actually dispatched. Never sends '
              'without confirmation. Use this when the user explicitly asks to '
              'send an email to someone (authority, court, lawyer, employer).',
      'input_schema': {
        'type': 'object',
        'properties': {
          'to': {
            'type': 'string',
            'description': 'Recipient email address.',
          },
          'subject': {
            'type': 'string',
            'description': 'Email subject line.',
          },
          'body': {
            'type': 'string',
            'description':
                'Full email body in plain text or simple markdown. Include '
                    'greeting and signature. Use the user\'s language.',
          },
          'cc': {
            'type': 'string',
            'description': 'Optional Cc address.',
          },
          'case_id': {
            'type': 'string',
            'description': 'Related case ID for logging to correspondence.',
          },
        },
        'required': ['to', 'subject', 'body'],
      },
    },
    {
      'name': 'read_document',
      'description':
          'Read the full extracted text (OCR or upload) of a document the '
              'user previously added to their vault or a case. Returns OCR '
              'text, file name, category and language. Use before '
              'analyze_contract or whenever the user refers to a document by '
              'name or asks you to look at it.',
      'input_schema': {
        'type': 'object',
        'properties': {
          'document_id': {
            'type': 'string',
            'description':
                'UUID of the document. Get it via list_documents first if '
                    'unsure.',
          },
        },
        'required': ['document_id'],
      },
    },
    {
      'name': 'list_documents',
      'description':
          'List the documents the user has uploaded. Optionally filter by '
              'case_id. Returns file name, short summary, upload date and id '
              'for each document. Use when the user asks "what documents do I '
              'have" or you need to pick one before read_document.',
      'input_schema': {
        'type': 'object',
        'properties': {
          'case_id': {
            'type': 'string',
            'description':
                'Optional case ID to filter documents by. Omit for all user '
                    'documents.',
          },
          'limit': {
            'type': 'integer',
            'description': 'Maximum number of documents. Default 20.',
          },
        },
        'required': <String>[],
      },
    },
    {
      'name': 'list_cases',
      'description':
          'List all legal cases belonging to the user, newest first. Returns '
              'id, title, type, status, last_activity for each. Use when the '
              'user asks about their cases or you need to find a case to act '
              'on.',
      'input_schema': {
        'type': 'object',
        'properties': {
          'status': {
            'type': 'string',
            'description':
                'Optional filter: active, closed, archived. Omit for all.',
          },
        },
        'required': <String>[],
      },
    },
    {
      'name': 'search_estonian_law',
      'description':
          'Semantic + paragraph lookup in the Estonian legal corpus (HMS, '
              'HKMS, PKS, TLS, KarS, VMS, VÕS, PärS, VõrdKS, MKS, TuMS, KMS, '
              'TsMS, KrMS, ÄS, IKS, LS, LKindlS, TsÜS, AsjS). If [paragraph] '
              'is given (e.g. "§ 121") it returns the exact text of that '
              'section. Otherwise performs keyword search across the corpus '
              'and returns the top 5 matching sections with citations.',
      'input_schema': {
        'type': 'object',
        'properties': {
          'query': {
            'type': 'string',
            'description':
                'The legal question or keywords (e.g. "koondamise hüvitis", '
                    '"срок апелляции deportации", "fraud under criminal code").',
          },
          'act': {
            'type': 'string',
            'description':
                'Optional act abbreviation to limit the search (e.g. KarS, '
                    'HMS, TLS, MKS).',
          },
          'paragraph': {
            'type': 'string',
            'description':
                'Optional direct § reference like "§ 121" or "§ 40 lg 3" to '
                    'retrieve the exact wording.',
          },
        },
        'required': ['query'],
      },
    },
    {
      'name': 'search_finnish_law',
      'description':
          'Semantic + paragraph lookup in the Finnish legal corpus '
              '(Ulkomaalaislaki, Rikoslaki, Rikosvahinkolaki, '
              'Oikeudenkäymiskaari including ROL 3:1, Hallintolaki). Use this '
              'ANY time the case jurisdiction is FI, the user mentions a '
              'Finnish statute, or the conversation is about a Finnish '
              'deportation (käännyttäminen), asylum, asianomistaja rights or '
              'Valtiokonttori compensation claim. The bundled corpus is a '
              'CURATED subset — if a specific section is not present, say so '
              'and point the user to finlex.fi.',
      'input_schema': {
        'type': 'object',
        'properties': {
          'query': {
            'type': 'string',
            'description':
                'The legal question or keywords (e.g. "törkeä pahoinpitely", '
                    '"valitusaika hallinto-oikeuteen", "asianomistajan '
                    'vaatimus", "Valtiokonttori kärsimys").',
          },
          'act': {
            'type': 'string',
            'description':
                'Optional act name to limit search: Ulkomaalaislaki, '
                    'Rikoslaki, Rikosvahinkolaki, Oikeudenkaymiskaari, '
                    'Hallintolaki.',
          },
          'paragraph': {
            'type': 'string',
            'description':
                'Optional direct paragraph reference like "RL 21:6", '
                    '"§ 168", or "ROL 3:1".',
          },
        },
        'required': ['query'],
      },
    },
    {
      'name': 'create_deadline',
      'description':
          'Create a new legal deadline in the user\'s agenda. Use when the '
              'user mentions a date that must not be missed (appeal deadline, '
              'court hearing, notary appointment). Always ask the user to '
              'confirm the date you parsed.',
      'input_schema': {
        'type': 'object',
        'properties': {
          'title': {
            'type': 'string',
            'description':
                'Short human-readable title (e.g. "Appeal deadline for '
                    'deportation decision").',
          },
          'due_date': {
            'type': 'string',
            'description': 'ISO-8601 date (YYYY-MM-DD) for when it is due.',
          },
          'case_id': {
            'type': 'string',
            'description': 'Optional case ID to link the deadline to.',
          },
          'description': {
            'type': 'string',
            'description': 'Optional longer explanation.',
          },
          'reminder_days_before': {
            'type': 'integer',
            'description':
                'How many days before the deadline to warn. Default 3.',
          },
        },
        'required': ['title', 'due_date'],
      },
    },
    {
      'name': 'update_case',
      'description':
          'Update an existing case with new metadata (title, description, '
              'status, court_case_number, migri_reference_number). Use when '
              'the user gives you new information about a case.',
      'input_schema': {
        'type': 'object',
        'properties': {
          'case_id': {
            'type': 'string',
            'description': 'UUID of the case to update.',
          },
          'title': {'type': 'string'},
          'description': {'type': 'string'},
          'status': {
            'type': 'string',
            'description':
                'One of: active, pending, closed, archived.',
          },
          'court_case_number': {'type': 'string'},
          'migri_reference_number': {'type': 'string'},
        },
        'required': ['case_id'],
      },
    },
    {
      'name': 'get_user_profile',
      'description':
          'Return the current user\'s profile: name, email, preferred '
              'language, country, subscription plan. Useful when the user '
              'asks "what do you know about me" or when you need to decide '
              'which jurisdiction to apply.',
      'input_schema': {
        'type': 'object',
        'properties': <String, Object>{},
        'required': <String>[],
      },
    },
    {
      'name': 'analyze_contract',
      'description':
          'Deep-analyze a contract that the user has uploaded. Extracts '
              'parties, obligations, payment terms, penalties, duration, '
              'termination clauses, jurisdiction and flags risky clauses '
              '(unlimited liability, auto-renewal, unilateral changes). Use '
              'when the user shares a contract and asks you to "check" or '
              '"review" it.',
      'input_schema': {
        'type': 'object',
        'properties': {
          'document_id': {
            'type': 'string',
            'description':
                'UUID of the contract document. Use list_documents to find '
                    'it if unsure.',
          },
        },
        'required': ['document_id'],
      },
    },
    // Phase 2 Pkg 1+2 — exact-paragraph statute lookup. Mirror of
    // search_estonian_law/search_finnish_law but for the case where the
    // user (or the model) names a known §. Bypasses embedding search,
    // hits the lookup_statute RPC directly. Returns null if the act/§
    // isn't in our bundled corpus or has been superseded (in_force=false).
    {
      'name': 'lookup_statute',
      'description':
          'EXACT paragraph lookup of a known statute. Use when the user '
              'names a specific § (e.g. "what does KarS § 121 say verbatim", '
              '"read me Rikoslaki 21:6"). No semantic search — direct DB '
              'lookup against the in-force version of the statute. Returns '
              'null if the act/paragraph is not in our bundled corpus; in '
              'that case fall back to search_estonian_law/search_finnish_law '
              'or web_search rather than fabricating text.',
      'input_schema': {
        'type': 'object',
        'properties': {
          'act': {
            'type': 'string',
            'description':
                'Statute code, e.g. KarS, HMS, TLS, VMS, Rikoslaki, '
                    'Ulkomaalaislaki. Case-insensitive (server uses ilike).',
          },
          'paragraph': {
            'type': 'string',
            'description':
                'Paragraph identifier without the § prefix, e.g. "121", '
                    '"40 lg 3", "21:6".',
          },
          'jurisdiction': {
            'type': 'string',
            'enum': ['EE', 'FI', 'EU'],
            'description':
                'Jurisdiction code: EE (Estonia, default), FI (Finland), '
                    'EU (EU directives via CELEX-ID).',
          },
        },
        'required': ['act', 'paragraph'],
      },
    },
    // v24.4 — long-horizon follow-up promises (agent_intentions).
    //
    // Use this tool whenever you commit to checking back later. Schedules
    // a row in the agent_intentions table; an hourly cron Edge Function
    // fires the actual notification when due. The user sees the pending
    // promise in their Case File ("Pending follow-ups" section) so they
    // can trust your word even across sessions.
    {
      'name': 'set_followup_intention',
      'description':
          'Schedule a future check-in with the user. Use when you promise '
              'to follow up — e.g. "I will remind you in 30 days about the '
              'appeal deadline" or "I will check the court case status next '
              'month". Creates a persisted reminder so the promise actually '
              'fires later, even across sessions.',
      'input_schema': {
        'type': 'object',
        'properties': {
          'intent_type': {
            'type': 'string',
            'enum': [
              'remind_deadline',
              'check_court_status',
              'follow_up_question',
              'check_company_status',
            ],
            'description':
                'Kind of follow-up. remind_deadline = nudge before a legal '
                    'deadline; check_court_status = poll a court case for '
                    'updates; follow_up_question = check in on the user; '
                    'check_company_status = re-run check_company on a target.',
          },
          'target_id': {
            'type': 'string',
            'description':
                'Optional identifier the cron uses when firing — court '
                    'case number, company registry code, deadline ID, etc.',
          },
          'check_at': {
            'type': 'string',
            'description':
                'ISO-8601 datetime (UTC preferred) when to follow up. '
                    'Must be in the future.',
          },
          'context_summary': {
            'type': 'string',
            'description':
                'Short (<=500 chars) summary of WHY we are following up. '
                    'GDPR: store only the AI intention summary, never raw '
                    'chat history.',
          },
        },
        'required': ['intent_type', 'check_at', 'context_summary'],
      },
    },
  ];

  // ── Anthropic server tools (executed on Anthropic's infrastructure) ───
  //
  // These tools are NOT implemented by the client — Anthropic runs them
  // server-side and returns results inline. They use a different schema
  // than user-defined tools: `type` + `name` only, no `input_schema`.
  //
  // See: https://platform.claude.com/docs/en/agents-and-tools/tool-use/tool-reference
  //
  // `web_search_20250305` (GA, shipped 2025-03-05) gives Claude the ability
  // to look up real-time information with source citations. We cap at
  // `max_uses: 3` per request — our users mostly need a single lookup
  // ("kohtutäitur contacts", "notar in Tallinn", "current Euribor"),
  // and capping limits cost (Anthropic bills $10/1K searches).

  /// Anthropic-executed server tools (web_search, etc.).
  ///
  /// These are sent alongside [toolDefinitions] in the `tools` array to the
  /// Claude API. The API handles execution; the client never sees a
  /// `tool_use` block for them — only the final assistant response with
  /// inline `web_search_tool_result` blocks and citations.
  static const List<Map<String, dynamic>> serverTools = [
    {
      'type': 'web_search_20250305',
      'name': 'web_search',
      'max_uses': 3,
    },
  ];

  /// All tools (client-executed + Anthropic-executed) in one array, ready
  /// to send to the Claude API `tools` parameter.
  static List<Map<String, dynamic>> get allTools => [
        ...toolDefinitions,
        ...serverTools,
      ];

  /// Returns only the tool names as a list.
  static List<String> get toolNames =>
      toolDefinitions.map((t) => t['name'] as String).toList();

  /// Look up a single tool definition by name. Returns null if not found.
  static Map<String, dynamic>? getDefinition(String name) {
    for (final tool in toolDefinitions) {
      if (tool['name'] == name) return tool;
    }
    return null;
  }
}
