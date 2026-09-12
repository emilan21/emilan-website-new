import { defineConfig } from "cypress";

export default defineConfig({
  video: false,
  screenshotOnRunFailure: false,
  retries: 0,
  e2e: {
    baseUrl: "http://localhost:8790",
    specPattern: "test/cypress/e2e/**/*.cy.js",
    supportFile: "test/cypress/support/e2e.js",
  },
});
