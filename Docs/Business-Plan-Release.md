# GOAT Lite — Release Business Plan

**Studio:** DawnforgeGames · **Author:** Producer (Claude) · **Date:** 2026-06-18
**Strategy (locked with the founder):** Standalone commercial product · Solo dev + Claude · **Steam (PC) Early Access + free web demo** · MVP/vertical-slice first, grown live in EA.

> Companion docs: `GDD.md` (design spec), `ROADMAP.md` (production tracker), `DataModel.md`, `EGM-Reference-Analysis.md`.
> All market figures are mid-2026 and were adversarially fact-checked; revenue figures are stated **net** (after Steam's cut + VAT + refunds ≈ 55–65% of list) unless marked *gross*. External legal facts (Blizzard suits) are date-sensitive — re-check before acting.

---

## 0. Executive Summary

GOAT Lite is a satirical, browser-grade **guild-management sim / auto-battler** that skins **WoW Mythic+** as a QA job: you don't play the dungeon, you *review the pull* — gear bots, set comp/talents/tactics, watch a Warcraft-Logs-style replay, diagnose what broke, push the key higher, climb a leaderboard. The design is ~90% locked and unusually deep; the **product is ~15–20% built** with **near-zero original art/audio and no online backend**.

**The thesis is sound but narrow.** There is a real, concentrated, underserved audience (WoW M+ theorycrafters who *already read combat logs for fun*), a proven commercial loop (Gladiator Guild Manager: ~262K units / ~$1.8M *gross* at $14.99), and a free direct competitor that validates the concept but caps the floor (Exiled Guild Manager — free, prototype, ~11 ratings). The plan is to convert that niche via **Steam Early Access** (the revenue engine) fed by a **free web demo + live leaderboard** (the funnel and the viral artifact), launched on **niche-creator seeding** timed to WoW patch windows.

**Three things decide whether this works, none of which are the code:**
1. **Legal cleanup (do first, gates everything).** The public repo is distributing a decompiled competitor's game, and the build ships verbatim WoW trademarks (all 8 M+ affix names, "Mythic+", "Emblems of Heroism", "Bloodlust", Details!/Warcraft Logs/Raider.io branding). A commercial Steam release **cannot proceed** until both are scrubbed.
2. **Art/audio + the online backend** — the two largest unbuilt costs, both human-gated even with AI assistance.
3. **One organic creator/Next-Fest hit.** Indie discovery is luck-dominated (median Steam game grosses ~$249; ~8.5% of releases clear $100K). Without a hit, realistic year-1 reach collapses toward the EGM floor.

**Positioning note:** this is a deliberately **art-light data-tool game** (Warcraft-Logs-meets-Football-Manager: text, tables, parse meters) — so it prices *below* asset-rich comps like GGM ($14.99). Target tier: **$4.99 EA → $6.99 at 1.0** (see §5).

**Headline numbers (net, ~12–18 mo horizon, at $5–7):** Floor ~$3.5K–10K · **Base ~$28K–70K** · Upside (top-decile, full 1.0) ~$0.3M–1.0M. **Cash to EA launch ≈ $1.5K–9K**; the real cost is **~4–7 focused solo+AI months** to a sellable EA slice. Break-even is ~500–2,500 units.

---

## 1. ⚠️ Pre-Launch Blockers (resolve before *any* public/commercial activity)

These are not roadmap items — they are gates. A paid product makes every fair-use argument weaker, so "satire" is **not** a shield here; treat WoW resemblance as a trademark/trade-dress liability to engineer down, not defend.

| # | Blocker | Evidence | Action | Severity |
|---|---|---|---|---|
| B1 | **Public repo distributes a decompiled competitor game** (ZiggyD's EGM, 3,714 files incl. 233 `.gd` scripts under `Extract/`). Active infringement *now*. | `gh repo view` = PUBLIC; `git ls-tree origin/master` = 3,714 Extract files; `.gitignore` excludes only the `.exe`. | **Flip repo private immediately** (seconds, reversible). Then delete + re-init from a scrubbed tree (cleaner than history surgery — only 3 commits, Extract added in commit 1). Keep `EGM-Reference-Analysis.md` (original commentary); keep the binary/decompile **offline only**, if at all. | 🔴 HIGH (realized) |
| B2 | **Verbatim WoW trademarks in build + data.** All 8 M+ affix names, "Mythic+ Manager", "Emblems of Heroism", "Bloodlust", "Details!/Warcraft Logs/Raider.io". Blizzard is actively litigating WoW IP in 2025–26. | `data/affixes.json`, `season.json`, `currencies.json`, `skills.json`, `TopBar.tsx`, `logs.css`, `analytics.ts`. | **Trademark-scrub pass:** rename all 8 affixes, retitle away from "Mythic+", replace WoW-derived currency/ability/tool strings with invented in-world equivalents. Note: the in-flight engine rewrite is *reintroducing* WoW terms (`abilities-player.json`, `combat.ts` "Bloodlust") — the scrub is a moving target, not a one-time pass. | 🔴 HIGH |
| B3 | **Borrowed/derivative assets.** `public/warcraftcn/` WoW-race hero portraits (orc/undead/elf/human — license-undefined for images); 39 game-icons.net SVGs are CC BY 3.0 but **no attribution file exists** (out of compliance). | `ls public/warcraftcn/`; `web/README.md`; no LICENSE/ATTRIBUTION/CREDITS in `web/`. | Replace race portraits with **original, generic-fantasy** art (Phase E.1) — a pre-release legal gate, not polish. Add a CC-BY attribution file *today* or swap the icons. | 🟠 MED |
| B4 | **Commercialization weakens the legal posture.** A paid SKU + "satire" framing strengthens a trademark / false-designation claim. | Fair-use factor 1 (commerciality); satire ≠ parody in US courts. | Reframe public copy as a **generic-fantasy guild-sim that evokes the M+ genre**, not "WoW satire". Get a short **written games-IP attorney opinion** (~$500–2,500) on residual trade-dress (class-colour conventions, item-quality colours, parchment/log look) before marketing spend. | 🟠 MED |

**Do-first sequence:** repo private → scrub strings/assets in code+data → original art bible (generic fantasy) → attorney sanity opinion → *then* open a Steam page. None of this blocks engineering; all of it blocks *publishing*.

---

## 2. Product & Positioning

**One-liner:** *M+ minus the sweating, plus a job.* You're a burned-out ex-world-first raider doing QA on an MMO beta — recruit bots, gear them, set the plan, watch the replay, file the report, push the key.

**Why it can win a niche:** the target audience already lives in the parse/leaderboard mental model the game mimics (Raider.io, Warcraft Logs, Details!). The **in-universe satirical combat log is the product's marketing engine** — `"[1:52] Grymdark has left the dungeon"` is a shareable screenshot that needs no art budget. No competitor has aimed satire at the M+ theorycrafter surface.

**Differentiators that are genuinely ours (per the EGM reference analysis — these cannot be cribbed and carry full design/tuning risk):**
- **Party-level tactics** (aggression dial + 6 points × 4 categories) mapped to an **affix↔counterplay matrix**.
- **The dungeon timer + keystone ladder** with weekly affixes (the "come back this week" hook).
- **Role-modeled sim** (tank threat/mitigation, healer mana/OOM) — EGM has no healer role.
- A **deterministic, server-re-simulatable** engine → a genuinely cheat-resistant leaderboard most web games can't offer. **This is the strategic technical asset** and should be a headline feature.

**Deliberate art hedge:** the **Warcraft-Logs / data-tool aesthetic** (text + meters, class colours, parse tables) is both cheap *and* exactly what this audience finds appealing — turning the ~0% art state into an on-theme strength. Lean into it; minimize illustrated assets.

---

## 3. Market & Audience (de-hyped)

**Do NOT anchor on genre TAMs.** Aggregator "sim $2.7B–$25B / idle $2.4–14B / auto-battler $2.34B" figures disagree 5–10× and describe mobile/F2P money pools this game can't access. Anchor on the **audience funnel** instead:

| Layer | Definition | Size (stated as assumption) |
|---|---|---|
| **TAM** | MMO-endgame-literate people who'd *get* the joke | ~10–20M (cultural, not revenue) |
| **SAM** | English-speaking M+/parse-culture who'd engage a management sim | **~1–4M**, haircut for language/region (top WoW/Raider.io countries include DE/CN/RU/FR — the GTM is English/Reddit-centric) |
| **SOM (Yr 1, solo, niche)** | What you can capture with ~$0 marketing + 1–3 organic hits | **~5K–50K triers, ~1K–10K retained.** Without a hit, the EGM floor (dozens–hundreds engaged) applies. |

**Supporting signal (confirmed):** WoW ~7.25M subs (early 2024, excl. China); Dragonflight M+ cohort 4.2M timed-run / 1.2M did +15 *(these are class-population counts, not unique humans — treat as upper bounds)*; Raider.io a few M visits/mo, **swinging 30–260% with patches**; Warcraft Logs spiked 6.3M→13.9M on a patch. Audience is **77% male, 25–34, US/EU, long sessions** — the exact burned-out-ex-raider persona, with disposable income.

**Two cautions the data forces:**
- **M+ participation fell ~66% in War Within S1** — the niche is real but actively shrinking and tightly coupled to WoW's health. Concentration risk is real.
- **Survivorship bias:** every comp below is a hit. The base rate is brutal (median Steam game grosses ~$249; ~8.5% of ~19K 2025 releases cleared $100K; ~49% got <10 reviews).

---

## 4. Competitive Landscape

| Game | Platform / Model | Performance | Lesson for GOAT Lite |
|---|---|---|---|
| **Gladiator Guild Manager** | Steam, **$14.99 premium**, EA→1.0 | **~262K units / ~$1.8M gross**; launch-day all-time peak 3,335, now ~100–150 daily | **The load-bearing comp & ceiling.** Same "watch-don't-play" guild loop sells on Steam at $14.99. Grew via **Steam wishlists/EA/genre discovery — NOT a creator audience** → your exact playbook is precedented. Treat 262K/$1.8M as **top-decile gross**, not a base case. |
| **Exiled Guild Manager (EGM)** | itch.io, **free**, prototype | ~11 ratings (4.3/5), placeholder art, no sound; dev ZiggyD ~**240K** subs (not 2.6M) | **The floor & the direct substitute.** Validates the concept, proves thin organic traction at prototype stage, and is your loudest differentiation target. Its "creator-led" edge was a ~240K niche audience — **replicable via 2–4 mid-tier WoW creators.** |
| **Backpack Battles** | Steam, $12.99 EA | 640K month-one (~½ China) | Niche auto-battler EA can break out fast on the right hook. |
| **Mechabellum** | Steam | ~422–553K copies, ~$4.1M gross | Auto-battler depth + live-ops retains. |
| **Wrestling Empire** | Steam, $19.99, solo dev | 100–200K owners, 94% positive, thin concurrency | **The realistic shape:** solo "watch-and-manage" sim → long thin tail, small live numbers, cult following. |
| **Loop Hero / There Is No Game / Pony Island** | Steam premium | 1M+ / ~$4M net / 500K–1M | Tone/meta-hook *can* carry sales — but always on a deep loop, never jokes alone. |

**Net take-home reality:** all those revenue figures are **gross**. A solo dev nets ~55–65% after Steam's 30%, VAT, and refunds. At $9.99 that's **~$6/unit**; at $14.99, ~$8.5–9.5.

---

## 5. Business Model & Pricing

**Model: Premium one-time purchase on Steam (the earner) + free web demo (the funnel).** This is the correct fit for the founder's "standalone commercial" choice and for a design with **unlimited free runs + engagement-ranked leaderboards** — which structurally **forbid pay-to-win spend**. (F2P-with-IAP earns ~$0 on Steam without mobile-scale live-ops a solo studio can't sustain; web-portal ad share is weak and injects ads into a satirical sim.)

| Element | Decision |
|---|---|
| **Steam EA price** | **$4.99 EA → $6.99 at 1.0.** The *data-tool / Football-Manager-meets-Warcraft-Logs* aesthetic is deliberately art-light, so it positions **below** asset-rich comps (GGM at $14.99). Stay at the **upper end of $3–7 ($5–7)**: below ~$5 net drops to ~$2/unit and signals shovelware to a discerning audience; $5–7 is still impulse-buy territory while protecting margin. Pairs naturally with the free demo — *play free in-browser, buy on Steam to own it + support the dev + get the full/growing content, cloud saves, achievements.* Standard EA convention: launch a touch lower, raise at 1.0 (rewards early adopters). |
| **Free demo** | The deterministic Ashveil key as a **Steam Demo** (separate free app on the same store page → feeds Next Fest, Popular Upcoming, and wishlists directly). Optionally *also* a web build for frictionless ~4s creator-linkable play that reaches non-Steam players. Funnels into the **paid Steam** product. |
| **Cosmetics (later, optional)** | Only **leaderboard-neutral** cosmetics / an optional cosmetic pass, post-1.0, once there's art worth selling. No IAP, no gacha, no progress sales. |
| **GOAT main game** | Treated as **future optionality / sequel hook**, not load-bearing. The plan stands on Steam EA revenue alone. |

**Cost structure (cash, solo + Claude):**

| Item | Cost |
|---|---|
| Steam Direct fee | $100 (recouped at $1K gross) |
| Backend — **$0 with Steam-native** (Steam Leaderboards/Cloud/Stats). A serverless re-sim validator later is ~pennies–$25/mo, only if added | ~$0 |
| Domain + static hosting (Vercel/Cloudflare free) | ~$0–180/yr |
| **Capsule / key art** (commission — 68–88% of Next Fest wishlists come from the capsule, not the demo, so this is the one art line worth paying for) | ~$300–1,500 |
| Selective in-game art (3 portraits + few enemies): AI-gen + curation, or commission | $0–1,500 |
| Music (2 tracks) + core SFX: AI/royalty-free or commission | $0–500 |
| **IP attorney opinion** (pre-monetization gate) | ~$500–2,500 |
| 1–2 launch creator integrations (optional; core seeding is $0) | $0–3,000 |
| **Total cash to EA** | **~$1.5K–9K** |

**Revenue scenarios (net, ~12–18 mo):**

*(Net/unit at this tier: ~$3 at $4.99, ~$4 at $6.99, after Steam 30% + VAT + refunds.)*

| Scenario | Units | ~Net/unit | Net revenue | Basis |
|---|---|---|---|---|
| **Floor** (no breakout, EGM-like) | 1–3K | ~$3 | **$3.5K–10K** | Median-indie reality; one weak channel |
| **Base** (1 creator hit + Next Fest + Popular Upcoming) | 8–20K | ~$3.5 | **$28K–70K** | Void Miner sold 10K/12 days off 8,449 wishlists @ 22%; VGI "hobby" band 2–20K |
| **Upside** (genre-discovery breakout at full 1.0) | 80–260K | ~$4 | **$0.3M–1.0M** | GGM top-decile ceiling — *survivorship-biased, not a forecast* |

A lower price trades **margin for adoption**: it lifts impulse-buy conversion, lowers refund friction (Steam refunds hit short games hardest), and widens the top-of-funnel/wishlist base — at a niche TAM the unit ceiling is capped, so total revenue vs. a $9.99 model is roughly a wash-to-slightly-lower, bought back in reach. Break-even ≈ **500–2,500 units**. The dominant real cost is **founder time**, not cash.

### Shipping the web app on Steam — how hard?

**Verdict: the port is easy (days of work); the friction is Steam bureaucracy + store assets, not the code.** Steam will not list a pure browser/URL game — you ship a desktop executable that wraps your built Vite bundle. The app stays the *same* React SPA; you add a thin native shell around `dist/`.

**Recommended shell: Tauri** (Rust; uses the OS webview — WebView2 on Windows). For an asset-light data-tool SPA it's the best fit: **~3–10 MB binary** (vs Electron's ~150–250 MB bundled Chromium — a 200 MB download for a $5 text game looks bad), better memory/perf, purpose-built to wrap a Vite app. **Electron** is the bulletproof fallback if Tauri's webview quirks bite (larger/heavier, but maximal compatibility + cross-platform). Either produces a working Steam build in days with Claude.

