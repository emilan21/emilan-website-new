// Visitor Counter API Configuration
// This connects to Cloudflare Worker at api.ericmilan.dev
// The Worker uses Cloudflare KV for storage (no AWS needed!)
const API_BASE_URL = 'https://visitor-counter.visitorcounter.workers.dev';
const GET_API = `${API_BASE_URL}/counts/get`;

// Fetch and display visitor count
fetch(GET_API)
  .then((response) => {
    if (!response.ok) {
      throw new Error(`HTTP error! status: ${response.status}`);
    }
    return response.json();
  })
  .then((data) => {
    if (data.count !== undefined) {
      document.getElementById("visits").innerHTML = data.count;
    } else {
      document.getElementById("visits").innerHTML = "0";
    }
  })
  .catch(error => {
    console.error('Error fetching visitor count:', error);
    document.getElementById("visits").innerHTML = "--";
  });
