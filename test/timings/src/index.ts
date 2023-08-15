/*var xml2js = require("xml2js");
var xpath = require("xml2js-xpath");

let xml = `
<testsuite name="Mocha Tests" tests="6" failures="0" errors="0" skipped="1" timestamp="Tue, 08 Aug 2023 16:40:52 GMT" time="507.477">
<testcase classname="EKS Workshop Unknown Logging in EKS" name="Logging in EKS" time="0"><skipped/></testcase>
<testcase classname="EKS Workshop Unknown Logging in EKS Control plane logs" name="Control plane logs" time="110.438"/>
<testcase classname="EKS Workshop Unknown Logging in EKS Control plane logs" name="Configuring control plane logs" time="56.007"/>
<testcase classname="EKS Workshop Unknown Logging in EKS Pod logging" name="Pod logging" time="136.864"/>
<testcase classname="EKS Workshop Unknown Logging in EKS Pod logging" name="Using Fluent Bit" time="3.256"/>
<testcase classname="EKS Workshop Unknown Logging in EKS Pod logging" name="Verify the logs in CloudWatch" time="7.85"/>
</testsuite>
`

xml2js.parseString(xml, function(err, json) {
  // find all elements: returns xml2js JSON of the element
  var matches = xpath.find(json, "//testcase[@classname='EKS Workshop Unknown Logging in EKS Control plane logs']");

  let total = 0;

  matches.forEach(function(value) {
    total += Math.round(parseFloat(value['$'].time))
  })

  console.log(total)
});*/
/*
import * as xml2js from "xml2js"
import * as xpath from "xml2js-xpath"
import { Gatherer } from "./lib/gatherer.js"

async function xml2json(xml: string): Promise<any> {
  return new Promise((resolve, reject) => {
    xml2js.parseString(xml, function(err, json) {
      if(err) {
        reject(err);
      }
      else {
        resolve(json);
      }
    });
  });
}

let xml = `
<testsuite name="Mocha Tests" tests="6" failures="0" errors="0" skipped="1" timestamp="Tue, 08 Aug 2023 16:40:52 GMT" time="507.477">
<testcase classname="EKS Workshop Unknown Logging in EKS" name="Logging in EKS" time="0"><skipped/></testcase>
<testcase classname="EKS Workshop Unknown Logging in EKS Control plane logs" name="Control plane logs" time="110.438"/>
<testcase classname="EKS Workshop Unknown Logging in EKS Control plane logs" name="Configuring control plane logs" time="56.007"/>
<testcase classname="EKS Workshop Unknown Logging in EKS Pod logging" name="Pod logging" time="136.864"/>
<testcase classname="EKS Workshop Unknown Logging in EKS Pod logging" name="Using Fluent Bit" time="3.256"/>
<testcase classname="EKS Workshop Unknown Logging in EKS Pod logging" name="Verify the logs in CloudWatch" time="7.85"/>
</testsuite>
`

let gatherer = new Gatherer();

let results = await gatherer.gather('../../website/docs/observability');

let json = await xml2json(xml);

for(let i = 0; i < results.length; i++) {
  let lab = results[i];

  let namePath = 'EKS Workshop '+lab.parts.join(' ')+ ' ' + lab.title;

  var matches = xpath.find(json, `//testcase[@classname='${namePath}']`);

  let total_lab = 0;

  matches.forEach(function(value) {
    total_lab += Math.round(parseFloat(value['$'].time))
  })

  let total = Math.ceil((((total_lab * 1000) + lab.duration) / 60000) / 5) * 5

  console.log(`Total for ${lab.title} is ${total} minutes`)
}*/

import { Gatherer } from "./lib/gatherer.js"
import * as xml2js from "xml2js"
import * as xpath from "xml2js-xpath"
import path from 'path'
import fs from "fs";

async function xml2json(xml: string): Promise<any> {
  return new Promise((resolve, reject) => {
    xml2js.parseString(xml, function(err, json) {
      if(err) {
        reject(err);
      }
      else {
        resolve(json);
      }
    });
  });
}

if(process.argv.length < 3) {
  console.log('Error: You must provide a module name');
  process.exit(1);
}

let module = process.argv[2];

let json = await xml2json(fs.readFileSync('../../test-output/test-report.xml', { encoding: 'utf8', flag: 'r' }));

let gatherer = new Gatherer();

let dir = path.resolve(`../../website/docs/${module}`);

let results = await gatherer.gather(dir);

let mapped = results.map(function(lab) {
  if(lab.estimatedLabTimeSeconds == 0) {
    let namePath = 'EKS Workshop '+lab.parts.join(' ')+ ' ' + lab.title;

    var matches = xpath.find(json, `//testcase[@classname='${namePath}']`);

    let total_lab = 0;

    matches.forEach(function(value) {
      total_lab += Math.round(parseFloat(value['$'].time))
    })

    lab.estimatedLabTimeSeconds = total_lab;
  }
  else {
    console.log(`Using pre-computed estimate for ${lab.title} - ${lab.estimatedLabTimeSeconds}`)
  }

  return {title: lab.title, directory: path.relative(path.resolve(dir, '..'), lab.directory), file: path.relative(path.resolve(dir, '..'), lab.file), executionTimeSeconds: lab.estimatedLabTimeSeconds}
});

fs.writeFileSync(`data/${module}.json`, JSON.stringify(mapped));