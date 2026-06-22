import { chromium } from "playwright";
import { pathToFileURL } from "node:url";
import path from "node:path";

const file = path.resolve(process.cwd(), "../Docs/roadmap-board.html");
const url = pathToFileURL(file).href;

const browser = await chromium.launch();
const page = await browser.newPage({ viewport: { width: 1500, height: 1000 } });
const errors = [];
page.on("console", m => { if (m.type() === "error") errors.push(m.text()); });
page.on("pageerror", e => errors.push("PAGEERROR: " + e.message));

await page.goto(url, { waitUntil: "networkidle" });

const views = [
  ["board", "🗂 Board"],
  ["gantt", "📊 Timeline"],
  ["deps", "🔗 Dependencies"],
  ["quad", "⚡ Quick Wins"],
];

for (const [v, label] of views) {
  await page.click(`.tab[data-view="${v}"]`);
  await page.waitForTimeout(300);
  await page.screenshot({ path: `../Docs/_board-${v}.png`, fullPage: true });
}

// sanity assertions
const kpiPct = await page.textContent("#kpis .kpi.pct b");
const boardCols = await page.$$eval("#view-board .col", c => c.length);
const ganttRows = await page.$$eval("#view-gantt .grow", r => r.length);
const depNodes = await page.$$eval("#view-deps .node", n => n.length);
const quadDots = await page.$$eval("#view-quad .dotnode", d => d.length);
const nowFlag = await page.$("#view-gantt .nowflag") ? "yes" : "NO";

console.log(JSON.stringify({
  kpiPct, boardCols, ganttRows, depNodes, quadDots, nowFlag,
  consoleErrors: errors,
}, null, 2));

await browser.close();
