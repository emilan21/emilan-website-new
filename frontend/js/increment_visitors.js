// Visitor Counter API Configuration
// Update these values after deploying infrastructure with Terraform
const API_BASE_URL = 'https://YOUR_API_GATEWAY_ID.execute-api.us-east-1.amazonaws.com/prod';
const INCREMENT_API = `${API_BASE_URL}/counts/increment`;

// Visitor ID (can be customized)
const VISITOR_ID = 0;

const sendData = { id: VISITOR_ID };

// Check if user has already visited this session
const hasVisited = sessionStorage.getItem('hasVisited');

if (!hasVisited) {
  fetch(INCREMENT_API, {
    method: 'POST',
    headers: {
      "Content-Type": "application/json"
    },
    body: JSON.stringify(sendData)
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
