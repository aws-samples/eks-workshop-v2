const visit = require('unist-util-visit');
const fs = require('fs/promises');
const path = require('path');
const yaml = require('yamljs');
const { parse } = require('path');
const Diff = require('diff');

const plugin = (options) => {
  const terraformDir = options.terraformDir

  const transformer = async (ast) => {
    const promises = [];
    visit(ast, 'code', (node, index, parent) => {
      if(node.lang === 'addon') {
        const addonName = node.value

        node.type = 'jsx'

        const shellPromise = execShellCommand(`terraform -chdir=${terraformDir} output -json blueprints_addons`)
          .then(
            res => {
              const parsed = JSON.parse(res)

              const addon = parsed[addonName]

              const helmRelease = addon.helm_release['0']

              //console.log(helmRelease)

              values = Buffer.from(yaml.stringify(JSON.parse(helmRelease.metadata[0].values), 99, 2)).toString('base64')

              node.value= `<blueprintsAddon name="${helmRelease.name}" values="${values}" namespace="${helmRelease.namespace}" repository="${helmRelease.repository}" chart="${helmRelease.chart}" version="${helmRelease.version}" link="${addon.link}"></blueprintsAddon>`
          });

        promises.push(shellPromise);
      }
    });
    await Promise.all(promises);
  };
  return transformer;
};

function execShellCommand(cmd) {
  const exec = require('child_process').exec;

  return new Promise((resolve, reject) => {
    exec(cmd, (error, stdout, stderr) => {
      if (error) {
        console.warn(error);
      }
      resolve(stdout? stdout : stderr);
    });
  });
 }

module.exports = plugin;