**What actually takes the time (~1–2 weeks of work, spread across a mandatory wait):**
1. **Steamworks setup + the 30-day hold.** $100 Steam Direct fee + tax/bank forms + app records — *plus Steam's mandatory ~30-day wait between paying the fee and being allowed to release.* This is a **calendar gate, not effort** — start it early.
2. **Store-page assets** — capsule art, ≥5 screenshots, a trailer, copy. The real lift, and it's art/marketing (commission the capsule), not engineering.
3. **Saves → disk + cloud.** Today saves are `localStorage` (works inside the webview), but a desktop build should write real files (Tauri fs / Electron `userData`) and enable **Steam Cloud** sync. Minor, ~1 day.
4. **Build → upload.** Tauri/Electron build → upload via SteamPipe (`steamcmd`) → depot config. Well-documented, scriptable.
5. **Windows-first.** WoW M+ players are overwhelmingly Windows; ship Win64 first. Mac/Linux add signing/notarization overhead — defer.

**Backend (the demo-on-Steam decision simplifies this a lot).** If *both* the demo and the full game live on Steam, everyone is a Steam user — so you can **skip Supabase entirely and use Steam's built-in backend**: **Steam Leaderboards** (hosted, ranked, global/friends/around-user), **Steam Cloud** (saves), **Stats/Achievements**, and Steam **identity** (no auth to build). Free, zero hosting, zero monthly cost, zero ops — it deletes a whole workstream from the critical path. **The one real tradeoff:** Steam Leaderboards store whatever integer the client uploads — **there is no server-side re-simulation** — so you lose the cheat-proof board the deterministic engine was built to enable (Steam boards are easily spoofed). Mitigations short of a server: attach each run's **seed+inputs as entry details/UGC** so suspect top runs are auditable, and periodically pull the top N and **re-sim them offline** to purge fakes. If cheating ever becomes a real problem (or a web build returns), add the moat back cheaply with a **single serverless re-sim function** (one Cloud/edge function validating submissions — pennies, not a managed DB). **Gotcha:** a Steam *demo* is a separate appID with its own stats/leaderboards — decide whether the demo carries the competitive board at all (clean answer: demo = single-player taste, leaderboard = full-game feature).

