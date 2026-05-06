// =====================================================================
// IntakeGreetingService — generates the assistant's first chat message
// after the user finishes the structured-intake wizard (Pkg 3).
//
// Flow:
//   1. Caller passes the freshly-created `UserCase`, the wizard draft,
//      and (optionally) a list of uploaded document filenames /
//      summaries.
//   2. We build a one-shot prompt: "Here is the case file. Write a
//      2-3 sentence greeting in {language} that demonstrates you
//      understand the case, names the most-pressing risk, and
//      proposes a next step."
//   3. Sonnet generates the greeting. We persist it as the first
//      assistant message of the case's chat thread.
//   4. On error / timeout, we fall back to a deterministic template
//      per (case_type, language) so the chat is never empty.
//
// The service is pure logic — it takes typed dependencies (a chat-send
// callback and a chat-message-saver callback) so it's trivially
// testable without the full ClaudeService stack.
// =====================================================================

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/claude_service.dart';
import '../../../services/supabase_service.dart';
import '../models/user_case.dart';
import '../state/intake_wizard_state.dart';

/// Maximum time we wait for Sonnet before falling back to the template.
/// 8 s is a reasonable upper bound (5 s SLA + 3 s slack); the wizard
/// host UI shows a "Готовлю ваше дело…" loader during this window.
const kIntakeGreetingTimeout = Duration(seconds: 8);

/// Function shape for "ask Claude one question, get one string back".
/// Tests inject a stub; production binds to [ClaudeService.sendMessage].
typedef GreetSendFn = Future<String> Function({
  required List<Map<String, String>> messages,
  required String systemPrompt,
  int maxTokens,
  String? model,
});

/// Function shape for persisting the greeting as the first assistant
/// chat message of the case. Tests record calls; production binds to
/// [SupabaseService.saveChatMessage].
typedef GreetSaveFn = Future<void> Function({
  required String caseId,
  required String role,
  required String content,
});

/// Result of [generateGreeting] — exposes whether the AI path was used
/// or whether we fell back. Useful for analytics / debugging.
class IntakeGreetingResult {
  const IntakeGreetingResult({
    required this.greeting,
    required this.usedFallback,
  });

  final String greeting;
  final bool usedFallback;
}

class IntakeGreetingService {
  IntakeGreetingService({
    required GreetSendFn send,
    required GreetSaveFn save,
    Duration timeout = kIntakeGreetingTimeout,
  })  : _send = send,
        _save = save,
        _timeout = timeout;

  final GreetSendFn _send;
  final GreetSaveFn _save;
  final Duration _timeout;

