type AssetsBinding = Pick<Fetcher, "fetch">;

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

export async function handleRequest(
  request: Request,
  env: Env,
  assets: AssetsBinding = env.ASSETS,
): Promise<Response> {
  const { pathname } = new URL(request.url);
  try {
    if (pathname === "/api/health") {
      return request.method === "GET"
        ? jsonResponse({ status: "ok" })
        : methodNotAllowed("GET");
    }
    if (pathname === "/api" || pathname.startsWith("/api/")) {
      return jsonResponse({ error: "Not found" }, { status: 404 });
    }
    return await assets.fetch(request);
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
