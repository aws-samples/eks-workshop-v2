import { visit } from "unist-util-visit";
import { promises as fs } from "fs";
import * as path from "path";

const regex = /(\w+)=([^\s]+)/g;

const plugin = (options) => {
  const manifestsDir = options.manifestsDir;

  const transformer = async (ast, vfile) => {
    const promises = [];
    visit(ast, "code", (node) => {
      if (node.lang === "file") {
        const value = node.value;

        let hidePath = false;
        var m;

        if (node.meta) {
          while ((m = regex.exec(node.meta)) !== null) {
            const key = m[1];
            const metaValue = m[2];

            switch (key) {
              case "hidePath":
                hidePath = metaValue === "true";
                break;
            }
          }
        }

        const normalizedPath = `${path.normalize(`${value}`)}`;

        let title = `/eks-workshop/${normalizedPath}`;

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

export default plugin;
