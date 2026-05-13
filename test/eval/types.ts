// Advocat.ee — chat-quality eval harness types.
//
// Sister suites (not duplicative):
//   * `eval/runner.ts`            — email-triage Pkg 8 fixtures (XML-tag blocks)
//   * `scripts/eval/run-eval.ts`  — single-case YAML judge with swap (Sulga)
//   * THIS one  (`test/eval/`)    — broad ET legal categories with JSON criteria
//                                   for chat answer quality vs. expected facts.

/** Difficulty band — used for weighting and per-band reporting. */
export type Difficulty = "easy" | "medium" | "hard";

/** ISO language code we exercise the chat in. */
export type Language = "et" | "ru" | "en" | "fi";

/** Category slug — keep in sync with file names under questions/. */
export type Category =
  | "employment"
  | "housing"
  | "family"
  | "deportation"
  | "consumer"
  | "contract";

/** Per-question expected-answer criteria. */
export interface Expected {
  /**
   * Legal-act short codes the answer SHOULD cite. ET examples: TLS, VÕS, PKS,
   * KarS, ATS, KMS, TsMS. FI examples: TSL, UlkL, HOL. Match is case-sensitive
   * substring search by default; judge interprets context.
   */
  must_mention_laws: string[];
  /**
   * Concepts / phrases the answer MUST contain — natural language, judge
   * interprets semantically (not strict substring). Each entry should be a
   * SHORT description: "30-day notice period", not a full sentence.
   */
  must_include: string[];
  /**
   * Anti-patterns the answer MUST NOT contain. Example: "definitive legal
   * advice without disclaimer", "fabricated case law". Judge interprets.
   */
  must_not_include: string[];
  /** Stylistic guidance for the judge — professional, empathetic, etc. */
  tone: string;
  /** Soft length floor — answers shorter than this lose points. */
  min_word_count: number;
  /** Soft length ceiling — verbose answers lose points. */
  max_word_count: number;
}

/** One eval question loaded from questions/<category>.json. */
export interface Question {
  /** Stable ID, format `<cat-prefix>-NNN`, e.g. `emp-001`. */
  id: string;
  category: Category;
  language: Language;
  /** Verbatim user question, as a real person would type it. */
  question: string;
  expected: Expected;
  difficulty: Difficulty;
  /** Free-form tags for filtering/grouping in reports. */
  tags: string[];
}

/** Per-criterion grading outcome from the LLM judge. */
export interface CriterionResult {
  criterion: string;
  /** `must_mention_laws` | `must_include` | `must_not_include` | `tone` | `length`. */
  type:
    | "must_mention_laws"
    | "must_include"
    | "must_not_include"
    | "tone"
    | "length";
  pass: boolean;
  /** Short justification (<=200 chars) from the judge. */
  evidence: string;
}

/** Full grader output for one (question, candidate-answer) pair. */
export interface GraderResult {
  /** 0-100 overall score after weighting. */
  score: number;
  /** Pass = score >= question.pass_threshold (default 70). */
  pass: boolean;
  criteria: CriterionResult[];
  /** Word count of the candidate answer. */
  word_count: number;
  /** Optional judge notes / overall comment. */
  notes?: string;
  /** Raw judge model output, kept for audit / debugging. */
  raw?: string;
}

/** One row in the run JSON output. */
export interface RunRow {
  question_id: string;
  category: Category;
  difficulty: Difficulty;
  language: Language;
  question: string;
  candidate_answer: string;
  candidate_latency_ms: number;
  candidate_model: string;
  grader: GraderResult;
  ts: string;
  /** Set when the candidate call (NOT the judge) errored. */
  error?: string;
}

/** Whole run output, written to results/<date>-<model>.json. */
export interface RunSummary {
  run_id: string;
  ts: string;
  model: string;
  api_endpoint: string;
  total_questions: number;
  passed: number;
  failed: number;
  errored: number;
  pass_rate: number;
  /** Mean score across non-errored questions. */
  mean_score: number;
  per_category: Record<
    Category,
    { total: number; passed: number; mean_score: number }
  >;
  per_difficulty: Record<
    Difficulty,
    { total: number; passed: number; mean_score: number }
  >;
  rows: RunRow[];
}

/** Default pass threshold (overall score, 0-100). */
export const DEFAULT_PASS_THRESHOLD = 70;
