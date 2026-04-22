// ingest_estonian_laws.dart
//
// Rebuild Estonian legal corpus from Riigi Teataja (https://www.riigiteataja.ee).
//
// WHY this script exists:
//   The prior corpus in assets/legal/estonia/*.json was produced by a parser
//   that cut HTML by chapter headings instead of by § anchors. Result: 59%
//   of 10319 sections had body text from neighbouring chapter titles rather
//   than actual legal content. See docs/corpus-fix/00-diagnose.md.
//
// WHAT this script does:
//   - Downloads full consolidated text of each act from /akt/{ACT}.
//   - Parses the RT anchor-based HTML structure:
//       <h3><strong>§ N. </strong><a name="paraN"></a>TITLE</h3>
//       <p><a name="paraNlgM"></a>(M) BODY</p>
//   - Emits assets/legal/estonia/{act}.json with {paragraph, title, body,
//     subsections, redaction_refs}.
//
// USAGE:
//   dart run scripts/ingest_estonian_laws.dart              # all 20 acts
//   dart run scripts/ingest_estonian_laws.dart --act VMS    # one act
//   dart run scripts/ingest_estonian_laws.dart --dry-run    # no file writes
//
// RATE LIMIT: 2 seconds between requests (respectful — RT runs on modest
// infrastructure and is a state service).

import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// The 20 acts to ingest.
///
/// Each entry specifies:
///   - [serviceCode]: the code used inside `EstonianLawSearch.knownActs`
///     and stored as the "act" field inside the JSON asset,
///   - [rtCode]: the path segment on riigiteataja.ee (sometimes differs
///     from the service code: e.g. RT uses "AÕS" but the service uses
///     "AsjS" for historical reasons),
///   - [fileStem]: the base name of the JSON in assets/legal/estonia/.
class _ActSpec {
  final String serviceCode;
  final String rtCode;
  final String fileStem;
  const _ActSpec(this.serviceCode, this.rtCode, this.fileStem);
}

const List<_ActSpec> _acts = [
  _ActSpec('HMS', 'HMS', 'hms'),
  _ActSpec('HKMS', 'HKMS', 'hkms'),
  _ActSpec('PKS', 'PKS', 'pks'),
  _ActSpec('TLS', 'TLS', 'tls'),
  _ActSpec('KarS', 'KarS', 'kars'),
  _ActSpec('VMS', 'VMS', 'vms'),
  _ActSpec('VÕS', 'VÕS', 'vos'),
  _ActSpec('PärS', 'PärS', 'pars'),
  _ActSpec('VõrdKS', 'VõrdKS', 'vordks'),
  _ActSpec('MKS', 'MKS', 'mks'),
  _ActSpec('TuMS', 'TuMS', 'tums'),
  _ActSpec('KMS', 'KMS', 'kms'),
  _ActSpec('TsMS', 'TsMS', 'tsms'),
  _ActSpec('KrMS', 'KrMS', 'krms'),
  _ActSpec('ÄS', 'ÄS', 'as'),
  _ActSpec('IKS', 'IKS', 'iks'),
  _ActSpec('LS', 'LS', 'ls'),
  _ActSpec('LKindlS', 'LKindlS', 'lkindls'),
  _ActSpec('TsÜS', 'TsÜS', 'tsus'),
  // Service code "AsjS" but RT URL path is "AÕS".
  _ActSpec('AsjS', 'AÕS', 'asjs'),
];

const String _userAgent =
    'AdvocatCorpusIngester/1.0 (legal-aid nonprofit; contact: legal@advocat.ee)';
const Duration _rateLimit = Duration(seconds: 2);

