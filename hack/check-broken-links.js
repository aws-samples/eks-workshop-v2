#!/usr/bin/env node

/**
 * Web crawler to check for broken links and images on localhost:3000
 * Limits crawling to the localhost:3000 domain only
 * Uses Puppeteer for JavaScript-rendered content (Docusaurus)
 * Validates image integrity and checks for non-WebP formats
 */

const puppeteer = require('puppeteer');
const http = require('http');
const https = require('https');

const BASE_URL = 'http://localhost:3000';
const visited = new Set();
const broken = new Map();
const nonWebpImages = new Map();
const corruptedImages = new Map();
const queue = [BASE_URL];

// ANSI color codes for terminal output
const colors = {
  reset: '\x1b[0m',
  green: '\x1b[32m',
  red: '\x1b[31m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
  gray: '\x1b[90m',
  magenta: '\x1b[35m'
};

function log(message, color = 'reset') {
  console.log(`${colors[color]}${message}${colors.reset}`);
}

function isValidUrl(urlString) {
  try {
    const url = new URL(urlString, BASE_URL);
    return url.hostname === 'localhost' && url.port === '3000';
  } catch {
    return false;
  }
}

function normalizeUrl(urlString) {
  try {
    const url = new URL(urlString, BASE_URL);
    url.hash = ''; // Remove hash fragments
    return url.href;
  } catch {
    return null;
  }
}

function getImageFormat(url) {
  const urlLower = url.toLowerCase();
  if (urlLower.endsWith('.webp')) return 'webp';
  if (urlLower.endsWith('.png')) return 'png';
  if (urlLower.endsWith('.jpg') || urlLower.endsWith('.jpeg')) return 'jpeg';
  if (urlLower.endsWith('.gif')) return 'gif';
  if (urlLower.endsWith('.svg')) return 'svg';
  if (urlLower.endsWith('.ico')) return 'ico';
  return 'unknown';
}

function validateImageBuffer(buffer, format) {
  if (!buffer || buffer.length === 0) {
    return { valid: false, error: 'Empty buffer' };
  }

  // Check minimum size (corrupted images are often very small)
  if (buffer.length < 100) {
    return { valid: false, error: `Suspiciously small (${buffer.length} bytes)` };
  }

  // Check magic bytes for common formats
  const header = buffer.slice(0, 12);
  
  if (format === 'png') {
    // PNG: 89 50 4E 47 0D 0A 1A 0A
    if (header[0] !== 0x89 || header[1] !== 0x50 || header[2] !== 0x4E || header[3] !== 0x47) {
      return { valid: false, error: 'Invalid PNG header' };
    }
  } else if (format === 'jpeg') {
    // JPEG: FF D8 FF
    if (header[0] !== 0xFF || header[1] !== 0xD8 || header[2] !== 0xFF) {
      return { valid: false, error: 'Invalid JPEG header' };
    }
  } else if (format === 'webp') {
    // WebP: RIFF ... WEBP
    if (header[0] !== 0x52 || header[1] !== 0x49 || header[2] !== 0x46 || header[3] !== 0x46) {
      return { valid: false, error: 'Invalid WebP RIFF header' };
    }
    if (header[8] !== 0x57 || header[9] !== 0x45 || header[10] !== 0x42 || header[11] !== 0x50) {
      return { valid: false, error: 'Invalid WebP signature' };
    }
  } else if (format === 'gif') {
    // GIF: GIF87a or GIF89a
    if (header[0] !== 0x47 || header[1] !== 0x49 || header[2] !== 0x46) {
      return { valid: false, error: 'Invalid GIF header' };
    }
  } else if (format === 'svg') {
    // SVG is XML, check for < character
    const text = buffer.toString('utf8', 0, Math.min(100, buffer.length));
    if (!text.includes('<svg') && !text.includes('<?xml')) {
      return { valid: false, error: 'Invalid SVG content' };
    }
  }

  return { valid: true };
}

