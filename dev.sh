#!/bin/bash

# Development server startup script for ericmilan.dev
# This starts both the Pages dev server and the Worker API

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Eric Milan Website - Development Server ===${NC}"
echo ""

# Check if wrangler is installed
if ! command -v wrangler &> /dev/null; then
    echo -e "${YELLOW}Wrangler not found. Installing...${NC}"
    npm install -g wrangler
fi

# Check if user is logged in
if ! wrangler whoami &> /dev/null; then
    echo -e "${YELLOW}Please login to Cloudflare first:${NC}"
    wrangler login
fi

echo -e "${GREEN}Starting development servers...${NC}"
echo ""
echo -e "${YELLOW}Services will be available at:${NC}"
echo "  - Website:    http://localhost:8000"
echo "  - Worker API: http://localhost:8787"
echo ""
echo -e "${YELLOW}Press Ctrl+C to stop both servers${NC}"
echo ""

# Start the Worker in the background
echo -e "${BLUE}Starting Worker API on port 8787...${NC}"
wrangler dev frontend/worker.js --port=8787 &
WORKER_PID=$!

# Wait a moment for worker to start
sleep 2

# Start the Pages dev server
echo -e "${BLUE}Starting Pages dev server on port 8000...${NC}"
wrangler pages dev frontend --port=8000 --compatibility-date=2024-01-01 &
PAGES_PID=$!

# Function to cleanup on exit
cleanup() {
    echo ""
    echo -e "${YELLOW}Shutting down development servers...${NC}"
    kill $WORKER_PID 2>/dev/null || true
    kill $PAGES_PID 2>/dev/null || true
    exit 0
}

# Trap Ctrl+C and cleanup
trap cleanup INT TERM

# Wait for both processes
wait