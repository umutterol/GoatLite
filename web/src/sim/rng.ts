/* Deterministic seeded PRNG (mulberry32). Same seed → identical run.
   Load-bearing for the Phase-2 leaderboard (server re-simulation). */
export class Rng {
  private s: number
  constructor(seed: number) { this.s = seed >>> 0 }
  next(): number {
    this.s = (this.s + 0x6d2b79f5) | 0
    let t = Math.imul(this.s ^ (this.s >>> 15), 1 | this.s)
    t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296
  }
  chance(p: number): boolean { return this.next() < p }
  range(min: number, max: number): number { return min + this.next() * (max - min) }
  int(min: number, max: number): number { return Math.floor(this.range(min, max + 1)) }
  pick<T>(arr: T[]): T { return arr[Math.floor(this.next() * arr.length)] }
}

export function seedFromString(str: string): number {
  let h = 2166136261 >>> 0
  for (let i = 0; i < str.length; i++) { h ^= str.charCodeAt(i); h = Math.imul(h, 16777619) }
  return h >>> 0
}
