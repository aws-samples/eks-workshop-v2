const visit = require('unist-util-visit');

const regex = /(\w+)=([^\s]+)/g;

const other_regex = /\@\{([A-Za-z0-9\/\-_]+)\}/gm;

const plugin = (options) => {
  const manifestsRef = options.ref

  const transformer = async (ast, vfile) => {
    visit(ast, 'code', (node) => {
      if(node.lang === 'bash') {
        if(manifestsRef != '') {
          value = node.value.replace(other_regex, 'github.com/aws-samples/eks-workshop-v2/environment$1?ref='+manifestsRef);
        }
        else {
          value = node.value.replace(other_regex, '$1');
        }

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