Future<void> main(List<String> argv) async {
  final args = _parseArgs(argv);
  final outDir = Directory(args.outputDir);
  if (!args.dryRun && !outDir.existsSync()) {
    outDir.createSync(recursive: true);
  }

  final targets = args.single == null
      ? List<_ActSpec>.from(_acts)
      : _acts.where((a) => a.serviceCode == args.single).toList();

  if (targets.isEmpty) {
    stderr.writeln(
      'ERROR: --act "${args.single}" not in known list: '
      '${_acts.map((a) => a.serviceCode).join(", ")}',
    );
    exit(2);
  }

  final report = <_ActReport>[];
  final client = HttpClient()..userAgent = _userAgent;

  try {
    for (var i = 0; i < targets.length; i++) {
      final spec = targets[i];
      final code = spec.serviceCode;
      final stem = spec.fileStem;

      stdout.writeln('[${i + 1}/${targets.length}] Fetching $code '
          '(RT: ${spec.rtCode}) …');
      try {
        final fetched = await _fetchAct(client, spec.rtCode);
        final parsed = _parseAct(code, fetched.html, fetched.url);
        final healthy = parsed.sections.where(_isHealthy).length;
        stdout.writeln(
          '  parsed ${parsed.sections.length} § '
          '($healthy healthy, ${parsed.sections.length - healthy} empty/repealed) '
          '— ${fetched.bytes} bytes',
        );

        if (!args.dryRun) {
          final outFile = File('${args.outputDir}/$stem.json');
          outFile.writeAsStringSync(_encode(parsed));
          stdout.writeln('  wrote ${outFile.path}');
        }

        report.add(_ActReport(
          code: code,
          stem: stem,
          total: parsed.sections.length,
          healthy: healthy,
          bytes: fetched.bytes,
          error: null,
        ));
      } catch (e, st) {
        stderr.writeln('  FAILED: $e');
        stderr.writeln(st.toString().split('\n').take(3).join('\n'));
        report.add(_ActReport(
          code: code,
          stem: stem,
          total: 0,
          healthy: 0,
          bytes: 0,
          error: e.toString(),
        ));
      }

      if (i < targets.length - 1) {
        await Future<void>.delayed(_rateLimit);
      }
    }
  } finally {
    client.close();
  }

  _printReport(report);
  final failures = report.where((r) => r.error != null).length;
  if (failures > 0) {
    exit(1);
  }
}

// ---------------------------------------------------------------------------
// Fetching
// ---------------------------------------------------------------------------

class _Fetched {
  final String html;
  final String url;
  final int bytes;
  _Fetched(this.html, this.url, this.bytes);
}

Future<_Fetched> _fetchAct(HttpClient client, String code) async {
  final url = 'https://www.riigiteataja.ee/akt/$code';
  final uri = Uri.parse(url);
  const maxAttempts = 3;

  for (var attempt = 1; attempt <= maxAttempts; attempt++) {
    try {
      final req = await client.getUrl(uri);
      req.headers.set(HttpHeaders.acceptLanguageHeader, 'et,en;q=0.5');
      final resp = await req.close();
      if (resp.statusCode != 200) {
        throw HttpException('status ${resp.statusCode}', uri: uri);
      }
      final body = await resp.transform(utf8.decoder).join();
      return _Fetched(body, url, body.length);
    } catch (e) {
      if (attempt == maxAttempts) rethrow;
      stderr.writeln('  retry $attempt/$maxAttempts after error: $e');
      await Future<void>.delayed(Duration(seconds: attempt * 2));
    }
  }
  throw StateError('unreachable');
}

// ---------------------------------------------------------------------------
// Parsing
// ---------------------------------------------------------------------------

class _ParsedAct {
  final String code;
  final String name;
  final String source;
  final String fetchedAt;
  final String? redactionId;
  final String? redactionDate;
  final List<_Section> sections;

  _ParsedAct({
    required this.code,
    required this.name,
    required this.source,
    required this.fetchedAt,
    required this.redactionId,
    required this.redactionDate,
    required this.sections,
  });
}

class _Section {
  final String paragraph;
  final String title;
  final String? body;
  final List<_Subsection> subsections;
  final List<String> redactionRefs;
  final bool repealed;
  final String? parseError;

  _Section({
    required this.paragraph,
    required this.title,
    required this.body,
    required this.subsections,
    required this.redactionRefs,
    required this.repealed,
    required this.parseError,
  });
}

class _Subsection {
  final String number; // "1", "2", ...
  final String text;
  _Subsection(this.number, this.text);
}

