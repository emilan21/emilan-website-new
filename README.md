# ericmilan.dev

Eric Milan's framework-free portfolio, deployed as one Cloudflare Worker. Workers Static Assets serves the HTML, CSS, favicon, and résumé; a small TypeScript Worker provides the health endpoint. Private traffic and Core Web Vitals reporting comes from Cloudflare Web Analytics.

## Architecture

```text
ericmilan.dev
├── /, /404.html, /css/*, /files/*  → Workers Static Assets
└── /api/*                           → TypeScript Worker
    ├── GET /api/health             → JSON health response
    └── every other API request     → JSON 404
```

There is no public counter, visitor cookie, visitor-identification system, or application database. Cloudflare Web Analytics is the sole visitor, page-view, and Core Web Vitals data source, and its aggregate reports are visible only in the Cloudflare dashboard.

## Requirements and local development

- Node.js 24 or newer
- npm
- A Cloudflare account only when deploying or viewing analytics

Install the lockfile-pinned tools and run the production-equivalent local Worker:

```bash
npm ci
npm run types
npm run dev
```

Open <http://localhost:8790>.

## API

| Request | Response | Notes |
| --- | --- | --- |
| `GET /api/health` | `200 {"status":"ok"}` | Runtime health check. |
| Any other `/api` request | `404 {"error":"Not found"}` | Includes the retired `/api/visits` route. |

Unsupported methods on `/api/health` return JSON `405` with `Allow: GET`. Unexpected failures return a generic JSON `500`. API responses are not cacheable and do not expose CORS headers.

## Tests and checks

```bash
npm test                 # types, Worker routes, HTML, and local links
npm run test:worker      # Worker route and Static Assets integration tests
npm run test:e2e         # local Worker + headless Cypress/Axe
npm run check:html       # HTML validation and local link checks
npm run check:lighthouse # local Lighthouse CI, all category targets >= 95
npm run deploy:dry-run   # validate production packaging
```

Worker tests cover health, unsupported methods, JSON API 404s, static assets, security headers, and generic failures. Cypress verifies the absence of the visitor counter and `/api/visits` requests, browser errors, keyboard and pointer navigation, fixed-nav offsets, icon names, the 404 route, accessibility, responsive overflow, and third-party font requests.

## Deployment and Web Analytics

GitHub Actions runs the full validation suite for pull requests and pushes. The protected `main` branch deploys only after the `verify` job passes. Configure repository secrets `CLOUDFLARE_API_TOKEN` and `CLOUDFLARE_ACCOUNT_ID`; scope the token to the target account with Workers Scripts edit and account read permissions.

Before the first deployment of this version, enable automatic Web Analytics setup for `ericmilan.dev` under **Analytics & Logs → Web Analytics**. An API token with `Account Settings Write` can instead enable the site through the Cloudflare API. Automatic setup injects the browser beacon without adding repository JavaScript.

The repository CSP intentionally permits the analytics beacon from `static.cloudflareinsights.com` and reporting to `cloudflareinsights.com`. Turn off Scrape Shield **Email Address Obfuscation** for the zone so Cloudflare does not inject its email-decode script.

Deploy with the exact lockfile-pinned Wrangler version:

```bash
npm ci
npm test
npm run test:e2e
npm run check:lighthouse
npm run deploy:dry-run
npm run deploy
```

After deployment, verify that:

- the homepage displays no visitor count and requests no counter-specific JavaScript;
- `/api/visits` returns JSON `404` and `/api/health` remains healthy;
- the analytics beacon reports through `/cdn-cgi/rum`;
- visitor, page-view, and Core Web Vitals data appears only in the Cloudflare dashboard.

The `v2` Worker migration permanently deletes the former `VisitorCounter` Durable Object class, namespace, and stored count. That data cannot be restored by rolling back Worker code. Analytics begins when Web Analytics is activated; historical traffic and the former approximate count are intentionally not reconstructed.

## Observability, caching, and security

Workers Logs and sampled traces are enabled in `wrangler.jsonc`. Errors are emitted as structured JSON with method and path, without request cookies, IP addresses, or stack traces in public responses.

HTML revalidates while the versioned CSS caches immutably. Repository-managed headers apply CSP, clickjacking protection, a restrictive Permissions Policy, referrer controls, MIME sniffing protection, and HSTS without `includeSubDomains`.

## License

MIT — see [LICENSE](LICENSE).
