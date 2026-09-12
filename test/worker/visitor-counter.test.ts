import { env, exports as workerExports } from "cloudflare:workers";
import { reset } from "cloudflare:test";
import { beforeEach, describe, expect, it } from "vitest";
import { handleRequest } from "../../src/index";

type JsonBody = { count?: number; error?: string; status?: string };

async function json(response: Response): Promise<JsonBody> {
  return response.json<JsonBody>();
}

beforeEach(async () => {
  await reset();
});

describe("VisitorCounter Durable Object", () => {
  it("initializes once and persists its configured value", async () => {
    const stub = env.VISITOR_COUNTER.getByName("global");
    expect(await stub.getCount()).toBe(3);
    expect(await stub.increment()).toBe(4);
    expect(await stub.getCount()).toBe(4);
  });

  it("serializes concurrent increments without losing updates", async () => {
    const stub = env.VISITOR_COUNTER.getByName("global");
    const results = await Promise.all(Array.from({ length: 50 }, () => stub.increment()));
    expect(new Set(results).size).toBe(50);
    expect(await stub.getCount()).toBe(53);
  });
});

describe("visitor API", () => {
  it("returns health and a stable JSON schema", async () => {
    const health = await workerExports.default.fetch("https://example.com/api/health");
    expect(health.status).toBe(200);
    expect(await json(health)).toEqual({ status: "ok" });

    const visits = await workerExports.default.fetch("https://example.com/api/visits");
    expect(visits.status).toBe(200);
    expect(await json(visits)).toEqual({ count: 3 });
    expect(visits.headers.get("Access-Control-Allow-Origin")).toBeNull();
    expect(visits.headers.get("Strict-Transport-Security")).toBe("max-age=31536000");
    expect(visits.headers.get("X-Frame-Options")).toBe("DENY");
  });

  it("increments once per valid cookie window and always returns the count", async () => {
    const first = await workerExports.default.fetch("https://example.com/api/visits", { method: "POST" });
    expect(await json(first)).toEqual({ count: 4 });
    const setCookie = first.headers.get("Set-Cookie") ?? "";
    expect(setCookie).toContain("visitor_counted=1");
    expect(setCookie).toContain("Max-Age=86400");
    expect(setCookie).toContain("Secure");
    expect(setCookie).toContain("HttpOnly");
    expect(setCookie).toContain("SameSite=Lax");

    const repeat = await workerExports.default.fetch("https://example.com/api/visits", {
      method: "POST",
      headers: { Cookie: "visitor_counted=1" },
    });
    expect(await json(repeat)).toEqual({ count: 4 });
    expect(repeat.headers.get("Set-Cookie")).toBeNull();

    const get = await workerExports.default.fetch("https://example.com/api/visits", {
      headers: { Cookie: "visitor_counted=1" },
    });
    expect(await json(get)).toEqual({ count: 4 });
    expect(get.headers.get("X-Visitor-Counted")).toBe("true");
  });

  it("returns 405 responses with Allow headers", async () => {
    const visits = await workerExports.default.fetch("https://example.com/api/visits", { method: "DELETE" });
    expect(visits.status).toBe(405);
    expect(visits.headers.get("Allow")).toBe("GET, POST");

    const health = await workerExports.default.fetch("https://example.com/api/health", { method: "POST" });
    expect(health.status).toBe(405);
    expect(health.headers.get("Allow")).toBe("GET");
  });

  it("returns JSON 404 responses for unknown API routes", async () => {
    for (const path of ["/api", "/api/missing"]) {
      const response = await workerExports.default.fetch(`https://example.com${path}`);
      expect(response.status).toBe(404);
      expect(response.headers.get("Content-Type")).toContain("application/json");
      expect(await json(response)).toEqual({ error: "Not found" });
    }
  });

  it("does not expose storage failures", async () => {
    const failedCounter = {
      getCount() { throw new Error("storage unavailable"); },
      increment() { throw new Error("storage unavailable"); },
    };
    const response = await handleRequest(
      new Request("https://example.com/api/visits"),
      env,
      failedCounter,
    );
    expect(response.status).toBe(500);
    expect(await json(response)).toEqual({ error: "Internal server error" });
  });
});
