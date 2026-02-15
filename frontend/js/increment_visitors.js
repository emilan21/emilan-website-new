// Visitor Counter API Configuration
// This connects to Cloudflare Worker at api.ericmilan.dev
// The Worker uses Cloudflare KV for storage (no AWS needed!)
const API_BASE_URL = 'https://visitor-counter.visitorcounter.workers.dev';
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
