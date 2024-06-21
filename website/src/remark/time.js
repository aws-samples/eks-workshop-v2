import { visit } from "unist-util-visit";
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

const timingData = JSON.parse(timingDataString);

const plugin = (options) => {
  const enabled = options.enabled;
  const factor = options.factor;

  const transformer = async (ast, vfile) => {
    visit(ast, "leafDirective", (node, index, parent) => {
      if (node.name !== "required-time") return;

      if (!enabled) {
        parent.children.splice(index, 1);
        return;
      }

      let defaultAttributes = { estimatedLabExecutionTimeMinutes: "0" };

      let attributes = { ...defaultAttributes, ...node.attributes };

      const filePath = vfile.history[0];
      const relativePath = path.relative(`${vfile.cwd}/docs`, filePath);

      if (attributes.estimatedLabExecutionTimeMinutes === "0") {
        attributes.estimatedLabExecutionTimeMinutes = calculateLabExecutionTime(
          relativePath,
          timingData,
        );
      }

      let totalTime =
        Math.ceil(
          ((calculateReadingTime(filePath) +
            parseInt(attributes.estimatedLabExecutionTimeMinutes)) *
            factor) /
            5,
        ) * 5;

      const jsxNode = {
        type: "mdxJsxFlowElement",
        name: "p",
        attributes: [],
        children: [
          {
            type: "mdxJsxTextElement",
            name: "b",
            attributes: [],
            children: [
              {
                type: "text",
                value: "Estimated time required:",
              },
            ],
            data: {
              _mdxExplicitJsx: true,
            },
          },
          {
            type: "text",
            value: ` ${totalTime} minutes`,
          },
        ],
      };

      parent.children.splice(index, 1, jsxNode);
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

  const timingDataEntry = timingData[relativePath];

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

export default plugin;
