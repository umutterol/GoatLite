/* sim-dump — configurable headless GOAT Lite sim harness that SAVES runs to files.
 *
 * Two jobs:
 *   1. single — run ONE deterministic sim and dump the full input + RunResult + derived
 *      analytics as JSON, plus a human-readable combat log (.md). Hand the .md/.json to
 *      Claude (or read it yourself) to investigate a specific scenario.
 *   2. sweep  — run a MATRIX (key levels × affix sets × aggressions × seeds) and dump an
 *      aggregated summary table. This is the balance-investigation workhorse.
 *
 * The whole point: stop hand-editing one-off probe scripts. Describe a scenario once (comp,
 * per-member ilvl/morale/skills/traits/talents, tactics, affix, aggression, key, seed) in a
 * JSON config or via CLI flags, and get a saved log file back.
 *
 * USAGE (run from web/):
 *   node scripts/sim-dump.mjs                          # default single run (standard comp, week affixes)
 *   node scripts/sim-dump.mjs --config scenario.json   # drive everything from a config file
 *   node scripts/sim-dump.mjs --key 14 --ilvl 115 --aggression Yolo --comp probe
 *   node scripts/sim-dump.mjs --mode sweep --config scenario.json
 *   node scripts/sim-dump.mjs --mode sweep --comp probe --ilvl-mode fixed --ilvl 115   # intake-curve sweep
 *
 * CLI flags (override the config / defaults):
 *   --config <path>      load a JSON config (see scripts/sim-config.example.json)
 *   --out <dir>          output dir (default: sim-logs/)
 *   --name <label>       label used in output filenames
 *   --mode single|sweep
 *   --key <n>            key level (single)
 *   --ilvl <n>           ilvl for all members lacking an explicit one
 *   --ilvl-mode auto|fixed   (sweep) auto = gear-appropriate per key (112+4·key, cap 160)
 *   --seed <n>           seed (single)
 *   --aggression Safe|Balanced|Yolo
 *   --affixes a,b,c      affix ids (default: save.week.affixes)
 *   --tactics i,p,c,k    the 4 dials 0-3 (default: 2,1,1,2)
 *   --comp <preset|csv>  preset (standard|probe|safety) OR a comma list of specIds
 *   --morale <n>         morale for all members (default 60)
 *   --skills e,a,c       operator skills for all members (default: engine baseline)
 *   --keys a,b,c         (sweep) key levels to sweep
 *   --seeds a,b,c        (sweep) seeds to average over
 *
 * Config schema (all optional; sensible defaults applied):
 *   {
 *     "mode": "single" | "sweep",
 *     "name": "my-scenario",
 *     "dungeonId": "ashveil-crypts",
 *     "keyLevel": 14,
 *     "affixIds": ["fortified","bursting","spiteful"],
 *     "aggression": "Balanced",
 *     "tactics": { "interrupts": 2, "positioning": 1, "cooldowns": 1, "killorder": 2 },
 *     "seed": 12345,
 *     "ilvl": 115, "morale": 60,
 *     "skills": { "execution": 1, "awareness": 1, "composure": 1 },
 *     "comp": [ "guardian", { "specId": "cleric", "ilvl": 120 }, ... ],   // 5 members
 *     "sweep": {
 *       "keyLevels": [2,5,8,11,14,17,20,23,26],
 *       "seeds": [12345,7,99,2024,31337],
 *       "ilvlMode": "auto",                          // "auto" | "fixed"
 *       "affixSets": [ {"id":"week","affixIds":["fortified","bursting","spiteful"]} ],
 *       "aggressions": ["Balanced"]
 *     }
 *   }
 */
import { createServer } from "vite"
import { mkdirSync, writeFileSync, readFileSync } from "node:fs"
import { resolve } from "node:path"

// ---------------- CLI parsing ----------------
const argv = process.argv.slice(2)
const flags = {}
for (let i = 0; i < argv.length; i++) {
  const a = argv[i]
  if (a.startsWith("--")) { const k = a.slice(2); const v = argv[i + 1]?.startsWith("--") ? "true" : argv[++i]; flags[k] = v ?? "true" }
}
const csv = (s) => (s == null ? undefined : String(s).split(",").map((x) => x.trim()).filter(Boolean))
const num = (s) => (s == null ? undefined : Number(s))

