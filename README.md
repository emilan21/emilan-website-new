# ericmilan.dev

Personal resume website with serverless visitor counter.

## Quick Start (Cloudflare - Recommended)

**Fully serverless, no AWS needed!**

- **Frontend**: Cloudflare Pages (free hosting + SSL)
- **Visitor Counter**: Cloudflare Worker + KV (free serverless function)
- **Cost**: **$0/month** (within free tier limits)

### Deploy in 5 Minutes:

```bash
# 1. Install Wrangler CLI
npm install -g wrangler

# 2. Login to Cloudflare
wrangler login

# 3. Deploy visitor counter worker
cd worker
wrangler kv namespace create "VISITOR_COUNTER"
# Copy the ID to wrangler.toml, then:
wrangler deploy

# 4. Deploy website
cd ..
wrangler pages deploy frontend --project-name=ericmilan-website

# 5. Add custom domain in Cloudflare dashboard
# 6. Update Namecheap nameservers
# Done! 🎉
```

### GitHub Auto-Deploy (Optional but Recommended)

Setup automatic deployment when you push to GitHub:

1. **Get Cloudflare API Token**:
   - Cloudflare dashboard → My Profile → API Tokens
   - Create token with `Cloudflare Pages:Edit` and `Account:Read` permissions
   - Copy the token

2. **Add GitHub Secrets**:
   - GitHub repo → Settings → Secrets and variables → Actions
   - Add `CLOUDFLARE_API_TOKEN` - paste your token
   - Add `CLOUDFLARE_ACCOUNT_ID` - get from Cloudflare dashboard right sidebar

3. **Push to main branch**:
   ```bash
   git add .
   git commit -m "Update website"
   git push origin main
   ```
   
   Website automatically deploys! 🚀

**Full guide**: [CLOUDFLARE_WORKER.md](CLOUDFLARE_WORKER.md)

---

## Architecture Options

### Option 1: Cloudflare Only ⭐ (Recommended)
```
ericmilan.dev (Pages) → Cloudflare CDN + SSL
api.ericmilan.dev (Worker) → Cloudflare KV storage
```
- **Pros**: Free, automatic SSL, global CDN, simple deployment
- **Cons**: Less control than AWS (but you probably don't need it)

### Option 2: AWS (Legacy - More Complex)
```
ericmilan.dev → S3 → CloudFront → Route53 (DNS)
API → API Gateway → Lambda → DynamoDB
```
- **Pros**: Full control, enterprise-grade
- **Cons**: Complex setup, SSL certificate validation delays, monthly costs

---

## Project Structure

```
ericmilan.dev/
├── frontend/              # Your static website
│   ├── index.html
│   ├── js/
│   │   ├── visitors.js          # Calls visitor counter API
│   │   └── increment_visitors.js # Calls visitor counter API
│   └── ...
├── worker/               # Cloudflare Worker (visitor counter backend)
│   ├── index.js         # Worker code
│   └── wrangler.toml    # Worker config
├── backend/            # Lambda code (optional - AWS legacy)
├── infrastructure/     # Terraform (optional - AWS legacy)
└── .github/workflows/  # CI/CD
```

## Documentation

- **[CLOUDFLARE_WORKER.md](CLOUDFLARE_WORKER.md)** - Complete Cloudflare-only setup guide
- **[CLOUDFLARE.md](CLOUDFLARE.md)** - Cloudflare Pages hosting only
- **[DEPLOY.md](DEPLOY.md)** - AWS multi-environment deployment (legacy)
- **[MIGRATION.md](MIGRATION.md)** - Migrating from AWS to Cloudflare

## Prerequisites (Cloudflare Option)

- Cloudflare account (free tier)
- GitHub repository
- Domain at Namecheap
- Wrangler CLI: `npm install -g wrangler`

## Why Cloudflare?

| Feature | AWS | Cloudflare |
|---------|-----|------------|
| **SSL Setup** | 30+ min (ACM validation) | **Instant** |
| **Deployment** | Terraform + S3 + CloudFront | **Git push** |
| **Visitor Counter** | Lambda + DynamoDB + API Gateway | **Worker + KV** |
| **Cost** | ~$1-2/month | **Free** |
| **Complexity** | High | **Low** |
| **CDN** | CloudFront (paid) | **Global (free)** |

For a personal resume site, Cloudflare is simpler, faster, and cheaper.

## Quick Commands

```bash
# Deploy everything
wrangler login
wrangler pages deploy frontend --project-name=ericmilan-website
cd worker && wrangler deploy

# Or use the script
./deploy-cloudflare.sh
```

## Updating Your Website

### Method 1: GitHub Auto-Deploy (Easiest)
```bash
# Edit files
vim frontend/index.html

# Commit and push
 git add .
 git commit -m "Update resume"
 git push origin main

# Done! Website updates automatically
```

### Method 2: Manual Deploy
```bash
# Edit files
vim frontend/index.html

# Deploy manually
wrangler pages deploy frontend --project-name=ericmilan-website

# Or use helper script
./deploy-cloudflare.sh
```

### Updating the Visitor Counter API
```bash
# Edit worker code
cd worker
vim index.js

# Deploy changes
wrangler deploy

# Back to project root
cd ..
```

## License

MIT License - See LICENSE file
