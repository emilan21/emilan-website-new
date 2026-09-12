# ericmilan.dev

Eric Milan's framework-free portfolio, deployed as one Cloudflare Worker. Static Assets serves the HTML, CSS, résumé, and JavaScript; a SQLite-backed Durable Object provides the same-origin visitor-session counter.

## Architecture

```text
ericmilan.dev
├── /, /404.html, /css/*, /js/*  → Workers Static Assets
└── /api/*                       → TypeScript Worker
    └── VISITOR_COUNTER/global   → SQLite Durable Object
```

The stable `global` Durable Object instance serializes all increments. It stores only a non-negative count. A `Secure`, `HttpOnly`, `SameSite=Lax` cookie prevents another increment for 24 hours; no IP address or visitor identifier is stored. This is an approximate visitor-session metric, not a unique-person count.

## Requirements and local development

- Node.js 24 or newer
- npm
- A Cloudflare account only when deploying

Install the lockfile-pinned tools and run the production-equivalent local Worker:

```bash
npm ci
npm run types
npm run dev
```

Open <http://localhost:8790>. Local Durable Object data lives under `.wrangler/` and never touches production.

## API

| Request | Response | Notes |
| --- | --- | --- |
| `GET /api/visits` | `200 {"count":3}` | Returns the current non-negative integer count. |
| `POST /api/visits` | `200 {"count":4}` | Atomically increments unless the 24-hour cookie is valid. |
| `GET /api/health` | `200 {"status":"ok"}` | Runtime health check. |

Unsupported methods return JSON `405` with `Allow`; unknown API routes return JSON `404`; unexpected failures return a generic JSON `500`. API responses are not cacheable and do not expose CORS headers.

## Tests and checks

```bash
npm test                 # types, Worker tests, HTML, and local links
npm run test:worker      # Workers runtime + real SQLite Durable Object
npm run test:e2e         # local Worker + headless Cypress/Axe
npm run check:html       # HTML validation and local link checks
npm run check:lighthouse # local Lighthouse CI, all category targets >= 95
npm run deploy:dry-run   # validate production packaging
```

Worker tests cover initialization, persistence, concurrent atomic increments, the cookie window, routes, methods, response schemas, headers, and safe storage-error handling. Cypress covers browser errors, counter reloads, keyboard and pointer navigation, fixed-nav offsets, icon names, the 404 route, Axe, responsive overflow, and the absence of Font Awesome requests.

## Counter initialization and cutover

`INITIAL_VISITOR_COUNT` in `wrangler.jsonc` is used only by `INSERT OR IGNORE` when the Durable Object is first created. The repository value (`3`) was read from the legacy KV Worker on 2026-09-11; it is a snapshot, not a live synchronization mechanism.

For the first remote deployment:

1. Read the legacy count immediately before deploying: `curl -fsS https://visitor-counter.visitorcounter.workers.dev/counts/get`.
2. Update `INITIAL_VISITOR_COUNT` to that count and rerun `npm test` plus `npm run deploy:dry-run`.
3. Run `npm run deploy` and validate the generated `workers.dev` preview URL, `/api/health`, response headers, one-increment cookie behavior, and the displayed count.
4. Attach `ericmilan.dev` as the Worker's custom domain only after preview validation. Do not initialize the production Durable Object before the final count is captured.
5. After production validation, remove the prior Pages project, KV Worker, and legacy KV namespace.

Changing `INITIAL_VISITOR_COUNT` after the Durable Object exists does not overwrite its stored count.

## Deployment and CI

Manual deployment uses the exact local Wrangler version:

```bash
npm ci
npm test
npm run test:e2e
npm run check:lighthouse
npm run deploy:dry-run
npm run deploy
```

GitHub Actions runs the same validation for pull requests and pushes. Only `main` deploys. Configure repository secrets `CLOUDFLARE_API_TOKEN` and `CLOUDFLARE_ACCOUNT_ID`; scope the token to the target account with Workers Scripts edit and account read permissions. The former Pages action is not used.

Cloudflare Web Analytics remains compatible with the repository CSP through explicit `static.cloudflareinsights.com` and `cloudflareinsights.com` allowances. Enable it for the Worker custom domain in the Cloudflare dashboard to retain privacy-oriented traffic and Core Web Vitals reporting. Turn off Scrape Shield **Email Address Obfuscation** for the zone so Cloudflare does not inject its email-decode script.

## Observability and operations

Workers Logs and sampled traces are enabled in `wrangler.jsonc`. Errors are emitted as structured JSON with method and path, without request cookies, IP addresses, or stack traces in public responses.

For the first 24 hours after cutover, monitor:

- Worker error rate and `/api/visits` latency in Workers Observability
- count continuity and unexpected increment patterns
- Web Analytics traffic and Core Web Vitals

Before rollback, review Cloudflare's [rollback limitations](https://developers.cloudflare.com/workers/configuration/versions-and-deployments/rollbacks/): code rollback does not roll back connected storage. Roll back to an earlier `ericmilan-website` Worker version while leaving the custom domain and Durable Object in place; do not delete or recreate the Durable Object.

## Caching, security, and cost

HTML revalidates while versioned CSS and JavaScript cache immutably. Repository-managed headers apply CSP, clickjacking protection, a restrictive Permissions Policy, referrer controls, MIME sniffing protection, and HSTS without `includeSubDomains`.

Cloudflare pricing and limits can change. Check the current official documentation before deployment:

- [Workers pricing](https://developers.cloudflare.com/workers/platform/pricing/)
- [Static Assets billing and limits](https://developers.cloudflare.com/workers/static-assets/billing-and-limitations/)
- [Durable Objects pricing](https://developers.cloudflare.com/durable-objects/platform/pricing/)

## License

MIT — see [LICENSE](LICENSE).
