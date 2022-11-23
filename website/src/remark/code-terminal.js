const visit = require('unist-util-visit');

const regex = /(\w+)=([^\s]+)/g;

const plugin = (options) => {
  const transformer = async (ast, vfile) => {
    visit(ast, 'code', (node) => {
      if(node.lang === 'bash') {
        value = node.value

        smartMode = false

        if(node.meta) {
          while((m = regex.exec(node.meta)) !== null) {
            key = m[1]
            metaValue = m[2]

            switch(key) {
              case 'smartMode':
                smartMode = (metaValue === 'true')
                break;
            }
          }
        } 

        // TODO: Is this necessary? Was having issues with formatting
        //output = Buffer.from(output).toString('base64')

        node.type = 'jsx'
        
        node.value= `<terminal output='${Buffer.from(value).toString('base64')}'></terminal>`

        delete node.lang
      }
    });
  };
  return transformer;
};

module.exports = plugin;