  /// Builds the prompt sent to Sonnet. Public for testability.
  ({String systemPrompt, String userMessage}) buildPrompt({
    required UserCase userCase,
    required IntakeDraft draft,
    List<String> uploadedFilenames = const [],
    List<String> documentSummaries = const [],
  }) {
    final lang = userCase.language;
    final urgent = draft.urgentShortcutTaken;
    final systemPrompt = '''
You are Advocat, a legal-defense assistant. The user just finished a
structured intake wizard. Write the FIRST assistant message they will
see when the chat opens.

CRITICAL CONSTRAINTS:
1. Write in language code "$lang" — native level, formal register
   (Вы / teie / Sie / vous / Te). No emoji. No greeting fluff like
   "Hello, I'm Advocat" — they already know.
2. Keep it 2–3 sentences, max ~60 words.
3. Demonstrate understanding: name the case type, jurisdiction, the
   key authority, OR (if available) one concrete fact from the
   document summaries.
4. Name the single most-pressing risk or unknown.
5. Propose ONE concrete next step the user can take in this chat.
6. ${urgent ? 'The user marked this URGENT and skipped most fields. Acknowledge time pressure first; ask the user to state the question; promise to fill in details as the conversation proceeds.' : 'Be calm and direct.'}

Output: just the greeting text, no JSON, no markdown.
''';

    final caseSummary = StringBuffer()
      ..writeln('=== CASE FILE ===')
      ..writeln('Title: ${userCase.title}')
      ..writeln('Jurisdiction: ${userCase.jurisdiction}')
      ..writeln('Case type: ${userCase.caseType ?? "unspecified"}')
      ..writeln('User language: $lang');

    if (draft.authorityType != null) {
      caseSummary.writeln('Authority: ${draft.authorityType!.dbValue}'
          '${draft.authorityName.isNotEmpty ? " (${draft.authorityName})" : ""}');
    }
    if (draft.userRole != null) {
      caseSummary.writeln('User role: ${draft.userRole!.dbValue}');
    }
    if (draft.opposingSide.isNotEmpty) {
      caseSummary.writeln('Opposing side: ${draft.opposingSide}');
    }
    if (draft.witnesses.isNotEmpty) {
      caseSummary.writeln('Witnesses: ${draft.witnesses.join(", ")}');
    }
    if (draft.caseNumber.isNotEmpty) {
      caseSummary.writeln('Case number: ${draft.caseNumber}');
    }
    if (draft.incidentDate != null) {
      final d = draft.incidentDate!;
      caseSummary.writeln('Incident date: '
          '${d.year.toString().padLeft(4, '0')}-'
          '${d.month.toString().padLeft(2, '0')}-'
          '${d.day.toString().padLeft(2, '0')}');
    }
    if (draft.deadlines.isNotEmpty) {
      caseSummary.writeln('Known deadlines:');
      for (final dl in draft.deadlines) {
        if (dl.what.isEmpty && dl.date == null) continue;
        final dStr = dl.date == null
            ? 'unspecified'
            : '${dl.date!.year.toString().padLeft(4, '0')}-'
                '${dl.date!.month.toString().padLeft(2, '0')}-'
                '${dl.date!.day.toString().padLeft(2, '0')}';
        caseSummary.writeln('  - ${dl.what.isEmpty ? "deadline" : dl.what}'
            ' (by $dStr)');
      }
    }
    if (uploadedFilenames.isNotEmpty) {
      caseSummary.writeln('Uploaded documents: ${uploadedFilenames.join(", ")}');
    }
    if (documentSummaries.isNotEmpty) {
      caseSummary.writeln('Document summaries:');
      for (final s in documentSummaries) {
        caseSummary.writeln('  - $s');
      }
    }
    if (draft.urgentShortcutTaken) {
      caseSummary.writeln('NOTE: User invoked the URGENT shortcut — most '
          'fields are empty.');
    }

    return (
      systemPrompt: systemPrompt,
      userMessage: caseSummary.toString(),
    );
  }

  /// Generates the greeting and persists it as the first assistant
  /// chat message for [userCase]. Never throws — on any failure the
  /// fallback template is used instead.
  Future<IntakeGreetingResult> generateAndPersist({
    required UserCase userCase,
    required IntakeDraft draft,
    List<String> uploadedFilenames = const [],
    List<String> documentSummaries = const [],
  }) async {
    final prompt = buildPrompt(
      userCase: userCase,
      draft: draft,
      uploadedFilenames: uploadedFilenames,
      documentSummaries: documentSummaries,
    );

    String greeting = '';
    bool usedFallback = false;

    try {
      greeting = await _send(
        messages: [
          {'role': 'user', 'content': prompt.userMessage},
        ],
        systemPrompt: prompt.systemPrompt,
        maxTokens: 400,
        model: ClaudeService.modelSonnet,
      ).timeout(_timeout);
      greeting = greeting.trim();
      if (greeting.isEmpty) {
        usedFallback = true;
        greeting = fallbackGreeting(
          caseType: userCase.caseType,
          language: userCase.language,
          urgent: draft.urgentShortcutTaken,
        );
      }
    } catch (_) {
      usedFallback = true;
      greeting = fallbackGreeting(
        caseType: userCase.caseType,
        language: userCase.language,
        urgent: draft.urgentShortcutTaken,
      );
    }

    // Best-effort persist — if the chat-message insert fails the chat
    // screen falls back to "no history yet" rather than crashing.
    try {
      await _save(
        caseId: userCase.id,
        role: 'assistant',
        content: greeting,
      );
    } catch (_) {/* swallow */}

    return IntakeGreetingResult(greeting: greeting, usedFallback: usedFallback);
  }

