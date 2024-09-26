// https://github.com/facebook/docusaurus/issues/395#issuecomment-1406242394

import { visit } from "unist-util-visit";

const plugin = (options) => {
  const transformer = async (ast) => {
    visit(ast, ["text", "code"], (node) => {
      node.value = node.value.replace(/VAR::([A-Z_]+)/g, (match, varName) => {
        return options.replacements[varName] || match;
      });
    });

    visit(ast, ["link"], (node) => {
      node.url = node.url.replace(/VAR::([A-Z_]+)/g, (match, varName) => {
        return options.replacements[varName] || match;
      });
    });
  };
  return transformer;
};

export default plugin;
