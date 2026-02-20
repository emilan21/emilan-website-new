// Local development worker for visitor counter API
// This mocks the Cloudflare Worker functionality for local testing

export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    
    // Handle CORS preflight
    if (request.method === 'OPTIONS') {
      return new Response(null, {
        status: 204,
        headers: {
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
          'Access-Control-Allow-Headers': 'Content-Type',
        },
      });
    }

    // GET /counts/get - Return visitor count
    if (url.pathname === '/counts/get' && request.method === 'GET') {
      // Try to get from KV store, default to random number for local dev
      let count = 42; // Default for local testing
      
      try {
        if (env.VISITOR_COUNTER) {
          const stored = await env.VISITOR_COUNTER.get('count');
          if (stored) {
            count = parseInt(stored);
          }
        }
      } catch (e) {
        console.log('KV not available, using mock count');
      }
      
      return new Response(JSON.stringify({ count }), {
        status: 200,
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*',
        },
      });
    }

    // POST /counts/increment - Increment visitor count
    if (url.pathname === '/counts/increment' && request.method === 'POST') {
      let count = 42;
      
      try {
        if (env.VISITOR_COUNTER) {
          const stored = await env.VISITOR_COUNTER.get('count');
          count = stored ? parseInt(stored) + 1 : 1;
          await env.VISITOR_COUNTER.put('count', count.toString());
        } else {
          count = Math.floor(Math.random() * 100) + 50; // Random for local dev
        }
      } catch (e) {
        console.log('KV not available, using mock count');
        count = Math.floor(Math.random() * 100) + 50;
      }
      
      return new Response(JSON.stringify({ count }), {
        status: 200,
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*',
        },
      });
    }

    // Return 404 for unknown paths
    return new Response(JSON.stringify({ error: 'Not found' }), {
      status: 404,
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
      },
    });
  },
};