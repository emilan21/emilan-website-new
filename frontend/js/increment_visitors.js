// Visitor Counter API Configuration
// This connects to Cloudflare Worker at api.ericmilan.dev
// The Worker uses Cloudflare KV for storage (no AWS needed!)
// For local development with Wrangler, the worker runs on localhost:8787
const API_BASE_URL = (typeof window !== 'undefined' && window.location.hostname === 'localhost')
  ? 'http://localhost:8787'  // Local development
  : 'https://visitor-counter.visitorcounter.workers.dev';  // Production
const INCREMENT_API = `${API_BASE_URL}/counts/increment`;

// Check if user has already visited this session
const hasVisited = sessionStorage.getItem('hasVisited');

if (!hasVisited) {
  fetch(INCREMENT_API, {
    method: 'POST',
    headers: {
      "Content-Type": "application/json"
    }
  })
  .then((response) => {
    if (!response.ok) {
      throw new Error(`HTTP error! status: ${response.status}`);
    }
    return response.json();
  })
  .then((data) => {
    console.log('Visitor count incremented:', data);
  })
  .catch(error => {
    console.error('Error incrementing visitor count:', error);
  });

  // Mark as visited for this session
  sessionStorage.setItem('hasVisited', 'true');
}