  /// Deterministic fallback. Keys mirror the canonical case-type
  /// taxonomy, with a default for unknown types. Languages: ru, en,
  /// et, fi (and Ukrainian uk). Other languages fall back to English.
  static String fallbackGreeting({
    required String? caseType,
    required String language,
    required bool urgent,
  }) {
    if (urgent) {
      switch (language) {
        case 'ru':
          return 'Я вижу, что вам нужно срочно. Спросите вопрос — '
              'по ходу разговора заполню досье и предложу шаги.';
        case 'et':
          return 'Ma näen, et see on kiireloomuline. Esita oma küsimus — '
              'täidan toimiku jutu käigus ja pakun samme.';
        case 'fi':
          return 'Näen, että asia on kiireellinen. Kysy kysymyksesi — '
              'täydennän tietoja keskustelun edetessä ja ehdotan seuraavia '
              'askeleita.';
        case 'uk':
          return 'Бачу, що це терміново. Запитайте — заповню деталі по '
              'ходу розмови та запропоную кроки.';
        default:
          return "I see this is urgent. Ask your question — I'll fill in "
              "the rest of the file as we talk.";
      }
    }

    final t = caseType ?? 'other';
    switch (language) {
      case 'ru':
        return _ruFallback(t);
      case 'et':
        return _etFallback(t);
      case 'fi':
        return _fiFallback(t);
      case 'uk':
        return _ukFallback(t);
      default:
        return _enFallback(t);
    }
  }

  static String _ruFallback(String t) {
    switch (t) {
      case 'criminal':
        return 'Я вижу ваше уголовное дело. Главный риск сейчас — '
            'упустить процессуальные сроки. Расскажите коротко, что '
            'произошло — начнём с этого.';
      case 'civil':
        return 'Я вижу ваше гражданское дело. С чего удобнее начать — '
            'описать суть спора или загрузить переписку и документы?';
      case 'family':
        return 'Я вижу ваше семейное дело. Часто здесь главное — '
            'защитить интересы детей и не пропустить сроки. С чего '
            'начнём?';
      case 'admin':
        return 'Я вижу ваше административное дело. Скажите, какое '
            'решение получили и есть ли срок на обжалование — это '
            'обычно важнее всего.';
      case 'immigration':
        return 'Я вижу ваше миграционное дело. Чаще всего ключевой '
            'риск — пропустить срок апелляции. Какой документ на руках '
            'и до какой даты нужно реагировать?';
      case 'labor':
        return 'Я вижу ваш трудовой спор. Расскажите, кто работодатель '
            'и есть ли уже письменное решение — это определит наши '
            'дальнейшие шаги.';
      case 'consumer':
        return 'Я вижу ваше потребительское дело. С чего начнём — '
            'опишем продавца и проблему или сразу составим претензию?';
      case 'inheritance':
        return 'Я вижу наследственное дело. Главный риск обычно — '
            'упустить сроки принятия наследства. Расскажите, кто умер '
            'и какие документы у вас на руках.';
      default:
        return 'Я вижу ваше дело. Скажите, что сейчас острее всего — '
            'разберёмся вместе.';
    }
  }

  static String _enFallback(String t) {
    switch (t) {
      case 'criminal':
        return 'I see your criminal case. The main risk right now is '
            'missing a procedural deadline. Tell me briefly what '
            "happened — we'll start there.";
      case 'civil':
        return "I see your civil case. Easier to start by describing "
            "the dispute, or do you want to upload correspondence first?";
      case 'family':
        return "I see your family case. Most often the priority is "
            "protecting children's interests and meeting deadlines. "
            "Where do we begin?";
      case 'admin':
        return "I see your administrative case. Tell me what decision "
            "you received and whether there's an appeal deadline — "
            "that's usually the most important thing.";
      case 'immigration':
        return "I see your immigration case. The key risk is usually "
            "missing the appeal deadline. What document do you have "
            "and by when must you respond?";
      case 'labor':
        return "I see your labor dispute. Tell me who the employer is "
            "and whether you have a written decision — that drives "
            "what we do next.";
      case 'consumer':
        return "I see your consumer case. Shall we describe the seller "
            "and the issue, or draft a complaint right away?";
      case 'inheritance':
        return "I see your inheritance case. The usual risk is missing "
            "the deadline to accept the estate. Tell me who passed "
            "away and what documents you have.";
      default:
        return "I see your case. Tell me what's most pressing right "
            "now — we'll work through it together.";
    }
  }