_ParsedAct _parseAct(String code, String html, String source) {
  // Act title from <title>X – Riigi Teataja</title>
  final titleMatch = RegExp(
    r'<title>([^<]+?)[\u2013\u2014\-]Riigi\s+Teataja</title>',
    caseSensitive: false,
  ).firstMatch(html);
  final actName = titleMatch?.group(1)?.trim() ?? code;

  // Redaction ID from canonical /akt/{id} or /akt_seosed.html?id={id}
  final redIdMatch = RegExp(r'akt_seosed\.html\?id=(\d{10,})').firstMatch(html);
  final redactionId = redIdMatch?.group(1);

  // Redaction effective date — look for "Kehtib alates: dd.mm.yyyy" or similar.
  final redDateMatch = RegExp(
    r'(?:Kehtib alates|Avaldamismärge)[^0-9]*(\d{2}\.\d{2}\.\d{4})',
  ).firstMatch(html);
  final redactionDate = redDateMatch?.group(1);

  // Section heading pattern:
  //   <h3><strong>§ N[<sup>K</sup>]. </strong><a name="paraN[bK]"> </a>TITLE</h3>
  //
  // Capture groups:
  //   1 = raw display of § number (possibly containing <sup>...</sup>)
  //   2 = anchor name (paraN or paraNbK) — canonical machine id
  //   3 = title text (nonβgreedy, until </h3>)
  final headingRe = RegExp(
    r'<h3[^>]*>\s*<strong>\s*§\s+(.*?)\.\s*</strong>\s*<a\s+name="(para[0-9a-z]+)"[^>]*>\s*</a>\s*(.*?)</h3>',
    caseSensitive: false,
    dotAll: true,
  );

  final headings = headingRe.allMatches(html).toList();
  final sections = <_Section>[];

  for (var i = 0; i < headings.length; i++) {
    final m = headings[i];
    final numRaw = m.group(1)!;
    final anchorName = m.group(2)!;
    final titleRaw = m.group(3) ?? '';

    // Convert <sup>K</sup> to ^K for a readable § number (e.g. "§ 31^1").
    final numDisplay = numRaw
        .replaceAllMapped(
          RegExp(r'<sup>([^<]*)</sup>', caseSensitive: false),
          (m) => '^${m.group(1)}',
        )
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .trim();
    final paragraph = '§ $numDisplay';
    final title = _normalizeWhitespace(_stripHtmlTags(titleRaw));

    // Slice from end of this heading to start of next heading (or EOF).
    final sliceStart = m.end;
    final sliceEnd =
        i + 1 < headings.length ? headings[i + 1].start : html.length;
    final slice = html.substring(sliceStart, sliceEnd);

    final parsed = _parseSectionSlice(anchorName, slice);
    // If the title itself carries "[Kehtetu ...]" it means the entire
    // heading was repealed; mark accordingly even if body is null.
    final repealedInTitle =
        RegExp(r'\[Kehtetu', caseSensitive: false).hasMatch(title);
    sections.add(parsed.copyWith(
      paragraph: paragraph,
      title: title,
      repealed: parsed.repealed || repealedInTitle,
    ));
  }

  return _ParsedAct(
    code: code,
    name: actName,
    source: source,
    fetchedAt: DateTime.now().toUtc().toIso8601String(),
    redactionId: redactionId,
    redactionDate: redactionDate,
    sections: sections,
  );
}

extension _SectionCopy on _Section {
  _Section copyWith({String? paragraph, String? title, bool? repealed}) =>
      _Section(
        paragraph: paragraph ?? this.paragraph,
        title: title ?? this.title,
        body: body,
        subsections: subsections,
        redactionRefs: redactionRefs,
        repealed: repealed ?? this.repealed,
        parseError: parseError,
      );
}

