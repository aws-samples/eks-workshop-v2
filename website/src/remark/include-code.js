const visit = require("unist-util-visit");
const fs = require("fs/promises");
var path = require("path");

const regex = /(\w+)=([^\s]+)/g;

const plugin = (options) => {
  const manifestsDir = options.manifestsDir;

  const transformer = async (ast, vfile) => {
    const promises = [];
    visit(ast, "code", (node) => {
      if (node.lang === "file") {
        value = node.value;

        hidePath = false;

        if (node.meta) {
          while ((m = regex.exec(node.meta)) !== null) {
            key = m[1];
            metaValue = m[2];

            switch (key) {
              case "hidePath":
                hidePath = metaValue === "true";
                break;
            }
          }
        }

        normalizedPath = `${path.normalize(`${value}`)}`;

        title = `/eks-workshop/${normalizedPath}`;

        if (normalizedPath.startsWith("manifests/")) {
          title = `${normalizedPath}`.replace(
            "manifests",
            "~/environment/eks-workshop",
          );
        }

        const filePath = `${manifestsDir}/${value}`;
        const extension = path.extname(filePath).slice(1);

        node.lang = extension;

        if (!hidePath) {
          node.meta = `title="${title}"`;
        }

        const p = fs.readFile(filePath, { encoding: "utf8" }).then((res) => {
          node.value = res;
        });
        promises.push(p);
      }
    });
    await Promise.all(promises);
  };
  return transformer;
};

module.exports = plugin;