  static String _etFallback(String t) {
    switch (t) {
      case 'criminal':
        return 'Ma näen sinu kriminaalasja. Suurim risk praegu on '
            'menetlustähtaja unustamine. Räägi lühidalt, mis juhtus '
            '— alustame sealt.';
      case 'civil':
        return 'Ma näen sinu tsiviilasja. Kas alustame vaidluse sisu '
            'kirjeldamisest või laadid kõigepealt üles dokumendid?';
      case 'family':
        return 'Ma näen sinu perekonnaasja. Kõige tähtsam on tavaliselt '
            'laste huvide kaitse ja tähtaegade järgimine. Kust alustame?';
      case 'admin':
        return 'Ma näen sinu haldusasja. Ütle, milline otsus saadi ja '
            'kas on vaidlustamise tähtaeg — see on tavaliselt kõige '
            'olulisem.';
      case 'immigration':
        return 'Ma näen sinu rändeasja. Põhirisk on tavaliselt '
            'apellatsioonitähtaja möödalaskmine. Mis dokument on käes '
            'ja mis kuupäevaks tuleb reageerida?';
      case 'labor':
        return 'Ma näen sinu töövaidlust. Ütle, kes on tööandja ja kas '
            'on kirjalik otsus — sellest sõltuvad järgmised sammud.';
      case 'consumer':
        return 'Ma näen sinu tarbijaasja. Kas alustame müüja ja '
            'probleemi kirjeldamisest või koostame kohe pretensiooni?';
      case 'inheritance':
        return 'Ma näen sinu pärimisasja. Tavaline risk on pärandi '
            'vastuvõtmise tähtaja möödalaskmine. Räägi, kes lahkus ja '
            'mis dokumendid sul on.';
      default:
        return 'Ma näen sinu juhtumit. Ütle, mis on praegu kõige '
            'kiirem — vaatame koos läbi.';
    }
  }

  static String _fiFallback(String t) {
    switch (t) {
      case 'criminal':
        return 'Näen rikosasiasi. Suurin riski on nyt menettelyajan '
            'umpeutuminen. Kerro lyhyesti mitä tapahtui — aloitetaan '
            'siitä.';
      case 'civil':
        return 'Näen siviiliasiasi. Aloitetaanko riidan kuvaamisesta '
            'vai lataatko ensin asiakirjat?';
      case 'family':
        return 'Näen perheasiasi. Tärkeintä on yleensä lasten edun '
            'turvaaminen ja määräaikojen noudattaminen. Mistä aloitamme?';
      case 'admin':
        return 'Näen hallintoasiasi. Kerro, minkä päätöksen sait ja '
            'onko valitusaikaa — se on yleensä tärkeintä.';
      case 'immigration':
        return 'Näen maahanmuuttoasiasi. Suurin riski on yleensä '
            'valitusajan umpeutuminen. Mikä asiakirja sinulla on ja '
            'mihin mennessä on toimittava?';
      case 'labor':
        return 'Näen työasiasi. Kerro, kuka työnantaja on ja onko '
            'kirjallinen päätös — se määrittää seuraavat askeleet.';
      case 'consumer':
        return 'Näen kuluttaja-asiasi. Aloitetaanko myyjän ja ongelman '
            'kuvaamisesta vai laaditaanko heti reklamaatio?';
      case 'inheritance':
        return 'Näen perintöasiasi. Tavallinen riski on perinnön '
            'vastaanottamisen määräajan umpeutuminen. Kerro, kuka '
            'kuoli ja mitä asiakirjoja sinulla on.';
      default:
        return 'Näen asiasi. Kerro, mikä on kiireellisintä — käymme '
            'sen yhdessä läpi.';
    }
  }

  static String _ukFallback(String t) {
    switch (t) {
      case 'criminal':
        return 'Бачу вашу кримінальну справу. Головний ризик зараз — '
            'пропустити процесуальний строк. Розкажіть коротко, що '
            'сталося — почнемо з цього.';
      case 'immigration':
        return 'Бачу вашу міграційну справу. Часто головний ризик — '
            'пропустити строк апеляції. Який документ на руках і до '
            'якої дати потрібно реагувати?';
      default:
        return 'Бачу вашу справу. Скажіть, що зараз найгостріше — '
            'розберемося разом.';
    }
  }
}

/// Provider — resolves to a service wired against ClaudeService and
/// SupabaseService. Tests override this with a fake.
final intakeGreetingServiceProvider = Provider<IntakeGreetingService>((ref) {
  final claude = ref.watch(claudeServiceProvider);
  final supa = ref.watch(supabaseServiceProvider);
  return IntakeGreetingService(
    send: ({
      required messages,
      required systemPrompt,
      int maxTokens = 400,
      String? model,
    }) =>
        claude.sendMessage(
      messages: messages,
      systemPrompt: systemPrompt,
      maxTokens: maxTokens,
      model: model,
    ),
    save: ({
      required caseId,
      required role,
      required content,
    }) =>
        supa.saveChatMessage(
      caseId: caseId,
      role: role,
      content: content,
    ),
  );
});
