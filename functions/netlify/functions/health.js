// PSM Enterprise - Netlify Health Check
exports.handler = async (event, context) => {
  const checks = {
    function: 'healthy',
    memory: process.memoryUsage().heapUsed,
    uptime: process.uptime()
  };

  return {
    statusCode: 200,
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      status: 'healthy',
      checks,
      timestamp: new Date().toISOString()
    })
  };
};
