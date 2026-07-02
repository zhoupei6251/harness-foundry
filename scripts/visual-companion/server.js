#!/usr/bin/env node
/**
 * Visual Companion Server
 *
 * A lightweight HTTP server for visual design assistance during brainstorming.
 * Provides:
 * - Mockup creation with live preview
 * - Mermaid diagram generation
 * - Static file serving
 *
 * Port: 3847 (Superpowers standard port)
 */

const http = require('http');
const fs = require('fs');
const path = require('path');
const { spawn, execSync } = require('child_process');

const PORT = 3847;
const STATIC_DIR = path.join(__dirname, 'static');

// MIME types for static file serving
const mimeTypes = {
  '.html': 'text/html; charset=utf-8',
  '.css': 'text/css',
  '.js': 'application/javascript',
  '.json': 'application/json',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.svg': 'image/svg+xml',
  '.ico': 'image/x-icon'
};

/**
 * Serve static files from the static directory
 */
function serveStatic(req, res) {
  let urlPath = req.url.split('?')[0];
  let filePath = path.join(STATIC_DIR, urlPath === '/' ? 'index.html' : urlPath);

  // Security: prevent path traversal
  if (!filePath.startsWith(STATIC_DIR)) {
    res.writeHead(403);
    res.end('Forbidden');
    return;
  }

  if (!fs.existsSync(filePath)) {
    res.writeHead(404);
    res.end('Not found: ' + urlPath);
    return;
  }

  const stat = fs.statSync(filePath);
  if (stat.isDirectory()) {
    filePath = path.join(filePath, 'index.html');
    if (!fs.existsSync(filePath)) {
      res.writeHead(403);
      res.end('Directory listing not allowed');
      return;
    }
  }

  const ext = path.extname(filePath);
  const contentType = mimeTypes[ext] || 'text/plain; charset=utf-8';

  res.writeHead(200, { 'Content-Type': contentType });
  fs.createReadStream(filePath).pipe(res);
}

/**
 * Handle POST requests for mockup and diagram generation
 */
function handlePost(req, res) {
  let body = '';
  req.on('data', chunk => body += chunk);
  req.on('end', () => {
    try {
      const data = JSON.parse(body);

      if (data.type === 'mockup') {
        const mockup = generateMockup(data);
        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ success: true, mockup }));
      } else if (data.type === 'diagram') {
        const diagram = generateDiagram(data);
        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ success: true, diagram }));
      } else if (data.type === 'html-preview') {
        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({
          success: true,
          html: data.html || '<p>Enter HTML to preview</p>'
        }));
      } else {
        res.writeHead(400, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ success: false, error: 'Unknown request type' }));
      }
    } catch (err) {
      res.writeHead(400, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ success: false, error: err.message }));
    }
  });
}

/**
 * Generate mockup HTML from description
 */
function generateMockup(data) {
  const { description, components = [], layout = 'vertical' } = data;

  const componentsHtml = components.map(comp => {
    return `<div class="component ${comp.type || 'default'}" style="${comp.style || ''}">
      ${comp.label || ''}
    </div>`;
  }).join('\n');

  const layoutClass = layout === 'horizontal' ? 'layout-h' : 'layout-v';

  return {
    type: 'html',
    content: `
      <div class="mockup ${layoutClass}">
        <h3>${description || 'Mockup'}</h3>
        <div class="components">
          ${componentsHtml || '<p class="empty">Add components to preview</p>'}
        </div>
      </div>
    `,
    css: `
      .mockup { padding: 20px; background: #f5f5f5; border-radius: 8px; }
      .layout-v .components { display: flex; flex-direction: column; gap: 10px; }
      .layout-h .components { display: flex; gap: 10px; }
      .component { padding: 15px; background: white; border: 2px solid #ddd; border-radius: 4px; }
      .component.button { background: #007bff; color: white; text-align: center; cursor: pointer; }
      .component.input { background: white; border-style: dashed; }
      .component.card { min-height: 100px; }
      .empty { color: #999; font-style: italic; }
    `
  };
}

/**
 * Generate Mermaid diagram
 */
function generateDiagram(data) {
  const { structure, diagramType = 'flowchart' } = data;

  // Map common diagram types to Mermaid syntax
  const typeMap = {
    'flowchart': 'flowchart',
    'sequence': 'sequenceDiagram',
    'class': 'classDiagram',
    'state': 'stateDiagram-v2',
    'er': 'erDiagram',
    'gantt': 'gantt',
    'pie': 'pie'
  };

  const mermaidType = typeMap[diagramType] || 'flowchart';

  return {
    type: 'mermaid',
    syntax: mermaidType,
    content: structure || 'graph TD\n    A[Start] --> B[End]'
  };
}

/**
 * Open browser automatically (cross-platform)
 */
function openBrowser(url) {
  const platform = process.platform;

  try {
    if (platform === 'darwin') {
      // macOS
      spawn('open', [url]);
    } else if (platform === 'win32') {
      // Windows
      spawn('cmd', ['/c', 'start', '', url], { detached: true, stdio: 'ignore' });
    } else {
      // Linux
      spawn('xdg-open', [url]);
    }
    return true;
  } catch (err) {
    console.error('Failed to open browser:', err.message);
    return false;
  }
}

/**
 * Check if port is available
 */
function isPortAvailable(port) {
  return new Promise((resolve) => {
    const server = http.createServer();
    server.once('error', () => resolve(false));
    server.once('listening', () => {
      server.close();
      resolve(true);
    });
    server.listen(port);
  });
}

/**
 * Main server setup
 */
const server = http.createServer((req, res) => {
  // Add CORS headers for local development
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') {
    res.writeHead(204);
    res.end();
    return;
  }

  if (req.method === 'GET') {
    serveStatic(req, res);
  } else if (req.method === 'POST') {
    handlePost(req, res);
  } else {
    res.writeHead(405);
    res.end('Method not allowed');
  }
});

// Start server
async function start() {
  const portAvailable = await isPortAvailable(PORT);

  if (!portAvailable) {
    console.log(`Port ${PORT} is in use. Opening existing Visual Companion...`);
    openBrowser(`http://localhost:${PORT}`);
    process.exit(0);
  }

  server.listen(PORT, () => {
    console.log(`
╔═══════════════════════════════════════════════════════════╗
║           Visual Companion Server                         ║
║                                                           ║
║   Running at: http://localhost:${PORT.toString().padEnd(23)}║
║                                                           ║
║   Features:                                               ║
║   • Mockup creation with live preview                     ║
║   • Mermaid diagram generation                            ║
║   • HTML/CSS prototyping                                  ║
║                                                           ║
║   Press Ctrl+C to stop                                    ║
╚═══════════════════════════════════════════════════════════╝
    `);

    // Auto-open browser
    const shouldOpen = process.argv.includes('--open') || process.argv.includes('-o');
    if (shouldOpen) {
      setTimeout(() => openBrowser(`http://localhost:${PORT}`), 500);
    }
  });
}

// Graceful shutdown
process.on('SIGINT', () => {
  console.log('\nShutting down Visual Companion...');
  server.close(() => {
    console.log('Server stopped.');
    process.exit(0);
  });
});

process.on('SIGTERM', () => {
  server.close(() => process.exit(0));
});

// Export for testing
module.exports = { server, generateMockup, generateDiagram };

// Run if executed directly
if (require.main === module) {
  start();
}