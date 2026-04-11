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
