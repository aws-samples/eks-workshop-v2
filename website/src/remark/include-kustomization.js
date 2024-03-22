const visit = require("unist-util-visit");
const fs = require("fs/promises");
const path = require("path");
const yamljs = require("yamljs");
const YAML = require("yaml");
const { parse } = require("path");
const Diff = require("diff");

const plugin = (options) => {
  const manifestsDir = options.manifestsDir;

  const transformer = async (ast, vfile) => {
    const promises = [];
    visit(ast, "code", (node, index, parent) => {
      if (node.lang === "kustomization") {
        const value = node.value;

        const parts = value.split("\n");

        const file = parts[0];
        const resource = parts[1];

        const filePath = path.normalize(`${manifestsDir}/${file}`);
        const kustomizationPath = path.dirname(filePath);

        const resourceParts = resource.split("/");
        const resourceKind = resourceParts[0];
        const resourceName = resourceParts[1];

        node.type = "jsx";

        const filePromise = fs.readFile(filePath, { encoding: "utf8" });
        const originalPromise = readKustomization(kustomizationPath).then(
          (res) => {
            let base = "";
            if ("bases" in res) {
              base = res["bases"][0];
            } else if ("resources" in res) {
              base = res["resources"][0];
            }

            if (base) {
              const actualPath = path.normalize(`${kustomizationPath}/${base}`);

              return generateYaml(
                actualPath,
                resourceKind,
                resourceName,
                false,
              );
            }

            return Promise.resolve({ complete: res, manifest: "" });
          },
        );
        const mutatedPromise = generateYaml(
          kustomizationPath,
          resourceKind,
          resourceName,
          true,
        );

        const nicePath = `~/environment/eks-workshop/${file}`;

        const p = Promise.all([
          filePromise,
          originalPromise,
          mutatedPromise,
        ]).then((res) => {
          const mutatedManifest = res[2].manifest;

          let originalManifest = "";

          if (res[1] !== null) {
            originalManifest = res[1].manifest;
          }

          const diff = Diff.createPatch(
            "dummy",
            originalManifest,
            mutatedManifest,
          );

          const kustomizeEncoded = Buffer.from(res[0]).toString("base64");
          const completeEncoded =
            Buffer.from(mutatedManifest).toString("base64");
          const diffEncoded = Buffer.from(diff).toString("base64");

          node.value = `<kustomization resource="${resource}" path="${nicePath}" kustomize="${kustomizeEncoded}" complete="${completeEncoded}" diff="${diffEncoded}"></kustomization>`;
        });
        promises.push(p);
      }
    });
    await Promise.all(promises);
  };
  return transformer;
};

function readKustomization(path) {
  const filePromise = fs.readFile(`${path}/kustomization.yaml`, {
    encoding: "utf8",
  });

  return filePromise.then((res) => {
    return yamljs.parse(res);
  });
}

function generateYaml(path, kind, resource, failOnMissing) {
  return execShellCommand(`kubectl kustomize ${path}`).then((res) => {
    return new Promise((resolve, reject) => {
      // (*)
      const parts = res.split("---");
      for (let i = 0; i < parts.length; i++) {
        const e = parts[i];
        const parsed = yamljs.parse(e);

        if (
          parsed["kind"] === kind &&
          parsed["metadata"]["name"] === resource
        ) {
          return resolve({ complete: res, manifest: YAML.stringify(parsed) });
        }
      }

      if (failOnMissing) {
        return reject(`Failed to find resource ${kind}/${resource} at ${path}`);
      }

      return resolve(null);
    });
  });
}

function execShellCommand(cmd) {
  const exec = require("child_process").exec;

  return new Promise((resolve, reject) => {
    exec(cmd, (error, stdout, stderr) => {
      if (error) {
        console.warn(`Error running shell command: ${error}`);
      }
      resolve(stdout ? stdout : stderr);
    });
  });
}

module.exports = plugin;
