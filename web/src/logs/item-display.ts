/* C.5 — display-only helpers for the WoW-style item tooltip.
   Weapon damage is FAKED (cosmetic): it is derived deterministically from ilvl + speed + uid and never feeds the
   combat sim (the sim sources power from effIlvl, see item-stats.ts). Same for the type/hands/material lines and the
   authored flavor/equip/sellPrice "possibility" fields — none of this touches balance. */
import { content } from "@/content"
import type { GearItem } from "@/state/game-store"

/* Fallback attack speeds (seconds) if a weapon has no authored `speed`. */
const WEAPON_SPEED: Record<string, number> = {
  Dagger: 1.8, "Fist Weapon": 2.0, Sword: 2.6, Mace: 2.6, Flail: 2.7, Axe: 3.6,
  Polearm: 3.6, Staff: 3.3, Bow: 2.8, Crossbow: 2.8, Gun: 2.8, Wand: 1.5,
}
const RANGED = new Set(["Bow", "Crossbow", "Gun", "Wand"])
const K_DPS = 0.9   // fake DPS per item level — tune here; display-only

/* Tiny deterministic 0..1 hash (FNV-1a + a finalizer). Not the sim RNG — only varies the damage spread per item. */
function hash01(s: string): number {
  let h = 2166136261 >>> 0
  for (let i = 0; i < s.length; i++) { h ^= s.charCodeAt(i); h = Math.imul(h, 16777619) }
  h ^= h >>> 13; h = Math.imul(h, 0x5bd1e995); h ^= h >>> 15
  return (h >>> 0) / 4294967296
}

/* Light fallback: read a weapon type out of the free-text `note` when no `weaponType` is authored. */
function weaponTypeFromNote(note?: string): string | null {
  if (!note) return null
  const n = note.toLowerCase()
  if (n.includes("dagger")) return "Dagger"
  if (n.includes("fist")) return "Fist Weapon"
  if (n.includes("staff") || n.includes("stave")) return "Staff"
  if (n.includes("bow")) return "Bow"
  if (n.includes("axe")) return "Axe"
  if (n.includes("flail")) return "Flail"
  if (n.includes("mace")) return "Mace"
  if (n.includes("sword")) return "Sword"
  if (n.includes("polearm")) return "Polearm"
  return null
}

export interface WeaponInfo {
  handLabel: string   // "One-Hand" | "Two-Hand" | "Ranged"
  weaponType: string  // "Dagger", "Axe", …
  speed: number
  min: number         // faked damage range
  max: number
  dps: number         // faked damage-per-second (already matches min/max & speed)
}

/** Faked weapon line for a weapon-slot item; null for armor/trinkets or weapons with no resolvable type. */
export function weaponInfo(item: GearItem): WeaponInfo | null {
  if (item.slot !== "weapon") return null
  const base = content.items.get(item.baseId)
  const weaponType = base?.weaponType ?? weaponTypeFromNote(base?.note)
  if (!weaponType) return null
  const hands = base?.hands ?? (/(two-hand|two hand|greatstaff|staff|polearm)/i.test(base?.note ?? "") ? 2 : 1)
  const speed = base?.speed ?? WEAPON_SPEED[weaponType] ?? (hands === 2 ? 3.4 : 2.4)
  const handLabel = RANGED.has(weaponType) ? "Ranged" : hands === 2 ? "Two-Hand" : "One-Hand"
  const avg = Math.round(item.ilvl * K_DPS) * speed
  const min = Math.round(avg * (0.80 + hash01(item.uid + "a") * 0.05))   // ~0.80–0.85 × avg
  const max = Math.round(avg * (1.18 + hash01(item.uid + "b") * 0.05))   // ~1.18–1.23 × avg
  return { handLabel, weaponType, speed, min, max, dps: (min + max) / 2 / speed }
}

/** Armor material ("Plate"/"Leather"/"Cloth"/"Mail") read from the `note`; null if unknown or not armor. */
export function armorMaterial(note?: string): string | null {
  if (!note) return null
  const first = note.trim().split(/[\s(]/)[0].toLowerCase()
  const map: Record<string, string> = { plate: "Plate", mail: "Mail", leather: "Leather", cloth: "Cloth" }
  return map[first] ?? null
}

/** Split a copper amount into gold / silver / copper for the WoW-style sell-price line. */
export function splitPrice(copper: number): { g: number; s: number; c: number } {
  return { g: Math.floor(copper / 10000), s: Math.floor((copper % 10000) / 100), c: copper % 100 }
}
