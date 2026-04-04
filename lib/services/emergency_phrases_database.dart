/// Emergency Phrases Database for Immigrants
///
/// Contains 20 essential emergency phrases translated into all 24 EU
/// official languages with pronunciation hints for difficult languages
/// (Finnish, Hungarian, Greek).
///
/// Usage:
/// ```dart
/// final db = EmergencyPhrasesDatabase();
/// final phrases = db.getPhrasesForLanguage('fi'); // Finnish
/// final phrase = db.getPhrase('fi', EmergencyPhraseKey.needHelp);
/// ```
library;

// ---------------------------------------------------------------------------
// Data model
// ---------------------------------------------------------------------------

/// Identifies each of the 20 standard emergency phrases.
enum EmergencyPhraseKey {
  needHelp,
  callPolice,
  needDoctor,
  dontSpeakLanguage,
  needInterpreter,
  rightToLawyer,
  dontUnderstand,
  whereIsHospital,
  victimOfCrime,
  needPhoneCall,
  whatAreMyRights,
  applyForAsylum,
  speakSlowly,
  needFoodWater,
  whereIsEmbassy,
  haveChildren,
  needMedication,
  findShelter,
  beingThreatened,
  thisIsEmergency,
}

/// A single translated phrase with optional pronunciation guide.
class EmergencyPhrase {
  final EmergencyPhraseKey key;
  final String english;
  final String translated;

  /// Optional phonetic / pronunciation hint (primarily for Finnish,
  /// Hungarian, and Greek).
  final String? pronunciation;

  const EmergencyPhrase({
    required this.key,
    required this.english,
    required this.translated,
    this.pronunciation,
  });

  Map<String, dynamic> toJson() => {
        'key': key.name,
        'english': english,
        'translated': translated,
        if (pronunciation != null) 'pronunciation': pronunciation,
      };
}

/// Metadata about a supported language.
class LanguageInfo {
  final String code; // ISO 639-1
  final String nameEnglish;
  final String nameNative;
  final String emergencyNumber;
  final bool hasPronunciationHints;

  const LanguageInfo({
    required this.code,
    required this.nameEnglish,
    required this.nameNative,
    required this.emergencyNumber,
    this.hasPronunciationHints = false,
  });
}

// ---------------------------------------------------------------------------
// Main database
// ---------------------------------------------------------------------------

class EmergencyPhrasesDatabase {
  // Singleton
  static final EmergencyPhrasesDatabase _instance =
      EmergencyPhrasesDatabase._internal();
  factory EmergencyPhrasesDatabase() => _instance;
  EmergencyPhrasesDatabase._internal();

  // -----------------------------------------------------------------------
  // Language registry
  // -----------------------------------------------------------------------

  static const List<LanguageInfo> supportedLanguages = [
    LanguageInfo(code: 'en', nameEnglish: 'English', nameNative: 'English', emergencyNumber: '112'),
    LanguageInfo(code: 'fr', nameEnglish: 'French', nameNative: 'Fran\u00e7ais', emergencyNumber: '112'),
    LanguageInfo(code: 'de', nameEnglish: 'German', nameNative: 'Deutsch', emergencyNumber: '112'),
    LanguageInfo(code: 'it', nameEnglish: 'Italian', nameNative: 'Italiano', emergencyNumber: '112'),
    LanguageInfo(code: 'es', nameEnglish: 'Spanish', nameNative: 'Espa\u00f1ol', emergencyNumber: '112'),
    LanguageInfo(code: 'pt', nameEnglish: 'Portuguese', nameNative: 'Portugu\u00eas', emergencyNumber: '112'),
    LanguageInfo(code: 'nl', nameEnglish: 'Dutch', nameNative: 'Nederlands', emergencyNumber: '112'),
    LanguageInfo(code: 'pl', nameEnglish: 'Polish', nameNative: 'Polski', emergencyNumber: '112'),
    LanguageInfo(code: 'ro', nameEnglish: 'Romanian', nameNative: 'Rom\u00e2n\u0103', emergencyNumber: '112'),
    LanguageInfo(code: 'cs', nameEnglish: 'Czech', nameNative: '\u010ce\u0161tina', emergencyNumber: '112'),
    LanguageInfo(code: 'hu', nameEnglish: 'Hungarian', nameNative: 'Magyar', emergencyNumber: '112', hasPronunciationHints: true),
    LanguageInfo(code: 'sv', nameEnglish: 'Swedish', nameNative: 'Svenska', emergencyNumber: '112'),
    LanguageInfo(code: 'fi', nameEnglish: 'Finnish', nameNative: 'Suomi', emergencyNumber: '112', hasPronunciationHints: true),
    LanguageInfo(code: 'et', nameEnglish: 'Estonian', nameNative: 'Eesti', emergencyNumber: '112'),
    LanguageInfo(code: 'lv', nameEnglish: 'Latvian', nameNative: 'Latvie\u0161u', emergencyNumber: '112'),
    LanguageInfo(code: 'lt', nameEnglish: 'Lithuanian', nameNative: 'Lietuvi\u0173', emergencyNumber: '112'),
    LanguageInfo(code: 'bg', nameEnglish: 'Bulgarian', nameNative: '\u0411\u044a\u043b\u0433\u0430\u0440\u0441\u043a\u0438', emergencyNumber: '112'),
    LanguageInfo(code: 'hr', nameEnglish: 'Croatian', nameNative: 'Hrvatski', emergencyNumber: '112'),
    LanguageInfo(code: 'sk', nameEnglish: 'Slovak', nameNative: 'Sloven\u010dina', emergencyNumber: '112'),
    LanguageInfo(code: 'sl', nameEnglish: 'Slovenian', nameNative: 'Sloven\u0161\u010dina', emergencyNumber: '112'),
    LanguageInfo(code: 'da', nameEnglish: 'Danish', nameNative: 'Dansk', emergencyNumber: '112'),
    LanguageInfo(code: 'el', nameEnglish: 'Greek', nameNative: '\u0395\u03bb\u03bb\u03b7\u03bd\u03b9\u03ba\u03ac', emergencyNumber: '112', hasPronunciationHints: true),
    LanguageInfo(code: 'mt', nameEnglish: 'Maltese', nameNative: 'Malti', emergencyNumber: '112'),
    LanguageInfo(code: 'ga', nameEnglish: 'Irish', nameNative: 'Gaeilge', emergencyNumber: '112'),
  ];

  /// Look up [LanguageInfo] by ISO code.
  LanguageInfo? getLanguageInfo(String code) {
    final lc = code.toLowerCase();
    try {
      return supportedLanguages.firstWhere((l) => l.code == lc);
    } catch (_) {
      return null;
    }
  }

  // -----------------------------------------------------------------------
  // Phrase retrieval helpers
  // -----------------------------------------------------------------------

  /// All 20 phrases for a given language code.
  List<EmergencyPhrase> getPhrasesForLanguage(String languageCode) {
    final lc = languageCode.toLowerCase();
    return _phrases[lc] ?? _phrases['en']!;
  }

  /// Single phrase by language + key.
  EmergencyPhrase? getPhrase(String languageCode, EmergencyPhraseKey key) {
    final list = _phrases[languageCode.toLowerCase()];
    if (list == null) return null;
    try {
      return list.firstWhere((p) => p.key == key);
    } catch (_) {
      return null;
    }
  }

  /// Search phrases that contain [query] (case-insensitive) across all
  /// languages, returning a map of languageCode -> matching phrases.
  Map<String, List<EmergencyPhrase>> searchPhrases(String query) {
    final q = query.toLowerCase();
    final results = <String, List<EmergencyPhrase>>{};
    for (final entry in _phrases.entries) {
      final matches =
          entry.value.where((p) => p.translated.toLowerCase().contains(q) || p.english.toLowerCase().contains(q)).toList();
      if (matches.isNotEmpty) {
        results[entry.key] = matches;
      }
    }
    return results;
  }

  /// Returns all languages that have pronunciation hints.
  List<String> get languagesWithPronunciation =>
      supportedLanguages.where((l) => l.hasPronunciationHints).map((l) => l.code).toList();

  // -----------------------------------------------------------------------
  // Complete phrase data (24 languages x 20 phrases)
  // -----------------------------------------------------------------------