**Minor caveats:** the Steam Overlay (shift-tab) is unreliable over a static DOM UI like yours (known Electron/Tauri issue; workarounds exist, or just accept no overlay — minor for a data-tool game); Windows SmartScreen warns without a ~$100–400/yr code-signing cert (optional); disclose any AI-generated assets per Steam policy. **None of this is hard** — the hard parts of the release stay art, legal (§1), and marketing, not the port.

---

## 6. Go-to-Market

**Highest-leverage channel: niche WoW M+ creator seeding** (not Reddit, not paid ads). The EGM comp's only real advantage was a ~240K niche audience — **manufacturable** by giving 30–50 mid/small WoW M+ & theorycrafter creators (1K–100K subs) free early access; the satire writes their script. Budget *time* here, not cash.

**Channel priorities (evidence-backed):**
- ✅ **Creators** (free-key seeding) + 1–2 paid mid-tier integrations at launch ($500–3K).
- ✅ **Steam wishlists** via a free "Coming Soon" page → **Popular Upcoming** (~7K wishlist soft-threshold; *velocity matters more than the raw number*) → **Steam Next Fest** (free; ~1,400 wishlists for the Void Miner analog).
- ✅ **The share-card as a launch feature** — one-click "export combat log card" + "share my leaderboard run" image. The screenshot *is* the ad, at $0 marginal cost.
- ✅ **YouTube Shorts** for the looping log gags (TikTok organic collapsed in 2025).
- ⚠️ **Reddit = credibility/community, not a faucet.** Direct promo returns ~100 wishlists and gets removed; r/CompetitiveWoW (192K) is the right room, r/wow (3.1M) is the wrong one. Earn one organic "look what this satirical log generated" moment.
- ❌ Mass-casual web portals (Poki/CrazyGames) only as top-of-funnel awareness — audience mismatch + mandatory ad SDK.

