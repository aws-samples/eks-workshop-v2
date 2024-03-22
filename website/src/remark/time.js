const visit = require("unist-util-visit");
const fs = require("fs");
const yamljs = require("yamljs");
const path = require("path");
const { globSync } = require("glob");
const readingTime = require("reading-time");
const { parsePairs } = require("parse-pairs");

const timingDataString = fs.readFileSync(`./lab-timing-data.json`, {
  encoding: "utf8",
  flag: "r",
});

timingData = JSON.parse(timingDataString);

const plugin = (options) => {
  const enabled = options.enabled;
  const factor = options.factor;

  const transformer = async (ast, vfile) => {
    visit(ast, "text", (node) => {
      const regex = /{{% required-time(.*?) %}}/;

      if ((m = regex.exec(node.value)) !== null) {
        if (!enabled) {
          node.value = "";
          return;
        }

        let attributes = { estimatedLabExecutionTimeMinutes: 0 };

        if (m.length > 1) {
          let attributeString = m[1];

          if (attributeString) {
            let parsed = parsePairs(m[1]);

            Object.keys(parsed).forEach((key) => {
              switch (key) {
                case "estimatedLabExecutionTimeMinutes":
                  attributes.estimatedLabExecutionTimeMinutes = parseInt(
                    parsed[key],
                  );
                  break;
              }
            });
          }
        }

        const filePath = vfile.history[0];
        const relativePath = path.relative(`${vfile.cwd}/docs`, filePath);

        if (attributes.estimatedLabExecutionTimeMinutes == 0) {
          attributes.estimatedLabExecutionTimeMinutes =
            calculateLabExecutionTime(relativePath, timingData);
        }

        let totalTime =
          Math.ceil(
            ((calculateReadingTime(filePath) +
              attributes.estimatedLabExecutionTimeMinutes) *
              factor) /
              5,
          ) * 5;

        node.type = "jsx";

        node.value = `<p><b>Estimated time required:</b> ${totalTime} minutes</p>`;

        delete node.lang;
      }
    });
  };
  return transformer;
};

function calculateReadingTime(filePath) {
  const directory = path.dirname(filePath);

  const mdFiles = globSync("**/*.{md,mdx}", { cwd: directory });

  let totalReadingTime = 0;

  for (let i = 0; i < mdFiles.length; i++) {
    const filename = mdFiles[i];

    const fileData = fs.readFileSync(path.join(directory, filename), {
      encoding: "utf8",
      flag: "r",
    });
    const stats = readingTime(fileData);

    totalReadingTime += stats.minutes;
  }

  return totalReadingTime;
}

function calculateLabExecutionTime(relativePath, timingData) {
  let labExecutionTime = 0;

  timingDataEntry = timingData[relativePath];

  if (timingDataEntry) {
    labExecutionTime = timingDataEntry.executionTimeSeconds / 60;
  } else {
    console.log(`Failed to find ${relativePath}`);
  }

  if (labExecutionTime === 0) {
    throw new Error(`Got 0 lab execution time for ${relativePath}`);
  }

  return labExecutionTime;
}

module.exports = plugin;
