const visit = require('unist-util-visit');
const fs = require('fs/promises');
const path = require('path');
const yaml = require('yamljs');
const { parse } = require('path');
const Diff = require('diff');

const modulesPath = '~/modules'

const plugin = (options) => {
  const manifestsDir = options.manifestsDir
  const baseDir = `${options.manifestsDir}/../manifests`

  const transformer = async (ast, vfile) => {
    const promises = [];
    visit(ast, 'code', (node, index, parent) => {
      if(node.lang === 'kustomization') {
        const value = node.value

        const parts = value.split('\n')

        const file = parts[0]
        const resource = parts[1]

        const kustomizationPath = `${manifestsDir}/${path.dirname(file)}`

        const filePath = `${manifestsDir}/${file}`
        const extension = path.extname(filePath).slice(1)

        resourceParts = resource.split('/')
        resourceKind = resourceParts[0]
        resourceName = resourceParts[1]

        node.type = 'jsx'
        //node.meta = `title="${modulesPath}/${value}"`

        const filePromise = fs.readFile(filePath, { encoding: 'utf8' });
        const originalPromise = generateYaml(baseDir, resourceKind, resourceName)
        const mutatedPromise = generateYaml(kustomizationPath, resourceKind, resourceName)
          //return {patch: res.patch, kustomizeOutput}

        const nicePath = `~/modules/${file}`

        const p = Promise.all([filePromise, originalPromise, mutatedPromise]).then(res => {
          const originalManifest = res[1].manifest
          const mutatedManifest = res[2].manifest

          const diff = Diff.createPatch('dummy', originalManifest, mutatedManifest)

          kustomizeEncoded = Buffer.from(res[0]).toString('base64')
          completeEncoded = Buffer.from(mutatedManifest).toString('base64')
          diffEncoded = Buffer.from(diff).toString('base64')

          node.value= `<kustomization resource="${resource}" path="${nicePath}" kustomize="${kustomizeEncoded}" complete="${completeEncoded}" diff="${diffEncoded}"></kustomization>`
        });
        promises.push(p);
      }
    });
    await Promise.all(promises);
  };
  return transformer;
};

function generateYaml(path, kind, resource) {
  return execShellCommand(`kubectl kustomize ${path}`)
    .then(res => {
      return new Promise((resolve, reject) => { // (*)
        const parts = res.split('---')
        for(let i = 0; i < parts.length; i++) {
          const e = parts[i]
          const parsed = yaml.parse(e)

          if(parsed['kind'] === kind && parsed['metadata']['name'] === resource) {
            resolve({complete: res, manifest: yaml.stringify(parsed, 99, 2)})
          }
        }

        reject(`Failed to find resource ${kind}/${resource}`)
      });
    });
}

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