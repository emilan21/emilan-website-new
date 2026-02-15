# Complete Cloudflare-Only Setup Guide

## Overview

This guide sets up **everything on Cloudflare** - no AWS needed!

- **Website hosting**: Cloudflare Pages (static site)
- **Visitor counter API**: Cloudflare Worker (serverless function)
- **Data storage**: Cloudflare KV (key-value store)
- **SSL**: Automatic & free
- **CDN**: Global (included)
- **Cost**: **Free** (within limits)

## Architecture

```
ericmilan.dev (Cloudflare Pages)
├── Static HTML/CSS/JS (frontend/)
├── Visitor Counter Widget (calls API)
└── api.ericmilan.dev (Cloudflare Worker)
    ├── GET /counts/get (returns count from KV)
    └── POST /counts/increment (updates count in KV)
```

## Prerequisites

1. **Cloudflare account** (free tier)
2. **GitHub repository** with your code
3. **Domain** at Namecheap (or anywhere)
4. **Wrangler CLI** (Cloudflare's CLI tool)

## Step 1: Install Wrangler CLI

```bash
npm install -g wrangler
```

Login to Cloudflare:
```bash
wrangler login
```

This will open a browser window to authenticate.

## Step 2: Create KV Namespace

Create the key-value store for visitor count:

```bash
cd /path/to/ericmilan-website-new
wrangler kv namespace create "VISITOR_COUNTER"
```

This will output something like:
```
🌀 Creating namespace with title "VISITOR_COUNTER"
✨ Success!
Add the following to your configuration file:
[[kv_namespaces]]
binding = "VISITOR_COUNTER"
id = "a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p"
```

**Copy that `id` value** and paste it into `worker/wrangler.toml`:

```toml
[[kv_namespaces]]
binding = "VISITOR_COUNTER"
id = "a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p"  # Your actual ID here
```

## Step 3: Deploy the Worker

```bash
cd worker/
wrangler deploy
```

Your API is now live at:
- `https://visitor-counter.your-account.workers.dev`

## Step 4: Set Up Custom Subdomain (Optional)

To use `api.ericmilan.dev` instead of the workers.dev URL:

1. In Cloudflare dashboard → **Workers & Pages**
2. Click your **visitor-counter** worker
3. Go to **Triggers** → **Custom Domains**
4. Click **Add Custom Domain**
5. Enter: `api.ericmilan.dev`
6. Click **Add Domain**

Cloudflare will automatically create the DNS record.

## Step 5: Update Frontend API URL

Edit `frontend/js/visitors.js` and `frontend/js/increment_visitors.js`:

**Option A: Using workers.dev URL (works immediately)**
```javascript
const API_BASE_URL = 'https://visitor-counter.your-account.workers.dev';
```

**Option B: Using custom subdomain (after DNS propagates)**
```javascript
const API_BASE_URL = 'https://api.ericmilan.dev';
```

## Step 6: Deploy Website to Cloudflare Pages

### Option 1: Using Wrangler CLI

```bash
cd /path/to/ericmilan-website-new
wrangler pages deploy frontend --project-name=ericmilan-website
```

Your site is now at: `https://ericmilan-website.pages.dev`

### Option 2: GitHub Integration (Recommended)

1. Go to Cloudflare dashboard → **Pages**
2. Click **Create a project** → **Connect to Git**
3. Select your GitHub repo
4. Configure:
   - **Project name**: `ericmilan-website`
   - **Production branch**: `main`
   - **Build command**: (leave empty)
   - **Build output directory**: `frontend`
5. Click **Save and Deploy**

## Step 7: Add Custom Domain

### Add Domain to Pages

1. In your Pages project, go to **Custom domains**
2. Click **Set up a custom domain**
3. Enter: `ericmilan.dev`
4. Click **Continue**

Cloudflare will give you **2 nameservers**.

### Update Namecheap DNS

1. Log into Namecheap
2. Go to **Domain List** → **Manage** for ericmilan.dev
3. Go to **Nameservers** section
4. Change to **Custom DNS**
5. Enter the 2 Cloudflare nameservers
6. Click **Save**

Wait for DNS propagation (usually 30 minutes to a few hours).

## Step 8: Test Everything

1. **Test API directly**:
   ```bash
   curl https://api.ericmilan.dev/counts/get
   # Should return: {"count":0}
   
   curl -X POST https://api.ericmilan.dev/counts/increment
   # Should return: {"count":1}
   ```

2. **Test website**:
   - Visit `https://ericmilan.dev`
   - Check that visitor counter shows a number
   - Refresh the page - count should increment

## Complete Setup Flow

```bash
# 1. Login to Cloudflare
wrangler login

# 2. Create KV namespace
cd ericmilan-website-new
wrangler kv namespace create "VISITOR_COUNTER"
# Copy the ID to worker/wrangler.toml

# 3. Deploy Worker
cd worker
wrangler deploy
# Note the deployed URL

# 4. Update frontend API URL
# Edit frontend/js/visitors.js
# Edit frontend/js/increment_visitors.js
# Change API_BASE_URL to your Worker URL

# 5. Deploy website
cd ..
wrangler pages deploy frontend --project-name=ericmilan-website

# 6. Set up custom domains in Cloudflare dashboard
# - Add api.ericmilan.dev to Worker
# - Add ericmilan.dev to Pages

# 7. Update Namecheap nameservers
# Done! 🎉
```

## File Structure

```
ericmilan-website-new/
├── frontend/              # Your website
│   ├── index.html
│   ├── js/
│   │   ├── visitors.js          # Calls Cloudflare Worker
│   │   └── increment_visitors.js # Calls Cloudflare Worker
│   └── ...
├── worker/               # Cloudflare Worker (visitor counter API)
│   ├── index.js         # Worker code
│   └── wrangler.toml    # Worker config
├── wrangler.toml         # Root config (optional)
└── .github/workflows/
    └── cloudflare-deploy.yml  # Auto-deploy on push
```

## Limits (Free Tier)

- **Worker requests**: 100,000/day (more than enough for a resume site)
- **KV reads**: 100,000/day
- **KV writes**: 1,000/day (visitor counter does 1 write per new session)
- **Pages bandwidth**: Unlimited (fair use)
- **Pages builds**: 500/month

For a low-traffic resume site, you'll never hit these limits.

## Troubleshooting

### Worker not responding
Check that the KV namespace ID is correct in `wrangler.toml`:
```bash
wrangler kv:namespace list
```

### CORS errors in browser
The Worker code already includes CORS headers. If you see errors, check:
- The API URL in JavaScript files is correct
- You're using `https://` not `http://`

### Count not incrementing
- Check browser console for errors
- Verify the Worker is deployed: `wrangler tail` to see logs
- Test the API directly with curl

### DNS not working
- DNS propagation takes time (up to 24 hours)
- Verify nameservers at Namecheap match Cloudflare's
- Check SSL status in Cloudflare dashboard (should say "Active")

## Alternative Backends (If You Don't Want Cloudflare Workers)

### Option 1: Supabase (PostgreSQL)
- Free tier: 500MB database
- Use their REST API
- Good for more complex data

### Option 2: PlanetScale (MySQL)
- Free tier: 5GB storage
- Serverless database
- Good scaling

### Option 3: MongoDB Atlas
- Free tier: 512MB storage
- NoSQL database
- Good for simple counters

### Option 4: Vercel KV
- Redis-compatible
- Free tier available
- Easy integration with Vercel hosting

### Option 5: Netlify Functions + FaunaDB
- Serverless functions on Netlify
- FaunaDB for storage
- Both have free tiers

## Next Steps

1. ✅ Install Wrangler: `npm install -g wrangler`
2. ✅ Login: `wrangler login`
3. ✅ Create KV namespace
4. ✅ Deploy Worker
5. ✅ Update frontend JavaScript with Worker URL
6. ✅ Deploy website to Cloudflare Pages
7. ✅ Add custom domains
8. ✅ Update Namecheap nameservers
9. 🎉 **Done!** No AWS needed!

## Questions?

- Cloudflare Workers docs: https://developers.cloudflare.com/workers/
- KV docs: https://developers.cloudflare.com/kv/
- Pages docs: https://developers.cloudflare.com/pages/

**Total setup time**: 20-30 minutes
**Monthly cost**: **$0** (free tier covers everything)
