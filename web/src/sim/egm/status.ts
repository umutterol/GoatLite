/* EGM-model status container (Phase 2).
   Statuses are applied, stacked, and (for DoTs/HoTs) ticked for real. Their *control* and *stat*
   consequences (CC blocking, buff stat-mods, special mechanics) are recorded but NOT enforced yet —
   that's Phase 3+. Kept minimal so modifiers/conditions can read live state today. */
import { content } from "@/content"
import { dealDamage, passiveSpecial, type Combatant, type StatMod, type ActiveStatus } from "./stats"

/** Total stacks of `id` on a combatant — counts both resources (e.g. rampage) and active statuses (e.g. poison). */
export function stacksOf(c: Combatant, id: string): number {
  let n = c.resources[id] ?? 0
  for (const s of c.statuses) if (s.id === id) n += s.stacks
  return n
}
export function hasStatus(c: Combatant, id: string, minStacks = 1): boolean {
  return stacksOf(c, id) >= minStacks
}
export function hotStacks(c: Combatant): number {
  let n = 0
  for (const s of c.statuses) if (s.kind === "hot") n += s.stacks
  return n
}

/** Nature's Grace HoT amplification factor (≥1) for a HoT of `statusId` applied by `applier`. */
export function hotAmplifyFactor(applier: Combatant | undefined, statusId: string, stacks: number): number {
  if (!applier) return 1
  const amp = passiveSpecial(applier, "hot-amplify-per-stack") as
    | { affectsStatuses?: string[]; maxAmountPct?: number; amountPctPerStack?: number } | undefined
  if (!amp || !(amp.affectsStatuses ?? []).includes(statusId)) return 1
  return 1 + Math.min(amp.maxAmountPct ?? Infinity, (amp.amountPctPerStack ?? 0) * stacks) / 100
}

export function applyStatus(
  target: Combatant,
  statusId: string,
  opts: { perTick?: number; durationSec: number; stacks?: number; applierId: string; t: number },
): void {
  const def = content.statuses.get(statusId)
  if (!def) return
  const add = opts.stacks ?? 1
  const expiresAt = opts.durationSec > 0 ? opts.t + opts.durationSec : Infinity
  const existing = target.statuses.find((s) => s.id === statusId)
  if (existing) {
    switch (def.refresh) {
      case "stack":
        existing.stacks = Math.min(def.maxStacks, existing.stacks + add)
        existing.expiresAt = expiresAt
        existing.applierId = opts.applierId
        if (opts.perTick != null) existing.perTick = opts.perTick
        break
      case "refresh":
        existing.stacks = Math.min(def.maxStacks, existing.stacks + add)
        existing.expiresAt = expiresAt
        existing.applierId = opts.applierId
        if (opts.perTick != null) existing.perTick = opts.perTick
        break
      case "replace":
        existing.stacks = Math.min(def.maxStacks, add)
        existing.expiresAt = expiresAt
        existing.applierId = opts.applierId
        if (opts.perTick != null) existing.perTick = opts.perTick
        break
      case "strongest":
        if ((opts.perTick ?? 0) >= existing.perTick) {
          existing.perTick = opts.perTick ?? existing.perTick
          existing.expiresAt = expiresAt
          existing.applierId = opts.applierId
        }
        break
    }
  } else {
    target.statuses.push({
      id: statusId, kind: def.kind, control: def.control,
      stacks: Math.min(def.maxStacks, add), perTick: opts.perTick ?? 0,
      statMods: def.statMods, untargetable: def.untargetable,
      expiresAt, applierId: opts.applierId,
    })
  }
}

/** Apply an inline buff/debuff effect (no status-def lookup) — e.g. War Cry's +armour, Rally Cry's +damage. */
export function applyInline(
  target: Combatant,
  opts: { id: string; kind: "buff" | "debuff"; statMods: StatMod[]; durationSec: number; applierId: string; t: number },
): void {
  const expiresAt = opts.durationSec > 0 ? opts.t + opts.durationSec : Infinity
  const existing = target.statuses.find((s) => s.id === opts.id)
  if (existing) { existing.statMods = opts.statMods; existing.expiresAt = expiresAt; existing.applierId = opts.applierId }
  else target.statuses.push({ id: opts.id, kind: opts.kind, stacks: 1, perTick: 0, statMods: opts.statMods, expiresAt, applierId: opts.applierId })
}

/** Current crowd-control state from active statuses. */
export function controlState(c: Combatant): { blocked: boolean; silenced: boolean; dazed: boolean } {
  let blocked = false, silenced = false, dazed = false
  for (const s of c.statuses) {
    if (s.control === "stun" || s.control === "freeze") blocked = true
    else if (s.control === "silence") silenced = true
    else if (s.control === "daze") dazed = true
  }
  return { blocked, silenced, dazed }
}
/** Daze = "loses next action": consume it once the action is skipped. */
export function consumeDaze(c: Combatant): void {
  if (c.statuses.some((s) => s.control === "daze")) c.statuses = c.statuses.filter((s) => s.control !== "daze")
}
/** Remove up to n debuffs/DoTs/CC from a combatant (Cleanse / Mass Dispel). */
export function cleanseStatuses(c: Combatant, n: number): number {
  let removed = 0
  c.statuses = c.statuses.filter((s) => {
    if (removed < n && (s.kind === "debuff" || s.kind === "dot" || s.kind === "cc")) { removed++; return false }
    return true
  })
  return removed
}

/** What a status tick produced, so the combat layer can react (atonement-on-dot, bloom-on-expire). */
export interface StatusTick {
  dots: { status: ActiveStatus; amount: number }[]   // DoT damage that landed this step
  expired: ActiveStatus[]                            // statuses that ran out this step
}

/** Apply DoT damage / HoT healing for `dt` seconds, attribute to the applier, then drop expired statuses. */
export function tickStatuses(c: Combatant, dt: number, t: number, resolve: (id: string) => Combatant | undefined): StatusTick {
  const dots: StatusTick["dots"] = []
  for (const s of c.statuses) {
    if (!s.perTick || (s.kind !== "dot" && s.kind !== "hot")) continue
    let amt = s.perTick * s.stacks * dt
    if (s.kind === "dot") {
      dealDamage(c, amt)
      const src = resolve(s.applierId); if (src) src.dmgDone += amt
      dots.push({ status: s, amount: amt })
    } else {
      // Nature's Grace: the HoT's caster amplifies their own regrowth/blossom/breath by +x%/stack (capped).
      const src = resolve(s.applierId)
      amt *= hotAmplifyFactor(src, s.id, s.stacks)
      const before = c.hp
      c.hp = Math.min(c.maxHp, c.hp + amt)
      if (src) src.healDone += c.hp - before
    }
  }
  const expired = c.statuses.filter((s) => t >= s.expiresAt)
  if (expired.length) c.statuses = c.statuses.filter((s) => t < s.expiresAt)
  return { dots, expired }
}