**Cold-start the leaderboard before anyone sees it:** pre-seed with **deterministic dev/"ghost" runs** across comps/keys/affixes (the seeded sim makes these legitimate) + a **closed-beta cohort**. First-session hook: *"You're ranked #437 — here's the run that beat you."* No player should ever see an empty board.

**Timing:** align launch + content drops to **WoW season/patch starts**, when the niche's traffic spikes 30–120% and "adapt your build to the affix" satire lands hardest. Weekly affix rotation = free recurring content cadence.

**Launch window:** concentrate creators + Next Fest + Steam-page-live into one 7-day spike (first month is ~25–40% of lifetime sales).

---

## 7. Product Roadmap to Release

### Target A — Early Access launch slice (the sellable MVP)
**Definition:** 1 dungeon (Ashveil, 4 bosses + elite), 3 MVP specs, keys +2–10, Fortified+Bursting, tactics+aggression, calling-the-run, morale (departure flag off), gear/6-slot, **interactive talent picker**, loot-drama modal, **a live "highest key timed" leaderboard with minimal accounts + server re-sim**, and a **coherent original visual+audio identity** (generic-fantasy, IP-clean).

**Critical path (in order — each gates the next):**
1. **Freeze the combat engine.** Finish the EGM rebuild (Phases 3.5→5: wire affixes/tactics/boss-mechanics, enemy front/back bands), **switch the live app off the old `sim/engine.ts` onto `sim/egm/`**, and **retune to the Dungeon Timer acceptance table**. *Today the shipping game still runs the old "fake" flat-power sim; the new engine is unwired scaffolding (~1,325 LOC, imported nowhere).* Everything downstream depends on this freeze.
2. **Leaderboard (Steam-native for EA).** Wire **Steam Leaderboards + Cloud + Stats** through the Steamworks SDK (`steamworks.js` for Electron / Rust bindings for Tauri) — hosted "highest key timed" board, no DB/auth/hosting to build. Attach each run's seed+inputs as entry details/UGC for auditability. **Defer** the server-side re-sim validator (and the client-only-vs-isomorphic decision) until cheating actually bites or a web build returns — but keep the determinism discipline (seeded PRNG + RunResult) so it stays a drop-in. Pre-seed the board with dev/ghost runs before launch (§6).
3. **Legal scrub + first art/audio.** Blockers B1–B4 + an art style bible (generic fantasy) + capsule + first assets (AI-assisted, curated; disclose AI use per Steam policy).
4. **Close blocking UI.** Interactive **talent picker** (today it's a read-only deterministic auto-pick — a core advertised pillar is non-functional) and the **loot-drama** modal. *(Recruitment + core boards already exist in the "Logs" reskin — smaller gap than the dated roadmap snapshot implies.)*
5. **Cold-start seeding + share-card export.**

**Effort (solo + Claude):** ~**4–7 focused calendar months**. *(Research estimated 9–13 person-months solo without AI; Claude compresses the engineering/content fraction ~2–3×, but art-direction curation, backend ops, balance ownership, marketing labor, and the legal scrub are human-gated and don't compress — plus the scrub is net-new work. Order-of-magnitude.)*

### Target B — 1.0 full game (grow it *in* Early Access)
6 dungeons (24 bosses, ~50–70 enemies, ~60–72 items, 6 environments), 10 specs + per-spec talent trees (~150 nodes) + tier sets, full affix calendar, recruitment/potentials/earned-traits, crafting/economy/gold sinks, full social leaderboard + seasons, complete art+audio. **Paced by content + art + balance throughput, not code** — a year-plus arc best de-risked by EA reception. **Do not gate launch on it.**

**Hidden costs the estimates under-size (budget for them):** re-validating *already-authored* content (60 skills, traits, affixes) against the frozen new engine; the leaderboard **anti-cheat trust model** (forged gear/seed inputs — harder than just re-running the sim); a **balance-regression harness** pinning the timer-acceptance curve (today it's ad-hoc smoke scripts).

---

## 8. Risk Register

| Risk | Severity | Mitigation |
|---|---|---|
| **IP — public repo distributes decompiled competitor** (realized) | 🔴 HIGH | Private now → scrub from history / re-init (§1, B1). Top priority. |
| **IP — verbatim WoW trademarks in a *commercial* build** vs litigious Blizzard | 🔴 HIGH | Full rename/scrub before any public or paid build; reframe to generic-fantasy (B2, B4). |
| **Execution — solo scope vs 6-dungeon/10-spec/art/audio/backend, mid-engine-rewrite** | 🔴 HIGH | Ship the 1-dungeon/3-spec EA slice; grow the rest live; freeze the engine before scaling content. AI absorbs eng/content, not art-direction/ops/balance. |
| **Art/audio throughput** (the dominant unbuilt, least-compressible cost) | 🟠 HIGH | Lean into the data-tool aesthetic; AI-gen + curation for the few illustrated assets; **commission only the capsule**; original/generic-fantasy to also clear B3. |
| **Backend/liveops underestimate** (0 lines today; a second product surface) | 🟠 MED-HIGH | Thin slice only for EA; Supabase Pro; defer social/guild grouping to 1.0. |
| **Market — niche, shrinking M+, discovery is luck** | 🟠 MED | One creator/Next-Fest hit is the lever; launch on a patch window; lean on the share-card. |
| **Leaderboard cold-start (empty board kills the loop)** | 🟠 MED | Ghost-run pre-seeding + closed beta before public exposure. |
| **Refund risk** (<2-hr loops refund higher; EA median ~12.4%) | 🟡 MED | Ensure ≥ a few hours of real decision-depth in the EA slice before charging; price conservatively. |
| **Asset-license non-compliance** (CC-BY icons, undefined portrait license) | 🟡 MED | Attribution file today; original art before paid launch (B3). |
| **Burnout / single-person bus factor** | 🟡 MED | Milestone-gate art/audio spend; ship EA early for motivation + revenue + signal. |
| **Client-side-sim cheating** (Steam-native board trusts client-uploaded scores; no live re-sim at EA) | 🟡 LOW–MED | Acceptable at EA/niche scale; attach seed+inputs for audit + offline-re-sim the top entries to purge fakes; add a serverless re-sim validator if it becomes real. Determinism keeps that a drop-in. |

---

## 9. Recommended Plan — Next 90 Days

1. **Week 1 (legal, do-first):** repo → private; scrub `Extract/` from tree + history (or re-init); add CC-BY attribution; start the WoW-string scrub in `data/` + `web/src`.
2. **Weeks 2–8 (engine freeze):** finish EGM Phases 3.5→5, switch the live app onto `sim/egm/`, retune to the timer table, re-prove determinism. Lock the **shared-TS isomorphic** decision.
3. **Weeks 4–10 (parallel — art bible + backend):** commission an art-direction bible (generic fantasy) + capsule; stand up the thin leaderboard backend (seeds → submit → re-sim → board → minimal accounts) on Supabase Pro.
4. **Weeks 8–12 (close the slice):** interactive talent picker + loot-drama modal; share-card export; cold-start ghost-seeding; first AI-assisted art/audio pass.
5. **In parallel from Week 2:** open a free Steam "Coming Soon" page; start the YouTube-Shorts log-gag cadence; build the 30–50 creator seeding list; book Next Fest; get the attorney opinion before any marketing spend.
6. **Gate:** **do not spend the one-time launch spike** until (a) legal scrub complete, (b) leaderboard backend live, (c) a minimum art/content bar that survives the Steam capsule. Then concentrate the EA launch into one patch-aligned week.

**The plan in one line:** *Clean the IP, freeze the engine, ship a small but genuinely competitive Early-Access slice to the M+ theorycrafter niche via creator seeding and a free leaderboard demo — then grow it in public.*
