import { DurableObject } from "cloudflare:workers";

const COUNTER_INSTANCE_NAME = "global";
const COOKIE_NAME = "visitor_counted";
const COOKIE_MAX_AGE_SECONDS = 86_400;

type CountRow = { count: number };
type CounterOperations = Pick<VisitorCounter, "getCount" | "increment">;

export class VisitorCounter extends DurableObject<Env> {
  constructor(ctx: DurableObjectState, env: Env) {
    super(ctx, env);
    const initialCount = parseInitialCount(env.INITIAL_VISITOR_COUNT);
    this.ctx.storage.sql.exec(`
      CREATE TABLE IF NOT EXISTS visitor_counter (
        singleton INTEGER PRIMARY KEY CHECK (singleton = 1),
        count INTEGER NOT NULL CHECK (count >= 0)
      )
    `);
    this.ctx.storage.sql.exec(
      "INSERT OR IGNORE INTO visitor_counter (singleton, count) VALUES (1, ?)",
      initialCount,
    );
  }

  getCount(): number {
    return this.ctx.storage.sql
      .exec<CountRow>("SELECT count FROM visitor_counter WHERE singleton = 1")
      .one().count;
  }

  increment(): number {
    return this.ctx.storage.sql
      .exec<CountRow>(
        "UPDATE visitor_counter SET count = count + 1 WHERE singleton = 1 RETURNING count",
      )
      .one().count;
  }
}

function parseInitialCount(value: string): number {
  const parsed = Number.parseInt(value, 10);
  return Number.isSafeInteger(parsed) && parsed >= 0 ? parsed : 0;
}

function hasCountedCookie(request: Request): boolean {
  const cookie = request.headers.get("Cookie") ?? "";
  return cookie
    .split(";")
    .some((part) => part.trim().startsWith(`${COOKIE_NAME}=`));
}

function jsonResponse(
  body: object,
  init: ResponseInit = {},
  extraHeaders: HeadersInit = {},
): Response {
  const headers = new Headers(init.headers);
  headers.set("Content-Type", "application/json; charset=utf-8");
  headers.set("Cache-Control", "no-store");
  headers.set("X-Content-Type-Options", "nosniff");
  headers.set("X-Frame-Options", "DENY");
  headers.set("Strict-Transport-Security", "max-age=31536000");
  headers.set("Referrer-Policy", "strict-origin-when-cross-origin");
  headers.set("Permissions-Policy", "camera=(), microphone=(), geolocation=()");
  headers.set("Content-Security-Policy", "default-src 'none'; frame-ancestors 'none'; base-uri 'none'");
  for (const [name, value] of new Headers(extraHeaders)) {
    headers.set(name, value);
  }
  return new Response(JSON.stringify(body), { ...init, headers });
}

function methodNotAllowed(allow: string): Response {
  return jsonResponse({ error: "Method not allowed" }, { status: 405 }, { Allow: allow });
}

async function handleVisits(
  request: Request,
  env: Env,
  counterOverride?: CounterOperations,
): Promise<Response> {
  const counted = hasCountedCookie(request);
  const counter = counterOverride ?? env.VISITOR_COUNTER.getByName(COUNTER_INSTANCE_NAME);

  if (request.method === "GET") {
    return jsonResponse(
      { count: await counter.getCount() },
      {},
      { "X-Visitor-Counted": String(counted) },
    );
  }

  if (request.method === "POST") {
    const count = counted ? await counter.getCount() : await counter.increment();
    const headers = new Headers({ "X-Visitor-Counted": "true" });
    if (!counted) {
      headers.set(
        "Set-Cookie",
        `${COOKIE_NAME}=1; Max-Age=${COOKIE_MAX_AGE_SECONDS}; Path=/; Secure; HttpOnly; SameSite=Lax`,
      );
    }
    return jsonResponse({ count }, {}, headers);
  }

  return methodNotAllowed("GET, POST");
}

export async function handleRequest(
  request: Request,
  env: Env,
  counterOverride?: CounterOperations,
): Promise<Response> {
  const { pathname } = new URL(request.url);
  try {
    if (pathname === "/api/visits") return await handleVisits(request, env, counterOverride);
    if (pathname === "/api/health") {
      return request.method === "GET"
        ? jsonResponse({ status: "ok" })
        : methodNotAllowed("GET");
    }
    if (pathname === "/api" || pathname.startsWith("/api/")) {
      return jsonResponse({ error: "Not found" }, { status: 404 });
    }
    return await env.ASSETS.fetch(request);
  } catch (error) {
    console.error(JSON.stringify({
      message: "request failed",
      method: request.method,
      path: pathname,
      error: error instanceof Error ? error.message : String(error),
    }));
    return jsonResponse({ error: "Internal server error" }, { status: 500 });
  }
}

export default {
  fetch(request, env) {
    return handleRequest(request, env);
  },
} satisfies ExportedHandler<Env>;