  static final Map<String, List<EmergencyPhrase>> _phrases = {
    // =====================================================================
    // ENGLISH (en)
    // =====================================================================
    'en': const [
      EmergencyPhrase(key: EmergencyPhraseKey.needHelp, english: 'I need help', translated: 'I need help'),
      EmergencyPhrase(key: EmergencyPhraseKey.callPolice, english: 'Call the police', translated: 'Call the police'),
      EmergencyPhrase(key: EmergencyPhraseKey.needDoctor, english: 'I need a doctor', translated: 'I need a doctor'),
      EmergencyPhrase(key: EmergencyPhraseKey.dontSpeakLanguage, english: "I don't speak [language]", translated: "I don't speak English"),
      EmergencyPhrase(key: EmergencyPhraseKey.needInterpreter, english: 'I need an interpreter', translated: 'I need an interpreter'),
      EmergencyPhrase(key: EmergencyPhraseKey.rightToLawyer, english: 'I have the right to a lawyer', translated: 'I have the right to a lawyer'),
      EmergencyPhrase(key: EmergencyPhraseKey.dontUnderstand, english: "I don't understand", translated: "I don't understand"),
      EmergencyPhrase(key: EmergencyPhraseKey.whereIsHospital, english: 'Where is the hospital?', translated: 'Where is the hospital?'),
      EmergencyPhrase(key: EmergencyPhraseKey.victimOfCrime, english: 'I am a victim of a crime', translated: 'I am a victim of a crime'),
      EmergencyPhrase(key: EmergencyPhraseKey.needPhoneCall, english: 'I need to make a phone call', translated: 'I need to make a phone call'),
      EmergencyPhrase(key: EmergencyPhraseKey.whatAreMyRights, english: 'What are my rights?', translated: 'What are my rights?'),
      EmergencyPhrase(key: EmergencyPhraseKey.applyForAsylum, english: 'I want to apply for asylum', translated: 'I want to apply for asylum'),
      EmergencyPhrase(key: EmergencyPhraseKey.speakSlowly, english: 'Please speak slowly', translated: 'Please speak slowly'),
      EmergencyPhrase(key: EmergencyPhraseKey.needFoodWater, english: 'I need food and water', translated: 'I need food and water'),
      EmergencyPhrase(key: EmergencyPhraseKey.whereIsEmbassy, english: 'Where is the embassy of [country]?', translated: 'Where is the embassy of [country]?'),
      EmergencyPhrase(key: EmergencyPhraseKey.haveChildren, english: 'I have children with me', translated: 'I have children with me'),
      EmergencyPhrase(key: EmergencyPhraseKey.needMedication, english: 'I need medication', translated: 'I need medication'),
      EmergencyPhrase(key: EmergencyPhraseKey.findShelter, english: 'Can you help me find shelter?', translated: 'Can you help me find shelter?'),
      EmergencyPhrase(key: EmergencyPhraseKey.beingThreatened, english: 'I am being threatened', translated: 'I am being threatened'),
      EmergencyPhrase(key: EmergencyPhraseKey.thisIsEmergency, english: 'This is an emergency', translated: 'This is an emergency'),
    ],

    // =====================================================================
    // FRENCH (fr)
    // =====================================================================
    'fr': const [
      EmergencyPhrase(key: EmergencyPhraseKey.needHelp, english: 'I need help', translated: "J'ai besoin d'aide"),
      EmergencyPhrase(key: EmergencyPhraseKey.callPolice, english: 'Call the police', translated: 'Appelez la police'),
      EmergencyPhrase(key: EmergencyPhraseKey.needDoctor, english: 'I need a doctor', translated: "J'ai besoin d'un m\u00e9decin"),
      EmergencyPhrase(key: EmergencyPhraseKey.dontSpeakLanguage, english: "I don't speak [language]", translated: 'Je ne parle pas fran\u00e7ais'),
      EmergencyPhrase(key: EmergencyPhraseKey.needInterpreter, english: 'I need an interpreter', translated: "J'ai besoin d'un interpr\u00e8te"),
      EmergencyPhrase(key: EmergencyPhraseKey.rightToLawyer, english: 'I have the right to a lawyer', translated: "J'ai le droit \u00e0 un avocat"),
      EmergencyPhrase(key: EmergencyPhraseKey.dontUnderstand, english: "I don't understand", translated: 'Je ne comprends pas'),
      EmergencyPhrase(key: EmergencyPhraseKey.whereIsHospital, english: 'Where is the hospital?', translated: "O\u00f9 est l'h\u00f4pital ?"),
      EmergencyPhrase(key: EmergencyPhraseKey.victimOfCrime, english: 'I am a victim of a crime', translated: "Je suis victime d'un crime"),
      EmergencyPhrase(key: EmergencyPhraseKey.needPhoneCall, english: 'I need to make a phone call', translated: "J'ai besoin de passer un appel t\u00e9l\u00e9phonique"),
      EmergencyPhrase(key: EmergencyPhraseKey.whatAreMyRights, english: 'What are my rights?', translated: 'Quels sont mes droits ?'),
      EmergencyPhrase(key: EmergencyPhraseKey.applyForAsylum, english: 'I want to apply for asylum', translated: "Je veux demander l'asile"),
      EmergencyPhrase(key: EmergencyPhraseKey.speakSlowly, english: 'Please speak slowly', translated: 'Parlez lentement, s\'il vous pla\u00eet'),
      EmergencyPhrase(key: EmergencyPhraseKey.needFoodWater, english: 'I need food and water', translated: "J'ai besoin de nourriture et d'eau"),
      EmergencyPhrase(key: EmergencyPhraseKey.whereIsEmbassy, english: 'Where is the embassy of [country]?', translated: "O\u00f9 est l'ambassade de [pays] ?"),
      EmergencyPhrase(key: EmergencyPhraseKey.haveChildren, english: 'I have children with me', translated: "J'ai des enfants avec moi"),
      EmergencyPhrase(key: EmergencyPhraseKey.needMedication, english: 'I need medication', translated: "J'ai besoin de m\u00e9dicaments"),
      EmergencyPhrase(key: EmergencyPhraseKey.findShelter, english: 'Can you help me find shelter?', translated: "Pouvez-vous m'aider \u00e0 trouver un h\u00e9bergement ?"),
      EmergencyPhrase(key: EmergencyPhraseKey.beingThreatened, english: 'I am being threatened', translated: 'Je suis menac\u00e9(e)'),
      EmergencyPhrase(key: EmergencyPhraseKey.thisIsEmergency, english: 'This is an emergency', translated: "C'est une urgence"),
    ],

    // =====================================================================
    // GERMAN (de)
    // =====================================================================
    'de': const [
      EmergencyPhrase(key: EmergencyPhraseKey.needHelp, english: 'I need help', translated: 'Ich brauche Hilfe'),
      EmergencyPhrase(key: EmergencyPhraseKey.callPolice, english: 'Call the police', translated: 'Rufen Sie die Polizei'),
      EmergencyPhrase(key: EmergencyPhraseKey.needDoctor, english: 'I need a doctor', translated: 'Ich brauche einen Arzt'),
      EmergencyPhrase(key: EmergencyPhraseKey.dontSpeakLanguage, english: "I don't speak [language]", translated: 'Ich spreche kein Deutsch'),
      EmergencyPhrase(key: EmergencyPhraseKey.needInterpreter, english: 'I need an interpreter', translated: 'Ich brauche einen Dolmetscher'),
      EmergencyPhrase(key: EmergencyPhraseKey.rightToLawyer, english: 'I have the right to a lawyer', translated: 'Ich habe das Recht auf einen Anwalt'),
      EmergencyPhrase(key: EmergencyPhraseKey.dontUnderstand, english: "I don't understand", translated: 'Ich verstehe nicht'),
      EmergencyPhrase(key: EmergencyPhraseKey.whereIsHospital, english: 'Where is the hospital?', translated: 'Wo ist das Krankenhaus?'),
      EmergencyPhrase(key: EmergencyPhraseKey.victimOfCrime, english: 'I am a victim of a crime', translated: 'Ich bin Opfer einer Straftat'),
      EmergencyPhrase(key: EmergencyPhraseKey.needPhoneCall, english: 'I need to make a phone call', translated: 'Ich muss telefonieren'),
      EmergencyPhrase(key: EmergencyPhraseKey.whatAreMyRights, english: 'What are my rights?', translated: 'Was sind meine Rechte?'),
      EmergencyPhrase(key: EmergencyPhraseKey.applyForAsylum, english: 'I want to apply for asylum', translated: 'Ich m\u00f6chte Asyl beantragen'),
      EmergencyPhrase(key: EmergencyPhraseKey.speakSlowly, english: 'Please speak slowly', translated: 'Bitte sprechen Sie langsam'),
      EmergencyPhrase(key: EmergencyPhraseKey.needFoodWater, english: 'I need food and water', translated: 'Ich brauche Essen und Wasser'),
      EmergencyPhrase(key: EmergencyPhraseKey.whereIsEmbassy, english: 'Where is the embassy of [country]?', translated: 'Wo ist die Botschaft von [Land]?'),
      EmergencyPhrase(key: EmergencyPhraseKey.haveChildren, english: 'I have children with me', translated: 'Ich habe Kinder bei mir'),
      EmergencyPhrase(key: EmergencyPhraseKey.needMedication, english: 'I need medication', translated: 'Ich brauche Medikamente'),
      EmergencyPhrase(key: EmergencyPhraseKey.findShelter, english: 'Can you help me find shelter?', translated: 'K\u00f6nnen Sie mir helfen, eine Unterkunft zu finden?'),
      EmergencyPhrase(key: EmergencyPhraseKey.beingThreatened, english: 'I am being threatened', translated: 'Ich werde bedroht'),
      EmergencyPhrase(key: EmergencyPhraseKey.thisIsEmergency, english: 'This is an emergency', translated: 'Dies ist ein Notfall'),
    ],

    // =====================================================================
    // ITALIAN (it)
    // =====================================================================
    'it': const [
      EmergencyPhrase(key: EmergencyPhraseKey.needHelp, english: 'I need help', translated: 'Ho bisogno di aiuto'),
      EmergencyPhrase(key: EmergencyPhraseKey.callPolice, english: 'Call the police', translated: 'Chiamate la polizia'),
      EmergencyPhrase(key: EmergencyPhraseKey.needDoctor, english: 'I need a doctor', translated: 'Ho bisogno di un medico'),
      EmergencyPhrase(key: EmergencyPhraseKey.dontSpeakLanguage, english: "I don't speak [language]", translated: 'Non parlo italiano'),
      EmergencyPhrase(key: EmergencyPhraseKey.needInterpreter, english: 'I need an interpreter', translated: 'Ho bisogno di un interprete'),
      EmergencyPhrase(key: EmergencyPhraseKey.rightToLawyer, english: 'I have the right to a lawyer', translated: 'Ho diritto a un avvocato'),
      EmergencyPhrase(key: EmergencyPhraseKey.dontUnderstand, english: "I don't understand", translated: 'Non capisco'),
      EmergencyPhrase(key: EmergencyPhraseKey.whereIsHospital, english: 'Where is the hospital?', translated: "Dov'\u00e8 l'ospedale?"),
      EmergencyPhrase(key: EmergencyPhraseKey.victimOfCrime, english: 'I am a victim of a crime', translated: 'Sono vittima di un reato'),
      EmergencyPhrase(key: EmergencyPhraseKey.needPhoneCall, english: 'I need to make a phone call', translated: 'Devo fare una telefonata'),
      EmergencyPhrase(key: EmergencyPhraseKey.whatAreMyRights, english: 'What are my rights?', translated: 'Quali sono i miei diritti?'),
      EmergencyPhrase(key: EmergencyPhraseKey.applyForAsylum, english: 'I want to apply for asylum', translated: "Voglio fare domanda d'asilo"),
      EmergencyPhrase(key: EmergencyPhraseKey.speakSlowly, english: 'Please speak slowly', translated: 'Per favore, parli lentamente'),
      EmergencyPhrase(key: EmergencyPhraseKey.needFoodWater, english: 'I need food and water', translated: 'Ho bisogno di cibo e acqua'),
      EmergencyPhrase(key: EmergencyPhraseKey.whereIsEmbassy, english: 'Where is the embassy of [country]?', translated: "Dov'\u00e8 l'ambasciata di [paese]?"),
      EmergencyPhrase(key: EmergencyPhraseKey.haveChildren, english: 'I have children with me', translated: 'Ho dei bambini con me'),
      EmergencyPhrase(key: EmergencyPhraseKey.needMedication, english: 'I need medication', translated: 'Ho bisogno di medicine'),
      EmergencyPhrase(key: EmergencyPhraseKey.findShelter, english: 'Can you help me find shelter?', translated: 'Pu\u00f2 aiutarmi a trovare un alloggio?'),
      EmergencyPhrase(key: EmergencyPhraseKey.beingThreatened, english: 'I am being threatened', translated: 'Sono minacciato/a'),
      EmergencyPhrase(key: EmergencyPhraseKey.thisIsEmergency, english: 'This is an emergency', translated: "Questa \u00e8 un'emergenza"),
    ],

    // =====================================================================
    // SPANISH (es)
    // =====================================================================
    'es': const [
      EmergencyPhrase(key: EmergencyPhraseKey.needHelp, english: 'I need help', translated: 'Necesito ayuda'),
      EmergencyPhrase(key: EmergencyPhraseKey.callPolice, english: 'Call the police', translated: 'Llamen a la polic\u00eda'),
      EmergencyPhrase(key: EmergencyPhraseKey.needDoctor, english: 'I need a doctor', translated: 'Necesito un m\u00e9dico'),
      EmergencyPhrase(key: EmergencyPhraseKey.dontSpeakLanguage, english: "I don't speak [language]", translated: 'No hablo espa\u00f1ol'),
      EmergencyPhrase(key: EmergencyPhraseKey.needInterpreter, english: 'I need an interpreter', translated: 'Necesito un int\u00e9rprete'),
      EmergencyPhrase(key: EmergencyPhraseKey.rightToLawyer, english: 'I have the right to a lawyer', translated: 'Tengo derecho a un abogado'),
      EmergencyPhrase(key: EmergencyPhraseKey.dontUnderstand, english: "I don't understand", translated: 'No entiendo'),
      EmergencyPhrase(key: EmergencyPhraseKey.whereIsHospital, english: 'Where is the hospital?', translated: '\u00bfD\u00f3nde est\u00e1 el hospital?'),
      EmergencyPhrase(key: EmergencyPhraseKey.victimOfCrime, english: 'I am a victim of a crime', translated: 'Soy v\u00edctima de un delito'),
      EmergencyPhrase(key: EmergencyPhraseKey.needPhoneCall, english: 'I need to make a phone call', translated: 'Necesito hacer una llamada telef\u00f3nica'),
      EmergencyPhrase(key: EmergencyPhraseKey.whatAreMyRights, english: 'What are my rights?', translated: '\u00bfCu\u00e1les son mis derechos?'),
      EmergencyPhrase(key: EmergencyPhraseKey.applyForAsylum, english: 'I want to apply for asylum', translated: 'Quiero solicitar asilo'),
      EmergencyPhrase(key: EmergencyPhraseKey.speakSlowly, english: 'Please speak slowly', translated: 'Por favor, hable despacio'),
      EmergencyPhrase(key: EmergencyPhraseKey.needFoodWater, english: 'I need food and water', translated: 'Necesito comida y agua'),
      EmergencyPhrase(key: EmergencyPhraseKey.whereIsEmbassy, english: 'Where is the embassy of [country]?', translated: '\u00bfD\u00f3nde est\u00e1 la embajada de [pa\u00eds]?'),
      EmergencyPhrase(key: EmergencyPhraseKey.haveChildren, english: 'I have children with me', translated: 'Tengo ni\u00f1os conmigo'),
      EmergencyPhrase(key: EmergencyPhraseKey.needMedication, english: 'I need medication', translated: 'Necesito medicamentos'),
      EmergencyPhrase(key: EmergencyPhraseKey.findShelter, english: 'Can you help me find shelter?', translated: '\u00bfPuede ayudarme a encontrar refugio?'),
      EmergencyPhrase(key: EmergencyPhraseKey.beingThreatened, english: 'I am being threatened', translated: 'Estoy siendo amenazado/a'),
      EmergencyPhrase(key: EmergencyPhraseKey.thisIsEmergency, english: 'This is an emergency', translated: 'Esto es una emergencia'),
    ],

    // =====================================================================
    // PORTUGUESE (pt)
    // =====================================================================
    'pt': const [
      EmergencyPhrase(key: EmergencyPhraseKey.needHelp, english: 'I need help', translated: 'Preciso de ajuda'),
      EmergencyPhrase(key: EmergencyPhraseKey.callPolice, english: 'Call the police', translated: 'Chamem a pol\u00edcia'),
      EmergencyPhrase(key: EmergencyPhraseKey.needDoctor, english: 'I need a doctor', translated: 'Preciso de um m\u00e9dico'),
      EmergencyPhrase(key: EmergencyPhraseKey.dontSpeakLanguage, english: "I don't speak [language]", translated: 'Eu n\u00e3o falo portugu\u00eas'),
      EmergencyPhrase(key: EmergencyPhraseKey.needInterpreter, english: 'I need an interpreter', translated: 'Preciso de um int\u00e9rprete'),
      EmergencyPhrase(key: EmergencyPhraseKey.rightToLawyer, english: 'I have the right to a lawyer', translated: 'Tenho direito a um advogado'),
      EmergencyPhrase(key: EmergencyPhraseKey.dontUnderstand, english: "I don't understand", translated: 'Eu n\u00e3o entendo'),
      EmergencyPhrase(key: EmergencyPhraseKey.whereIsHospital, english: 'Where is the hospital?', translated: 'Onde fica o hospital?'),
      EmergencyPhrase(key: EmergencyPhraseKey.victimOfCrime, english: 'I am a victim of a crime', translated: 'Sou v\u00edtima de um crime'),
      EmergencyPhrase(key: EmergencyPhraseKey.needPhoneCall, english: 'I need to make a phone call', translated: 'Preciso de fazer um telefonema'),
      EmergencyPhrase(key: EmergencyPhraseKey.whatAreMyRights, english: 'What are my rights?', translated: 'Quais s\u00e3o os meus direitos?'),
      EmergencyPhrase(key: EmergencyPhraseKey.applyForAsylum, english: 'I want to apply for asylum', translated: 'Quero pedir asilo'),
      EmergencyPhrase(key: EmergencyPhraseKey.speakSlowly, english: 'Please speak slowly', translated: 'Por favor, fale devagar'),
      EmergencyPhrase(key: EmergencyPhraseKey.needFoodWater, english: 'I need food and water', translated: 'Preciso de comida e \u00e1gua'),
      EmergencyPhrase(key: EmergencyPhraseKey.whereIsEmbassy, english: 'Where is the embassy of [country]?', translated: 'Onde fica a embaixada de [pa\u00eds]?'),
      EmergencyPhrase(key: EmergencyPhraseKey.haveChildren, english: 'I have children with me', translated: 'Tenho crian\u00e7as comigo'),
      EmergencyPhrase(key: EmergencyPhraseKey.needMedication, english: 'I need medication', translated: 'Preciso de medicamentos'),
      EmergencyPhrase(key: EmergencyPhraseKey.findShelter, english: 'Can you help me find shelter?', translated: 'Pode ajudar-me a encontrar abrigo?'),
      EmergencyPhrase(key: EmergencyPhraseKey.beingThreatened, english: 'I am being threatened', translated: 'Estou a ser amea\u00e7ado/a'),
      EmergencyPhrase(key: EmergencyPhraseKey.thisIsEmergency, english: 'This is an emergency', translated: 'Isto \u00e9 uma emerg\u00eancia'),
    ],

    // =====================================================================
    // DUTCH (nl)
    // =====================================================================
    'nl': const [
      EmergencyPhrase(key: EmergencyPhraseKey.needHelp, english: 'I need help', translated: 'Ik heb hulp nodig'),
      EmergencyPhrase(key: EmergencyPhraseKey.callPolice, english: 'Call the police', translated: 'Bel de politie'),
      EmergencyPhrase(key: EmergencyPhraseKey.needDoctor, english: 'I need a doctor', translated: 'Ik heb een dokter nodig'),
      EmergencyPhrase(key: EmergencyPhraseKey.dontSpeakLanguage, english: "I don't speak [language]", translated: 'Ik spreek geen Nederlands'),
      EmergencyPhrase(key: EmergencyPhraseKey.needInterpreter, english: 'I need an interpreter', translated: 'Ik heb een tolk nodig'),
      EmergencyPhrase(key: EmergencyPhraseKey.rightToLawyer, english: 'I have the right to a lawyer', translated: 'Ik heb recht op een advocaat'),
      EmergencyPhrase(key: EmergencyPhraseKey.dontUnderstand, english: "I don't understand", translated: 'Ik begrijp het niet'),
      EmergencyPhrase(key: EmergencyPhraseKey.whereIsHospital, english: 'Where is the hospital?', translated: 'Waar is het ziekenhuis?'),
      EmergencyPhrase(key: EmergencyPhraseKey.victimOfCrime, english: 'I am a victim of a crime', translated: 'Ik ben slachtoffer van een misdrijf'),
      EmergencyPhrase(key: EmergencyPhraseKey.needPhoneCall, english: 'I need to make a phone call', translated: 'Ik moet een telefoontje plegen'),
      EmergencyPhrase(key: EmergencyPhraseKey.whatAreMyRights, english: 'What are my rights?', translated: 'Wat zijn mijn rechten?'),
      EmergencyPhrase(key: EmergencyPhraseKey.applyForAsylum, english: 'I want to apply for asylum', translated: 'Ik wil asiel aanvragen'),
      EmergencyPhrase(key: EmergencyPhraseKey.speakSlowly, english: 'Please speak slowly', translated: 'Spreek alstublieft langzaam'),
      EmergencyPhrase(key: EmergencyPhraseKey.needFoodWater, english: 'I need food and water', translated: 'Ik heb eten en water nodig'),
      EmergencyPhrase(key: EmergencyPhraseKey.whereIsEmbassy, english: 'Where is the embassy of [country]?', translated: 'Waar is de ambassade van [land]?'),
      EmergencyPhrase(key: EmergencyPhraseKey.haveChildren, english: 'I have children with me', translated: 'Ik heb kinderen bij me'),
      EmergencyPhrase(key: EmergencyPhraseKey.needMedication, english: 'I need medication', translated: 'Ik heb medicijnen nodig'),
      EmergencyPhrase(key: EmergencyPhraseKey.findShelter, english: 'Can you help me find shelter?', translated: 'Kunt u mij helpen onderdak te vinden?'),
      EmergencyPhrase(key: EmergencyPhraseKey.beingThreatened, english: 'I am being threatened', translated: 'Ik word bedreigd'),
      EmergencyPhrase(key: EmergencyPhraseKey.thisIsEmergency, english: 'This is an emergency', translated: 'Dit is een noodgeval'),
    ],

    // =====================================================================
    // POLISH (pl)
    // =====================================================================
    'pl': const [
      EmergencyPhrase(key: EmergencyPhraseKey.needHelp, english: 'I need help', translated: 'Potrzebuj\u0119 pomocy'),
      EmergencyPhrase(key: EmergencyPhraseKey.callPolice, english: 'Call the police', translated: 'Prosz\u0119 zadzwoni\u0107 na policj\u0119'),
      EmergencyPhrase(key: EmergencyPhraseKey.needDoctor, english: 'I need a doctor', translated: 'Potrzebuj\u0119 lekarza'),
      EmergencyPhrase(key: EmergencyPhraseKey.dontSpeakLanguage, english: "I don't speak [language]", translated: 'Nie m\u00f3wi\u0119 po polsku'),
      EmergencyPhrase(key: EmergencyPhraseKey.needInterpreter, english: 'I need an interpreter', translated: 'Potrzebuj\u0119 t\u0142umacza'),
      EmergencyPhrase(key: EmergencyPhraseKey.rightToLawyer, english: 'I have the right to a lawyer', translated: 'Mam prawo do adwokata'),
      EmergencyPhrase(key: EmergencyPhraseKey.dontUnderstand, english: "I don't understand", translated: 'Nie rozumiem'),
      EmergencyPhrase(key: EmergencyPhraseKey.whereIsHospital, english: 'Where is the hospital?', translated: 'Gdzie jest szpital?'),
      EmergencyPhrase(key: EmergencyPhraseKey.victimOfCrime, english: 'I am a victim of a crime', translated: 'Jestem ofiar\u0105 przest\u0119pstwa'),
      EmergencyPhrase(key: EmergencyPhraseKey.needPhoneCall, english: 'I need to make a phone call', translated: 'Musz\u0119 zadzwoni\u0107'),
      EmergencyPhrase(key: EmergencyPhraseKey.whatAreMyRights, english: 'What are my rights?', translated: 'Jakie s\u0105 moje prawa?'),
      EmergencyPhrase(key: EmergencyPhraseKey.applyForAsylum, english: 'I want to apply for asylum', translated: 'Chc\u0119 z\u0142o\u017cy\u0107 wniosek o azyl'),
      EmergencyPhrase(key: EmergencyPhraseKey.speakSlowly, english: 'Please speak slowly', translated: 'Prosz\u0119 m\u00f3wi\u0107 wolno'),
      EmergencyPhrase(key: EmergencyPhraseKey.needFoodWater, english: 'I need food and water', translated: 'Potrzebuj\u0119 jedzenia i wody'),
      EmergencyPhrase(key: EmergencyPhraseKey.whereIsEmbassy, english: 'Where is the embassy of [country]?', translated: 'Gdzie jest ambasada [kraj]?'),
      EmergencyPhrase(key: EmergencyPhraseKey.haveChildren, english: 'I have children with me', translated: 'Mam ze sob\u0105 dzieci'),
      EmergencyPhrase(key: EmergencyPhraseKey.needMedication, english: 'I need medication', translated: 'Potrzebuj\u0119 lek\u00f3w'),
      EmergencyPhrase(key: EmergencyPhraseKey.findShelter, english: 'Can you help me find shelter?', translated: 'Czy mo\u017cecie mi pom\u00f3c znale\u017a\u0107 schronienie?'),
      EmergencyPhrase(key: EmergencyPhraseKey.beingThreatened, english: 'I am being threatened', translated: 'Jestem zagro\u017cony/a'),
      EmergencyPhrase(key: EmergencyPhraseKey.thisIsEmergency, english: 'This is an emergency', translated: 'To jest nag\u0142y wypadek'),
    ],

    // =====================================================================
    // ROMANIAN (ro)
    // =====================================================================
    'ro': const [
      EmergencyPhrase(key: EmergencyPhraseKey.needHelp, english: 'I need help', translated: 'Am nevoie de ajutor'),
      EmergencyPhrase(key: EmergencyPhraseKey.callPolice, english: 'Call the police', translated: 'Chema\u021bi poli\u021bia'),
      EmergencyPhrase(key: EmergencyPhraseKey.needDoctor, english: 'I need a doctor', translated: 'Am nevoie de un medic'),
      EmergencyPhrase(key: EmergencyPhraseKey.dontSpeakLanguage, english: "I don't speak [language]", translated: 'Nu vorbesc rom\u00e2n\u0103'),
      EmergencyPhrase(key: EmergencyPhraseKey.needInterpreter, english: 'I need an interpreter', translated: 'Am nevoie de un interpret'),
      EmergencyPhrase(key: EmergencyPhraseKey.rightToLawyer, english: 'I have the right to a lawyer', translated: 'Am dreptul la un avocat'),
      EmergencyPhrase(key: EmergencyPhraseKey.dontUnderstand, english: "I don't understand", translated: 'Nu \u00een\u021beleg'),
      EmergencyPhrase(key: EmergencyPhraseKey.whereIsHospital, english: 'Where is the hospital?', translated: 'Unde este spitalul?'),
      EmergencyPhrase(key: EmergencyPhraseKey.victimOfCrime, english: 'I am a victim of a crime', translated: 'Sunt victima unei infrac\u021biuni'),
      EmergencyPhrase(key: EmergencyPhraseKey.needPhoneCall, english: 'I need to make a phone call', translated: 'Trebuie s\u0103 dau un telefon'),
      EmergencyPhrase(key: EmergencyPhraseKey.whatAreMyRights, english: 'What are my rights?', translated: 'Care sunt drepturile mele?'),
      EmergencyPhrase(key: EmergencyPhraseKey.applyForAsylum, english: 'I want to apply for asylum', translated: 'Vreau s\u0103 solicit azil'),
      EmergencyPhrase(key: EmergencyPhraseKey.speakSlowly, english: 'Please speak slowly', translated: 'V\u0103 rog, vorbi\u021bi \u00eencet'),
      EmergencyPhrase(key: EmergencyPhraseKey.needFoodWater, english: 'I need food and water', translated: 'Am nevoie de m\u00e2ncare \u0219i ap\u0103'),
      EmergencyPhrase(key: EmergencyPhraseKey.whereIsEmbassy, english: 'Where is the embassy of [country]?', translated: 'Unde este ambasada [\u021bar\u0103]?'),
      EmergencyPhrase(key: EmergencyPhraseKey.haveChildren, english: 'I have children with me', translated: 'Am copii cu mine'),
      EmergencyPhrase(key: EmergencyPhraseKey.needMedication, english: 'I need medication', translated: 'Am nevoie de medicamente'),
      EmergencyPhrase(key: EmergencyPhraseKey.findShelter, english: 'Can you help me find shelter?', translated: 'M\u0103 pute\u021bi ajuta s\u0103 g\u0103sesc un ad\u0103post?'),
      EmergencyPhrase(key: EmergencyPhraseKey.beingThreatened, english: 'I am being threatened', translated: 'Sunt amenin\u021bat/\u0103'),
      EmergencyPhrase(key: EmergencyPhraseKey.thisIsEmergency, english: 'This is an emergency', translated: 'Aceasta este o urgen\u021b\u0103'),
    ],

    // =====================================================================
    // CZECH (cs)
    // =====================================================================
    'cs': const [
      EmergencyPhrase(key: EmergencyPhraseKey.needHelp, english: 'I need help', translated: 'Pot\u0159ebuji pomoc'),
      EmergencyPhrase(key: EmergencyPhraseKey.callPolice, english: 'Call the police', translated: 'Zavolejte policii'),
      EmergencyPhrase(key: EmergencyPhraseKey.needDoctor, english: 'I need a doctor', translated: 'Pot\u0159ebuji l\u00e9ka\u0159e'),
      EmergencyPhrase(key: EmergencyPhraseKey.dontSpeakLanguage, english: "I don't speak [language]", translated: 'Nemluv\u00edm \u010desky'),
      EmergencyPhrase(key: EmergencyPhraseKey.needInterpreter, english: 'I need an interpreter', translated: 'Pot\u0159ebuji tlumo\u010dn\u00edka'),
      EmergencyPhrase(key: EmergencyPhraseKey.rightToLawyer, english: 'I have the right to a lawyer', translated: 'M\u00e1m pr\u00e1vo na advok\u00e1ta'),
      EmergencyPhrase(key: EmergencyPhraseKey.dontUnderstand, english: "I don't understand", translated: 'Nerozum\u00edm'),
      EmergencyPhrase(key: EmergencyPhraseKey.whereIsHospital, english: 'Where is the hospital?', translated: 'Kde je nemocnice?'),
      EmergencyPhrase(key: EmergencyPhraseKey.victimOfCrime, english: 'I am a victim of a crime', translated: 'Jsem ob\u011bt\u00ed trestn\u00e9ho \u010dinu'),
      EmergencyPhrase(key: EmergencyPhraseKey.needPhoneCall, english: 'I need to make a phone call', translated: 'Pot\u0159ebuji zavolat'),
      EmergencyPhrase(key: EmergencyPhraseKey.whatAreMyRights, english: 'What are my rights?', translated: 'Jak\u00e1 jsou m\u00e1 pr\u00e1va?'),
      EmergencyPhrase(key: EmergencyPhraseKey.applyForAsylum, english: 'I want to apply for asylum', translated: 'Chci po\u017e\u00e1dat o azyl'),
      EmergencyPhrase(key: EmergencyPhraseKey.speakSlowly, english: 'Please speak slowly', translated: 'Pros\u00edm, mluvte pomalu'),
      EmergencyPhrase(key: EmergencyPhraseKey.needFoodWater, english: 'I need food and water', translated: 'Pot\u0159ebuji j\u00eddlo a vodu'),
      EmergencyPhrase(key: EmergencyPhraseKey.whereIsEmbassy, english: 'Where is the embassy of [country]?', translated: 'Kde je ambas\u00e1da [zem\u011b]?'),
      EmergencyPhrase(key: EmergencyPhraseKey.haveChildren, english: 'I have children with me', translated: 'M\u00e1m s sebou d\u011bti'),
      EmergencyPhrase(key: EmergencyPhraseKey.needMedication, english: 'I need medication', translated: 'Pot\u0159ebuji l\u00e9ky'),
      EmergencyPhrase(key: EmergencyPhraseKey.findShelter, english: 'Can you help me find shelter?', translated: 'M\u016f\u017eete mi pomoci naj\u00edt p\u0159\u00edst\u0159e\u0161\u00ed?'),
      EmergencyPhrase(key: EmergencyPhraseKey.beingThreatened, english: 'I am being threatened', translated: 'Jsem ohro\u017eov\u00e1n/a'),
      EmergencyPhrase(key: EmergencyPhraseKey.thisIsEmergency, english: 'This is an emergency', translated: 'Toto je nouzov\u00e1 situace'),
    ],

    // =====================================================================
    // HUNGARIAN (hu) - WITH PRONUNCIATION HINTS
    // =====================================================================
    'hu': const [
      EmergencyPhrase(key: EmergencyPhraseKey.needHelp, english: 'I need help', translated: 'Seg\u00edts\u00e9gre van sz\u00fcks\u00e9gem', pronunciation: 'SHEH-geet-shay-greh von SYOOK-shay-gem'),
      EmergencyPhrase(key: EmergencyPhraseKey.callPolice, english: 'Call the police', translated: 'H\u00edvj\u00e1k a rend\u0151rs\u00e9get', pronunciation: 'HEEV-yaak ah REND-ur-shay-get'),
      EmergencyPhrase(key: EmergencyPhraseKey.needDoctor, english: 'I need a doctor', translated: 'Orvosra van sz\u00fcks\u00e9gem', pronunciation: 'OR-vosh-rah von SYOOK-shay-gem'),
      EmergencyPhrase(key: EmergencyPhraseKey.dontSpeakLanguage, english: "I don't speak [language]", translated: 'Nem besz\u00e9lek magyarul', pronunciation: 'Nem BEH-say-lek MAH-dyah-rool'),
      EmergencyPhrase(key: EmergencyPhraseKey.needInterpreter, english: 'I need an interpreter', translated: 'Tolm\u00e1csra van sz\u00fcks\u00e9gem', pronunciation: 'TOL-maach-rah von SYOOK-shay-gem'),
      EmergencyPhrase(key: EmergencyPhraseKey.rightToLawyer, english: 'I have the right to a lawyer', translated: 'Jogom van \u00fcgyv\u00e9dhez', pronunciation: 'YOH-gom von OOG-ee-vayd-hez'),
      EmergencyPhrase(key: EmergencyPhraseKey.dontUnderstand, english: "I don't understand", translated: 'Nem \u00e9rtem', pronunciation: 'Nem AYR-tem'),
      EmergencyPhrase(key: EmergencyPhraseKey.whereIsHospital, english: 'Where is the hospital?', translated: 'Hol van a k\u00f3rh\u00e1z?', pronunciation: 'Hol von ah KOHR-haaz?'),
      EmergencyPhrase(key: EmergencyPhraseKey.victimOfCrime, english: 'I am a victim of a crime', translated: 'B\u0171ncselekm\u00e9ny \u00e1ldozata vagyok', pronunciation: 'BOON-cheh-lek-mayn AAL-doh-zah-tah VAH-dyok'),
      EmergencyPhrase(key: EmergencyPhraseKey.needPhoneCall, english: 'I need to make a phone call', translated: 'Telefonh\u00edv\u00e1st kell ind\u00edtanom', pronunciation: 'TEH-leh-fon-hee-vaasht kell IN-dee-tah-nom'),
      EmergencyPhrase(key: EmergencyPhraseKey.whatAreMyRights, english: 'What are my rights?', translated: 'Mik a jogaim?', pronunciation: 'Meek ah YOH-gah-eem?'),
      EmergencyPhrase(key: EmergencyPhraseKey.applyForAsylum, english: 'I want to apply for asylum', translated: 'Menek\u00fclt st\u00e1tuszt szeretn\u00e9k k\u00e9rni', pronunciation: 'MEH-neh-koolt SHTAA-toost SEH-ret-nayk KAYR-nee'),
      EmergencyPhrase(key: EmergencyPhraseKey.speakSlowly, english: 'Please speak slowly', translated: 'K\u00e9rem, besz\u00e9ljen lassan', pronunciation: 'KAY-rem, BEH-sayl-yen LOSH-shon'),
      EmergencyPhrase(key: EmergencyPhraseKey.needFoodWater, english: 'I need food and water', translated: '\u00c9telre \u00e9s v\u00edzre van sz\u00fcks\u00e9gem', pronunciation: 'AY-tel-reh aysh VEEZ-reh von SYOOK-shay-gem'),
      EmergencyPhrase(key: EmergencyPhraseKey.whereIsEmbassy, english: 'Where is the embassy of [country]?', translated: 'Hol van [orsz\u00e1g] nagyk\u00f6vets\u00e9ge?', pronunciation: 'Hol von [OR-saag] NAHDY-ku-vet-shay-geh?'),
      EmergencyPhrase(key: EmergencyPhraseKey.haveChildren, english: 'I have children with me', translated: 'Gyerekek vannak velem', pronunciation: 'DYEH-reh-kek VON-nahk VEH-lem'),
      EmergencyPhrase(key: EmergencyPhraseKey.needMedication, english: 'I need medication', translated: 'Gy\u00f3gyszerre van sz\u00fcks\u00e9gem', pronunciation: 'DYOHDY-ser-reh von SYOOK-shay-gem'),
      EmergencyPhrase(key: EmergencyPhraseKey.findShelter, english: 'Can you help me find shelter?', translated: 'Tudna seg\u00edteni sz\u00e1ll\u00e1st tal\u00e1lni?', pronunciation: 'TOOD-nah SHEH-gee-teh-nee SAAL-laasht TAH-laal-nee?'),
      EmergencyPhrase(key: EmergencyPhraseKey.beingThreatened, english: 'I am being threatened', translated: 'Fenyegetnek', pronunciation: 'FEH-nyeh-get-nek'),
      EmergencyPhrase(key: EmergencyPhraseKey.thisIsEmergency, english: 'This is an emergency', translated: 'Ez egy v\u00e9szhelyzet', pronunciation: 'Ez edgy VAYS-hey-zet'),
    ],

    // =====================================================================
    // SWEDISH (sv)
    // =====================================================================
    'sv': const [
      EmergencyPhrase(key: EmergencyPhraseKey.needHelp, english: 'I need help', translated: 'Jag beh\u00f6ver hj\u00e4lp'),
      EmergencyPhrase(key: EmergencyPhraseKey.callPolice, english: 'Call the police', translated: 'Ring polisen'),
      EmergencyPhrase(key: EmergencyPhraseKey.needDoctor, english: 'I need a doctor', translated: 'Jag beh\u00f6ver en l\u00e4kare'),
      EmergencyPhrase(key: EmergencyPhraseKey.dontSpeakLanguage, english: "I don't speak [language]", translated: 'Jag talar inte svenska'),
      EmergencyPhrase(key: EmergencyPhraseKey.needInterpreter, english: 'I need an interpreter', translated: 'Jag beh\u00f6ver en tolk'),
      EmergencyPhrase(key: EmergencyPhraseKey.rightToLawyer, english: 'I have the right to a lawyer', translated: 'Jag har r\u00e4tt till en advokat'),
      EmergencyPhrase(key: EmergencyPhraseKey.dontUnderstand, english: "I don't understand", translated: 'Jag f\u00f6rst\u00e5r inte'),
      EmergencyPhrase(key: EmergencyPhraseKey.whereIsHospital, english: 'Where is the hospital?', translated: 'Var \u00e4r sjukhuset?'),
      EmergencyPhrase(key: EmergencyPhraseKey.victimOfCrime, english: 'I am a victim of a crime', translated: 'Jag \u00e4r offer f\u00f6r ett brott'),
      EmergencyPhrase(key: EmergencyPhraseKey.needPhoneCall, english: 'I need to make a phone call', translated: 'Jag beh\u00f6ver ringa ett telefonsamtal'),
      EmergencyPhrase(key: EmergencyPhraseKey.whatAreMyRights, english: 'What are my rights?', translated: 'Vilka \u00e4r mina r\u00e4ttigheter?'),
      EmergencyPhrase(key: EmergencyPhraseKey.applyForAsylum, english: 'I want to apply for asylum', translated: 'Jag vill ans\u00f6ka om asyl'),
      EmergencyPhrase(key: EmergencyPhraseKey.speakSlowly, english: 'Please speak slowly', translated: 'V\u00e4nligen tala l\u00e5ngsamt'),
      EmergencyPhrase(key: EmergencyPhraseKey.needFoodWater, english: 'I need food and water', translated: 'Jag beh\u00f6ver mat och vatten'),
      EmergencyPhrase(key: EmergencyPhraseKey.whereIsEmbassy, english: 'Where is the embassy of [country]?', translated: 'Var \u00e4r [lands] ambassad?'),
      EmergencyPhrase(key: EmergencyPhraseKey.haveChildren, english: 'I have children with me', translated: 'Jag har barn med mig'),
      EmergencyPhrase(key: EmergencyPhraseKey.needMedication, english: 'I need medication', translated: 'Jag beh\u00f6ver medicin'),
      EmergencyPhrase(key: EmergencyPhraseKey.findShelter, english: 'Can you help me find shelter?', translated: 'Kan du hj\u00e4lpa mig att hitta boende?'),
      EmergencyPhrase(key: EmergencyPhraseKey.beingThreatened, english: 'I am being threatened', translated: 'Jag blir hotad'),
      EmergencyPhrase(key: EmergencyPhraseKey.thisIsEmergency, english: 'This is an emergency', translated: 'Det h\u00e4r \u00e4r ett n\u00f6dfall'),
    ],

    // =====================================================================
    // FINNISH (fi) - WITH PRONUNCIATION HINTS
    // =====================================================================
    'fi': const [
      EmergencyPhrase(key: EmergencyPhraseKey.needHelp, english: 'I need help', translated: 'Tarvitsen apua', pronunciation: 'TAR-vit-sen AH-poo-ah'),
      EmergencyPhrase(key: EmergencyPhraseKey.callPolice, english: 'Call the police', translated: 'Soittakaa poliisi', pronunciation: 'SOY-tah-kaa POH-lee-see'),
      EmergencyPhrase(key: EmergencyPhraseKey.needDoctor, english: 'I need a doctor', translated: 'Tarvitsen l\u00e4\u00e4k\u00e4ri\u00e4', pronunciation: 'TAR-vit-sen LAA-kaa-ree-aa'),
      EmergencyPhrase(key: EmergencyPhraseKey.dontSpeakLanguage, english: "I don't speak [language]", translated: 'En puhu suomea', pronunciation: 'En POO-hoo SOO-oh-meh-ah'),
      EmergencyPhrase(key: EmergencyPhraseKey.needInterpreter, english: 'I need an interpreter', translated: 'Tarvitsen tulkin', pronunciation: 'TAR-vit-sen TOOL-kin'),
      EmergencyPhrase(key: EmergencyPhraseKey.rightToLawyer, english: 'I have the right to a lawyer', translated: 'Minulla on oikeus asianajajaan', pronunciation: 'MIH-nool-lah on OY-keh-oos AH-see-ah-nah-yah-yaan'),
      EmergencyPhrase(key: EmergencyPhraseKey.dontUnderstand, english: "I don't understand", translated: 'En ymm\u00e4rr\u00e4', pronunciation: 'En OOM-mar-raa'),
      EmergencyPhrase(key: EmergencyPhraseKey.whereIsHospital, english: 'Where is the hospital?', translated: 'Miss\u00e4 on sairaala?', pronunciation: 'MIS-saa on SAI-raa-lah?'),
      EmergencyPhrase(key: EmergencyPhraseKey.victimOfCrime, english: 'I am a victim of a crime', translated: 'Olen rikoksen uhri', pronunciation: 'OH-len REE-kok-sen OOH-ree'),
      EmergencyPhrase(key: EmergencyPhraseKey.needPhoneCall, english: 'I need to make a phone call', translated: 'Minun t\u00e4ytyy soittaa puhelu', pronunciation: 'MIH-noon TAY-too SOY-taa POO-heh-loo'),
      EmergencyPhrase(key: EmergencyPhraseKey.whatAreMyRights, english: 'What are my rights?', translated: 'Mitk\u00e4 ovat oikeuteni?', pronunciation: 'MIT-kaa OH-vat OY-keh-oo-teh-nee?'),
      EmergencyPhrase(key: EmergencyPhraseKey.applyForAsylum, english: 'I want to apply for asylum', translated: 'Haluan hakea turvapaikkaa', pronunciation: 'HAH-loo-ahn HAH-keh-ah TOOR-vah-pike-kaa'),
      EmergencyPhrase(key: EmergencyPhraseKey.speakSlowly, english: 'Please speak slowly', translated: 'Puhukaa hitaasti', pronunciation: 'POO-hoo-kaa HEE-taas-tee'),
      EmergencyPhrase(key: EmergencyPhraseKey.needFoodWater, english: 'I need food and water', translated: 'Tarvitsen ruokaa ja vett\u00e4', pronunciation: 'TAR-vit-sen ROO-oh-kaa yah VET-taa'),
      EmergencyPhrase(key: EmergencyPhraseKey.whereIsEmbassy, english: 'Where is the embassy of [country]?', translated: 'Miss\u00e4 on [maan] suurl\u00e4hetyst\u00f6?', pronunciation: 'MIS-saa on [maan] SOOR-laa-heh-toos-tu?'),
      EmergencyPhrase(key: EmergencyPhraseKey.haveChildren, english: 'I have children with me', translated: 'Minulla on lapsia mukanani', pronunciation: 'MIH-nool-lah on LAP-see-ah MOO-kah-nah-nee'),
      EmergencyPhrase(key: EmergencyPhraseKey.needMedication, english: 'I need medication', translated: 'Tarvitsen l\u00e4\u00e4kett\u00e4', pronunciation: 'TAR-vit-sen LAAH-ket-taa'),
      EmergencyPhrase(key: EmergencyPhraseKey.findShelter, english: 'Can you help me find shelter?', translated: 'Voitteko auttaa minua l\u00f6yt\u00e4m\u00e4\u00e4n majoituksen?', pronunciation: 'VOY-teh-koh OUT-taa MIH-noo-ah LUU-ee-taa-maan MAH-yoy-took-sen?'),
      EmergencyPhrase(key: EmergencyPhraseKey.beingThreatened, english: 'I am being threatened', translated: 'Minua uhataan', pronunciation: 'MIH-noo-ah OO-hah-taan'),
      EmergencyPhrase(key: EmergencyPhraseKey.thisIsEmergency, english: 'This is an emergency', translated: 'T\u00e4m\u00e4 on h\u00e4t\u00e4tilanne', pronunciation: 'TAA-maa on HAA-taa-tee-lan-neh'),
    ],

    // =====================================================================
    // ESTONIAN (et)
    // =====================================================================
    'et': const [
      EmergencyPhrase(key: EmergencyPhraseKey.needHelp, english: 'I need help', translated: 'Ma vajan abi'),
      EmergencyPhrase(key: EmergencyPhraseKey.callPolice, english: 'Call the police', translated: 'Kutsuge politsei'),
      EmergencyPhrase(key: EmergencyPhraseKey.needDoctor, english: 'I need a doctor', translated: 'Ma vajan arsti'),
      EmergencyPhrase(key: EmergencyPhraseKey.dontSpeakLanguage, english: "I don't speak [language]", translated: 'Ma ei r\u00e4\u00e4gi eesti keelt'),
      EmergencyPhrase(key: EmergencyPhraseKey.needInterpreter, english: 'I need an interpreter', translated: 'Ma vajan t\u00f5lki'),
      EmergencyPhrase(key: EmergencyPhraseKey.rightToLawyer, english: 'I have the right to a lawyer', translated: 'Mul on \u00f5igus advokaadile'),
      EmergencyPhrase(key: EmergencyPhraseKey.dontUnderstand, english: "I don't understand", translated: 'Ma ei saa aru'),
      EmergencyPhrase(key: EmergencyPhraseKey.whereIsHospital, english: 'Where is the hospital?', translated: 'Kus on haigla?'),
      EmergencyPhrase(key: EmergencyPhraseKey.victimOfCrime, english: 'I am a victim of a crime', translated: 'Ma olen kuriteo ohver'),
      EmergencyPhrase(key: EmergencyPhraseKey.needPhoneCall, english: 'I need to make a phone call', translated: 'Ma pean helistama'),
      EmergencyPhrase(key: EmergencyPhraseKey.whatAreMyRights, english: 'What are my rights?', translated: 'Millised on minu \u00f5igused?'),
      EmergencyPhrase(key: EmergencyPhraseKey.applyForAsylum, english: 'I want to apply for asylum', translated: 'Ma tahan taotleda var\u006aupaika'),
      EmergencyPhrase(key: EmergencyPhraseKey.speakSlowly, english: 'Please speak slowly', translated: 'Palun r\u00e4\u00e4kige aeglaselt'),
      EmergencyPhrase(key: EmergencyPhraseKey.needFoodWater, english: 'I need food and water', translated: 'Ma vajan toitu ja vett'),
      EmergencyPhrase(key: EmergencyPhraseKey.whereIsEmbassy, english: 'Where is the embassy of [country]?', translated: 'Kus on [riigi] saatkond?'),
      EmergencyPhrase(key: EmergencyPhraseKey.haveChildren, english: 'I have children with me', translated: 'Mul on lapsed kaasas'),
      EmergencyPhrase(key: EmergencyPhraseKey.needMedication, english: 'I need medication', translated: 'Ma vajan ravimeid'),
      EmergencyPhrase(key: EmergencyPhraseKey.findShelter, english: 'Can you help me find shelter?', translated: 'Kas saate mind aidata peavarju leidma?'),
      EmergencyPhrase(key: EmergencyPhraseKey.beingThreatened, english: 'I am being threatened', translated: 'Mind \u00e4hvardat\u0061kse'),
      EmergencyPhrase(key: EmergencyPhraseKey.thisIsEmergency, english: 'This is an emergency', translated: 'See on h\u00e4daolukord'),
    ],

    // =====================================================================
    // LATVIAN (lv)
    // =====================================================================
    'lv': const [
      EmergencyPhrase(key: EmergencyPhraseKey.needHelp, english: 'I need help', translated: 'Man ir nepiecie\u0161ama pal\u012bdz\u012bba'),
      EmergencyPhrase(key: EmergencyPhraseKey.callPolice, english: 'Call the police', translated: 'Izsauciet policiju'),
      EmergencyPhrase(key: EmergencyPhraseKey.needDoctor, english: 'I need a doctor', translated: 'Man ir nepiecie\u0161ams \u0101rsts'),
      EmergencyPhrase(key: EmergencyPhraseKey.dontSpeakLanguage, english: "I don't speak [language]", translated: 'Es nerun\u0101ju latvie\u0161u valod\u0101'),
      EmergencyPhrase(key: EmergencyPhraseKey.needInterpreter, english: 'I need an interpreter', translated: 'Man ir nepiecie\u0161ams tulks'),
      EmergencyPhrase(key: EmergencyPhraseKey.rightToLawyer, english: 'I have the right to a lawyer', translated: 'Man ir ties\u012bbas uz advok\u0101tu'),
      EmergencyPhrase(key: EmergencyPhraseKey.dontUnderstand, english: "I don't understand", translated: 'Es nesaprotu'),
      EmergencyPhrase(key: EmergencyPhraseKey.whereIsHospital, english: 'Where is the hospital?', translated: 'Kur atrodas slimn\u012bca?'),
      EmergencyPhrase(key: EmergencyPhraseKey.victimOfCrime, english: 'I am a victim of a crime', translated: 'Es esmu nozieguma upuris'),
      EmergencyPhrase(key: EmergencyPhraseKey.needPhoneCall, english: 'I need to make a phone call', translated: 'Man j\u0101veic telefona zvans'),
      EmergencyPhrase(key: EmergencyPhraseKey.whatAreMyRights, english: 'What are my rights?', translated: 'K\u0101das ir manas ties\u012bbas?'),
      EmergencyPhrase(key: EmergencyPhraseKey.applyForAsylum, english: 'I want to apply for asylum', translated: 'Es v\u0113los pieteikties patv\u0113rumam'),
      EmergencyPhrase(key: EmergencyPhraseKey.speakSlowly, english: 'Please speak slowly', translated: 'L\u016bdzu, run\u0101jiet l\u0113ni'),
      EmergencyPhrase(key: EmergencyPhraseKey.needFoodWater, english: 'I need food and water', translated: 'Man ir nepiecie\u0161ams \u0113diens un \u016bdens'),
      EmergencyPhrase(key: EmergencyPhraseKey.whereIsEmbassy, english: 'Where is the embassy of [country]?', translated: 'Kur atrodas [valsts] v\u0113stniec\u012bba?'),
      EmergencyPhrase(key: EmergencyPhraseKey.haveChildren, english: 'I have children with me', translated: 'Man l\u012bdzi ir b\u0113rni'),
      EmergencyPhrase(key: EmergencyPhraseKey.needMedication, english: 'I need medication', translated: 'Man ir nepiecie\u0161amas z\u0101les'),
      EmergencyPhrase(key: EmergencyPhraseKey.findShelter, english: 'Can you help me find shelter?', translated: 'Vai j\u016bs varat man pal\u012bdz\u0113t atrast patv\u0113rumu?'),
      EmergencyPhrase(key: EmergencyPhraseKey.beingThreatened, english: 'I am being threatened', translated: 'Man draud'),
      EmergencyPhrase(key: EmergencyPhraseKey.thisIsEmergency, english: 'This is an emergency', translated: '\u0160\u012b ir \u0101rk\u0101rtas situ\u0101cija'),
    ],

    // =====================================================================
    // LITHUANIAN (lt)
    // =====================================================================
    'lt': const [
      EmergencyPhrase(key: EmergencyPhraseKey.needHelp, english: 'I need help', translated: 'Man reikia pagalbos'),
      EmergencyPhrase(key: EmergencyPhraseKey.callPolice, english: 'Call the police', translated: 'I\u0161kvieskite policij\u0105'),
      EmergencyPhrase(key: EmergencyPhraseKey.needDoctor, english: 'I need a doctor', translated: 'Man reikia gydytojo'),
      EmergencyPhrase(key: EmergencyPhraseKey.dontSpeakLanguage, english: "I don't speak [language]", translated: 'A\u0161 nekalbu lietuvi\u0161kai'),
      EmergencyPhrase(key: EmergencyPhraseKey.needInterpreter, english: 'I need an interpreter', translated: 'Man reikia vert\u0117jo'),
      EmergencyPhrase(key: EmergencyPhraseKey.rightToLawyer, english: 'I have the right to a lawyer', translated: 'A\u0161 turiu teis\u0119 \u012f advokat\u0105'),
      EmergencyPhrase(key: EmergencyPhraseKey.dontUnderstand, english: "I don't understand", translated: 'A\u0161 nesuprantu'),
      EmergencyPhrase(key: EmergencyPhraseKey.whereIsHospital, english: 'Where is the hospital?', translated: 'Kur yra ligonin\u0117?'),
      EmergencyPhrase(key: EmergencyPhraseKey.victimOfCrime, english: 'I am a victim of a crime', translated: 'A\u0161 esu nusikaltimo auka'),
      EmergencyPhrase(key: EmergencyPhraseKey.needPhoneCall, english: 'I need to make a phone call', translated: 'Man reikia paskambinti telefonu'),
      EmergencyPhrase(key: EmergencyPhraseKey.whatAreMyRights, english: 'What are my rights?', translated: 'Kokios mano teis\u0117s?'),
      EmergencyPhrase(key: EmergencyPhraseKey.applyForAsylum, english: 'I want to apply for asylum', translated: 'Noriu pra\u0161yti prieglobs\u010dio'),
      EmergencyPhrase(key: EmergencyPhraseKey.speakSlowly, english: 'Please speak slowly', translated: 'Pra\u0161au, kalb\u0117kite l\u0117tai'),
      EmergencyPhrase(key: EmergencyPhraseKey.needFoodWater, english: 'I need food and water', translated: 'Man reikia maisto ir vandens'),
      EmergencyPhrase(key: EmergencyPhraseKey.whereIsEmbassy, english: 'Where is the embassy of [country]?', translated: 'Kur yra [\u0161alies] ambasada?'),
      EmergencyPhrase(key: EmergencyPhraseKey.haveChildren, english: 'I have children with me', translated: 'Su manimi yra vaikai'),
      EmergencyPhrase(key: EmergencyPhraseKey.needMedication, english: 'I need medication', translated: 'Man reikia vaist\u0173'),
      EmergencyPhrase(key: EmergencyPhraseKey.findShelter, english: 'Can you help me find shelter?', translated: 'Ar galite pad\u0117ti rasti prieglobst\u012f?'),
      EmergencyPhrase(key: EmergencyPhraseKey.beingThreatened, english: 'I am being threatened', translated: 'Man grasinama'),
      EmergencyPhrase(key: EmergencyPhraseKey.thisIsEmergency, english: 'This is an emergency', translated: 'Tai yra nelaiming\u0105s atsitikimas'),
    ],

    // =====================================================================
    // BULGARIAN (bg)
    // =====================================================================
    'bg': const [
      EmergencyPhrase(key: EmergencyPhraseKey.needHelp, english: 'I need help', translated: '\u041d\u0443\u0436\u0434\u0430\u044f \u0441\u0435 \u043e\u0442 \u043f\u043e\u043c\u043e\u0449'),
      EmergencyPhrase(key: EmergencyPhraseKey.callPolice, english: 'Call the police', translated: '\u041e\u0431\u0430\u0434\u0435\u0442\u0435 \u0441\u0435 \u043d\u0430 \u043f\u043e\u043b\u0438\u0446\u0438\u044f\u0442\u0430'),
      EmergencyPhrase(key: EmergencyPhraseKey.needDoctor, english: 'I need a doctor', translated: '\u041d\u0443\u0436\u0434\u0430\u044f \u0441\u0435 \u043e\u0442 \u043b\u0435\u043a\u0430\u0440'),
      EmergencyPhrase(key: EmergencyPhraseKey.dontSpeakLanguage, english: "I don't speak [language]", translated: '\u041d\u0435 \u0433\u043e\u0432\u043e\u0440\u044f \u0431\u044a\u043b\u0433\u0430\u0440\u0441\u043a\u0438'),
      EmergencyPhrase(key: EmergencyPhraseKey.needInterpreter, english: 'I need an interpreter', translated: '\u041d\u0443\u0436\u0434\u0430\u044f \u0441\u0435 \u043e\u0442 \u043f\u0440\u0435\u0432\u043e\u0434\u0430\u0447'),
      EmergencyPhrase(key: EmergencyPhraseKey.rightToLawyer, english: 'I have the right to a lawyer', translated: '\u0418\u043c\u0430\u043c \u043f\u0440\u0430\u0432\u043e \u043d\u0430 \u0430\u0434\u0432\u043e\u043a\u0430\u0442'),
      EmergencyPhrase(key: EmergencyPhraseKey.dontUnderstand, english: "I don't understand", translated: '\u041d\u0435 \u0440\u0430\u0437\u0431\u0438\u0440\u0430\u043c'),
      EmergencyPhrase(key: EmergencyPhraseKey.whereIsHospital, english: 'Where is the hospital?', translated: '\u041a\u044a\u0434\u0435 \u0435 \u0431\u043e\u043b\u043d\u0438\u0446\u0430\u0442\u0430?'),
      EmergencyPhrase(key: EmergencyPhraseKey.victimOfCrime, english: 'I am a victim of a crime', translated: '\u0410\u0437 \u0441\u044a\u043c \u0436\u0435\u0440\u0442\u0432\u0430 \u043d\u0430 \u043f\u0440\u0435\u0441\u0442\u044a\u043f\u043b\u0435\u043d\u0438\u0435'),
      EmergencyPhrase(key: EmergencyPhraseKey.needPhoneCall, english: 'I need to make a phone call', translated: '\u0422\u0440\u044f\u0431\u0432\u0430 \u0434\u0430 \u0441\u0435 \u043e\u0431\u0430\u0434\u044f \u043f\u043e \u0442\u0435\u043b\u0435\u0444\u043e\u043d\u0430'),
      EmergencyPhrase(key: EmergencyPhraseKey.whatAreMyRights, english: 'What are my rights?', translated: '\u041a\u0430\u043a\u0432\u0438 \u0441\u0430 \u043f\u0440\u0430\u0432\u0430\u0442\u0430 \u043c\u0438?'),
      EmergencyPhrase(key: EmergencyPhraseKey.applyForAsylum, english: 'I want to apply for asylum', translated: '\u0418\u0441\u043a\u0430\u043c \u0434\u0430 \u043a\u0430\u043d\u0434\u0438\u0434\u0430\u0442\u0441\u0442\u0432\u0430\u043c \u0437\u0430 \u0443\u0431\u0435\u0436\u0438\u0449\u0435'),
      EmergencyPhrase(key: EmergencyPhraseKey.speakSlowly, english: 'Please speak slowly', translated: '\u041c\u043e\u043b\u044f, \u0433\u043e\u0432\u043e\u0440\u0435\u0442\u0435 \u0431\u0430\u0432\u043d\u043e'),
      EmergencyPhrase(key: EmergencyPhraseKey.needFoodWater, english: 'I need food and water', translated: '\u041d\u0443\u0436\u0434\u0430\u044f \u0441\u0435 \u043e\u0442 \u0445\u0440\u0430\u043d\u0430 \u0438 \u0432\u043e\u0434\u0430'),
      EmergencyPhrase(key: EmergencyPhraseKey.whereIsEmbassy, english: 'Where is the embassy of [country]?', translated: '\u041a\u044a\u0434\u0435 \u0435 \u043f\u043e\u0441\u043e\u043b\u0441\u0442\u0432\u043e\u0442\u043e \u043d\u0430 [\u0434\u044a\u0440\u0436\u0430\u0432\u0430]?'),
      EmergencyPhrase(key: EmergencyPhraseKey.haveChildren, english: 'I have children with me', translated: '\u0418\u043c\u0430\u043c \u0434\u0435\u0446\u0430 \u0441\u044a\u0441 \u0441\u0435\u0431\u0435 \u0441\u0438'),
      EmergencyPhrase(key: EmergencyPhraseKey.needMedication, english: 'I need medication', translated: '\u041d\u0443\u0436\u0434\u0430\u044f \u0441\u0435 \u043e\u0442 \u043b\u0435\u043a\u0430\u0440\u0441\u0442\u0432\u0430'),
      EmergencyPhrase(key: EmergencyPhraseKey.findShelter, english: 'Can you help me find shelter?', translated: '\u041c\u043e\u0436\u0435\u0442\u0435 \u043b\u0438 \u0434\u0430 \u043c\u0438 \u043f\u043e\u043c\u043e\u0433\u043d\u0435\u0442\u0435 \u0434\u0430 \u043d\u0430\u043c\u0435\u0440\u044f \u043f\u043e\u0434\u0441\u043b\u043e\u043d?'),
      EmergencyPhrase(key: EmergencyPhraseKey.beingThreatened, english: 'I am being threatened', translated: '\u0417\u0430\u043f\u043b\u0430\u0448\u0432\u0430\u0442 \u043c\u0435'),
      EmergencyPhrase(key: EmergencyPhraseKey.thisIsEmergency, english: 'This is an emergency', translated: '\u0422\u043e\u0432\u0430 \u0435 \u0441\u043f\u0435\u0448\u0435\u043d \u0441\u043b\u0443\u0447\u0430\u0439'),
    ],

    // =====================================================================
    // CROATIAN (hr)
    // =====================================================================
    'hr': const [
      EmergencyPhrase(key: EmergencyPhraseKey.needHelp, english: 'I need help', translated: 'Trebam pomo\u0107'),
      EmergencyPhrase(key: EmergencyPhraseKey.callPolice, english: 'Call the police', translated: 'Pozovite policiju'),
      EmergencyPhrase(key: EmergencyPhraseKey.needDoctor, english: 'I need a doctor', translated: 'Trebam lije\u010dnika'),
      EmergencyPhrase(key: EmergencyPhraseKey.dontSpeakLanguage, english: "I don't speak [language]", translated: 'Ne govorim hrvatski'),
      EmergencyPhrase(key: EmergencyPhraseKey.needInterpreter, english: 'I need an interpreter', translated: 'Trebam prevoditelja'),
      EmergencyPhrase(key: EmergencyPhraseKey.rightToLawyer, english: 'I have the right to a lawyer', translated: 'Imam pravo na odvjetnika'),
      EmergencyPhrase(key: EmergencyPhraseKey.dontUnderstand, english: "I don't understand", translated: 'Ne razumijem'),
      EmergencyPhrase(key: EmergencyPhraseKey.whereIsHospital, english: 'Where is the hospital?', translated: 'Gdje je bolnica?'),
      EmergencyPhrase(key: EmergencyPhraseKey.victimOfCrime, english: 'I am a victim of a crime', translated: '\u017drtva sam kaznenog djela'),
      EmergencyPhrase(key: EmergencyPhraseKey.needPhoneCall, english: 'I need to make a phone call', translated: 'Moram obaviti telefonski poziv'),
      EmergencyPhrase(key: EmergencyPhraseKey.whatAreMyRights, english: 'What are my rights?', translated: 'Koja su moja prava?'),
      EmergencyPhrase(key: EmergencyPhraseKey.applyForAsylum, english: 'I want to apply for asylum', translated: '\u017delim zatra\u017eiti azil'),
      EmergencyPhrase(key: EmergencyPhraseKey.speakSlowly, english: 'Please speak slowly', translated: 'Molim vas, govorite polako'),
      EmergencyPhrase(key: EmergencyPhraseKey.needFoodWater, english: 'I need food and water', translated: 'Trebam hranu i vodu'),
      EmergencyPhrase(key: EmergencyPhraseKey.whereIsEmbassy, english: 'Where is the embassy of [country]?', translated: 'Gdje je veleposlanstvo [dr\u017eave]?'),
      EmergencyPhrase(key: EmergencyPhraseKey.haveChildren, english: 'I have children with me', translated: 'Imam djecu sa sobom'),
      EmergencyPhrase(key: EmergencyPhraseKey.needMedication, english: 'I need medication', translated: 'Trebam lijekove'),
      EmergencyPhrase(key: EmergencyPhraseKey.findShelter, english: 'Can you help me find shelter?', translated: 'Mo\u017eete li mi pomo\u0107i prona\u0107i smje\u0161taj?'),
      EmergencyPhrase(key: EmergencyPhraseKey.beingThreatened, english: 'I am being threatened', translated: 'Prijete mi'),
      EmergencyPhrase(key: EmergencyPhraseKey.thisIsEmergency, english: 'This is an emergency', translated: 'Ovo je hitni slu\u010daj'),
    ],

    // =====================================================================
    // SLOVAK (sk)
    // =====================================================================
    'sk': const [
      EmergencyPhrase(key: EmergencyPhraseKey.needHelp, english: 'I need help', translated: 'Potrebujem pomoc'),
      EmergencyPhrase(key: EmergencyPhraseKey.callPolice, english: 'Call the police', translated: 'Zavolajte pol\u00edciu'),
      EmergencyPhrase(key: EmergencyPhraseKey.needDoctor, english: 'I need a doctor', translated: 'Potrebujem lek\u00e1ra'),
      EmergencyPhrase(key: EmergencyPhraseKey.dontSpeakLanguage, english: "I don't speak [language]", translated: 'Nehovor\u00edm po slovensky'),
      EmergencyPhrase(key: EmergencyPhraseKey.needInterpreter, english: 'I need an interpreter', translated: 'Potrebujem tl\u00edmo\u010dn\u00edka'),
      EmergencyPhrase(key: EmergencyPhraseKey.rightToLawyer, english: 'I have the right to a lawyer', translated: 'M\u00e1m pr\u00e1vo na advok\u00e1ta'),
      EmergencyPhrase(key: EmergencyPhraseKey.dontUnderstand, english: "I don't understand", translated: 'Nerozumiem'),
      EmergencyPhrase(key: EmergencyPhraseKey.whereIsHospital, english: 'Where is the hospital?', translated: 'Kde je nemocnica?'),
      EmergencyPhrase(key: EmergencyPhraseKey.victimOfCrime, english: 'I am a victim of a crime', translated: 'Som obe\u0165ou trestn\u00e9ho \u010dinu'),
      EmergencyPhrase(key: EmergencyPhraseKey.needPhoneCall, english: 'I need to make a phone call', translated: 'Potrebujem zatelefonova\u0165'),
      EmergencyPhrase(key: EmergencyPhraseKey.whatAreMyRights, english: 'What are my rights?', translated: 'Ak\u00e9 s\u00fa moje pr\u00e1va?'),
      EmergencyPhrase(key: EmergencyPhraseKey.applyForAsylum, english: 'I want to apply for asylum', translated: 'Chcem po\u017eiada\u0165 o azyl'),
      EmergencyPhrase(key: EmergencyPhraseKey.speakSlowly, english: 'Please speak slowly', translated: 'Pros\u00edm, hovorte pomaly'),
      EmergencyPhrase(key: EmergencyPhraseKey.needFoodWater, english: 'I need food and water', translated: 'Potrebujem jedlo a vodu'),
      EmergencyPhrase(key: EmergencyPhraseKey.whereIsEmbassy, english: 'Where is the embassy of [country]?', translated: 'Kde je ambas\u00e1da [krajiny]?'),
      EmergencyPhrase(key: EmergencyPhraseKey.haveChildren, english: 'I have children with me', translated: 'M\u00e1m so sebou deti'),
      EmergencyPhrase(key: EmergencyPhraseKey.needMedication, english: 'I need medication', translated: 'Potrebujem lieky'),
      EmergencyPhrase(key: EmergencyPhraseKey.findShelter, english: 'Can you help me find shelter?', translated: 'M\u00f4\u017eete mi pom\u00f4c\u0165 n\u00e1js\u0165 pr\u00edstrešie?'),
      EmergencyPhrase(key: EmergencyPhraseKey.beingThreatened, english: 'I am being threatened', translated: 'Som ohrozovan\u00fd/\u00e1'),
      EmergencyPhrase(key: EmergencyPhraseKey.thisIsEmergency, english: 'This is an emergency', translated: 'Toto je n\u00fadzov\u00e1 situ\u00e1cia'),
    ],

    // =====================================================================
    // SLOVENIAN (sl)
    // =====================================================================
    'sl': const [
      EmergencyPhrase(key: EmergencyPhraseKey.needHelp, english: 'I need help', translated: 'Potrebujem pomo\u010d'),
      EmergencyPhrase(key: EmergencyPhraseKey.callPolice, english: 'Call the police', translated: 'Pokli\u010dite policijo'),
      EmergencyPhrase(key: EmergencyPhraseKey.needDoctor, english: 'I need a doctor', translated: 'Potrebujem zdravnika'),
      EmergencyPhrase(key: EmergencyPhraseKey.dontSpeakLanguage, english: "I don't speak [language]", translated: 'Ne govorim slovensko'),
      EmergencyPhrase(key: EmergencyPhraseKey.needInterpreter, english: 'I need an interpreter', translated: 'Potrebujem tolma\u010da'),
      EmergencyPhrase(key: EmergencyPhraseKey.rightToLawyer, english: 'I have the right to a lawyer', translated: 'Imam pravico do odvetnika'),
      EmergencyPhrase(key: EmergencyPhraseKey.dontUnderstand, english: "I don't understand", translated: 'Ne razumem'),
      EmergencyPhrase(key: EmergencyPhraseKey.whereIsHospital, english: 'Where is the hospital?', translated: 'Kje je bolni\u0161nica?'),
      EmergencyPhrase(key: EmergencyPhraseKey.victimOfCrime, english: 'I am a victim of a crime', translated: 'Sem \u017ertev kaznivega dejanja'),
      EmergencyPhrase(key: EmergencyPhraseKey.needPhoneCall, english: 'I need to make a phone call', translated: 'Moram opraviti telefonski klic'),
      EmergencyPhrase(key: EmergencyPhraseKey.whatAreMyRights, english: 'What are my rights?', translated: 'Kak\u0161ne so moje pravice?'),
      EmergencyPhrase(key: EmergencyPhraseKey.applyForAsylum, english: 'I want to apply for asylum', translated: '\u017delim zaprositi za azil'),
      EmergencyPhrase(key: EmergencyPhraseKey.speakSlowly, english: 'Please speak slowly', translated: 'Prosim, govorite po\u010dasi'),
      EmergencyPhrase(key: EmergencyPhraseKey.needFoodWater, english: 'I need food and water', translated: 'Potrebujem hrano in vodo'),
      EmergencyPhrase(key: EmergencyPhraseKey.whereIsEmbassy, english: 'Where is the embassy of [country]?', translated: 'Kje je veleposlani\u0161tvo [dr\u017eave]?'),
      EmergencyPhrase(key: EmergencyPhraseKey.haveChildren, english: 'I have children with me', translated: 'S seboj imam otroke'),
      EmergencyPhrase(key: EmergencyPhraseKey.needMedication, english: 'I need medication', translated: 'Potrebujem zdravila'),
      EmergencyPhrase(key: EmergencyPhraseKey.findShelter, english: 'Can you help me find shelter?', translated: 'Mi lahko pomagate najti zavetje?'),
      EmergencyPhrase(key: EmergencyPhraseKey.beingThreatened, english: 'I am being threatened', translated: 'Grozijo mi'),
      EmergencyPhrase(key: EmergencyPhraseKey.thisIsEmergency, english: 'This is an emergency', translated: 'To je nujni primer'),
    ],

    // =====================================================================
    // DANISH (da)
    // =====================================================================
    'da': const [
      EmergencyPhrase(key: EmergencyPhraseKey.needHelp, english: 'I need help', translated: 'Jeg har brug for hj\u00e6lp'),
      EmergencyPhrase(key: EmergencyPhraseKey.callPolice, english: 'Call the police', translated: 'Ring til politiet'),
      EmergencyPhrase(key: EmergencyPhraseKey.needDoctor, english: 'I need a doctor', translated: 'Jeg har brug for en l\u00e6ge'),
      EmergencyPhrase(key: EmergencyPhraseKey.dontSpeakLanguage, english: "I don't speak [language]", translated: 'Jeg taler ikke dansk'),
      EmergencyPhrase(key: EmergencyPhraseKey.needInterpreter, english: 'I need an interpreter', translated: 'Jeg har brug for en tolk'),
      EmergencyPhrase(key: EmergencyPhraseKey.rightToLawyer, english: 'I have the right to a lawyer', translated: 'Jeg har ret til en advokat'),
      EmergencyPhrase(key: EmergencyPhraseKey.dontUnderstand, english: "I don't understand", translated: 'Jeg forst\u00e5r ikke'),
      EmergencyPhrase(key: EmergencyPhraseKey.whereIsHospital, english: 'Where is the hospital?', translated: 'Hvor er hospitalet?'),
      EmergencyPhrase(key: EmergencyPhraseKey.victimOfCrime, english: 'I am a victim of a crime', translated: 'Jeg er offer for en forbrydelse'),
      EmergencyPhrase(key: EmergencyPhraseKey.needPhoneCall, english: 'I need to make a phone call', translated: 'Jeg skal ringe en opringning'),
      EmergencyPhrase(key: EmergencyPhraseKey.whatAreMyRights, english: 'What are my rights?', translated: 'Hvad er mine rettigheder?'),
      EmergencyPhrase(key: EmergencyPhraseKey.applyForAsylum, english: 'I want to apply for asylum', translated: 'Jeg vil ans\u00f8ge om asyl'),
      EmergencyPhrase(key: EmergencyPhraseKey.speakSlowly, english: 'Please speak slowly', translated: 'V\u00e6r venlig at tale langsomt'),
      EmergencyPhrase(key: EmergencyPhraseKey.needFoodWater, english: 'I need food and water', translated: 'Jeg har brug for mad og vand'),
      EmergencyPhrase(key: EmergencyPhraseKey.whereIsEmbassy, english: 'Where is the embassy of [country]?', translated: 'Hvor er [lands] ambassade?'),
      EmergencyPhrase(key: EmergencyPhraseKey.haveChildren, english: 'I have children with me', translated: 'Jeg har b\u00f8rn med mig'),
      EmergencyPhrase(key: EmergencyPhraseKey.needMedication, english: 'I need medication', translated: 'Jeg har brug for medicin'),
      EmergencyPhrase(key: EmergencyPhraseKey.findShelter, english: 'Can you help me find shelter?', translated: 'Kan du hj\u00e6lpe mig med at finde husly?'),
      EmergencyPhrase(key: EmergencyPhraseKey.beingThreatened, english: 'I am being threatened', translated: 'Jeg bliver truet'),
      EmergencyPhrase(key: EmergencyPhraseKey.thisIsEmergency, english: 'This is an emergency', translated: 'Dette er en n\u00f8dsituation'),
    ],

    // =====================================================================
    // GREEK (el) - WITH PRONUNCIATION HINTS
    // =====================================================================
    'el': const [
      EmergencyPhrase(key: EmergencyPhraseKey.needHelp, english: 'I need help', translated: '\u03a7\u03c1\u03b5\u03b9\u03ac\u03b6\u03bf\u03bc\u03b1\u03b9 \u03b2\u03bf\u03ae\u03b8\u03b5\u03b9\u03b1', pronunciation: 'hree-AH-zo-meh vo-EE-thee-ah'),
      EmergencyPhrase(key: EmergencyPhraseKey.callPolice, english: 'Call the police', translated: '\u039a\u03b1\u03bb\u03ad\u03c3\u03c4\u03b5 \u03c4\u03b7\u03bd \u03b1\u03c3\u03c4\u03c5\u03bd\u03bf\u03bc\u03af\u03b1', pronunciation: 'kah-LES-teh teen ah-stee-no-MEE-ah'),
      EmergencyPhrase(key: EmergencyPhraseKey.needDoctor, english: 'I need a doctor', translated: '\u03a7\u03c1\u03b5\u03b9\u03ac\u03b6\u03bf\u03bc\u03b1\u03b9 \u03b3\u03b9\u03b1\u03c4\u03c1\u03cc', pronunciation: 'hree-AH-zo-meh yah-TRO'),
      EmergencyPhrase(key: EmergencyPhraseKey.dontSpeakLanguage, english: "I don't speak [language]", translated: '\u0394\u03b5\u03bd \u03bc\u03b9\u03bb\u03ac\u03c9 \u03b5\u03bb\u03bb\u03b7\u03bd\u03b9\u03ba\u03ac', pronunciation: 'then mee-LAH-oh eh-lee-nee-KAH'),
      EmergencyPhrase(key: EmergencyPhraseKey.needInterpreter, english: 'I need an interpreter', translated: '\u03a7\u03c1\u03b5\u03b9\u03ac\u03b6\u03bf\u03bc\u03b1\u03b9 \u03b4\u03b9\u03b5\u03c1\u03bc\u03b7\u03bd\u03ad\u03b1', pronunciation: 'hree-AH-zo-meh thee-er-mee-NEH-ah'),
      EmergencyPhrase(key: EmergencyPhraseKey.rightToLawyer, english: 'I have the right to a lawyer', translated: '\u0388\u03c7\u03c9 \u03b4\u03b9\u03ba\u03b1\u03af\u03c9\u03bc\u03b1 \u03c3\u03b5 \u03b4\u03b9\u03ba\u03b7\u03b3\u03cc\u03c1\u03bf', pronunciation: 'EH-ho thee-KEH-oh-mah seh thee-kee-GHO-ro'),
      EmergencyPhrase(key: EmergencyPhraseKey.dontUnderstand, english: "I don't understand", translated: '\u0394\u03b5\u03bd \u03ba\u03b1\u03c4\u03b1\u03bb\u03b1\u03b2\u03b1\u03af\u03bd\u03c9', pronunciation: 'then kah-tah-lah-VEH-no'),
      EmergencyPhrase(key: EmergencyPhraseKey.whereIsHospital, english: 'Where is the hospital?', translated: '\u03a0\u03bf\u03cd \u03b5\u03af\u03bd\u03b1\u03b9 \u03c4\u03bf \u03bd\u03bf\u03c3\u03bf\u03ba\u03bf\u03bc\u03b5\u03af\u03bf;', pronunciation: 'POO EE-neh to no-so-ko-MEE-oh?'),
      EmergencyPhrase(key: EmergencyPhraseKey.victimOfCrime, english: 'I am a victim of a crime', translated: '\u0395\u03af\u03bc\u03b1\u03b9 \u03b8\u03cd\u03bc\u03b1 \u03b5\u03b3\u03ba\u03bb\u03ae\u03bc\u03b1\u03c4\u03bf\u03c2', pronunciation: 'EE-meh THEE-mah eng-KLEE-mah-tos'),
      EmergencyPhrase(key: EmergencyPhraseKey.needPhoneCall, english: 'I need to make a phone call', translated: '\u03a0\u03c1\u03ad\u03c0\u03b5\u03b9 \u03bd\u03b1 \u03ba\u03ac\u03bd\u03c9 \u03ad\u03bd\u03b1 \u03c4\u03b7\u03bb\u03b5\u03c6\u03ce\u03bd\u03b7\u03bc\u03b1', pronunciation: 'PREH-pee nah KAH-no EH-nah tee-leh-FO-nee-mah'),
      EmergencyPhrase(key: EmergencyPhraseKey.whatAreMyRights, english: 'What are my rights?', translated: '\u03a0\u03bf\u03b9\u03b1 \u03b5\u03af\u03bd\u03b1\u03b9 \u03c4\u03b1 \u03b4\u03b9\u03ba\u03b1\u03b9\u03ce\u03bc\u03b1\u03c4\u03ac \u03bc\u03bf\u03c5;', pronunciation: 'PEE-ah EE-neh tah thee-keh-OH-mah-TAH moo?'),
      EmergencyPhrase(key: EmergencyPhraseKey.applyForAsylum, english: 'I want to apply for asylum', translated: '\u0398\u03ad\u03bb\u03c9 \u03bd\u03b1 \u03ba\u03ac\u03bd\u03c9 \u03b1\u03af\u03c4\u03b7\u03c3\u03b7 \u03b3\u03b9\u03b1 \u03ac\u03c3\u03c5\u03bb\u03bf', pronunciation: 'THEH-lo nah KAH-no EH-tee-see yah AH-see-lo'),
      EmergencyPhrase(key: EmergencyPhraseKey.speakSlowly, english: 'Please speak slowly', translated: '\u03a0\u03b1\u03c1\u03b1\u03ba\u03b1\u03bb\u03ce, \u03bc\u03b9\u03bb\u03ae\u03c3\u03c4\u03b5 \u03b1\u03c1\u03b3\u03ac', pronunciation: 'pah-rah-kah-LO, mee-LEE-steh ar-GAH'),
      EmergencyPhrase(key: EmergencyPhraseKey.needFoodWater, english: 'I need food and water', translated: '\u03a7\u03c1\u03b5\u03b9\u03ac\u03b6\u03bf\u03bc\u03b1\u03b9 \u03c6\u03b1\u03b3\u03b7\u03c4\u03cc \u03ba\u03b1\u03b9 \u03bd\u03b5\u03c1\u03cc', pronunciation: 'hree-AH-zo-meh fah-yee-TO keh neh-RO'),
      EmergencyPhrase(key: EmergencyPhraseKey.whereIsEmbassy, english: 'Where is the embassy of [country]?', translated: '\u03a0\u03bf\u03cd \u03b5\u03af\u03bd\u03b1\u03b9 \u03b7 \u03c0\u03c1\u03b5\u03c3\u03b2\u03b5\u03af\u03b1 \u03c4\u03b7\u03c2 [\u03c7\u03ce\u03c1\u03b1\u03c2];', pronunciation: 'POO EE-neh ee pres-VEE-ah tees [HO-ras]?'),
      EmergencyPhrase(key: EmergencyPhraseKey.haveChildren, english: 'I have children with me', translated: '\u0388\u03c7\u03c9 \u03c0\u03b1\u03b9\u03b4\u03b9\u03ac \u03bc\u03b1\u03b6\u03af \u03bc\u03bf\u03c5', pronunciation: 'EH-ho peh-THEE-AH mah-ZEE moo'),
      EmergencyPhrase(key: EmergencyPhraseKey.needMedication, english: 'I need medication', translated: '\u03a7\u03c1\u03b5\u03b9\u03ac\u03b6\u03bf\u03bc\u03b1\u03b9 \u03c6\u03ac\u03c1\u03bc\u03b1\u03ba\u03b1', pronunciation: 'hree-AH-zo-meh FAR-mah-kah'),
      EmergencyPhrase(key: EmergencyPhraseKey.findShelter, english: 'Can you help me find shelter?', translated: '\u039c\u03c0\u03bf\u03c1\u03b5\u03af\u03c4\u03b5 \u03bd\u03b1 \u03bc\u03b5 \u03b2\u03bf\u03b7\u03b8\u03ae\u03c3\u03b5\u03c4\u03b5 \u03bd\u03b1 \u03b2\u03c1\u03c9 \u03ba\u03b1\u03c4\u03b1\u03c6\u03cd\u03b3\u03b9\u03bf;', pronunciation: 'bo-REE-teh nah meh vo-ee-THEE-seh-teh nah vro kah-tah-FEE-yee-oh?'),
      EmergencyPhrase(key: EmergencyPhraseKey.beingThreatened, english: 'I am being threatened', translated: '\u0391\u03c0\u03b5\u03b9\u03bb\u03bf\u03cd\u03bc\u03b1\u03b9', pronunciation: 'ah-pee-LOO-meh'),
      EmergencyPhrase(key: EmergencyPhraseKey.thisIsEmergency, english: 'This is an emergency', translated: '\u0391\u03c5\u03c4\u03cc \u03b5\u03af\u03bd\u03b1\u03b9 \u03ad\u03ba\u03c4\u03b1\u03ba\u03c4\u03b7 \u03b1\u03bd\u03ac\u03b3\u03ba\u03b7', pronunciation: 'af-TO EE-neh EK-tak-tee ah-NANG-kee'),
    ],

    // =====================================================================
    // MALTESE (mt)
    // =====================================================================
    'mt': const [
      EmergencyPhrase(key: EmergencyPhraseKey.needHelp, english: 'I need help', translated: 'G\u0127andi b\u017conn ta\u2019 g\u0127ajnuna'),
      EmergencyPhrase(key: EmergencyPhraseKey.callPolice, english: 'Call the police', translated: '\u010aemplu lill-pulizija'),
      EmergencyPhrase(key: EmergencyPhraseKey.needDoctor, english: 'I need a doctor', translated: 'G\u0127andi b\u017conn ta\u2019 tabib'),
      EmergencyPhrase(key: EmergencyPhraseKey.dontSpeakLanguage, english: "I don't speak [language]", translated: 'Ma nitkellimx bil-Malti'),
      EmergencyPhrase(key: EmergencyPhraseKey.needInterpreter, english: 'I need an interpreter', translated: 'G\u0127andi b\u017conn ta\u2019 interpretu'),
      EmergencyPhrase(key: EmergencyPhraseKey.rightToLawyer, english: 'I have the right to a lawyer', translated: 'G\u0127andi dritt g\u0127al avukat'),
      EmergencyPhrase(key: EmergencyPhraseKey.dontUnderstand, english: "I don't understand", translated: 'Ma nifhimx'),
      EmergencyPhrase(key: EmergencyPhraseKey.whereIsHospital, english: 'Where is the hospital?', translated: 'Fejn hu l-isptar?'),
      EmergencyPhrase(key: EmergencyPhraseKey.victimOfCrime, english: 'I am a victim of a crime', translated: 'Jien vittma ta\u2019 reat'),
      EmergencyPhrase(key: EmergencyPhraseKey.needPhoneCall, english: 'I need to make a phone call', translated: 'Irrid nag\u0127mel telefonata'),
      EmergencyPhrase(key: EmergencyPhraseKey.whatAreMyRights, english: 'What are my rights?', translated: 'X\u2019inhuma d-drittijiet tieg\u0127i?'),
      EmergencyPhrase(key: EmergencyPhraseKey.applyForAsylum, english: 'I want to apply for asylum', translated: 'Irrid napplika g\u0127al a\u017cil'),
      EmergencyPhrase(key: EmergencyPhraseKey.speakSlowly, english: 'Please speak slowly', translated: 'Jekk jog\u0127\u0121bok, tkellem bil-mod'),
      EmergencyPhrase(key: EmergencyPhraseKey.needFoodWater, english: 'I need food and water', translated: 'G\u0127andi b\u017conn ta\u2019 ikel u ilma'),
      EmergencyPhrase(key: EmergencyPhraseKey.whereIsEmbassy, english: 'Where is the embassy of [country]?', translated: 'Fejn hi l-ambaxxata ta\u2019 [pajji\u017c]?'),
      EmergencyPhrase(key: EmergencyPhraseKey.haveChildren, english: 'I have children with me', translated: 'G\u0127andi tfal mieg\u0127i'),
      EmergencyPhrase(key: EmergencyPhraseKey.needMedication, english: 'I need medication', translated: 'G\u0127andi b\u017conn ta\u2019 medi\u010bina'),
      EmergencyPhrase(key: EmergencyPhraseKey.findShelter, english: 'Can you help me find shelter?', translated: 'Tista\u2019 tg\u0127inni nsib kenn?'),
      EmergencyPhrase(key: EmergencyPhraseKey.beingThreatened, english: 'I am being threatened', translated: 'Qed ji\u0121i mhedded'),
      EmergencyPhrase(key: EmergencyPhraseKey.thisIsEmergency, english: 'This is an emergency', translated: 'Din hija emer\u0121enza'),
    ],

    // =====================================================================
    // IRISH (ga)
    // =====================================================================
    'ga': const [
      EmergencyPhrase(key: EmergencyPhraseKey.needHelp, english: 'I need help', translated: 'T\u00e1 c\u00fanamh de dh\u00edth orm'),
      EmergencyPhrase(key: EmergencyPhraseKey.callPolice, english: 'Call the police', translated: 'Cuir gl\u00e1o ar na garda\u00ed'),
      EmergencyPhrase(key: EmergencyPhraseKey.needDoctor, english: 'I need a doctor', translated: 'T\u00e1 dochtúir de dh\u00edth orm'),
      EmergencyPhrase(key: EmergencyPhraseKey.dontSpeakLanguage, english: "I don't speak [language]", translated: 'N\u00ed labhraim Gaeilge'),
      EmergencyPhrase(key: EmergencyPhraseKey.needInterpreter, english: 'I need an interpreter', translated: 'T\u00e1 ateangaire de dh\u00edth orm'),
      EmergencyPhrase(key: EmergencyPhraseKey.rightToLawyer, english: 'I have the right to a lawyer', translated: 'T\u00e1 ceart agam ar dhl\u00edod\u00f3ir'),
      EmergencyPhrase(key: EmergencyPhraseKey.dontUnderstand, english: "I don't understand", translated: 'N\u00ed thuigim'),
      EmergencyPhrase(key: EmergencyPhraseKey.whereIsHospital, english: 'Where is the hospital?', translated: 'C\u00e1 bhfuil an t-ospid\u00e9al?'),
      EmergencyPhrase(key: EmergencyPhraseKey.victimOfCrime, english: 'I am a victim of a crime', translated: 'Is \u00edospartach coire m\u00e9'),
      EmergencyPhrase(key: EmergencyPhraseKey.needPhoneCall, english: 'I need to make a phone call', translated: 'Caithfidh m\u00e9 gl\u00e1o gut\u00e1in a dh\u00e9anamh'),
      EmergencyPhrase(key: EmergencyPhraseKey.whatAreMyRights, english: 'What are my rights?', translated: 'C\u00e9ard iad mo chearta?'),
      EmergencyPhrase(key: EmergencyPhraseKey.applyForAsylum, english: 'I want to apply for asylum', translated: 'Ba mhaith liom iarratas a dh\u00e9anamh ar thearmann'),
      EmergencyPhrase(key: EmergencyPhraseKey.speakSlowly, english: 'Please speak slowly', translated: 'Labhair go mall, le do thoil'),
      EmergencyPhrase(key: EmergencyPhraseKey.needFoodWater, english: 'I need food and water', translated: 'T\u00e1 bia agus uisce de dh\u00edth orm'),
      EmergencyPhrase(key: EmergencyPhraseKey.whereIsEmbassy, english: 'Where is the embassy of [country]?', translated: 'C\u00e1 bhfuil ambasáid [t\u00edr]?'),
      EmergencyPhrase(key: EmergencyPhraseKey.haveChildren, english: 'I have children with me', translated: 'T\u00e1 p\u00e1ist\u00ed liom'),
      EmergencyPhrase(key: EmergencyPhraseKey.needMedication, english: 'I need medication', translated: 'T\u00e1 c\u00f3gas de dh\u00edth orm'),
      EmergencyPhrase(key: EmergencyPhraseKey.findShelter, english: 'Can you help me find shelter?', translated: 'An f\u00e9idir leat cabhr\u00fa liom d\u00edde\u00e1n a aimsi\u00fa?'),
      EmergencyPhrase(key: EmergencyPhraseKey.beingThreatened, english: 'I am being threatened', translated: 'T\u00e1 bagairt \u00e1 d\u00e9anamh orm'),
      EmergencyPhrase(key: EmergencyPhraseKey.thisIsEmergency, english: 'This is an emergency', translated: '\u00c9igeand\u00e1il at\u00e1 ann'),
    ],
  };

