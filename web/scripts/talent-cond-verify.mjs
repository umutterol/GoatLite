// §A keystone (M1) functional probe: prove the new onlyIf-gated intake/crit channels actually fire.
// Byte-identical egm-smoke proves the refactor didn't BREAK existing behaviour; this proves the NEW capability WORKS.
// (No talent content uses these predicates yet — so this is the only positive test until M7.)
import { createServer } from "vite"

const server = await createServer({ server: { middlewareMode: true }, appType: "custom", logLevel: "error" })
let fail = 0
try {
  const { talentIntakeMult, talentCritBonus } = await server.ssrLoadModule("/src/sim/egm/combat.ts")

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

  console.log(`\n${fail === 0 ? "ALL PASS" : `${fail} FAILED`}`)
} finally {
  await server.close()
}
process.exit(fail === 0 ? 0 : 1)