/// Parse the slice of HTML belonging to one § (between its <h3> and the
/// next <h3>). Extracts lõige-style subsections and redaction refs.
_Section _parseSectionSlice(String anchorName, String slice) {
  // Subsection anchor pattern:
  //   <p><a name="paraNlgM"> </a>(M) BODY<br/>...</p>
  // The `(M)` prefix is visible text; we capture the anchor name and
  // the paragraph body up to the next subsection anchor or heading.
  final esc = _reEsc(anchorName);
  final subRe = RegExp(
    '<a\\s+name="(${esc}lg[0-9]+)"[^>]*>\\s*</a>\\s*(.*?)(?=<a\\s+name="${esc}lg[0-9]+"|<h[1-6]|\$)',
    caseSensitive: false,
    dotAll: true,
  );

  final subs = <_Subsection>[];
  for (final m in subRe.allMatches(slice)) {
    final name = m.group(1)!; // paraNlgM
    final raw = m.group(2) ?? '';
    final cleaned = _cleanSubsectionText(raw);
    if (cleaned.isEmpty) continue;
    final numMatch = RegExp(r'lg([0-9]+)').firstMatch(name);
    final num = numMatch?.group(1) ?? '?';
    subs.add(_Subsection(num, cleaned));
  }

  // Redaction references: <span class="mm">[<a ...>RT I, ...</a> - jõust. ...]</span>
  final redRefs = RegExp(
    r'<span\s+class="mm">\[([^\]]+)\]\s*</span>',
    caseSensitive: false,
    dotAll: true,
  )
      .allMatches(slice)
      .map((m) => _normalizeWhitespace(_stripHtmlTags(m.group(1) ?? '')))
      .where((s) => s.isNotEmpty)
      .toList();

  // Body = concatenation of all subsection texts joined by newlines.
  // Each subsection.text already starts with its own "(N)" marker as rendered
  // by RT, so we don't prepend it again. If the § has no lõige anchors
  // (single-sentence §), fall back to cleaning the whole slice.
  String? body;
  if (subs.isNotEmpty) {
    body = subs.map((s) => s.text).join('\n');
  } else {
    final fallback = _cleanSubsectionText(slice);
    body = fallback.isEmpty ? null : fallback;
  }

  // Detect repealed ("kehtetu") sections: RT marks these with
  // "[Kehtetu - RT I, ... - jõust. ...]" either in the body (if the § had
  // any content to repeal) or — more commonly — in the title (when the
  // entire § heading was struck). Repealed sections have no body content
  // by design; we should not count them as broken.
  // NOTE: title detection happens in _parseAct (where we have the title
  // string) via `repealedInTitle`. Here we only see the body slice.
  final repealed = body != null &&
      RegExp(r'^\s*\[?Kehtetu', caseSensitive: false).hasMatch(body);

  return _Section(
    paragraph: '',
    title: '',
    body: body,
    subsections: subs,
    redactionRefs: redRefs,
    repealed: repealed,
    parseError: null,
  );
}

// ---------------------------------------------------------------------------
// HTML text helpers
// ---------------------------------------------------------------------------

String _stripHtmlTags(String s) {
  // Remove <...> tags but keep their content.
  return s.replaceAll(RegExp(r'<[^>]*>'), '');
}

String _normalizeWhitespace(String s) {
  return s.replaceAll(RegExp(r'\s+'), ' ').trim();
}

String _cleanSubsectionText(String raw) {
  // 1. Strip inline redaction spans entirely.
  var s = raw.replaceAll(
    RegExp(r'<span\s+class="mm">.*?</span>',
        caseSensitive: false, dotAll: true),
    '',
  );
  // 2. Convert <br/> to spaces so line-wrapped text doesn't glue words.
  s = s.replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), ' ');
  // 3. Strip remaining tags.
  s = _stripHtmlTags(s);
  // 4. Decode common HTML entities.
  s = _decodeEntities(s);
  // 5. Normalize whitespace.
  s = _normalizeWhitespace(s);
  return s;
}

String _decodeEntities(String s) {
  const map = {
    '&nbsp;': ' ',
    '&amp;': '&',
    '&lt;': '<',
    '&gt;': '>',
    '&quot;': '"',
    '&#39;': "'",
    '&apos;': "'",
    '&szlig;': 'ß',
  };
  var out = s;
  map.forEach((k, v) => out = out.replaceAll(k, v));
  // numeric entities &#123; and &#x1A;
  out = out.replaceAllMapped(RegExp(r'&#(\d+);'), (m) {
    final cp = int.tryParse(m.group(1)!);
    return cp == null ? m.group(0)! : String.fromCharCode(cp);
  });
  out = out.replaceAllMapped(RegExp(r'&#x([0-9a-fA-F]+);'), (m) {
    final cp = int.tryParse(m.group(1)!, radix: 16);
    return cp == null ? m.group(0)! : String.fromCharCode(cp);
  });
  return out;
}

String _reEsc(String s) =>
    s.replaceAllMapped(RegExp(r'[\\^$.*+?()\[\]{}|]'), (m) => '\\${m.group(0)}');

