extends Node


const TOOLTIPS = {
    "target_lock": [
        "[b]Target Lock-On[/b]", 
        "How long this exile stays committed to a chosen target before the rule chain is re-evaluated.", 
        "[b]Important[/b]: while the lock is active, the rules above are [i]ignored[/i]. The exile keeps attacking the same target even if your rules would now pick someone else.", 
        "The lock [b]refreshes on every landed hit[/b], so against a target you're actively damaging the lock keeps renewing — a tough target can hold the lock for the entire fight. The lock clears the instant the target dies or escapes long enough to stop taking hits.", 
        "  • [b]Let Them Decide[/b] — inherit the gear-inferred default ([i]usually around 2.5 seconds[/i]).", 
        "  • [b]Off[/b] — re-evaluate before every attack. Most reactive; rule changes apply instantly.", 
        "  • [b]Short / Standard / Long[/b] — fixed seconds of commitment once a target is picked.", 
        "Higher = more committed and consistent. Lower = more reactive to rule changes like [i]Attacking me[/i] or [i]Without ignite[/i]."
    ], 
    "kite_profile": [
        "[b]Kite Profile[/b]", 
        "How this exile positions during combat.", 
        "  • [b]Evasive Melee[/b] — melee skirmisher. Stays in attack range but circles the target between swings (wide scatter angle, not a straight retreat).", 
        "  • [b]Careful Sniper[/b] — hugs maximum attack range, backs off readily. Ranged glass cannons. Breaks {target_lock} if a threat closes within 4 units.", 
        "  • [b]Balanced Aggressive[/b] — closer than a sniper for DPS uptime, still kites when threatened. Breaks {target_lock} if a threat closes within 3 units.", 
        "  • [b]Reckless[/b] — only kites melee opponents this exile can outrun. Stands and fights anything ranged or faster.", 
        "  • [b]No Kiting[/b] — never repositions. Plant and swing — works for both melee tanks and stationary ranged.", 
        "  • [b]Let Them Decide[/b] — inherit the gear-inferred default."
    ], 
    "target_priority_rules": [
        "[b]Target Priority Rules[/b]", 
        "An ordered list of conditions the exile checks every time they pick a target. Rules are evaluated [b]top to bottom[/b] — the first rule that matches any enemy wins, and the exile attacks whichever enemy that rule's picker chooses.", 
        "If no rule matches (e.g. nothing is attacking you and nothing has the status you specified), the [b]Fallback[/b] picker at the bottom takes over — it always finds someone.", 
        "Note: [b]Target Lock-On[/b] (below) overrides these rules while the lock is active — the exile stays on their current target instead of re-checking the chain.", 
        "Changes apply starting next combat."
    ], 
    "target_rule": [
        "[b]Target Rule[/b]", 
        "One row in the priority chain. Rules are checked top to bottom.", 
        "For each rule the exile first narrows the enemy list with the [b]filter[/b], optionally to enemies within attack range, then [b]picks[/b] one from the survivors. The first rule that finds any matching enemy wins.", 
        "If no rule matches, the [b]fallback picker[/b] at the bottom always picks someone."
    ], 
    "fallback_picker": [
        "[b]Fallback Picker[/b]", 
        "Always-runs-last selector. When none of your rules match a living enemy, this picks one from the entire enemy list — guaranteeing the exile never freezes for lack of a target."
    ], 
    "status_filter": [
        "[b]Status Filter[/b]", 
        "Narrows the candidate list to enemies that [i]have[/i] or [i]lack[/i] a specific status effect — ignite, shock, chill, etc.", 
        "[i]Poison and Impale are not selectable here — they use separate stack systems.[/i]"
    ], 
    "vitality": [
        "[b]Vitality[/b]", 
        "Vitality is consumed to recover {life} whenever healing occurs. Without Vitality, no health can be restored.", 
        "This includes the automatic healing when returning from a mission, as well {life_regen}, {life_leech}, and {life_gain_on_hit}.", 
        "Life Recovery drains 1 Vitality per Life in combat. Recovery at the Guild is much more efficient.", 
        "Recover Vitality by {resting}.", 
            ], 
    "life": [
        "[b]Life[/b]", 
        "When it reaches 0, the exile dies.", 
        "Life is automatically recovered when the exile returns to the guild.", 
        "In missions, Life can be restored through stats such as {life_regen}, {life_leech}, and {life_gain_on_hit}.", 
        "Most Life recovery consumes {vitality}.", 
        "[i]The last point of Life is the most important, the rest is a resource you can spend as you see fit.[/i]"
    ], 
    "morale": [
        "[b]Morale[/b]", 
        "Morale is the mental state of your exiles.", 
        "Missions, events, rest, and other experiences can all improve or damage the Morale of the exiles.", 
        "While in {high_morale} an exile fights more effectively. In {low_morale} they suffer penalties.", 
        "Exiles at 0 Morale may leave your guild in search of better opportunities.", 
        "Each exile can gain and lose Morale differently. In general: keep them challenged, keep them fed and look after them."
    ], 
    "high_morale": [
        "[b]High Morale[/b]", 
        "An exile is in High Morale while their {morale} is at or above 90% of their maximum.", 
        "  • 10% [b]more[/b] damage dealt", 
        "  • 10% [b]less[/b] damage taken", 
        "  • 10% [b]more[/b] experience gained", 
        "Some traits and passives grant extra bonuses that activate only at High Morale."
    ], 
    "low_morale": [
        "[b]Low Morale[/b]", 
        "An exile is in Low Morale while their {morale} is at or below 25% of their maximum.", 
        "  • 10% [b]less[/b] damage dealt", 
        "  • 10% [b]more[/b] damage taken", 
        "  • 10% [b]less[/b] experience gained", 
        "Some traits and passives apply extra penalties while in Low Morale.", 
        "At 0 Morale an exile is [b]Broken[/b] and may leave the guild — unless they have {unbreakable}."
    ], 
    "unbreakable": [
        "[b]Unbreakable[/b]", 
        "An exile with Unbreakable cannot leave the guild from broken {morale}, no matter how low it falls.", 
        "They still suffer {low_morale} penalties — Unbreakable only prevents the departure roll.", 
        "Granted by traits and passives such as Iron Willed."
    ], 
    "resting": [
        "[b]Resting[/b]", 
        "Exiles rest at the end of each day.", 
        "Each rest recovers {vitality} determined by the exile's {food_ration}.", 
        "Resting with food improves {morale}, resting without food hurts it (see {starvation})."
    ], 
    "food": [
        "[b]Food[/b]", 
        "Resting exiles convert food into extra {vitality} recovery and {morale} gain.", 
        "Each exile's daily consumption is controlled by their {food_ration}.", 
        "Without food, exiles forage to survive — they recover less and lose {morale} (see {starvation}).", 
    ], 
    "chaos": [
        "[b]Chaos Shard[/b]", 
        "A trade Currency and a crafting reagent.", 
        "Replaces one existing affix with a different one of the same kind (prefix→prefix, suffix→suffix).", 
        "Cost: 1 Chaos Shard per item level.", 
        "Does not interact with implicit modifiers. Cannot be used on {corrupted} items."
    ], 
    "exalt": [
        "[b]Exalted Shard[/b]", 
        "A crafting currency. Adds a new affix to a Magic or Rare item, upgrading rarity as needed.", 
        "Cost scales with item level — 1 Exalt per item level per craft.", 
    ], 
    "vaal_orb": [
        "[b]Vaal Orb[/b]", 
        "Applying a Vaal Orb to an item rolls one of four outcomes (even chance):", 
        "  • Reroll all affixes (same count)", 
        "  • Reroll all affix values (in current tier; affects implicits)", 
        "  • Each explicit affix shifts ±1 tier (independent rolls)", 
        "  • Adds a corruption-only modifier", 
        "All four outcomes set the item to {corrupted}, locking it from any further crafting."
    ], 
    "corrupted": [
        "[b]Corrupted[/b]", 
        "A terminal item state set by Vaal Orb crafts.", 
        "Corrupted items cannot be modified by any crafting orb (Exalt, Chaos, or another Vaal).", 
    ], 
    "scrap": [
        "[b]Scrap[/b]", 
        "A resource for building and crafting. (TODO not yet implemented)", 
        "Also used as a trade currency by passing merchant ships."
    ], 
    "day": [
        "[b]Day[/b]", 
        "Each day, exiles rest, recover {vitality} and {morale}, and consume {food} per their {food_ration}.", 
        "End the day from the guild screen to advance time."
    ], 
    "missing_in_action": [
        "[b]Missing in Action[/b]", 
        "An exile who was captured during a mission. Their fate is unresolved.", 
        "A {rescue_mission} for them appears in the area where they were lost. You have a limited window — typically 3 days — to reach them before the trail goes cold.", 
        "If the rescue window expires the exile is gone, but scouting reports may occasionally surface old leads in the area where they were lost.", 
        "[i]MIA exiles do not appear on the guild roster, rest, eat, or earn experience. Their morale and stats are paused until rescued.[/i]"
    ], 
    "rescue_mission": [
        "[b]Rescue Mission[/b]", 
        "A time-limited mission posted to recover a {missing_in_action} exile. The mission appears in the area where they were lost and is named after them.", 
        "On success, the exile returns to the guild in a {resting}-eligible state. You will be asked whether to welcome them back or let them go.", 
        "Recently captured exiles return with their gear intact. Exiles recovered from older leads return stripped of equipment and in rough shape.", 
        "Rescues scale to roughly your exile's level, capped by the area's toughest mission, so they stay relevant as you progress."
    ], 
    "dismissed": [
        "[b]Dismissed[/b]", 
        "An exile you have released from your guild. Their equipment returns to the stash; they are no longer available for missions.", 
        "Dismissals are permanent. Memorial records preserve them, but they will not rejoin."
    ], 
    "food_ration": [
        "[b]Food Ration[/b]", 
        "A per-exile setting that controls how much {food} the exile consumes each {resting}.", 
        "Three options: {no_ration}, {full_ration}, {double_ration}.", 
        "Set rations from the Quartermaster window. Rations persist between days.", 
        "If you run short on food, exiles are automatically downgraded — Double drops to Full first, then Full drops to None (recovering exiles preserved last)."
    ], 
    "no_ration": [
        "[b]No Rations[/b]", 
        "The exile feeds themselves through foraging and scavenging.", 
        "They survive — but the effort costs them recovery time and {morale}.", 
        "  • Costs 0 {food}", 
        "  • {vitality} regen: +2.5% (vs +5% on {full_ration})", 
        "  • {morale}: −1 per consecutive day without rations (stacks; see {starvation})"
    ], 
    "full_ration": [
        "[b]Full Rations[/b]", 
        "Standard provisions. The default setting.", 
        "  • Costs 1 {food}", 
        "  • {vitality} regen: +5%", 
        "  • {morale}: +2"
    ], 
    "double_ration": [
        "[b]Double Rations[/b]", 
        "Lavish provisions — a small feast.", 
        "  • Costs 2 {food}", 
        "  • {vitality} regen: +7.5% (50% bonus over {full_ration})", 
        "  • {morale}: +3"
    ], 
    "starvation": [
        "[b]Starvation[/b]", 
        "Consecutive rests on {no_ration} stack a growing {morale} penalty.", 
        "Each stack adds −1 {morale} at the next rest.", 
        "Feeding the exile any ration immediately clears the stacks."
    ], 
    "potential_system": [
        "[b]Potential System[/b]", 
        "Each Potential influences the liklihood of seeing a type of {passive_skill}.", 
        "Hidden potentials can be discovered as the exile levels.", 
        "Passive Rarity is also affected by potential.", 
        "Potentials below 1.0 [i]reduce[/i] the chance of seeing those passives."
    ], 
    "passive_skill": [
        "[b]Passive Skill[/b]", 
        "Passive Skills can be chosen from random options when an exile levels up.", 
        "Passives come in three types: Basic, Notable, and Keystone.", 
        "Notables tend to have greater impact, while Keystones can be build defining.", 
        "Each type also have Rarities, affecting the chance of seeing them (as well as their power level).", 
        "Passive options each level are also affected by the {potential_system}."
    ], 
    "resistance": [
        "[b]Resistances[/b]", 
        "Reduces damage taken of the specified type by the % amount.", 
        "Capped at 75% by default.", 
        "Negative values increase damage taken instead."
    ], 
    "fire_resistance": [
        "[b]Fire Resistance[/b]", 
        "Reduces incoming {fire_damage} by the % shown.", 
        "See {resistance} for the cap rules and how resistances combine."
    ], 
    "cold_resistance": [
        "[b]Cold Resistance[/b]", 
        "Reduces incoming {cold_damage} by the % shown.", 
        "See {resistance} for the cap rules and how resistances combine."
    ], 
    "lightning_resistance": [
        "[b]Lightning Resistance[/b]", 
        "Reduces incoming {lightning_damage} by the % shown.", 
        "See {resistance} for the cap rules and how resistances combine."
    ], 
    "shock": [
        "[b]Shock[/b]", 
        "A debuff that causes the target to take [b]more damage[/b] from all sources for a few seconds.", 
        "[b]Chance:[/b] 10% base on any lightning hit. Critical strikes always Shock. {shock_chance} affixes / passives add additively.", 
        "[b]Magnitude:[/b] scales with hit damage vs target max life. A hit dealing 10% of max life as lightning produces the maximum unscaled magnitude (20% increased damage taken). Smaller hits scale down along a curve; shocks computing below 5% are discarded entirely.", 
        "[b]Duration:[/b] 4 seconds by default. Re-applying refreshes (does not stack — only one Shock active at a time).", 
        "[b]Scaling stats:[/b] {shock_effect} increases magnitude. {shock_duration} increases duration.", 
        "[b]Defending:[/b] {reduced_shock_effect} cuts magnitude (can prevent Shock entirely if pushed below the discard floor). {reduced_shock_duration} shortens the duration. {lightning_resistance} also reduces the source lightning damage feeding the magnitude curve.", 
        "Shock amplifies damage AFTER all other defences (armour, resistance, block, endurance), so it cuts through tanky targets cleanly."
    ], 
    "chill": [
        "[b]Chill[/b]", 
        "A debuff that [b]slows the target[/b] — both attack speed and movement speed — for a few seconds.", 
        "[b]Trigger:[/b] applies on [i]every[/i] cold hit — there is no chance roll. The only gate is the magnitude minimum below. The chance-based aspect of cold damage is [i]Freeze[/i] (separate ailment, not yet implemented), not Chill.", 
        "[b]Magnitude:[/b] scales with hit damage vs target max life. A hit dealing 10% of max life as cold produces the maximum unscaled magnitude (20% reduced action speed). Smaller hits scale down along a curve; chills computing below 5% are discarded entirely.", 
        "[b]Duration:[/b] 4 seconds by default. Re-applying only takes effect when STRONGER — a bigger chill takes over; a weaker re-chill is ignored (existing magnitude and duration keep ticking).", 
        "[b]Scaling stats:[/b] {chill_effect} increases magnitude. {chill_duration} increases duration.", 
        "[b]Defending:[/b] {reduced_chill_effect} cuts magnitude (can prevent Chill entirely if pushed below the discard floor). {reduced_chill_duration} shortens duration. {cold_resistance} also reduces the source cold damage feeding the magnitude curve.", 
        "Chill scales the target's effective action speed, slowing [i]both[/i] their attack interval and their live movement speed — a chilled target attacks slower AND walks slower."
    ], 
    "ignite": [
        "[b]Ignite[/b]", 
        "A [b]damage-over-time[/b] debuff that deals fire damage per second for several seconds. Damage applies to {energy_shield} first, then {life}.", 
        "[b]Chance:[/b] 0% base — only [b]critical strikes[/b] ignite by default. {ignite_chance} affixes / passives lift the baseline. Crits ALWAYS ignite regardless of chance.", 
        "[b]Damage:[/b] 90% of the hit's post-mitigation fire damage, per second. A 1000-fire hit produces ~900 fire dmg/sec for the full duration. Ignites computing below 1 dmg/sec are discarded.", 
        "[b]Duration:[/b] 4 seconds by default. [b]Duration scaling does NOT dilute damage[/b] — a longer ignite is a longer-lasting burn at the SAME DPS, dealing more total damage.", 
        "[b]Scaling stats:[/b] {ignite_effect} increases DPS. {ignite_duration} extends time. {damage_over_time} is a generic multiplier that applies to ALL DoTs (ignite, future bleed / poison).", 
        "[b]Defending:[/b] {fire_resistance} reduces the source fire damage feeding the DPS calc (so an ignite from a resisted hit ticks for less). {reduced_ignite_duration} shortens the burn — fewer ticks at the same DPS = less total damage.", 
        "Re-applying only takes effect when STRONGER — a bigger ignite takes over; the new applier owns kill credit if the target dies from the burn."
    ], 
    "impale": [
        "[b]Impale[/b]", 
        "A physical hit drives a fragment into the target, [b]storing[/b] a slice of the damage. The next elemental hit shatters every stored impale, adding their stored damage to that hit as bonus elemental damage.", 
        "[b]Trigger:[/b] [b]chance-gated[/b] on every physical hit that deals damage. Base chance is [b]0%[/b] — impale never procs without investment via {impale_chance} from passives, gear, or implicits. Critical strikes do [b]not[/b] auto-impale (unlike Shock or Ignite).", 
        "[b]Overflow chance:[/b] unlike other ailments, impale chance [b]above 100%[/b] applies extra stacks per hit. Each full 100% block guarantees one stack; the fractional remainder rolls once for one more. 250% chance → 2 guaranteed stacks + 50% chance for a 3rd. Deposited stacks still respect the cap (FIFO eviction applies).", 
        "[b]Capture:[/b] 10% of post-mitigation physical damage by default — applied [i]if[/i] the chance roll passes. A 20-phys hit at 100% chance parks a 2-flat impale on the target. Captures below 1 flat are dropped.", 
        "[b]Stacks:[/b] up to 3 simultaneous impales by default — adding one past the cap [b]evicts the oldest[/b] (FIFO). Multiple attackers can stack impales on the same target.", 
        "[b]Consumption:[/b] the next cold / fire / lightning hit on the target consumes [b]all[/b] impales at once. Their summed flat damage is split across whichever elements the hit contains (a pure-fire hit gets all of it as fire; a 50/50 fire+cold hit splits 50/50).", 
        "Consumed flat damage is added [b]post-crit[/b] (not multiplied by crit) but flows through normal mitigation — it gets resisted like any other damage of its type.", 
        "[b]Scaling stats:[/b] {impale_chance} raises proc rate. {impale_effect} raises capture %. {max_impales} raises the stack cap.", 
        "No duration. Impales persist on the target until consumed or until combat ends."
    ], 
    "poison": [
        "[b]Poison[/b]", 
        "A [b]chaos damage-over-time[/b] debuff that stacks [b]independently[/b] — every successful proc adds a new stack with its own DPS, duration, and applier. Multiple stacks tick together, so total damage scales linearly with stack count.", 
        "[b]Trigger:[/b] chance-gated on every {physical_damage} or {chaos_damage} hit. Base chance is [b]0%[/b] — poison never procs without {poison_chance} from passives, gear, or class bonuses. Critical strikes do [b]not[/b] auto-poison (unlike Shock or Ignite).", 
        "[b]Overflow chance:[/b] poison chance [b]above 100%[/b] applies extra stacks per hit (every full 100% guarantees one, remainder rolls for one more). 150% → 1 guaranteed + 50% chance for a 2nd.", 
        "[b]Damage:[/b] each stack ticks 30% of the hit's combined post-mitigation (physical + chaos) damage per second, as [b]chaos damage[/b]. A 100-phys + 50-chaos hit deposits a stack ticking 45 chaos dmg/s. Damage applies to {energy_shield} first, then {life}. Stacks below 0.5 dmg/s are discarded.", 
        "[b]Duration:[/b] 2 seconds by default. Each stack carries its own expiry — older stacks fade while newer ones keep ticking, so a heavy poison build maintains a smooth stack profile.", 
        "[b]Stacks:[/b] effectively unlimited (sanity-capped at 999). Heavy poison stacking is the design goal — five 50-dps stacks = 250 effective DPS on the target.", 
        "[b]Scaling stats:[/b] {poison_chance} raises proc rate. {poison_effect} raises per-stack DPS. {poison_duration} extends each stack's lifetime. {damage_over_time} multiplies all DoTs you apply (poison + ignite).", 
        "[b]Defending:[/b] {chaos_resistance} reduces the source chaos portion of the hit before it feeds the 30% DPS formula. {armour} similarly mitigates the physical portion. The resulting DoT itself bypasses chaos resistance — mitigation was baked in at apply time. {reduced_poison_duration} cuts each stack's lifetime, reducing total damage.", 
        "Each stack credits kill attribution to its own applier — the last stack to tick on the killing frame wins credit."
    ], 

    "shock_chance": [
        "[b]Shock Chance[/b]", 
        "Additional % chance for a {lightning_damage} hit to inflict {shock}. Stacks additively on top of the 10% base.", 
        "Critical strikes [b]always[/b] Shock regardless of this stat — they short-circuit the chance roll."
    ], 
    "shock_effect": [
        "[b]Shock Effect[/b]", 
        "% bonus to the magnitude of {shock}s you apply. A 20% base shock with +50% Shock Effect lands at 30% (target takes 30% more damage from all sources for the shock's duration).", 
        "Scales with hit damage relative to target max life — see {shock} for the full magnitude curve."
    ], 
    "shock_duration": [
        "[b]Shock Duration[/b]", 
        "% bonus to the duration of {shock}s you apply. Scales the 4s base.", 
        "Independent of magnitude — a longer shock keeps amplifying damage for longer at the same percentage."
    ], 
    "chill_effect": [
        "[b]Chill Effect[/b]", 
        "% bonus to the magnitude of {chill}s you apply. A 20% base chill (action speed reduction) with +50% Chill Effect lands at 30%.", 
        "Scales with cold hit damage vs target max life — see {chill} for the curve."
    ], 
    "chill_duration": [
        "[b]Chill Duration[/b]", 
        "% bonus to the duration of {chill}s you apply. Scales the 4s base.", 
        "Independent of magnitude — a longer chill keeps the target slowed for longer at the same %."
    ], 
    "ignite_chance": [
        "[b]Ignite Chance[/b]", 
        "Additional % chance for a {fire_damage} hit to inflict {ignite}. Stacks additively on top of the 0% base.", 
        "Critical strikes [b]always[/b] Ignite regardless of this stat — they short-circuit the chance roll."
    ], 
    "impale_chance": [
        "[b]Impale Chance[/b]", 
        "Additional % chance for a physical hit to apply {impale}. Stacks additively on top of the [b]0% base[/b] — without this stat, impale never procs.", 
        "Unlike {shock} and {ignite}, critical strikes do [b]not[/b] auto-impale — each hit must pass the roll on its own.", 
        "[b]Overflow scales:[/b] chance above 100% applies multiple stacks per hit — every full 100% guarantees one stack, the remainder rolls for one more. The only ailment where overflow chance keeps paying out."
    ], 
    "ignite_effect": [
        "[b]Ignite Effect[/b]", 
        "% bonus to the per-second [b]damage[/b] of {ignite}s you apply. Does NOT change duration — Ignite Duration is a separate, independent lever.", 
        "Composes additively with {damage_over_time}: final DPS = base × (1 + Ignite Effect%/100) × (1 + Damage over Time%/100)."
    ], 
    "ignite_duration": [
        "[b]Ignite Duration[/b]", 
        "% bonus to the duration of {ignite}s you apply. Scales the 4s base.", 
        "Does NOT dilute DPS — a longer ignite ticks at the same per-second rate, dealing more total damage."
    ], 
    "damage_over_time": [
        "[b]Damage over Time[/b]", 
        "Generic % bonus to all Damage-over-Time effects you apply. Scales {ignite} and {poison} today; future Bleed will also use this stat.", 
        "Composes additively with each ailment's own effect stat (Ignite Effect, Poison Effect, etc) — see {ignite} or {poison} for the formula."
    ], 
    "poison_chance": [
        "[b]Poison Chance[/b]", 
        "Additional % chance for a {physical_damage} or {chaos_damage} hit to inflict {poison}. Stacks additively on top of the 0% base — without this stat, poison never procs.", 
        "Unlike {shock} and {ignite}, critical strikes do [b]not[/b] auto-poison — each hit must pass the roll on its own.", 
        "[b]Overflow scales:[/b] chance above 100% applies multiple stacks per hit — every full 100% guarantees one stack, the remainder rolls for one more. Mirrors {impale_chance}'s behaviour."
    ], 
    "poison_effect": [
        "[b]Poison Effect[/b]", 
        "% bonus to the per-second [b]damage[/b] of {poison} stacks you apply. Does NOT change duration — Poison Duration is a separate, independent lever.", 
        "Composes additively with {damage_over_time}: per-stack DPS = base × (1 + Poison Effect%/100) × (1 + Damage over Time%/100). Each new stack is independent — boosting one doesn't retroactively scale existing stacks on the target."
    ], 
    "poison_duration": [
        "[b]Poison Duration[/b]", 
        "% bonus to the duration of {poison} stacks you apply. Scales the 2s base.", 
        "Does NOT dilute DPS — a longer-lasting stack ticks at the same per-second rate, dealing more total damage over its lifetime. Each stack carries its own expiry independently."
    ], 
    "reduced_poison_duration": [
        "[b]Reduced Poison Duration[/b]", 
        "% reduction to the duration of {poison} stacks applied to you. Scales the post-attacker-scaling duration down — a shorter stack lifetime deals less total damage at the same per-second rate.", 
        "Stacks additively, clamped 0–100. Note: Poison DPS reduction lives on {chaos_resistance} and {armour}, which scale the source chaos / physical damage feeding the 30% DPS formula — this stat is the orthogonal duration lever."
    ], 
    "impale_effect": [
        "[b]Impale Effect[/b]", 
        "Additional % of post-mitigation {physical_damage} captured into {impale} stacks. Stacks additively on top of the 10% base capture.", 
        "Higher Impale Effect = bigger flat damage stored on each stack = more punishing elemental follow-up hits."
    ], 
    "max_impales": [
        "[b]Maximum Impales[/b]", 
        "Additional {impale} stacks you can park on a target. Stacks additively on top of the 3 base.", 
        "Adding past your cap [b]FIFO-evicts the oldest[/b] stack. Higher cap = more stored damage to release on the next elemental hit."
    ], 

    "reduced_shock_effect": [
        "[b]Reduced Shock Effect[/b]", 
        "% reduction to the magnitude of {shock}s applied to you. Applied AFTER the attacker's Shock Effect scaling — a high enough reduction pushes the magnitude below the discard floor and the shock fails to land at all.", 
        "Stacks additively across all sources, clamped 0–100. At 100%, you are effectively immune to Shock magnitude."
    ], 
    "reduced_shock_duration": [
        "[b]Reduced Shock Duration[/b]", 
        "% reduction to the duration of {shock}s applied to you. Scales the post-attacker-scaling duration down.", 
        "Stacks additively, clamped 0–100. At 100%, any Shock that lands expires immediately."
    ], 
    "reduced_chill_effect": [
        "[b]Reduced Chill Effect[/b]", 
        "% reduction to the magnitude of {chill}s applied to you. Applied AFTER the attacker's Chill Effect scaling — a high enough reduction can push the magnitude below the discard floor and prevent the chill from landing.", 
        "Stacks additively, clamped 0–100. At 100%, no Chill will ever slow you."
    ], 
    "reduced_chill_duration": [
        "[b]Reduced Chill Duration[/b]", 
        "% reduction to the duration of {chill}s applied to you. Scales the post-attacker-scaling duration down.", 
        "Stacks additively, clamped 0–100. At 100%, any Chill that lands expires immediately."
    ], 
    "reduced_ignite_duration": [
        "[b]Reduced Ignite Duration[/b]", 
        "% reduction to the duration of {ignite}s applied to you. Scales the post-attacker-scaling duration down — a shorter burn deals less total damage at the same per-second rate.", 
        "Stacks additively, clamped 0–100. Note: Ignite DPS reduction lives on {fire_resistance}, which scales the source fire damage feeding the ignite calculation — this stat is the orthogonal duration lever."
    ], 
    "chaos_resistance": [
        "[b]Chaos Resistance[/b]", 
        "Reduces incoming {chaos_damage} by the % shown.", 
        "Chaos resistance follows the same cap rules as the other {resistance}s, but chaos damage bypasses {energy_shield}."
    ], 
    "armour": [
        "[b]Armour[/b]", 
        "Reduces incoming {physical_damage} via the formula  reduction = ratio / (ratio + 10),  where ratio = Armour / hit damage.", 
        "Effective against many small hits, weak against a few big ones. Reduction is capped at 90%.", 
        "Local % armour affixes on a chest, helm, etc. scale only the source item's own base armour."
    ], 
    "evasion": [
        "[b]Evasion[/b]", 
        "Chance to avoid an incoming attack, rolled twice per hit:", 
        "  • Both rolls succeed → [color=#33ccff]Evaded[/color] (no damage)", 
        "  • One roll succeeds → [color=#33ccff]Glancing[/color] (half damage)", 
    ], 
    "energy_shield": [
        "[b]Energy Shield[/b]", 
        "A second pool of {life} that absorbs incoming damage before life is touched.", 
        "{chaos_damage} bypasses Energy Shield and hits {life} directly.", 
        "[i](PLACEHOLDER — Energy Shield is defined on stats but its regen / recharge behaviour is still being implemented.)[/i]"
    ], 
    "block": [
        "[b]Block[/b]", 
        "[b]Block Chance[/b] gives a chance reduce the damage of incoming hits.", 
        "On success, [b]Block Amount[/b] is subtracted from the damage before any other defences apply.", 
    ], 
    "endurance": [
        "[b]Endurance[/b]", 
        "While {life} is at or below the [b]Endurance Threshold[/b] (% of max life), all incoming damage is reduced by the [b]Endurance Amount[/b] (%).", 
        "Threshold of 25% with 10% amount means: below quarter life, take 10% less damage from everything."
    ], 
    "attack_speed": [
        "[b]Attack Speed[/b]", 
        "Base attacks per second. Effective speed in combat is [code]Attack Speed × Action Speed[/code].", 
        "Equipping a weapon [b]replaces[/b] the exile's base Attack Speed with the weapon's value — it does not stack additively.", 
        "% increased Attack Speed from passives, traits, and non-local affixes scales the final number."
    ], 
    "critical_strike": [
        "[b]Critical Strike[/b]", 
        "On each hit, roll against [b]Crit Chance[/b]. On success, the hit's damage is multiplied by [b]Crit Multi[/b] (e.g. 150% = 1.5×).", 
        "Like Attack Speed, a weapon's base Crit Chance [b]replaces[/b] the exile's base value; modifiers then scale it.", 
    ], 
    "second_wind": [
        "[b]Second Wind[/b]", 
        "When a hit drops the exile from above the [b]Second Wind Threshold[/b] to below it (without killing them), roll against [b]Second Wind Chance[/b].", 
        "On success, the exile is instantly healed to [b]Second Wind Amount[/b] % of max {life}.", 
        "Only one Second Wind can trigger per combat.", 
        "Second Wind's recovery does not consume {vitality}."
    ], 
    "life_regen": [
        "[b]Life Regeneration[/b]", 
        "Passively restores the specified amount of {life} each round of combat.", 
        "Consumes {vitality} 1:1 when it heals."
    ], 
    "life_leech": [
        "[b]Life Leech[/b]", 
        "Restores {life} based on a % of damage dealt when attacking enemies.", 
        "Consumes {vitality} 1:1 when it heals."
    ], 
    "life_gain_on_hit": [
        "[b]Life Gain on Hit[/b]", 
        "Restores a flat amount of {life} whenever you hit an enemy.", 
        "Consumes {vitality} 1:1 when it heals."
    ], 
    "traits": [
        "[b]Traits[/b]", 
        "Permanent characteristics that shape an exile's stats, behaviour, or growth.", 
        "Three categories:", 
        "  • [b]Background[/b] — given at hire; flavour + baseline modifiers", 
        "  • [b]Learned[/b] — acquired through gameplay (level-ups, events)", 
        "  • [b]Scar[/b] — earned from defeats; usually a penalty, sometimes a story (see {scarred})", 
        "Each trait has a rarity tier (Common / Uncommon / Rare / Legendary) shown by its border colour. Legendary traits are build-defining."
    ], 
    "potential_unknown": [
        "[b]Unknown Potential[/b]", 
        "A hidden {potential_system} entry — its tag and value are unknown until discovered.", 
        "Hidden potentials [b]still affect[/b] level-up growth — they are not 'off', just unseen.", 
        "Each time the exile levels up, there is a chance to reveal one of their hidden potentials.", 
        "[i]A high hidden potential can quietly carry an exile; a low one can quietly drag them down.[/i]"
    ], 
    "scouting": [
        "[b]Scouting[/b]", 
        "Scouting reveals new {area} connections, Events, and Missions.", 
        "Scouting can also reveal limited opportunity missions randomly.", 
        "Ambushes and other dangerous events can be mitigated by Exile parties with good Scouting ability."
    ], 
    "area": [
        "[b]Area[/b]", 
        "A location on the world map containing Missions and other opportunities.", 
        "Each Area has it's own {scouting} progression and unique missions."
        ], 

    "survival": [
        "[b]Survival[/b]", 
        "Improves the exile's ability to weather harsh conditions on missions — foraging, hazards, environmental damage.", 
        "[i](PLACEHOLDER — surfaced on certain mission types; broader survival mechanics in progress.)[/i]"
    ], 
    "scavenging": [
        "[b]Scavenging[/b]", 
        "Boosts the quality and quantity of loot the exile finds on missions.", 
        "[i](PLACEHOLDER — applied by mission loot rolls; full system in progress.)[/i]"
    ], 
    "movement_speed": [
        "[b]Movement Speed[/b]", 
        "% modifier to base movement rate in combat. Effective movement is [code]BASE × (1 + movement%) × action_speed[/code].", 
        "Also surfaces in some out-of-combat mission events (pursuit, retreats, escapes)."
    ], 
    "action_speed": [
        "[b]Action Speed[/b]", 
        "Global multiplier on everything the exile does in combat — both attacks and movement.", 
        "1.0 = normal. 1.1 = 10% faster everything. 0.0 = frozen (cannot act).", 
        "Applied [b]after[/b] {attack_speed} and movement calculations, so it scales the final number."
    ], 
    "morale_modifiers": [
        "[b]Morale Modifiers[/b]", 
        "Per-exile tuning on how {morale} swings up and down:", 
        "  • [b]Morale Gain Bonus[/b] — % bonus to all morale [b]gained[/b] (can be negative)", 
        "  • [b]Morale Loss Resistance[/b] — % reduction to all morale [b]losses[/b] (negative = worse)", 
        "  • [b]Victory Morale Bonus[/b] — flat morale gained on every mission victory", 
        "  • [b]Well-Fed Rest Bonus[/b] — flat extra morale on a fed {resting}"
    ], 
    "physical_damage": [
        "[b]Physical Damage[/b]", 
        "Mitigated by {armour}.", 
        "The default damage type for most weapons and unarmed strikes."
    ], 
    "fire_damage": [
        "[b]Fire Damage[/b]", 
        "Mitigated by {fire_resistance}. Bypassed by {armour}."
    ], 
    "cold_damage": [
        "[b]Cold Damage[/b]", 
        "Mitigated by {cold_resistance}. Bypassed by {armour}."
    ], 
    "lightning_damage": [
        "[b]Lightning Damage[/b]", 
        "Mitigated by {lightning_resistance}. Bypassed by {armour}."
    ], 
    "chaos_damage": [
        "[b]Chaos Damage[/b]", 
        "Mitigated by {chaos_resistance}. Bypasses {armour} [b]and[/b] {energy_shield} — hits {life} directly."
    ], 
    "recovering": [
        "[b]Recovering[/b]", 
        "This exile is in forced rest and cannot be sent on missions until they are fully healed.", 
        "Enters this state when they return from a mission with missing {life}, or as a consequence of being {downed} in combat.", 
        "At the end of each day, {resting} regenerates {vitality} which is immediately converted into {life} at the town heal rate of 1 Vitality per 10 Life.", 
        "They return to [b]Idle[/b] status on the next day after {life} is fully restored."
    ], 
    "downed": [
        "[b]Downed[/b]", 
        "Incapacitated during combat — the fight ends for them.", 
        "At mission end downed Exiles can suffer defeat outcomes, such as {battered}.", 
        "Repeat defeats accumulate {scarred} traits, increasing the risk of death when Downed.", 
        "Survivors return to the guild and enter {recovering}.", 
    ], 
    "battered": [
        "[b]Battered[/b]", 
        "A defeat outcome — the Exile took a serious beating and lost a chunk of {vitality} and {morale}.", 
        "Battered exiles enter {recovering} for several days before they can be sent on a mission again.", 
        "Rolled after being {downed} in combat. Less severe than receiving a {scarred} mark, but still a setback.", 
    ], 
    "scarred": [
        "[b]Scarred[/b]", 
        "Scars are permanent traits earned from being {downed} in combat — each one a story written on the exile's body or mind.", 
        "Some scars are physical (limbs lost, eyes ruined); others are mental (fears, compulsions). Most carry a stat penalty or behavioral quirk.", 
        "Crucially, every accumulated scar increases the chance of [b]death[/b] on the next defeat. A heavily scarred exile is on borrowed time.", 
        "[i]Hover the exile's character sheet to see the specific scars they carry.[/i]", 
    ], 
    "damage_scaling": [
        "[b]Damage Scaling[/b]", 
        "Total % increased damage of this type, summed from passives, traits, conditional bonuses, and non-local gear affixes.", 
        "All sources stack [b]additively[/b] — a +30% and a +20% source combine to +50% increased, not ×1.5 × ×1.2.", 
        "Per-type rows pick up composite tags: {fire_damage} / {cold_damage} / {lightning_damage} rows also include 'Elemental Damage' and 'Damage' modifiers; {physical_damage} and {chaos_damage} rows include 'Damage' modifiers.", 
        "[b]Excludes[/b] the local '% Physical Damage' affix on weapons (already baked into the weapon's contribution) and weapon base damage rolls."
    ], 
    "ailment_immunities": [
        "[b]Ailment Immunity[/b]", 
        "Listed ailments cannot apply to this exile — the application is silently dropped before any magnitude, duration, or roll is checked.", 
        "Sources: passives, gear affixes, monster traits, and conditional effects.", 
        "Immunity only blocks the [i]ailment[/i] itself. The hit's base damage (e.g. the {fire_damage} that would have fed an {ignite}) still applies in full through normal mitigation."
    ]
}

static func get_tooltip(key: String) -> Array[String]:
    if TOOLTIPS.has(key):
        var result: Array[String] = []
        result.assign(TOOLTIPS[key])
        return result
    return ["[color=red]Unknown concept: %s[/color]" % key]
