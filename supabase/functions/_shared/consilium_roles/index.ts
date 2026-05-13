// consilium_roles/index.ts — barrel re-export for the v2.2 consilium roles.
// -----------------------------------------------------------------------------

export * from "./types.ts";
export {
  DOMAIN_EXPERTS,
  getDomainExpert,
} from "./domain.ts";
export {
  STRATEGIC_POSITIONS,
  getStrategicPosition,
} from "./strategic.ts";
export {
  compileRoles,
  selectConsiliumRoles,
  type RoleSelection,
} from "./router.ts";
export {
  DenoMemoryReader,
  loadMemoryHooks,
  type MemoryReader,
  resolveDefaultMemoryDir,
  StubMemoryReader,
} from "./memory.ts";
