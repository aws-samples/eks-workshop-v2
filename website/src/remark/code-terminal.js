const visit = require('unist-util-visit');

const plugin = (options) => {
  const transformer = async (ast, vfile) => {
    visit(ast, 'code', (node) => {
      if(node.lang === 'bash') {
        value = node.value
        
        parts = value.split('\n')

        commandParts = []

        do {
          commandPart = parts.shift()
          commandParts.push(commandPart)
        } while (commandPart.endsWith(' \\'));

        command = commandParts.join(' \n').replaceAll("\"", "'")
        output = parts.join('\n').replaceAll("\"", "'")

        // TODO: Is this necessary? Was having issues with formatting
        output = Buffer.from(output).toString('base64')

        node.type = 'jsx'
        
        node.value= `<terminal command="${command}" output="${output}"></terminal>`

        delete node.lang
      }
    });
  };
  return transformer;
};

module.exports = plugin;