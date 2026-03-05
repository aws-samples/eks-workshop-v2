# Broken Links Checker v2

An optimized web crawler that scans http://localhost:3000/ for broken links and images with parallel processing.

## Why v2?

The v2 checker improves upon v1 with:

- **33% Faster**: Completes in ~200s vs ~300s for the same site
- **Parallel Crawling**: Processes 5 pages simultaneously instead of sequentially
- **Simpler Code**: Cleaner implementation, easier to maintain
- **Better Resource Usage**: Batch processing reduces memory overhead
- **Focused Validation**: Checks link availability without deep image analysis

## Features

- Recursively crawls all pages within localhost:3000
- Parallel page processing (5 concurrent pages)
- Checks HTTP status codes for all links and images
- Fast HTTP-based image validation
- Skips data: URLs (inline images)
- Reports broken resources with error details
- Color-coded terminal output
- CI-friendly exit codes

## Performance

- Scans ~380 pages and ~580 resources in approximately 200 seconds
- 33% faster than v1 through parallel processing
- Lower memory footprint with batch processing

## Usage

### Using Make

```bash
make check-broken-links-v2
```

### Using Yarn

```bash
yarn check-broken-links-v2
```

### Direct Execution

```bash
node hack/check-broken-links-v2.js
```

## Prerequisites

Make sure the development server is running on http://localhost:3000:

```bash
# In one terminal
make serve

# In another terminal
make check-broken-links-v2
```

## Output

The script provides:
- Real-time crawling progress with page-by-page updates
- Status indicators for broken links and images
- Summary with performance metrics (duration, pages, links checked)
- Detailed broken links report with parent page references
- Redirect warnings for links that could be optimized

## Configuration

The v2 checker is configured with sensible defaults:

- **Concurrency**: 5 parallel pages (configurable in code)
- **Timeout**: 15 seconds per page load
- **Image Timeout**: 10 seconds per image check
- **Wait Time**: 300ms for JavaScript rendering

To customize, edit `hack/check-broken-links-v2.js` and modify the `CONCURRENCY` constant or timeouts.

## Exit Codes

- `0`: All links and images are working
- `1`: Broken links or images found, or fatal error occurred

## Comparison with v1

| Feature | v1 (Puppeteer) | v2 (Optimized Puppeteer) |
|---------|----------------|--------------------------|
| Performance | ~300s for 388 pages | ~200s for 380 pages (33% faster) |
| Parallel crawling | ❌ Sequential | ✅ 5 concurrent pages |
| Image validation | ✅ (magic bytes) | ✅ (HTTP status only) |
| WebP warnings | ✅ | ❌ |
| Image corruption detection | ✅ | ❌ |
| Memory usage | Higher | Lower (parallel batching) |
| Code complexity | Higher | Lower |
| Progress reporting | Detailed | Cleaner |

## When to Use Which Version

**Use v1 if:**
- You need image format validation (WebP recommendations)
- You need to validate magic bytes for image integrity
- You want detailed image corruption detection

**Use v2 if:**
- You want faster execution (33% speed improvement)
- You prefer cleaner, simpler code
- You're focused on broken links rather than image optimization
- You want parallel crawling for better resource utilization

## Advanced Usage

### Adjust Concurrency

Edit `hack/check-broken-links-v2.js` and change the `CONCURRENCY` constant:

```javascript
const CONCURRENCY = 10;  // Increase for faster scanning (uses more resources)
```

### Adjust Timeouts

Modify timeout values in the code:

```javascript
// Page load timeout
timeout: 20000  // Increase if pages are slow to load

// Image check timeout
req.setTimeout(15000, ...)  // Increase for slow image servers
```

## Troubleshooting

**Pages timing out?**
- Increase the page load timeout (default: 15000ms)
- Check your network connection
- Reduce concurrency if system is overloaded

**Too many false positives?**
- Check if external resources are blocking automated requests
- Review the broken resources list for patterns

**Memory issues?**
- Reduce concurrency (default: 5)
- Run on a machine with more RAM
