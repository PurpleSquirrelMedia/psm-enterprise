/**
 * PSM Analytics API - Vercel Edge Functions
 */

export const config = {
  runtime: 'edge',
};

export default async function handler(request) {
  const url = new URL(request.url);
  
  // Mock analytics data
  const analytics = {
    pageViews: Math.floor(Math.random() * 10000) + 5000,
    uniqueVisitors: Math.floor(Math.random() * 3000) + 1000,
    avgSessionDuration: '3m 24s',
    bounceRate: '32%',
    topPages: [
      { path: '/', views: 4521 },
      { path: '/storage/vault', views: 1234 },
      { path: '/services', views: 892 }
    ],
    topCountries: ['US', 'UK', 'DE', 'JP', 'AU'],
    timestamp: new Date().toISOString()
  };
  
  return new Response(JSON.stringify(analytics), {
    headers: {
      'Content-Type': 'application/json',
      'Access-Control-Allow-Origin': '*'
    }
  });
}
