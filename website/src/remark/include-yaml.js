import { visit } from "unist-util-visit";
import { promises as fs } from "fs";
import * as path from "path";
import * as YAML from "yaml";
import { findPair } from "yaml/util";

const plugin = (options) => {
  const manifestsDir = options.manifestsDir;

  const transformer = async (ast, vfile) => {
    const promises = [];
    visit(ast, "leafDirective", (node, index, parent) => {
      if (node.name !== "yaml") return;

      const attributes = node.attributes;

      const normalizedPath = `${path.normalize(`${attributes.file}`)}`;

      let title = attributes.title || `/eks-workshop/${normalizedPath}`;

      if (normalizedPath.startsWith("manifests/")) {
        title = `${normalizedPath}`.replace(
          "manifests",
          "~/environment/eks-workshop",
        );
      }

      const filePath = `${manifestsDir}/${attributes.file}`;

      // TODO check extension is yaml

      var highlightPathsString = attributes.paths;
      var zoomPathString = attributes.zoomPath;
      var zoomPathBefore = parseInt(attributes.zoomBefore) || 0;
      var zoomPathAfter = parseInt(attributes.zoomAfter) || 0;

      const p = fs.readFile(filePath, { encoding: "utf8" }).then((res) => {
        let finalString = res.replaceAll("$", "\\$");

        let annotations = [];
        let zoomed = false;

        if (highlightPathsString) {
          let highlightPaths = highlightPathsString.split(",");

          if (parent.children.length > index + 1) {
            const annotationListNode = parent.children[index + 1];

            if (annotationListNode?.type === "list") {
              annotations = annotationListNode.children.map((e) => {
                return e.children;
              });

              parent.children.splice(index + 1, 1, {
                type: "mdxJsxFlowElement",
                name: "div",
                attributes: [],
              });
            }
          }

          for (let i = 0; i < highlightPaths.length; i++) {
            const lookup = highlightPaths[i];

            const { startLine, endLine } = getLinesForPath(finalString, lookup);

            const lines = finalString.split(/\r\n|\r|\n/);

            const startSection = lines.slice(0, startLine - 1).join("\n");
            const middleSection = lines
              .slice(startLine - 1, endLine - 1)
              .join("\n");
            const endSection = lines.slice(endLine - 1).join("\n");

            const classSuffix = i % 2 == 0 ? "even" : "odd";

            finalString =
              startSection +
              `\n# annotated-highlight-start-${classSuffix}\n` +
              (annotations.length > 0 ? "# highlight-annotation\n" : "") +
              middleSection +
              `\n# annotated-highlight-end-${classSuffix}\n` +
              endSection;
          }
        }

        if (zoomPathString) {
          zoomed = true;

          const { startLine, endLine } = getLinesForPath(
            finalString,
            zoomPathString,
          );

          const lines = finalString.split(/\r\n|\r|\n/);

          let targetEndLine = endLine - 1 + zoomPathAfter;

          if (lines[targetEndLine].startsWith("#")) {
            targetEndLine = targetEndLine + 2;
          }

          finalString = lines
            .slice(startLine - 1 - zoomPathBefore, targetEndLine)
            .join("\n");
        }

        const jsxNode = {
          type: "mdxJsxFlowElement",
          name: "div",
          attributes: [],
          children: [
            {
              type: "mdxJsxFlowElement",
              name: "YamlFile",
              attributes: [
                {
                  type: "mdxJsxAttribute",
                  name: "title",
                  value: title,
                },
                {
                  type: "mdxJsxAttribute",
                  name: "zoomed",
                  value: zoomed,
                },
              ],
              children: [
                {
                  type: "mdxFlowExpression",
                  data: {
                    estree: {
                      type: "Program",
                      body: [
                        {
                          type: "ExpressionStatement",
                          expression: {
                            type: "TemplateLiteral",
                            expressions: [],
                            quasis: [
                              {
                                type: "TemplateElement",
                                value: {
                                  raw: finalString,
                                  cooked: finalString,
                                },
                                tail: true,
                              },
                            ],
                          },
                        },
                      ],
                      sourceType: "module",
                      comments: [],
                    },
                  },
                },
              ],
            },
          ].concat(
            annotations.map((e, index) => {
              return {
                type: "mdxJsxFlowElement",
                name: "YamlAnnotation",
                attributes: [
                  {
                    type: "mdxJsxAttribute",
                    name: "sequence",
                    value: `${index + 1}`,
                  },
                ],
                children: e,
              };
            }),
          ),
        };

        parent.children.splice(index, 1, jsxNode);
      });
      promises.push(p);
    });
    await Promise.all(promises);
  };
  return transformer;
};

function getLinesForPath(inputString, lookup) {
  const lineCounter = new YAML.LineCounter();
  const parser = new YAML.Parser(lineCounter.addNewLine);
  const tokens = parser.parse(inputString);

  const docs = new YAML.Composer().compose(tokens);
  const docsArray = Array.from(docs);

  // Support document index prefix (e.g., "1.spec.controller" for second document)
  let docIndex = 0;
  let pathElements = lookup.split(".").map((e) => e.trim());
  
  if (pathElements.length > 0 && isInt(pathElements[0])) {
    docIndex = parseInt(pathElements[0]);
    pathElements = pathElements.slice(1);
  }

  const doc = docsArray[docIndex];

  const target = findByPath(doc.contents, pathElements);

  const startLine = lineCounter.linePos(target.start).line;
  const endLine = lineCounter.linePos(target.end).line;

  return {
    startLine,
    endLine,
  };
}

function findByPath(pathNode, pathElements) {
  let key = pathElements.shift();

  if (isInt(key)) {
    key = parseInt(key);
  }

  if (YAML.isMap(pathNode)) {
    const pair = findPair(pathNode.items, key);

    if (!pair) {
      throw new Error(`Unable to find ${key}`);
    }

    if (pathElements.length === 0) {
      return {
        start: pair.key.range[0],
        end: pair.value.range[2],
      };
    }

    return findByPath(pair.value, pathElements);
  } else if (YAML.isCollection(pathNode)) {
    const item = pathNode.items[key];

    if (pathElements.length === 0) {
      return {
        start: item.range[0],
        end: item.range[2],
      };
    }

    return findByPath(item, pathElements);
  }
}

function isInt(value) {
  var x;
  return isNaN(value) ? !1 : ((x = parseFloat(value)), (0 | x) === x);
}

export default plugin;