  // -----------------------------------------------------------------------
  // Pronunciation guide reference
  // -----------------------------------------------------------------------

  /// General pronunciation tips for difficult languages.
  static const Map<String, List<String>> pronunciationGuide = {
    'fi': [
      'Finnish vowels: a = "ah", e = "eh", i = "ee", o = "oh", u = "oo", y = "uu" (like French u), \u00e4 = "aa" (like "cat"), \u00f6 = "uh" (like German \u00f6)',
      'Double letters (aa, ii, kk, tt) are always pronounced longer/stronger',
      'Stress is ALWAYS on the first syllable',
      'J is pronounced like English Y',
      'R is always rolled/trilled',
      'H is always pronounced, even between vowels',
    ],
    'hu': [
      'Hungarian vowels: a = "oh", \u00e1 = "ah", e = "eh", \u00e9 = "ay", i = "ee", \u00ed = long "ee", o = "oh", \u00f3 = long "oh", u = "oo", \u00fa = long "oo"',
      '\u00f6 = "uh" (like German), \u0151 = long "uh", \u00fc = "uu" (like French u), \u0171 = long "uu"',
      'S = "sh", SZ = "s", ZS = "zh", CS = "ch", GY = "dy", LY = "y", NY = "ny", TY = "ty"',
      'Stress is ALWAYS on the first syllable',
      'Every letter is pronounced; no silent letters',
    ],
    'el': [
      'Greek vowels: \u03b1 = "ah", \u03b5 = "eh", \u03b7 = "ee", \u03b9 = "ee", \u03bf = "oh", \u03c5 = "ee", \u03c9 = "oh"',
      '\u03b4 (delta) = "th" as in "the" (voiced)',
      '\u03b8 (theta) = "th" as in "think" (unvoiced)',
      '\u03b3 (gamma) before \u03b5/\u03b9 = "y", otherwise = soft "gh"',
      '\u03c7 (chi) = "h" or "kh" (guttural)',
      '\u03bc\u03c0 = "b", \u03bd\u03c4 = "d" or "nd", \u03b3\u03ba = "g" or "ng"',
      'Stress mark (\u0384) indicates the emphasized syllable',
    ],
  };
}
