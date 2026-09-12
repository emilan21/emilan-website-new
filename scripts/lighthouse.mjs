import fs from "node:fs/promises";
import lighthouse from "lighthouse";
import * as chromeLauncher from "chrome-launcher";

const categories = ["performance", "accessibility", "best-practices", "seo"];
const chrome = await chromeLauncher.launch({ chromeFlags: ["--headless", "--no-sandbox"] });

try {
  const result = await lighthouse("http://localhost:8790/", {
    port: chrome.port,
    output: "json",
    logLevel: "info",
    onlyCategories: categories,
    formFactor: "desktop",
    screenEmulation: {
      mobile: false,
      width: 1350,
      height: 940,
      deviceScaleFactor: 1,
      disabled: false,
    },
    throttlingMethod: "provided",
  });
  if (!result) throw new Error("Lighthouse did not return a report");

  await fs.mkdir(".lighthouseci", { recursive: true });
  await fs.writeFile(".lighthouseci/report.json", result.report);

  let failed = false;
  for (const name of categories) {
    const score = result.lhr.categories[name]?.score ?? 0;
    console.log(`${name}: ${Math.round(score * 100)}`);
    if (score < 0.95) failed = true;
  }
  if (failed) throw new Error("One or more Lighthouse category scores are below 95");
} finally {
  await chrome.kill();
}
