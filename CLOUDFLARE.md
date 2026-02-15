# Cloudflare Pages Deployment Guide

## Overview

This guide sets up deployment to **Cloudflare Pages** - a much simpler alternative to AWS:

- **Free SSL** (automatic, instant)
- **Global CDN** (faster than CloudFront)
- **No complex setup** (no S3 buckets, no IAM roles)
- **GitHub integration** (auto-deploy on push)
- **Custom domain support** (ericmilan.dev)

## Prerequisites

1. **Cloudflare account** (free tier works fine)
2. **GitHub repository** with your code
3. **Domain registered** at Namecheap (or anywhere)
4. **Optional**: Keep your visitor counter API on AWS (or use Cloudflare Workers)

## Setup Steps

### Step 1: Sign Up for Cloudflare

1. Go to https://dash.cloudflare.com/sign-up
2. Create a free account
3. No need to change your Namecheap DNS yet

### Step 2: Create Cloudflare Pages Project

1. In Cloudflare dashboard, go to **Pages**
2. Click **Create a project**
3. Choose **Connect to Git**
4. Connect your GitHub account and select the `ericmilan-website` repo
5. Configure build settings:
   - **Project name**: `ericmilan-website`
   - **Production branch**: `main`
   - **Build command**: (leave empty - static site)
   - **Build output directory**: `frontend`

6. Click **Save and Deploy**

Your site will be live at: `https://ericmilan-website.pages.dev`

### Step 3: Set Up Custom Domain

1. In your Cloudflare Pages project, go to **Custom domains**
2. Click **Set up a custom domain**
3. Enter: `ericmilan.dev`
4. Click **Continue**

Cloudflare will give you **2 nameservers** to use.

### Step 4: Update Namecheap DNS

1. Log into Namecheap
2. Go to **Domain List** → click **Manage** for ericmilan.dev
3. Go to **Nameservers** section
4. Change from "Namecheap BasicDNS" to **Custom DNS**
5. Enter the 2 Cloudflare nameservers (e.g., `bob.ns.cloudflare.com`, `lara.ns.cloudflare.com`)
6. Click **Save**

**Note**: DNS changes can take 24-48 hours to propagate globally, but usually work within a few hours.

### Step 5: Enable SSL

Cloudflare automatically provisions SSL certificates. Just wait for:
- **Status**: Active on the custom domain page
- This usually happens within a few minutes after nameservers update

### Step 6: Visitor Counter (Options)

Since you're moving from AWS, you have choices for the visitor counter:

#### Option A: Keep AWS Lambda (Simplest)
Keep your visitor counter API on AWS. Update `frontend/js/visitors.js` with the AWS API Gateway URL.

#### Option B: Cloudflare Workers (Serverless)
Move the visitor counter to Cloudflare Workers (free tier includes 100,000 requests/day):
1. Create a Worker in Cloudflare dashboard
2. Port your Python Lambda code to JavaScript
3. Use Cloudflare KV (key-value store) instead of DynamoDB

#### Option C: Remove Visitor Counter
For a resume site, you might not need it. Simpler is often better.

### Step 7: Configure GitHub Actions

1. Get your Cloudflare credentials:
   - Go to Cloudflare dashboard → **My Profile** → **API Tokens**
   - Create a token with **Zone:Read** and **Page Rules:Edit** permissions
   - Or use Global API Key (less secure but easier)
   - Get your **Account ID** from the right sidebar of any Cloudflare page

2. Add GitHub Secrets:
   - Go to your GitHub repo → **Settings** → **Secrets and variables** → **Actions**
   - Add `CLOUDFLARE_API_TOKEN` - your API token
   - Add `CLOUDFLARE_ACCOUNT_ID` - your account ID

3. The workflow (`.github/workflows/cloudflare-deploy.yml`) is already set up!

## Testing

After setup, test with:
```bash
# Push a change to trigger deployment
git add .
git commit -m "Test Cloudflare deployment"
git push origin main
```

Then check:
1. GitHub Actions tab for build status
2. Cloudflare Pages dashboard for deployment status
3. Visit `https://ericmilan.dev` (after DNS propagates)

## Benefits vs AWS

| Feature | AWS | Cloudflare Pages |
|---------|-----|------------------|
| SSL Setup | Complex (ACM + validation) | Automatic (instant) |
| Deployment | Manual S3 sync + CloudFront invalidation | Automatic on Git push |
| CDN | CloudFront (paid) | Global CDN (free) |
| DNS Management | Route53 ($0.50/month) | Free |
| Complexity | High (Terraform, IAM, etc.) | Low (Git push) |
| Cost | ~$1-2/month | **Free** |

## What About AWS?

### Option 1: Clean Up AWS
If you want to delete the AWS resources we started creating:
```bash
cd infrastructure/
terraform destroy -var-file=prod.tfvars
```

**Note**: This may fail if the certificate validation is still pending. You might need to manually delete resources in AWS Console.

### Option 2: Keep AWS for API Only
Use Cloudflare Pages for hosting, but keep AWS Lambda for the visitor counter API:
- Update `frontend/js/visitors.js` with your AWS API Gateway URL
- Both can work together!

### Option 3: Archive Infrastructure
Just leave the `infrastructure/` folder in your repo. It won't hurt anything if not deployed.

## Troubleshooting

### "Domain not active" in Cloudflare
- DNS propagation takes time (up to 48 hours)
- Check that you entered the correct nameservers at Namecheap
- Verify no typos in the nameservers

### SSL not working
- Wait for the domain status to show "Active" in Cloudflare
- Cloudflare auto-provisions SSL - no manual steps needed

### Deployments not working
- Check GitHub Actions logs for errors
- Verify `CLOUDFLARE_API_TOKEN` and `CLOUDFLARE_ACCOUNT_ID` secrets are set
- Make sure the workflow file is at `.github/workflows/cloudflare-deploy.yml`

### Site shows 404
- Verify **Build output directory** is set to `frontend` in Cloudflare Pages settings
- Make sure `index.html` exists in your `frontend/` folder

## Next Steps

1. ✅ Set up Cloudflare Pages project
2. ✅ Update Namecheap nameservers
3. ✅ Wait for SSL (automatic)
4. ✅ Configure GitHub Actions
5. ✅ Test deployment
6. 🎉 Done! Your site is live with automatic SSL and global CDN

## Questions?

- Cloudflare docs: https://developers.cloudflare.com/pages/
- Free tier limits: 500 builds/month, 100,000 requests/day, 1GB storage

**Estimated setup time**: 15-20 minutes (mostly waiting for DNS)
