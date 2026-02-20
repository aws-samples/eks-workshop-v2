#!/usr/bin/env node

/**
 * Broken Link Checker v2 - Optimized Puppeteer crawler
 * 
 * Improvements over v1:
 * - Parallel page checking with worker pool
 * - Faster link extraction (no waiting for selectors)
 * - Batch image validation
 * - Better progress reporting
 * - Configurable concurrency
 * - Skips image format/magic byte validation (focus on broken links)
 */

const puppeteer = require('puppeteer');
const http = require('http');
const https = require('https');

const BASE_URL = 'http://localhost:3000';
const CONCURRENCY = 5; // Number of parallel pages to check
const visited = new Set();
const broken = new Map();
const queue = [BASE_URL];

// ANSI color codes
const colors = {
  reset: '\x1b[0m',
  green: '\x1b[32m',
  red: '\x1b[31m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
  gray: '\x1b[90m',
  cyan: '\x1b[36m'
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

async function checkResource(url) {
  return new Promise((resolve) => {
    try {
      const urlObj = new URL(url);
      
      // Skip data: URLs (inline images)
      if (urlObj.protocol === 'data:') {
        resolve({ url, status: 200, ok: true, skipped: true });
        return;
      }
      
      const client = urlObj.protocol === 'https:' ? https : http;
      
      const req = client.get(url, (res) => {
        const status = res.statusCode;
        resolve({ url, status, ok: status < 400 });
        res.resume(); // Consume response data to free up memory
      });

      req.on('error', (error) => {
        resolve({ url, status: 0, ok: false, error: error.message });
      });

      req.setTimeout(10000, () => {
        req.destroy();
        resolve({ url, status: 0, ok: false, error: 'Timeout' });
      });
    } catch (error) {
      resolve({ url, status: 0, ok: false, error: error.message });
    }
  });
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

async function crawlPage(browser, url) {
  const page = await browser.newPage();
  
  try {
    await page.setViewport({ width: 1920, height: 1080 });
    
    const response = await page.goto(url, { 
      waitUntil: 'domcontentloaded',
      timeout: 15000 
    });
    
    const status = response.status();
    
    if (status >= 400) {
      broken.set(url, { url, status, error: `HTTP ${status}` });
      return [];
    }
    
    // Quick wait for content (no selector waiting)
    await page.evaluate(() => new Promise(resolve => setTimeout(resolve, 300)));
    
    const { links, images } = await extractLinks(page);
    
    // Normalize and filter
    const validLinks = links
      .map(l => normalizeUrl(l))
      .filter(l => l && isValidUrl(l));
    
    const validImages = images
      .map(i => normalizeUrl(i))
      .filter(i => i);
    
    // Check images in parallel (fast HTTP HEAD requests)
    const imageChecks = validImages
      .filter(img => !visited.has(img))
      .map(img => {
        visited.add(img);
        return checkResource(img).then(result => {
          if (!result.ok) {
            broken.set(img, result);
          }
        });
      });
    
    await Promise.all(imageChecks);
    
    return validLinks;
    
  } catch (error) {
    broken.set(url, { url, status: 0, error: error.message });
    return [];
  } finally {
    await page.close();
  }
}

async function crawl() {
  const startTime = Date.now();
  
  log('\n🔍 Starting optimized link checker v2', 'blue');
  log(`Target: ${BASE_URL}`, 'cyan');
  log(`Concurrency: ${CONCURRENCY} parallel pages`, 'cyan');
  log('━'.repeat(60), 'gray');
  
  const browser = await puppeteer.launch({
    headless: 'new',
    args: ['--no-sandbox', '--disable-setuid-sandbox']
  });
  
  let processed = 0;
  
  try {
    while (queue.length > 0) {
      // Get batch of URLs to process
      const batch = [];
      while (batch.length < CONCURRENCY && queue.length > 0) {
        const url = queue.shift();
        
        if (visited.has(url)) {
          continue;
        }
        
        visited.add(url);
        batch.push(url);
      }
      
      if (batch.length === 0) {
        break;
      }
      
      // Process batch in parallel
      const results = await Promise.all(
        batch.map(async (url) => {
          processed++;
          log(`[${processed}] Crawling: ${url} (Queue: ${queue.length})`, 'gray');
          return crawlPage(browser, url);
        })
      );
      
      // Add new links to queue
      for (const newLinks of results) {
        for (const link of newLinks) {
          if (!visited.has(link) && !queue.includes(link)) {
            queue.push(link);
          }
        }
      }
    }
    
  } finally {
    await browser.close();
  }
  
  const duration = ((Date.now() - startTime) / 1000).toFixed(2);
  
  // Print summary
  log('\n' + '━'.repeat(60), 'gray');
  log('\n📊 Scan Summary', 'blue');
  log('━'.repeat(60), 'gray');
  log(`Duration: ${duration}s`, 'cyan');
  log(`Pages crawled: ${processed}`, 'blue');
  log(`Total resources checked: ${visited.size}`, 'blue');
  log(`Broken resources: ${broken.size}`, broken.size > 0 ? 'red' : 'green');
  
  if (broken.size > 0) {
    log('\n❌ Broken Resources:', 'red');
    log('━'.repeat(60), 'gray');
    
    for (const [url, info] of broken.entries()) {
      log(`\n${url}`, 'red');
      log(`  Status: ${info.status}`, 'yellow');
      if (info.error) {
        log(`  Error: ${info.error}`, 'yellow');
      }
    }
  }
  
  log('\n' + '━'.repeat(60), 'gray');
  
  if (broken.size > 0) {
    log('\n❌ Link check failed!', 'red');
    log('━'.repeat(60), 'gray');
    process.exit(1);
  } else {
    log('\n✅ All links and images are working!', 'green');
    log('━'.repeat(60), 'gray');
    process.exit(0);
  }
}

// Start crawling
crawl().catch((error) => {
  log(`\n❌ Fatal error: ${error.message}`, 'red');
  process.exit(1);
});
