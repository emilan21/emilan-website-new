// Visitor Counter API Configuration
// Update these values after deploying infrastructure with Terraform
const API_BASE_URL = 'https://YOUR_API_GATEWAY_ID.execute-api.us-east-1.amazonaws.com/prod';
const GET_API = `${API_BASE_URL}/counts/get`;

// Visitor ID (can be customized)
const VISITOR_ID = 0;

const sendData = { id: VISITOR_ID };

fetch(GET_API, {
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
  if (data.body && data.body.count !== undefined) {
    document.getElementById("visits").innerHTML = data.body.count;
  } else if (data.count !== undefined) {
    document.getElementById("visits").innerHTML = data.count;
  } else {
    document.getElementById("visits").innerHTML = "0";
  }
})
.catch(error => {
  console.error('Error fetching visitor count:', error);
  document.getElementById("visits").innerHTML = "--";
});
