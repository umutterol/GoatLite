// §A keystone (M1) functional probe: prove the new onlyIf-gated intake/crit channels actually fire.
// Byte-identical egm-smoke proves the refactor didn't BREAK existing behaviour; this proves the NEW capability WORKS.
// (No talent content uses these predicates yet — so this is the only positive test until M7.)
import { createServer } from "vite"

const server = await createServer({ server: { middlewareMode: true }, appType: "custom", logLevel: "error" })
let fail = 0
try {
  const { talentIntakeMult, talentCritBonus } = await server.ssrLoadModule("/src/sim/egm/combat.ts")
  const { applyAbilityOverrides, eff } = await server.ssrLoadModule("/src/sim/egm/stats.ts")
  const { applyEventRider } = await server.ssrLoadModule("/src/sim/egm/combat.ts")

  const mk = (o = {}) => ({ hp: 100, maxHp: 100, position: "Front", statuses: [], resources: {}, downedUntil: -1, hitSinceAction: false, talentCondIntake: [], talentCondCrit: [], ...o })
  const ctxOf = (mobs = [], party = []) => ({ mobs, party })
  const near = (a, b) => Math.abs(a - b) < 1e-9
  const ok = (label, got, want) => { const pass = near(got, want); if (!pass) fail++; console.log(`${pass ? "OK " : "XX "} ${label}: got ${got.toFixed(3)} want ${want.toFixed(3)}`) }

  // 1. selfHpBelowPct intake (the headline Tier-4 defensive: -50% taken while below 50% HP)
  {
    const c = mk({ talentCondIntake: [{ pct: -50, onlyIf: { type: "selfHpBelowPct", value: 50 } }] })
    c.hp = 40; ok("selfHpBelowPct intake @40%", talentIntakeMult(c, ctxOf()), 0.5)
    c.hp = 80; ok("selfHpBelowPct intake @80%", talentIntakeMult(c, ctxOf()), 1.0)
  }
  // 2. enemiesAtLeast intake (-30% while 3+ enemies)
  {
    const c = mk({ talentCondIntake: [{ pct: -30, onlyIf: { type: "enemiesAtLeast", value: 3 } }] })
    ok("enemiesAtLeast intake (3 mobs)", talentIntakeMult(c, ctxOf([mk(), mk(), mk()])), 0.7)
    ok("enemiesAtLeast intake (2 mobs)", talentIntakeMult(c, ctxOf([mk(), mk()])), 1.0)
  }
  // 3. crit gated by enemiesAtLeast (+20% crit while 3+)
  {
    const c = mk({ talentCondCrit: [{ pct: 20, onlyIf: { type: "enemiesAtLeast", value: 3 } }] })
    ok("enemiesAtLeast crit (3 mobs)", talentCritBonus(c, undefined, ctxOf([mk(), mk(), mk()])), 0.20)
    ok("enemiesAtLeast crit (2 mobs)", talentCritBonus(c, undefined, ctxOf([mk(), mk()])), 0)
  }
  // 4. crit gated by targetHpBelowPct (+15% crit vs target below 50%)
  {
    const c = mk({ talentCondCrit: [{ pct: 15, onlyIf: { type: "targetHpBelowPct", value: 50 } }] })
    ok("targetHpBelowPct crit (tgt 40%)", talentCritBonus(c, mk({ hp: 40 }), ctxOf()), 0.15)
    ok("targetHpBelowPct crit (tgt 80%)", talentCritBonus(c, mk({ hp: 80 }), ctxOf()), 0)
  }
  // 5. allyHpBelowPct intake (-25% while any ally below 40%)
  {
    const c = mk({ talentCondIntake: [{ pct: -25, onlyIf: { type: "allyHpBelowPct", value: 40 } }] })
    ok("allyHpBelowPct intake (ally 30%)", talentIntakeMult(c, ctxOf([], [c, mk({ hp: 30 })])), 0.75)
    ok("allyHpBelowPct intake (all full)", talentIntakeMult(c, ctxOf([], [c, mk({ hp: 100 })])), 1.0)
  }
  // 6. selfStacksAtLeast crit (+10% crit at 4+ rampage)
  {
    const c = mk({ talentCondCrit: [{ pct: 10, onlyIf: { type: "selfStacksAtLeast", value: 4, resource: "rampage" } }] })
    c.resources.rampage = 4; ok("selfStacksAtLeast crit (4 rampage)", talentCritBonus(c, undefined, ctxOf()), 0.10)
    c.resources.rampage = 2; ok("selfStacksAtLeast crit (2 rampage)", talentCritBonus(c, undefined, ctxOf()), 0)
  }
  // 7. targetHasStatus crit (+12% crit vs a chilled target)
  {
    const c = mk({ talentCondCrit: [{ pct: 12, onlyIf: { type: "targetHasStatus", value: 1, status: "chill", minStacks: 1 } }] })
    ok("targetHasStatus crit (chilled)", talentCritBonus(c, mk({ statuses: [{ id: "chill", kind: "debuff", stacks: 1 }] }), ctxOf()), 0.12)
    ok("targetHasStatus crit (clean)", talentCritBonus(c, mk(), ctxOf()), 0)
  }
  // 8. unconditional conditional-mod (no onlyIf) always applies — proves the !t.onlyIf branch
  {
    const c = mk({ talentCondIntake: [{ pct: -10 }] })
    ok("no-onlyIf intake always", talentIntakeMult(c, ctxOf()), 0.9)
  }

  // ---- M2 §B: abilityOverride (clone-and-patch; shared content never mutated) ----
  const okEq = (label, got, want) => { const pass = got === want; if (!pass) fail++; console.log(`${pass ? "OK " : "XX "} ${label}: got ${JSON.stringify(got)} want ${JSON.stringify(want)}`) }
  {
    // a Massacre-like ability (top-level cooldown + a damage effect w/ modifiers + a special w/ params)
    const orig = () => ({ id: "x", cooldownTurns: 7, targeting: { side: "enemy", pattern: "single" },
      effects: [ { type: "damage", base: 60, scale: 1.2, modifiers: [{ when: { type: "targetHpBelowPct", value: 20 }, multiplyDamage: 2 }] },
                 { type: "special", mechanic: "rampage-damage-bonus", params: { perStackPct: 4, resource: "rampage" } } ] })
    const base = orig()
    const r1 = applyAbilityOverrides([base], null, [{ kind: "cooldown", abilityId: "x", cooldownTurns: 3 }])
    okEq("cooldown override (clone cd)", r1.abilities[0].cooldownTurns, 3)
    okEq("cooldown override (orig untouched)", base.cooldownTurns, 7)
    okEq("cooldown override (clone is a new obj)", r1.abilities[0] === base, false)

    const r2 = applyAbilityOverrides([orig()], null, [{ kind: "targeting", abilityId: "x", pattern: "all", band: "front" }])
    okEq("targeting override pattern", r2.abilities[0].targeting.pattern, "all")
    okEq("targeting override band", r2.abilities[0].targeting.band, "front")

    const r3 = applyAbilityOverrides([orig()], null, [{ kind: "param", abilityId: "x", mechanic: "rampage-damage-bonus", key: "perStackPct", value: 6 }])
    okEq("param override perStackPct", r3.abilities[0].effects[1].params.perStackPct, 6)

    const r4 = applyAbilityOverrides([orig()], null, [{ kind: "scalar", abilityId: "x", effectType: "damage", field: "scale", value: 1.5 }])
    okEq("scalar override damage.scale", r4.abilities[0].effects[0].scale, 1.5)

    const r5 = applyAbilityOverrides([orig()], null, [{ kind: "addModifier", abilityId: "x", when: { type: "targetBand", band: "back" }, multiplyDamage: 1.6 }])
    okEq("addModifier appended", r5.abilities[0].effects[0].modifiers.length, 2)
    okEq("addModifier value", r5.abilities[0].effects[0].modifiers[1].multiplyDamage, 1.6)

    const noop = orig()
    const r6 = applyAbilityOverrides([noop], null, [])
    okEq("no overrides → same array ref", r6.abilities[0] === noop, true)

    const r7 = applyAbilityOverrides([orig()], null, [{ kind: "cooldown", abilityId: "missing", cooldownTurns: 1 }])
    okEq("unknown abilityId → skipped (no throw)", r7.abilities[0].cooldownTurns, 7)
  }

  // ---- M3a §E: event riders (deterministic actions) ----
  {
    const ctx = { t: 100, secondsPerTurn: 3, rng: { chance: () => true }, party: [] }
    const a1 = { cooldowns: {}, resources: {}, hp: 50, maxHp: 100, healDone: 0, shield: 0, downedUntil: -1, statuses: [] }; ctx.party = [a1]
    applyEventRider(a1, {}, { trigger: "on-kill", adjustCooldown: { abilityId: "fin", deltaTurns: -999 } }, { dealt: 0 }, ctx)
    okEq("rider: cooldown full reset to now", a1.cooldowns.fin, 100)
    const a2 = { cooldowns: { fin: 130 }, resources: {}, hp: 50, maxHp: 100, healDone: 0, shield: 0, downedUntil: -1, statuses: [] }; ctx.party = [a2]
    applyEventRider(a2, {}, { trigger: "on-hit", adjustCooldown: { abilityId: "fin", deltaTurns: -2 } }, { dealt: 0 }, ctx)
    okEq("rider: cooldown -2 turns (=-6s)", a2.cooldowns.fin, 124)
    const a3 = { cooldowns: {}, resources: { fury: 1 }, hp: 50, maxHp: 100, healDone: 0, shield: 0, downedUntil: -1, statuses: [] }; ctx.party = [a3]
    applyEventRider(a3, {}, { trigger: "on-kill", refundResource: { resource: "fury", amount: 2 } }, { dealt: 0 }, ctx)
    okEq("rider: refund +2 fury", a3.resources.fury, 3)
    const a4 = { cooldowns: {}, resources: {}, hp: 50, maxHp: 100, healDone: 0, shield: 0, downedUntil: -1, statuses: [] }; ctx.party = [a4]
    applyEventRider(a4, {}, { trigger: "on-crit", heal: { target: "self", pctOfMaxHp: 4 } }, { dealt: 0 }, ctx)
    okEq("rider: heal 4% maxHp self", a4.hp, 54)
    const a5 = { cooldowns: {}, resources: {}, hp: 50, maxHp: 100, healDone: 0, shield: 0, downedUntil: -1, statuses: [] }; ctx.party = [a5]
    applyEventRider(a5, {}, { trigger: "on-hit", heal: { target: "self", pctOfDamage: 10 } }, { dealt: 200 }, ctx)
    okEq("rider: heal 10% of 200 dmg self", a5.hp, 70)
  }

  // ---- M3b §C: healing-received (anti-heal) channel ----
  {
    const base = { power: 0, maxHp: 100, armour: 0, resist: 0, critChance: 0, critMult: 1, attackInterval: 1, dodgeChance: 0, damageTakenPct: 0 }
    const c = { ...base, statuses: [{ statMods: [{ stat: "healingReceived", amountPct: -50 }] }] }
    okEq("anti-heal: eff.healingTakenPct = -50", eff(c).healingTakenPct, -50)
    okEq("no debuff: healingTakenPct = 0", eff({ ...base, statuses: [] }).healingTakenPct, 0)
  }

  console.log(`\n${fail === 0 ? "ALL PASS" : `${fail} FAILED`}`)
} finally {
  await server.close()
}
process.exit(fail === 0 ? 0 : 1)
