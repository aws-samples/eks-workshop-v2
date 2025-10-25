import { visit } from "unist-util-visit";

const regex = /(\w+)=([^\s]+)/g;

const plugin = (options) => {
  const transformer = async (ast, vfile) => {
    visit(ast, "code", (node, index, parent) => {
      if (node.lang === "bash") {
        const value = node.value;

        var smartMode = false;
        var m;

        if (node.meta) {
          while ((m = regex.exec(node.meta)) !== null) {
            const key = m[1];
            const metaValue = m[2];

            switch (key) {
              case "smartMode":
                smartMode = metaValue === "true";
                break;
            }
          }
        }

        const jsxNode = {
          type: "mdxJsxFlowElement",
          name: "Terminal",
          attributes: [
            {
              type: "mdxJsxAttribute",
              name: "output",
              value: Buffer.from(value).toString("base64"),
            },
          ],
          children: [],
        };

        parent.children.splice(index, 1, jsxNode);
      }
    });
  };
  return transformer;
};

export default plugin;
