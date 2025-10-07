import { visit } from "unist-util-visit";
const fs = require("fs");
import * as yamljs from "yamljs";
import * as path from "path";
import { globSync } from "glob";
import getReadingTime from "reading-time";

const timingDataString = fs.readFileSync(`./test-durations.json`, {
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
          path.dirname(relativePath),
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
                value: "⏱️  Estimated time required:",
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
    const stats = getReadingTime(fileData);

    totalReadingTime += stats.minutes;
  }

  return totalReadingTime;
}

function calculateLabExecutionTime(relativePath, timingData) {
  const testDuration = sumFieldsWithPrefix(timingData, `/${relativePath}`);

  if (testDuration > 0) {
    return Math.round(testDuration / 1000 / 60);
  }

  throw new Error(`No test duration found for ${relativePath}`);
}

function sumFieldsWithPrefix(obj, prefix) {
  return Object.keys(obj)
    .filter((key) => key.startsWith(prefix))
    .reduce((sum, key) => {
      const value = obj[key];
      if (typeof value === "number") {
        return sum + value;
      } else if (typeof value === "object" && value !== null) {
        return sum + sumFieldsWithPrefix(value, prefix);
      }
      return sum;
    }, 0);
}

export default plugin;
