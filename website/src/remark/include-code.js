const visit = require('unist-util-visit');
const fs = require('fs/promises');
var path = require('path');

const modulesPath = '/workspace/modules'

const plugin = (options) => {
  const manifestsDir = options.manifestsDir

  const transformer = async (ast, vfile) => {
    const promises = [];
    visit(ast, 'code', (node) => {
      if(node.lang === 'file') {
        value = node.value

        const filePath = `${manifestsDir}/${value}`
        const extension = path.extname(filePath).slice(1)

        node.lang = extension
        node.meta = `title="${path.normalize(`${modulesPath}/${value}`)}"`

        const p = fs.readFile(filePath, { encoding: 'utf8' }).then(res => {
          node.value = res
        });
        promises.push(p);
      }
    });
    await Promise.all(promises);
  };
  return transformer;
};

module.exports = plugin;