// ---------------------------------------------------------------------------
// Output
// ---------------------------------------------------------------------------

String _encode(_ParsedAct act) {
  final obj = <String, dynamic>{
    'act': act.code,
    'name': act.name,
    'source': act.source,
    'fetched_at': act.fetchedAt,
    if (act.redactionId != null) 'redaction_id': act.redactionId,
    if (act.redactionDate != null) 'redaction_effective_from': act.redactionDate,
    'sections': act.sections.map(_encodeSection).toList(),
  };
  return const JsonEncoder.withIndent('  ').convert(obj);
}

Map<String, dynamic> _encodeSection(_Section s) => {
      'paragraph': s.paragraph,
      'title': s.title,
      'body': s.body,
      'repealed': s.repealed,
      // Service contract (lib/services/estonian_law_search.dart) expects
      // subsection objects with "id" + "text" keys. "id" is rendered as
      // e.g. "lg 1" / "lg 2" for readability.
      'subsections': s.subsections
          .map((sub) => {'id': 'lg ${sub.number}', 'text': sub.text})
          .toList(),
      'redaction_refs': s.redactionRefs,
      if (s.parseError != null) 'parse_error': s.parseError,
    };

// ---------------------------------------------------------------------------
// Health check — matches the definition used by the diagnostic report.
// ---------------------------------------------------------------------------

bool _isHealthy(_Section s) {
  if (s.repealed) return true; // [Kehtetu] sections are legitimately empty
  final b = s.body;
  if (b == null) return false;
  // Some valid §§ are a single short sentence ("Valdus on tegelik võim asja
  // üle." is 33 chars in AÕS § 32). Keep the threshold conservative.
  return b.length >= 20;
}

// ---------------------------------------------------------------------------
// CLI args
// ---------------------------------------------------------------------------

class _Args {
  final String? single;
  final bool dryRun;
  final String outputDir;
  _Args(this.single, this.dryRun, this.outputDir);
}

_Args _parseArgs(List<String> argv) {
  String? single;
  var dryRun = false;
  var outputDir = 'assets/legal/estonia';
  for (var i = 0; i < argv.length; i++) {
    switch (argv[i]) {
      case '--act':
        single = argv[++i];
        break;
      case '--dry-run':
        dryRun = true;
        break;
      case '--out':
        outputDir = argv[++i];
        break;
      case '--help':
      case '-h':
        stdout.writeln(
          'Usage: dart run scripts/ingest_estonian_laws.dart '
          '[--act CODE] [--dry-run] [--out DIR]\n\n'
          'Known acts: ${_acts.map((a) => a.serviceCode).join(", ")}',
        );
        exit(0);
    }
  }
  return _Args(single, dryRun, outputDir);
}

// ---------------------------------------------------------------------------
// Reporting
// ---------------------------------------------------------------------------

class _ActReport {
  final String code;
  final String stem;
  final int total;
  final int healthy;
  final int bytes;
  final String? error;
  _ActReport({
    required this.code,
    required this.stem,
    required this.total,
    required this.healthy,
    required this.bytes,
    required this.error,
  });
}

void _printReport(List<_ActReport> report) {
  stdout.writeln('\n=== INGEST REPORT ===');
  stdout.writeln('Act       Total   Healthy   %    Bytes        Error');
  var totalSections = 0;
  var totalHealthy = 0;
  for (final r in report) {
    final pct = r.total == 0 ? 0 : (100 * r.healthy / r.total).round();
    final err = r.error == null ? '-' : r.error!.split('\n').first;
    stdout.writeln(
      '${r.code.padRight(8)}  ${r.total.toString().padLeft(5)}   '
      '${r.healthy.toString().padLeft(5)}   ${pct.toString().padLeft(3)}%  '
      '${r.bytes.toString().padLeft(8)}    $err',
    );
    totalSections += r.total;
    totalHealthy += r.healthy;
  }
  final pct =
      totalSections == 0 ? 0 : (100 * totalHealthy / totalSections).round();
  stdout.writeln(
    'TOTAL     ${totalSections.toString().padLeft(5)}   '
    '${totalHealthy.toString().padLeft(5)}   ${pct.toString().padLeft(3)}%',
  );
}
