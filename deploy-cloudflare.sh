#!/bin/bash

# Deploy script for Cloudflare-only setup
# No AWS needed!

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}=== Cloudflare-Only Deployment ===${NC}"
echo ""

# Check if wrangler is installed
if ! command -v wrangler &> /dev/null; then
    echo "Installing Wrangler CLI..."
    npm install -g wrangler
fi

# Check if logged in
if ! wrangler whoami &> /dev/null; then
    echo -e "${GREEN}Step 1: Login to Cloudflare${NC}"
    wrangler login
fi

# Test the API first
echo -e "${GREEN}Step 2: Testing visitor counter API${NC}"
./test-api.sh

echo ""
read -p "Did the API tests pass? (yes/no): " confirm
if [ "$confirm" != "yes" ]; then
    echo "Please fix the API issues before deploying the website."
    exit 1
fi

# Deploy website
echo -e "${GREEN}Step 3: Deploying website to Cloudflare Pages${NC}"
if ! wrangler pages project list 2>/dev/null | grep -q "ericmilan-website"; then
    echo "Creating new Pages project..."
    echo "Please create project 'ericmilan-website' in Cloudflare dashboard first"
    echo "Or run: wrangler pages project create ericmilan-website"
    exit 1
fi

wrangler pages deploy frontend --project-name=ericmilan-website

echo ""
echo -e "${GREEN}=== Deployment complete! ===${NC}"
echo ""
echo "Your website is live at:"
echo "  https://ericmilan-website.pages.dev"
echo ""
echo "Next steps:"
echo "1. Add custom domain 'ericmilan.dev' in Cloudflare dashboard"
echo "2. Update Namecheap nameservers when ready"
echo "3. Test the visitor counter on your live site"
