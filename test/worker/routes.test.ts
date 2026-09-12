import { exports as workerExports } from "cloudflare:workers";
import { describe, expect, it } from "vitest";
import { handleRequest } from "../../src/index";

type JsonBody = { error?: string; status?: string };

async function json(response: Response): Promise<JsonBody> {
  return response.json<JsonBody>();
}

describe("Worker routes", () => {
  it("returns health with a stable JSON schema and security headers", async () => {
    const response = await workerExports.default.fetch("https://example.com/api/health");

    expect(response.status).toBe(200);
    expect(await json(response)).toEqual({ status: "ok" });
    expect(response.headers.get("Content-Type")).toContain("application/json");
    expect(response.headers.get("Cache-Control")).toBe("no-store");
    expect(response.headers.get("Access-Control-Allow-Origin")).toBeNull();
    expect(response.headers.get("Strict-Transport-Security")).toBe("max-age=31536000");
    expect(response.headers.get("X-Content-Type-Options")).toBe("nosniff");
    expect(response.headers.get("X-Frame-Options")).toBe("DENY");
  });

  it("rejects unsupported health methods", async () => {
    const response = await workerExports.default.fetch("https://example.com/api/health", {
      method: "POST",
    });

    expect(response.status).toBe(405);
    expect(response.headers.get("Allow")).toBe("GET");
    expect(await json(response)).toEqual({ error: "Method not allowed" });
  });

  it("returns JSON 404 responses for every other API route", async () => {
    const requests = [
      new Request("https://example.com/api"),
      new Request("https://example.com/api/visits"),
      new Request("https://example.com/api/visits", { method: "POST" }),
      new Request("https://example.com/api/missing"),
    ];
    for (const request of requests) {
      const response = await workerExports.default.fetch(request);
      expect(response.status).toBe(404);
      expect(response.headers.get("Content-Type")).toContain("application/json");
      expect(await json(response)).toEqual({ error: "Not found" });
    }
  });

  it("serves static assets through the assets binding", async () => {
    const response = await workerExports.default.fetch("https://example.com/");

    expect(response.status).toBe(200);
    expect(response.headers.get("Content-Type")).toContain("text/html");
    expect(response.headers.get("X-Content-Type-Options")).toBe("nosniff");
    expect(response.headers.get("X-Frame-Options")).toBe("DENY");
    const csp = response.headers.get("Content-Security-Policy") ?? "";
    expect(csp).toContain("https://static.cloudflareinsights.com");
    expect(csp).toContain("https://cloudflareinsights.com");
    expect(await response.text()).toContain("<title>Eric Milan");
  });

  it("returns a generic JSON error when an asset request fails", async () => {
    const failingAssets = {
      fetch(): Promise<Response> {
        return Promise.reject(new Error("upstream details"));
      },
    };
    const response = await handleRequest(
      new Request("https://example.com/"),
      {} as Env,
      failingAssets,
    );

    expect(response.status).toBe(500);
    expect(await json(response)).toEqual({ error: "Internal server error" });
  });
});
