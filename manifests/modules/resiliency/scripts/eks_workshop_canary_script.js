const synthetics = require("Synthetics");
const log = require("SyntheticsLogger");

const pageLoadBlueprint = async function () {
  const PAGE_LOAD_TIMEOUT = 30;
  const URL = process.env.INGRESS_URL || "http://localhost"; // Use environment variable or fallback

  let page = await synthetics.getPage();

  await synthetics.executeStep("Navigate to " + URL, async function () {
    const response = await page.goto(URL, {
      waitUntil: "domcontentloaded",
      timeout: PAGE_LOAD_TIMEOUT * 1000,
    });

    // Verify the page loaded successfully
    if (response.status() !== 200) {
      throw new Error(`Failed to load page. Status code: ${response.status()}`);
    }
  });

  await synthetics.executeStep("Verify page content", async function () {
    const pageTitle = await page.title();
    log.info("Page title: " + pageTitle);
  });
};

exports.handler = async () => {
  return await pageLoadBlueprint();
};