const COMP_PRESETS = {
  standard: ["guardian", "cleric", "assassin", "pyromancer", "berserker"],   // 1T/1H/3D (CLAUDE.md balance baseline)
  probe:    ["mystic", "lifebinder", "bard", "pyromancer", "assassin"],      // the comp in the enemy-damage-undertuned note
  safety:   ["guardian", "cleric", "lifebinder", "assassin", "pyromancer"],  // 2-healer safety comp (egm-smoke)
}

function resolveComp(spec) {
  if (!spec) return undefined
  if (Array.isArray(spec)) return spec
  if (COMP_PRESETS[spec]) return COMP_PRESETS[spec]
  return csv(spec)
}

// ---------------- bootstrap ----------------
const server = await createServer({ server: { middlewareMode: true }, appType: "custom", logLevel: "error" })
try {
  const { runDungeonEGM } = await server.ssrLoadModule("/src/sim/egm/engine.ts")
  const { content } = await server.ssrLoadModule("/src/content/index.ts")
  const save = content.save

  // ---------------- config resolution: defaults <- file <- CLI ----------------
  const fileCfg = flags.config ? JSON.parse(readFileSync(resolve(process.cwd(), flags.config), "utf8")) : {}
  const cfg = {
    mode: flags.mode ?? fileCfg.mode ?? "single",
    name: flags.name ?? fileCfg.name,
    dungeonId: fileCfg.dungeonId ?? save.keystone.dungeonId,
    keyLevel: num(flags.key) ?? fileCfg.keyLevel ?? 8,
    affixIds: csv(flags.affixes) ?? fileCfg.affixIds ?? save.week.affixes,
    aggression: flags.aggression ?? fileCfg.aggression ?? "Balanced",
    tactics: parseTactics(flags.tactics) ?? fileCfg.tactics ?? { interrupts: 2, positioning: 1, cooldowns: 1, killorder: 2 },
    seed: num(flags.seed) ?? fileCfg.seed ?? 12345,
    ilvl: num(flags.ilvl) ?? fileCfg.ilvl ?? 115,
    morale: num(flags.morale) ?? fileCfg.morale ?? 60,
    skills: parseSkills(flags.skills) ?? fileCfg.skills,
    comp: resolveComp(flags.comp) ?? fileCfg.comp ?? COMP_PRESETS.standard,
    sweep: fileCfg.sweep ?? {},
  }
  // sweep CLI overrides
  if (flags.keys) cfg.sweep.keyLevels = csv(flags.keys).map(Number)
  if (flags.seeds) cfg.sweep.seeds = csv(flags.seeds).map(Number)
  if (flags["ilvl-mode"]) cfg.sweep.ilvlMode = flags["ilvl-mode"]

  function parseTactics(s) {
    const v = csv(s)?.map(Number)
    if (!v) return undefined
    return { interrupts: v[0] ?? 0, positioning: v[1] ?? 0, cooldowns: v[2] ?? 0, killorder: v[3] ?? 0 }
  }
  function parseSkills(s) {
    const v = csv(s)?.map(Number)
    if (!v) return undefined
    return { execution: v[0] ?? 0, awareness: v[1] ?? 0, composure: v[2] ?? 0 }
  }

  const SPEC = (id) => content.specs.get(id)
  const ROLE = { Tank: "tank", Healer: "healer", DPS: "dps" }
  const gearIlvl = (key) => Math.min(112 + 4 * key, 160)   // mirrors game-store dropIlvl

  // ---------------- party builder ----------------
  function buildPartyInput(comp, defaults) {
    return comp.map((entry, i) => {
      const e = typeof entry === "string" ? { specId: entry } : { ...entry }
      const spec = SPEC(e.specId)
      if (!spec) throw new Error(`unknown specId '${e.specId}' (member ${i + 1})`)
      return {
        id: e.id ?? `m${i + 1}`,
        name: e.name ?? `${spec.name}`,
        specId: e.specId,
        ilvl: e.ilvl ?? defaults.ilvl,
        morale: e.morale ?? defaults.morale,
        traitIds: e.traitIds ?? [],
        ...(e.talents ? { talents: e.talents } : {}),
        ...((e.skills ?? defaults.skills) ? { skills: e.skills ?? defaults.skills } : {}),
        ...(e.profile ? { profile: e.profile } : {}),
      }
    })
  }

  // ---------------- derived analytics ----------------
  function analyze(input, result) {
    const ids = result.seriesIds
    const last = result.series.length - 1
    const combatSecs = Math.max(1, last)
    const members = result.partyMeta.map((meta, i) => {
      const inp = input.party.find((p) => p.id === meta.id) ?? {}
      const spec = SPEC(meta.specId)
      const aliveVals = result.hpSeries.map((row) => row[i]).filter((v) => v > 0)
      const minHp = aliveVals.length ? Math.min(...aliveVals) : 0
      const deaths = result.deaths.filter((d) => d.name === meta.name).length
      const dmg = result.series[last]?.[i] ?? 0
      const heal = result.healSeries[last]?.[i] ?? 0
      const finalHp = result.finalHpPct.find((h) => h.id === meta.id)
      return {
        id: meta.id, name: meta.name, spec: meta.specId, role: ROLE[spec?.role] ?? "?",
        ilvl: inp.ilvl, morale: inp.morale,
        dps: Math.round(dmg / combatSecs), hps: Math.round(heal / combatSecs),
        minHpPct: Math.round(minHp * 100), finalHpPct: finalHp?.pct ?? 0, deaths,
      }
    })
    const survivors = members.filter((m) => m.deaths === 0)
    // seconds in which at least one ALIVE member is below 40% (true 0 = dead, excluded)
    let dangerSecs = 0
    for (const row of result.hpSeries) if (row.some((v) => v > 0 && v < 0.4)) dangerSecs++
    const healers = members.filter((m) => m.role === "healer")
    return {
      outcome: result.outcome,
      durationSec: result.durationSec,
      timerSec: result.timerSec,
      marginSec: result.timerSec - result.durationSec,        // +timed to spare, -over
      keyDelta: result.keyDelta,
      totalDeaths: result.deaths.length,
      partyMinHpPct: members.length ? Math.min(...members.map((m) => m.minHpPct)) : 0,
      survivorMinHpPct: survivors.length ? Math.min(...survivors.map((m) => m.minHpPct)) : 0,
      dangerSecs,
      healerHps: healers.length ? Math.round(healers.reduce((a, m) => a + m.hps, 0) / healers.length) : 0,
      finalRezCharges: result.finalRezCharges,
      members,
    }
  }

  function runOne(over) {
    const ilvlDefault = over.ilvl ?? cfg.ilvl
    const party = buildPartyInput(over.comp ?? cfg.comp, { ilvl: ilvlDefault, morale: cfg.morale, skills: cfg.skills })
    const input = {
      dungeonId: cfg.dungeonId,
      keyLevel: over.keyLevel ?? cfg.keyLevel,
      affixIds: over.affixIds ?? cfg.affixIds,
      party,
      tactics: over.tactics ?? cfg.tactics,
      aggression: over.aggression ?? cfg.aggression,
      seed: over.seed ?? cfg.seed,
    }
    const result = runDungeonEGM(input)
    return { input, result, analysis: analyze(input, result) }
  }

  // ---------------- output dir ----------------
  const outDir = resolve(process.cwd(), flags.out ?? "sim-logs")
  mkdirSync(outDir, { recursive: true })
  const slug = (s) => String(s).replace(/[^a-z0-9]+/gi, "-").replace(/^-|-$/g, "").toLowerCase()

  if (cfg.mode === "sweep") {
    runSweep()
  } else {
    runSingle()
  }

  // ================= SINGLE =================
  function runSingle() {
    const { input, result, analysis } = runOne({})
    const compSlug = input.party.map((p) => p.specId.slice(0, 3)).join("")
    const name = cfg.name ?? `run-${slug(cfg.dungeonId)}-k${input.keyLevel}-${compSlug}-${input.aggression.toLowerCase()}-s${input.seed}`
    const jsonPath = resolve(outDir, `${name}.json`)
    const mdPath = resolve(outDir, `${name}.md`)
    writeFileSync(jsonPath, JSON.stringify({ kind: "single", config: cfg, input, analysis, result }, null, 2))
    writeFileSync(mdPath, renderSingleMd(input, analysis, result))
    console.log(`\n${analysis.outcome.toUpperCase()}  ${cfg.dungeonId} +${input.keyLevel}  ${input.aggression}  seed ${input.seed}`)
    console.log(`duration ${fmt(analysis.durationSec)} / timer ${fmt(analysis.timerSec)}  (margin ${analysis.marginSec >= 0 ? "+" : ""}${analysis.marginSec}s)  deaths ${analysis.totalDeaths}  partyMinHp ${analysis.partyMinHpPct}%`)
    console.log(`\nwrote:\n  ${mdPath}\n  ${jsonPath}`)
  }

  function renderSingleMd(input, a, result) {
    const L = []
    L.push(`# ${SPEC(input.party[0].specId) ? content.dungeons.get(input.dungeonId)?.name : input.dungeonId} +${input.keyLevel} — ${a.outcome.toUpperCase()}`)
    L.push("")
    L.push(`- **Affixes:** ${input.affixIds.map((x) => content.affixes.get(x)?.name ?? x).join(", ")}`)
    L.push(`- **Aggression:** ${input.aggression}   **Tactics:** interrupts ${input.tactics.interrupts} · positioning ${input.tactics.positioning} · cooldowns ${input.tactics.cooldowns} · killorder ${input.tactics.killorder}`)
    L.push(`- **Seed:** ${input.seed}`)
    L.push(`- **Result:** ${a.outcome} · duration ${fmt(a.durationSec)} / timer ${fmt(a.timerSec)} (margin ${a.marginSec >= 0 ? "+" : ""}${a.marginSec}s) · keyDelta ${a.keyDelta >= 0 ? "+" : ""}${a.keyDelta}`)
    L.push(`- **Survival:** ${a.totalDeaths} death(s) · party min-HP ${a.partyMinHpPct}% · survivor min-HP ${a.survivorMinHpPct}% · seconds-in-danger ${a.dangerSecs} · healer HPS ${a.healerHps} · rez charges left ${a.finalRezCharges}`)
    L.push("")
    L.push(`## Party`)
    L.push(`| Member | Spec | Role | ilvl | DPS | HPS | min-HP% | final-HP% | deaths |`)
    L.push(`|---|---|---|--:|--:|--:|--:|--:|--:|`)
    for (const m of a.members) L.push(`| ${m.name} | ${m.spec} | ${m.role} | ${m.ilvl} | ${m.dps} | ${m.hps} | ${m.minHpPct} | ${m.finalHpPct} | ${m.deaths} |`)
    L.push("")
    if (result.deaths.length) {
      L.push(`## Deaths`)
      for (const d of result.deaths) L.push(`- \`${d.t}\` **${d.name}** — ${d.cause}`)
      L.push("")
    }
    L.push(`## Combat log (${result.log.length} lines)`)
    L.push("```")
    for (const ln of result.log) L.push(`${ln.t.padStart(5)}  ${ln.kind.padEnd(8)} ${ln.text}`)
    L.push("```")
    return L.join("\n")
  }

  // ================= SWEEP =================
  function runSweep() {
    const sw = cfg.sweep
    const keyLevels = sw.keyLevels ?? [2, 5, 8, 11, 14, 17, 20, 23, 26]
    const seeds = sw.seeds ?? [12345, 7, 99, 2024, 31337]
    const ilvlMode = sw.ilvlMode ?? "auto"
    const affixSets = sw.affixSets ?? [{ id: "week", affixIds: cfg.affixIds }]
    const aggressions = sw.aggressions ?? [cfg.aggression]
    const compSlug = cfg.comp.map((c) => (typeof c === "string" ? c : c.specId).slice(0, 3)).join("")
    const name = cfg.name ?? `sweep-${compSlug}-${ilvlMode}-${ilvlMode === "fixed" ? `i${cfg.ilvl}` : "gear"}`

    const cells = []
    for (const aff of affixSets) for (const aggr of aggressions) {
      const rows = []
      for (const key of keyLevels) {
        const ilvl = ilvlMode === "auto" ? gearIlvl(key) : cfg.ilvl
        const runs = seeds.map((seed) => runOne({ keyLevel: key, seed, ilvl, affixIds: aff.affixIds, aggression: aggr }).analysis)
        const n = runs.length
        const avg = (sel) => runs.reduce((s, r) => s + sel(r), 0) / n
        const timed = runs.filter((r) => r.outcome === "timed").length
        rows.push({
          key, ilvl,
          timedRate: `${timed}/${n}`,
          outcomes: tally(runs.map((r) => r.outcome)),
          avgDeaths: round1(avg((r) => r.totalDeaths)),
          avgPartyMinHp: Math.round(avg((r) => r.partyMinHpPct)),
          avgSurvivorMinHp: Math.round(avg((r) => r.survivorMinHpPct)),
          avgDangerSecs: Math.round(avg((r) => r.dangerSecs)),
          avgMarginSec: Math.round(avg((r) => r.marginSec)),
          avgHealerHps: Math.round(avg((r) => r.healerHps)),
        })
      }
      cells.push({ affix: aff.id, affixIds: aff.affixIds, aggression: aggr, rows })
    }

    const jsonPath = resolve(outDir, `${name}.json`)
    const mdPath = resolve(outDir, `${name}.md`)
    writeFileSync(jsonPath, JSON.stringify({ kind: "sweep", config: cfg, sweep: { keyLevels, seeds, ilvlMode, affixSets, aggressions }, cells }, null, 2))
    writeFileSync(mdPath, renderSweepMd(name, { keyLevels, seeds, ilvlMode }, cells))
    console.log(`\nSWEEP ${name}  comp=[${cfg.comp.map((c) => typeof c === "string" ? c : c.specId).join(",")}]  ilvl=${ilvlMode}  seeds=${seeds.length}`)
    for (const cell of cells) {
      console.log(`\n  affix=${cell.affix} aggr=${cell.aggression}`)
      console.log(`  key  ilvl  timed   deaths  partyMinHp  survMinHp  dangerS  margin   healerHPS`)
      for (const r of cell.rows) console.log(`  +${String(r.key).padEnd(3)} ${String(r.ilvl).padEnd(4)} ${r.timedRate.padEnd(6)} ${String(r.avgDeaths).padStart(5)}  ${String(r.avgPartyMinHp).padStart(8)}%  ${String(r.avgSurvivorMinHp).padStart(7)}%  ${String(r.avgDangerSecs).padStart(6)}  ${String(r.avgMarginSec).padStart(6)}s  ${String(r.avgHealerHps).padStart(7)}`)
    }
    console.log(`\nwrote:\n  ${mdPath}\n  ${jsonPath}`)
  }

  function renderSweepMd(name, meta, cells) {
    const L = []
    L.push(`# ${name}`)
    L.push("")
    L.push(`- **Comp:** ${cfg.comp.map((c) => typeof c === "string" ? c : c.specId).join(", ")}`)
    L.push(`- **ilvl mode:** ${meta.ilvlMode}${meta.ilvlMode === "fixed" ? ` (ilvl ${cfg.ilvl})` : " (gear-appropriate: 112+4·key, cap 160)"}`)
    L.push(`- **Seeds:** ${meta.seeds.join(", ")}  ·  **Tactics:** ${JSON.stringify(cfg.tactics)}`)
    L.push("")
    L.push(`> **min-HP%** = lowest HP any *surviving* member reached (the survival-pressure signal). Near 100% with 0 deaths ⇒ intake is decorative.`)
    L.push("")
    for (const cell of cells) {
      L.push(`## affix: ${cell.affix} (${cell.affixIds.join(", ")}) · aggression: ${cell.aggression}`)
      L.push(`| key | ilvl | timed | outcomes | avg deaths | party min-HP% | survivor min-HP% | danger s | margin s | healer HPS |`)
      L.push(`|--:|--:|:--|:--|--:|--:|--:|--:|--:|--:|`)
      for (const r of cell.rows) L.push(`| +${r.key} | ${r.ilvl} | ${r.timedRate} | ${r.outcomes} | ${r.avgDeaths} | ${r.avgPartyMinHp} | ${r.avgSurvivorMinHp} | ${r.avgDangerSecs} | ${r.avgMarginSec} | ${r.avgHealerHps} |`)
      L.push("")
    }
    return L.join("\n")
  }

  function tally(arr) {
    const m = {}
    for (const x of arr) m[x] = (m[x] ?? 0) + 1
    return Object.entries(m).map(([k, v]) => `${v}${k[0]}`).join(" ")   // e.g. "3t 2d"
  }
  function round1(x) { return Math.round(x * 10) / 10 }
  function fmt(s) { const sign = s < 0 ? "-" : ""; s = Math.abs(s); return `${sign}${Math.floor(s / 60)}:${String(Math.floor(s % 60)).padStart(2, "0")}` }
} finally {
  await server.close()
}
