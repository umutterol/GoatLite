# GOAT Lite — UI

Browser UI for **GOAT Lite: Mythic+ Manager** (see `../Docs/GDD.md`). Aged-scroll
Warcraft aesthetic — parchment, gilt-gold frames, oiled leather — built for a fixed
**16:9** stage. No purple in the chrome.

## Stack
- **Vite + React + TypeScript**, **Tailwind CSS v4** (`@tailwindcss/vite`).
- UI component base: **[warcraftcn-ui](https://github.com/TheOrcDev/warcraftcn-ui)**
  (shadcn registry) — `Button`, `Card`, `Badge`, `Tooltip` and the rest live in
  `src/components/ui/warcraftcn/` with their shared `styles/warcraft.css`.

## Run
```bash
npm install      # if not already
npm run dev      # http://localhost:5173
npm run build    # production bundle in dist/
```

## Layout
- `src/components/kit.tsx` — `Stage` (1280×720 design, scaled to fit, letterboxed),
  `Icon` (tintable game-icons mask), `Portrait`, `MoraleBar`, `Pips`, chips, panels.
- `src/components/TopBar.tsx` — leather command bar: title, week affixes, currencies, nav.
- `src/screens/` — `GuildHall` (roster + keystone), `RunSetup` (key & tactics — interactive
  aggression dial + tactics-point pips + live "what will go wrong"), `CombatReplay`
  (in-universe event log + parse overlay + death report).
- `src/data/game.ts` — sample roster/specs/affixes/bosses/log, modeled from the GDD.
- `src/index.css` — the aged-parchment theme (palette, fonts, paper texture, frame-border
  utilities, WoW item-quality colours, the 16:9 stage).

## Assets (sourced from the web)
- `public/warcraftcn/` — frame/avatar/**hero-portrait** webp from warcraftcn.com.
- `public/icons/` — 39 **game-icons.net** SVGs (CC BY 3.0) for specs/affixes/tactics/
  stats/currencies, recoloured to `currentColor` so they tint to the theme.

Fonts: **Cinzel Decorative** (display), **Cinzel** (headings), **IM Fell English** /
**EB Garamond** (body), via Google Fonts.
