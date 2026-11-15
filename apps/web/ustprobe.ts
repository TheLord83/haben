import { computeVatFigures, loadFrequencies, preflight } from "./src/server/modules/umsatzsteuer/index.ts";
import { filingsFor } from "./src/server/modules/umsatzsteuer/vermerk.ts";
import { returnsForPeriod } from "./src/server/modules/umsatzsteuer/vat.ts";
import { currentMonth, periodKey, recentFilingPeriods } from "@haben/core";

const now = new Date();
const settings = await loadFrequencies();
const today = currentMonth(now);
console.log("heute:", JSON.stringify(today));

let gewaehlt: { year: number; month: number } | null = null;
for (const period of recentFilingPeriods(settings, today)) {
  const returns = await returnsForPeriod(period);
  const filings = await filingsFor(returns.map((r) => r.id));
  const abgegeben = filings.length > 0 || returns.some((r) => r.status === "sent");
  console.log(periodKey(period), "| Erklärungen:", returns.length, "| Vermerke:", filings.length, "| abgegeben:", abgegeben);
  if (!abgegeben && !gewaehlt) {
    gewaehlt = period;
    break;
  }
}
console.log("==> /umsatzsteuer öffnet:", gewaehlt ? periodKey(gewaehlt) : "(Fallback)");

if (gewaehlt) {
  const figures = await computeVatFigures(gewaehlt);
  const issues = await preflight(gewaehlt, figures);
  console.log("Vorprüfung", periodKey(gewaehlt) + ":");
  for (const i of issues) console.log("  -", i.tone, i.text, "->", i.link, JSON.stringify(i.search ?? null));
  console.log("Kz 66:", (figures.kz66 / 100).toFixed(2), "€ | Kz 83:", (figures.kz83 / 100).toFixed(2), "€");
}
process.exit(0);
