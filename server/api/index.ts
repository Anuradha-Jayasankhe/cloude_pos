process.env.VERCEL = '1';

let app: any;
try {
  app = require('../dist/server').default || require('../dist/server');
} catch (_) {
  app = require('../src/server').default || require('../src/server');
}

export default app;
