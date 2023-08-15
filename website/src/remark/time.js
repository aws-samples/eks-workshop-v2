const visit = require('unist-util-visit');
const fs = require('fs');
const yamljs = require('yamljs');
const path = require("path");
const { globSync } = require("glob");
const readingTime = require('reading-time');
const { parsePairs } = require('parse-pairs')

const plugin = (options) => {

  const transformer = async (ast, vfile) => {
    visit(ast, 'text', (node) => {
      const regex = /{{% required-time(.*?) %}}/;

      if ((m = regex.exec(node.value)) !== null) {
        /*m.forEach((match, groupIndex) => {
          console.log(`Found match, group ${groupIndex}: ${match}`);
        });*/

        let attributes = {estimatedLabExecutionTimeMinutes: 0};

        if(m.length > 1) {
          let attributeString = m[1];

          if(attributeString) {
            let parsed = parsePairs(m[1]);

            Object.keys(parsed).forEach(key => {
              switch(key) {
                case 'estimatedLabExecutionTimeMinutes':
                  attributes.estimatedLabExecutionTimeMinutes = parseInt(parsed[key])
                  break;
              }
            });
          }
        }

        const filePath = vfile.history[0]
        const relativePath = path.relative(`${vfile.cwd}/docs`, filePath)

        if(attributes.estimatedLabExecutionTimeMinutes == 0) {
          attributes.estimatedLabExecutionTimeMinutes = calculateLabExecutionTime(relativePath)
        }

        let totalTime = Math.ceil((calculateReadingTime(filePath) + attributes.estimatedLabExecutionTimeMinutes) / 5) * 5;

        node.type = 'jsx'
        
        node.value= `<p><b>Estimated time required:</b> ${totalTime} minutes</p>`

        delete node.lang
      }
    });
  };
  return transformer;
};

function calculateReadingTime(filePath) {
  const directory = path.dirname(filePath);

  const mdFiles = globSync('**/*.{md,mdx}', { cwd: directory })

  let totalReadingTime = 0;

  for(let i = 0; i < mdFiles.length; i++) {
    const filename = mdFiles[i];

    const fileData = fs.readFileSync(path.join(directory, filename),
      { encoding: 'utf8', flag: 'r' });
    const stats = readingTime(fileData);

    totalReadingTime += stats.minutes;
  }

  return totalReadingTime;
}

function calculateLabExecutionTime(relativePath) {
  moduleName = relativePath.split(path.sep)[0]

  const timingDataString = fs.readFileSync(`../test/timings/data/${moduleName}.json`,
      { encoding: 'utf8', flag: 'r' });

  timingData = JSON.parse(timingDataString)

  let labExecutionTime = 0;

  for(let j = 0; j < timingData.length; j++) {
    timingDataEntry = timingData[j];

    if(timingDataEntry.file == relativePath) {
      labExecutionTime = timingDataEntry.executionTimeSeconds / 60
    }
  }

  if(labExecutionTime === 0) {
    throw new Error(`Got 0 lab execution time for ${relativePath}`)
  }

  return labExecutionTime;
}

module.exports = plugin;
