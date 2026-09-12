const counter = document.querySelector("#visits");

function readCount(response, data) {
  if (!response.ok || !Number.isSafeInteger(data.count) || data.count < 0) {
    throw new Error("Invalid visitor response");
  }
  return data.count;
}

async function requestCount(method) {
  const response = await fetch("/api/visits", {
    method,
    credentials: "same-origin",
    headers: { Accept: "application/json" },
  });
  const data = await response.json();
  return { count: readCount(response, data), counted: response.headers.get("X-Visitor-Counted") === "true" };
}

async function updateCounter() {
  if (!counter) return;
  try {
    const current = await requestCount("GET");
    const result = current.counted ? current : await requestCount("POST");
    counter.textContent = new Intl.NumberFormat("en-US").format(result.count);
  } catch {
    counter.textContent = "Unavailable";
  }
}

void updateCounter();
