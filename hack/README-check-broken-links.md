# Broken Links Checker

A web crawler that scans http://localhost:3000/ for broken links and images.

## Features

- Crawls all pages within the localhost:3000 domain
- Checks HTTP status codes for all links and images
- Reports broken resources with error details
- Color-coded terminal output for easy reading
- Exits with code 1 if broken links are found (CI-friendly)

## Usage

### Using Make

```bash
make check-broken-links
```

### Using Yarn

```bash
yarn check-broken-links
```

### Direct Execution

```bash
node hack/check-broken-links.js
```

## Prerequisites

Make sure the development server is running on http://localhost:3000 before running the checker:

```bash
# In one terminal
make serve

# In another terminal
make check-broken-links
```

## Output

The script provides:
- Real-time crawling progress
- Status for each page and resource checked
- Summary with total counts
- Detailed list of broken resources (if any)

## Exit Codes

- `0`: All links and images are working
- `1`: Broken links or images found, or fatal error occurred
