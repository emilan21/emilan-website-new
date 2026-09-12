describe("portfolio", () => {
  it("loads without a public visitor count, analytics API call, application errors, or third-party fonts", () => {
    let fontAwesomeRequests = 0;
    let visitsRequests = 0;
    cy.intercept("*fontawesome*", () => { fontAwesomeRequests += 1; });
    cy.intercept("/api/visits", () => { visitsRequests += 1; });
    cy.visit("/", {
      onBeforeLoad(win) { cy.stub(win.console, "error").as("consoleError"); },
    });
    cy.get("#visits").should("not.exist");
    cy.contains("Approximate visitor sessions").should("not.exist");
    cy.get("@consoleError").should("not.have.been.called");
    cy.then(() => {
      expect(fontAwesomeRequests).to.equal(0);
      expect(visitsRequests).to.equal(0);
    });
  });

  it("supports keyboard and mouse navigation without hiding targets", () => {
    cy.visit("/");
    cy.get(".skip-link").focus().should("be.visible").and("have.attr", "href", "#main-content");
    cy.get('.site-nav a[href="#projects"]').click();
    cy.location("hash").should("eq", "#projects");
    cy.wait(750);
    cy.get("#projects").then(($section) => {
      expect($section[0].getBoundingClientRect().top).to.be.greaterThan(63);
    });
  });

  it("gives every icon link an accessible name", () => {
    cy.visit("/");
    cy.get("a:has(svg)").each(($link) => {
      const name = $link.attr("aria-label") || $link.text().trim();
      expect(name).not.to.equal("");
    });
  });

  it("serves a helpful 404 page with a working home link", () => {
    cy.request({ url: "/missing-page", failOnStatusCode: false }).its("status").should("eq", 404);
    cy.visit("/missing-page", { failOnStatusCode: false });
    cy.contains("That page is out of range");
    cy.contains("a", "Return home").click();
    cy.location("pathname").should("eq", "/");
  });

  for (const viewport of [[390, 844], [768, 1024], [1440, 900]]) {
    it(`has no horizontal overflow at ${viewport[0]}px`, () => {
      cy.viewport(viewport[0], viewport[1]);
      cy.visit("/");
      cy.document().then((document) => {
        expect(document.documentElement.scrollWidth).to.equal(document.documentElement.clientWidth);
      });
    });
  }

  it("has no serious or critical Axe violations", () => {
    cy.visit("/");
    cy.injectAxe({ axeCorePath: "node_modules/axe-core/axe.min.js" });
    cy.checkA11y(undefined, { includedImpacts: ["serious", "critical"] });
  });
});
