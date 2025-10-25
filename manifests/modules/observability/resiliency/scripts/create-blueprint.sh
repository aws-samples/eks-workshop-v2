#!/bin/bash

# Get Ingress URL
INGRESS_URL=$(kubectl get ingress -n ui -o jsonpath='{.items[0].status.loadBalancer.ingress[0].hostname}')

# Create the required directory structure
mkdir -p nodejs/node_modules

# Create the Node.js canary script with heartbeat blueprint
cat << EOF > nodejs/node_modules/canary.js
const { URL } = require('url');
const synthetics = require('Synthetics');
const log = require('SyntheticsLogger');
const syntheticsConfiguration = synthetics.getConfiguration();
const syntheticsLogHelper = require('SyntheticsLogHelper');

const loadBlueprint = async function () {
    const urls = ['http://${INGRESS_URL}'];

    // Set screenshot option
    const takeScreenshot = true;

    // Configure synthetics settings
    syntheticsConfiguration.disableStepScreenshots();
    syntheticsConfiguration.setConfig({
       continueOnStepFailure: true,
       includeRequestHeaders: true,
       includeResponseHeaders: true,
       restrictedHeaders: [],
       restrictedUrlParameters: []
    });

    let page = await synthetics.getPage();

    for (const url of urls) {
        await loadUrl(page, url, takeScreenshot);
    }
};

// Reset the page in-between
const resetPage = async function(page) {
    try {
        await page.goto('about:blank', {waitUntil: ['load', 'networkidle0'], timeout: 30000});
    } catch (e) {
        synthetics.addExecutionError('Unable to open a blank page. ', e);
    }
};

const loadUrl = async function (page, url, takeScreenshot) {
    let stepName = null;
    let domcontentloaded = false;

    try {
        stepName = new URL(url).hostname;
    } catch (e) {
        const errorString = \`Error parsing url: \${url}. \${e}\`;
        log.error(errorString);
        throw e;
    }

    await synthetics.executeStep(stepName, async function () {
        const sanitizedUrl = syntheticsLogHelper.getSanitizedUrl(url);

        const response = await page.goto(url, { waitUntil: ['domcontentloaded'], timeout: 30000});
        if (response) {
            domcontentloaded = true;
            const status = response.status();
            const statusText = response.statusText();

            logResponseString = \`Response from url: \${sanitizedUrl}  Status: \${status}  Status Text: \${statusText}\`;

            if (response.status() < 200 || response.status() > 299) {
                throw new Error(\`Failed to load url: \${sanitizedUrl} \${response.status()} \${response.statusText()}\`);
            }
        } else {
            const logNoResponseString = \`No response returned for url: \${sanitizedUrl}\`;
            log.error(logNoResponseString);
            throw new Error(logNoResponseString);
        }
    });

    // Wait for 15 seconds to let page load fully before taking screenshot.
    if (domcontentloaded && takeScreenshot) {
        await new Promise(r => setTimeout(r, 15000));
        await synthetics.takeScreenshot(stepName, 'loaded');
    }
    
    // Reset page
    await resetPage(page);
};

exports.handler = async () => {
    return await loadBlueprint();
};
EOF

# Zip the Node.js script
python3 - << EOL
import zipfile
with zipfile.ZipFile('canary.zip', 'w') as zipf:
    zipf.write('nodejs/node_modules/canary.js', arcname='nodejs/node_modules/canary.js')
EOL

# Ensure BUCKET_NAME is set
if [ -z "$BUCKET_NAME" ]; then
    echo "Error: BUCKET_NAME environment variable is not set."
    exit 1
fi

# Upload the zipped canary script to S3
aws s3 cp canary.zip "s3://${BUCKET_NAME}/canary-scripts/canary.zip"

echo "Canary script has been zipped and uploaded to s3://${BUCKET_NAME}/canary-scripts/canary.zip"
echo "The script is configured to check the URL: http://${INGRESS_URL}"
