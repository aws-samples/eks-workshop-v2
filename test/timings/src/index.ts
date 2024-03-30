import { Gatherer } from "./lib/gatherer.js";
import * as xml2js from "xml2js";
import * as xpath from "xml2js-xpath";
import path from "path";
import fs from "fs";

async function xml2json(xml: string): Promise<any> {
  return new Promise((resolve, reject) => {
    xml2js.parseString(xml, function (err, json) {
      if (err) {
        reject(err);
      } else {
        resolve(json);
      }
    });
  });
}

if (process.argv.length < 3) {
  console.log("Error: You must provide a module name");
  process.exit(1);
}

let module = process.argv[2];

let json = await xml2json(
  fs.readFileSync("../../test-output/test-report.xml", {
    encoding: "utf8",
    flag: "r",
  }),
);

let gatherer = new Gatherer();

let dir = path.resolve(`../../website/docs/${module}`);

let results = await gatherer.gather(dir);

let dataFilePath = "../../website/lab-timing-data.json";

let data: { [k: string]: any } = JSON.parse(
  fs.readFileSync(dataFilePath, "utf-8"),
);

for (let i = 0; i < results.length; i++) {
  let lab = results[i];

  if (lab.estimatedLabTimeSeconds == 0) {
    let namePath = "EKS Workshop " + lab.parts.join(" ") + " " + lab.title;

    var matches = xpath.find(json, `//testcase[@classname='${namePath}']`);

    let total_lab = 0;

    let failed = false;

    matches.forEach(function (value) {
      if (value.failure) {
        failed = true;
      }
      total_lab += Math.round(parseFloat(value["$"].time));
    });

    if (failed) {
      continue;
    }

    lab.estimatedLabTimeSeconds = total_lab;
  } else {
    console.log(
      `Using pre-computed estimate for ${lab.title} - ${lab.estimatedLabTimeSeconds}`,
    );
  }

  let file = path.relative(path.resolve(dir, ".."), lab.file);

  console.log(`Updating lab timing data for '${lab.title}'`);

  data[file] = {
    title: lab.title,
    directory: path.relative(path.resolve(dir, ".."), lab.directory),
    file,
    executionTimeSeconds: lab.estimatedLabTimeSeconds,
  };
}

fs.writeFileSync(dataFilePath, JSON.stringify(data, null, 4));
