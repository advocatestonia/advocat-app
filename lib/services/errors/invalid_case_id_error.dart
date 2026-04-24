/// Thrown when caseId must be a real UUID (e.g. for inserts with FK) but isn't.
/// Synthetic ids like 'general' should normally short-circuit with empty
/// results, not throw — use [SupabaseService.requireUuid] only where a UUID
/// is genuinely required.
class InvalidCaseIdError extends Error {
  final String caseId;
  final String context;
  InvalidCaseIdError(this.caseId, this.context);
  @override
  String toString() =>
      'InvalidCaseIdError($context): "$caseId" is not a UUID';
}