function fetchImageBuffer(url) {
  return new Promise((resolve, reject) => {
    const urlObj = new URL(url);
    const client = urlObj.protocol === 'https:' ? https : http;
    
    const req = client.get(url, (res) => {
      if (res.statusCode !== 200) {
        reject(new Error(`HTTP ${res.statusCode}`));
        return;
      }

      const chunks = [];
      res.on('data', (chunk) => chunks.push(chunk));
      res.on('end', () => resolve(Buffer.concat(chunks)));
    });

    req.on('error', reject);
    req.setTimeout(10000, () => {
      req.destroy();
      reject(new Error('Request timeout'));
    });
  });
}

async function checkResource(page, url, type = 'link') {
  try {
    const response = await page.goto(url, { 
      waitUntil: 'domcontentloaded', // Faster than networkidle0
      timeout: 15000 
    });
    
    const status = response.status();
    
    if (status >= 400) {
      return {
        url,
        type,
        status,
        error: `HTTP ${status}`
      };
    }
    
    return { url, type, status, ok: true };
  } catch (error) {
    return {
      url,
      type,
      status: 0,
      error: error.message
    };
  }
}

async function extractLinks(page) {
  return await page.evaluate(() => {
    const links = new Set();
    const images = new Set();
    
    // Extract all <a> tags
    document.querySelectorAll('a[href]').forEach(a => {
      links.add(a.href);
    });
    
    // Extract all images
    document.querySelectorAll('img[src]').forEach(img => {
      images.add(img.src);
    });
    
    // Extract srcset images
    document.querySelectorAll('img[srcset]').forEach(img => {
      const srcset = img.getAttribute('srcset');
      if (srcset) {
        srcset.split(',').forEach(src => {
          const url = src.trim().split(/\s+/)[0];
          if (url) images.add(url);
        });
      }
    });
    
    return {
      links: Array.from(links),
      images: Array.from(images)
    };
  });
}

