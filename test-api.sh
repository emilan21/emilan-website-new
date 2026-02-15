#!/bin/bash

# Test script for visitor counter API
# This tests your Cloudflare Worker

echo "=== Testing Visitor Counter API ==="
echo "URL: https://visitor-counter.visitorcounter.workers.dev"
echo ""

echo "Test 1: GET current count"
echo "-------------------------"
curl -s https://visitor-counter.visitorcounter.workers.dev/counts/get | python3 -m json.tool 2>/dev/null || curl -s https://visitor-counter.visitorcounter.workers.dev/counts/get
echo ""
echo ""

echo "Test 2: POST increment count"
echo "----------------------------"
curl -s -X POST https://visitor-counter.visitorcounter.workers.dev/counts/increment | python3 -m json.tool 2>/dev/null || curl -s -X POST https://visitor-counter.visitorcounter.workers.dev/counts/increment
echo ""
echo ""

echo "Test 3: GET count again (should be +1)"
echo "-------------------------------------"
curl -s https://visitor-counter.visitorcounter.workers.dev/counts/get | python3 -m json.tool 2>/dev/null || curl -s https://visitor-counter.visitorcounter.workers.dev/counts/get
echo ""
echo ""

echo "=== Tests complete ==="
echo ""
echo "If all tests passed, deploy your website with:"
echo "  wrangler pages deploy frontend --project-name=ericmilan-website"