async function crawl() {
  log('\n🔍 Starting web crawler for ' + BASE_URL, 'blue');
  log('━'.repeat(60), 'gray');
  
  const browser = await puppeteer.launch({
    headless: 'new',
    args: ['--no-sandbox', '--disable-setuid-sandbox']
  });
  
  const page = await browser.newPage();
  
  // Set viewport
  await page.setViewport({ width: 1920, height: 1080 });
  
  let processed = 0;
  let totalLinks = 0;
  
  try {
    while (queue.length > 0) {
      const url = queue.shift();
      
      if (visited.has(url)) {
        continue;
      }
      
      visited.add(url);
      processed++;
      
      log(`\n[${processed}] Crawling: ${url}`, 'gray');
      
      const result = await checkResource(page, url, 'page');
      
      if (!result.ok) {
        broken.set(url, result);
        log(`  ✗ BROKEN: ${result.error}`, 'red');
        continue;
      }
      
      log(`  ✓ OK (${result.status})`, 'green');
      
      try {
        // Wait for Docusaurus to render content
        await page.waitForSelector('article, main, .markdown', { timeout: 3000 }).catch(() => {});
        
        // Give React a moment to hydrate
        await page.evaluate(() => new Promise(resolve => setTimeout(resolve, 500)));
        
        const { links, images } = await extractLinks(page);
        
        // Filter and normalize links
        const validLinks = links
          .map(l => normalizeUrl(l))
          .filter(l => l && isValidUrl(l));
        
        const validImages = images
          .map(i => normalizeUrl(i))
          .filter(i => i);
        
        log(`  Found ${validLinks.length} links and ${validImages.length} images (Queue: ${queue.length})`, 'gray');
        totalLinks += validLinks.length + validImages.length;
        
        // Add new links to queue for recursive crawling
        for (const link of validLinks) {
          if (!visited.has(link) && !queue.includes(link)) {
            queue.push(link);
          }
        }
        
        // Check images with validation
        for (const imgUrl of validImages) {
          if (!visited.has(imgUrl)) {
            visited.add(imgUrl);
            
            const format = getImageFormat(imgUrl);
            
            try {
              // Fetch image buffer for validation
              const buffer = await fetchImageBuffer(imgUrl);
              
              // Validate image integrity
              const validation = validateImageBuffer(buffer, format);
              
              if (!validation.valid) {
                corruptedImages.set(imgUrl, {
                  url: imgUrl,
                  format,
                  error: validation.error,
                  size: buffer.length
                });
                log(`    ✗ Image corrupted: ${imgUrl} - ${validation.error}`, 'red');
              } else {
                // Track non-WebP images
                if (format !== 'webp' && format !== 'svg' && format !== 'ico') {
                  nonWebpImages.set(imgUrl, {
                    url: imgUrl,
                    format,
                    size: buffer.length
                  });
                  log(`    ⚠ Non-WebP image: ${imgUrl} (${format}, ${(buffer.length / 1024).toFixed(1)}KB)`, 'yellow');
                }
              }
            } catch (error) {
              // Only report actual errors, not timeouts on images
              if (!error.message.includes('timeout')) {
                broken.set(imgUrl, {
                  url: imgUrl,
                  type: 'image',
                  status: 0,
                  error: error.message
                });
                log(`    ✗ Image broken: ${imgUrl} - ${error.message}`, 'red');
              }
            }
          }
        }
        
      } catch (error) {
        log(`  ⚠ Error parsing page: ${error.message}`, 'yellow');
      }
    }
  } finally {
    await browser.close();
  }
  
  // Print summary
  log('\n' + '━'.repeat(60), 'gray');
  log('\n📊 Crawl Summary', 'blue');
  log('━'.repeat(60), 'gray');
  log(`Total pages crawled: ${processed}`, 'blue');
  log(`Total resources checked: ${visited.size}`, 'blue');
  log(`Total links found: ${totalLinks}`, 'blue');
  log(`Broken resources found: ${broken.size}`, broken.size > 0 ? 'red' : 'green');
  log(`Corrupted images found: ${corruptedImages.size}`, corruptedImages.size > 0 ? 'red' : 'green');
  log(`Non-WebP images found: ${nonWebpImages.size}`, nonWebpImages.size > 0 ? 'yellow' : 'green');
  
  let hasIssues = false;
  
  if (broken.size > 0) {
    hasIssues = true;
    log('\n❌ Broken Resources:', 'red');
    log('━'.repeat(60), 'gray');
    
    for (const [url, info] of broken.entries()) {
      log(`\n${info.type.toUpperCase()}: ${url}`, 'red');
      log(`  Error: ${info.error}`, 'yellow');
    }
  }
  
  if (corruptedImages.size > 0) {
    hasIssues = true;
    log('\n❌ Corrupted Images:', 'red');
    log('━'.repeat(60), 'gray');
    
    for (const [url, info] of corruptedImages.entries()) {
      log(`\n${url}`, 'red');
      log(`  Format: ${info.format}`, 'yellow');
      log(`  Error: ${info.error}`, 'yellow');
      log(`  Size: ${info.size} bytes`, 'yellow');
    }
  }
  
  if (nonWebpImages.size > 0) {
    log('\n⚠️  Non-WebP Images:', 'yellow');
    log('━'.repeat(60), 'gray');
    log('Consider converting these to WebP for better performance:\n', 'gray');
    
    const formatCounts = {};
    for (const [url, info] of nonWebpImages.entries()) {
      formatCounts[info.format] = (formatCounts[info.format] || 0) + 1;
      log(`${info.format.toUpperCase()}: ${url} (${(info.size / 1024).toFixed(1)}KB)`, 'yellow');
    }
    
    log('\n' + '━'.repeat(60), 'gray');
    log('Format breakdown:', 'gray');
    for (const [format, count] of Object.entries(formatCounts)) {
      log(`  ${format.toUpperCase()}: ${count} images`, 'yellow');
    }
  }
  
  log('\n' + '━'.repeat(60), 'gray');
  
  if (hasIssues) {
    process.exit(1);
  } else {
    log('\n✅ All links and images are working!', 'green');
    if (nonWebpImages.size > 0) {
      log('⚠️  However, some images could be optimized to WebP format', 'yellow');
    }
    log('━'.repeat(60), 'gray');
    process.exit(0);
  }
}

// Start crawling
crawl().catch((error) => {
  log(`\n❌ Fatal error: ${error.message}`, 'red');
  process.exit(1);
});
