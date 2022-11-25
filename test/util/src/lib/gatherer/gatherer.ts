import fs from 'fs';
import path from 'path'
import YAML from 'yaml'
import {unified} from 'unified'
import remarkParse from 'remark-parse'
import remarkFrontmatter, { Root } from 'remark-frontmatter'
import remarkGfm from 'remark-gfm'

export class Category {
  constructor(public title: string, public weight: number, public children: Array<Category>, public pages: Array<Page>, public run: boolean, public path: string) { 
  }

  addChild(child: Category) {
    this.children.push(child);
  }

  addPage(page: Page) {
    this.pages.push(page);
  }
}

export class Page {
  constructor(public title: string, public file: string, public weight: number, public isIndex: boolean, public scripts: Array<Script>) { 
  }
}

export class Script {
  constructor(public command: string, public wait: number, public timeout: number, 
    public hook: string | null, public hookTimeout: number, public expectError: boolean, public lineNumber: number | undefined) { 
  }
}

export class Gatherer {
  static TITLE_KEY: string = 'title';
  static WEIGHT_KEY: string = 'weight';
  static SIDEBAR_POSITION: string = 'sidebar_position';
  static TIMEOUT_KEY: string = 'timeout';
  static WAIT_KEY: string = 'wait';
  static HOOK_KEY: string = 'hook';
  static HOOK_TIMEOUT_KEY: string = 'hookTimeout';
  static TEST_KEY: string = 'test';
  static EXPECT_ERROR_KEY: string = 'expectError';
  static RAW_KEY: string = 'raw';

  static INDEX_PAGES : Array<string> = ['_index.md', 'index.en.md', 'index.md']

  private parser = unified()
    .use(remarkParse)
    .use(remarkGfm)
    .use(remarkFrontmatter);

  public async gather(directory: string): Promise<Category | null> {
    if(!fs.existsSync(directory)) {
      throw new Error(`Directory '${directory}' not found`)
    }

    return await this.walk(directory)
  }

  private async walk(directory: string): Promise<Category | null> {
    const files = fs.readdirSync(directory);

    let title = 'Unknown'
    let weight = 0;
    let run = true;
    const children: Array<Category> = []
    const pages: Array<Page> = []

    for(const item of files) {
      let itemPath = path.join(directory, item);

      let stats = fs.statSync(itemPath);
  
      if(item === '.notest') {
        run = false
      }
      else if (stats.isDirectory()) {
        const result = await this.walk(itemPath)

        if(result) {
          children.push(result);
        }
      } 
      else if(item.endsWith(".md")) {
        let page = await this.readPage(itemPath, directory, Gatherer.INDEX_PAGES.includes(item))
  
        if(page) {
          if(page.isIndex) {
            title = page.title
            weight = page.weight
  
            page.weight = 1
          }
  
          pages.push(page)
        }
      }
    }

    if(children.length === 0 && pages.length === 0) {
      return null;
    }

    return new Category(title, weight, 
      children.sort(this.sortByWeight), 
      pages.sort(this.sortByWeight), 
      run, directory);
  }

  private sortByWeight(a: any, b: any) {
    return a.weight - b.weight
  }

  private async readPage(file: string, directory: string, isIndex: boolean): Promise<Page | null> {
    const data = await fs.promises.readFile(file, 'utf8');

    const parsed = await this.parser.parse(data)

    let title = 'Unknown'
    let weight = 0;

    const { children } = parsed
    let child = children[0]

    if(child) {
      if (child.type === 'yaml') {
        let value = child.value

        let obj = YAML.parse(value)
        title = obj[Gatherer.TITLE_KEY]

        if( obj[Gatherer.WEIGHT_KEY] !== undefined ) {
          weight = parseInt(obj[Gatherer.WEIGHT_KEY])
        }
        else if( obj[Gatherer.SIDEBAR_POSITION] !== undefined ) {
          weight = parseInt(obj[Gatherer.SIDEBAR_POSITION])
        }
      }
      else {
        throw new Error(`No Frontmatter found at ${file}`)
      }

      const scripts = this.readScripts(parsed, directory)

      if(isIndex || scripts.length > 0) {
        return new Page(title, file, weight, isIndex, scripts)
      }
    }

    return null;
  }

  private readScripts(root: Root, directory: string): Array<Script> {
  
    const { children } = root
    let data: Array<Script> = []
    let i = -1
    let child
  
    while (++i < children.length) {
      child = children[i]
  
      if (child.type === 'code' && child.value) {
        if (child.lang === 'bash') {

          let meta = child.meta
          let add = true
          let wait = 0
          let timeout = 120
          let hook : String | null = null
          let hookTimeout = 0
          let expectError = false
          let raw = false;
  
          if(meta) {
            // TODO: Change this to regex https://regex101.com/r/uB4sI9/1
            let params = meta.split(' ')
  
            if(params) {
              params.forEach(function(param) {
                let parts = param.split("=")
  
                if(parts.length == 2) {
                  let key = parts[0]
                  let value = parts[1]
  
                  switch (key) {
                    case Gatherer.WAIT_KEY:
                      wait = parseInt(value)
                      break;
                    case Gatherer.TIMEOUT_KEY:
                      timeout = parseInt(value)
                      break;
                    case Gatherer.TEST_KEY:
                      add = (value === "false") ? false : true;
                      break;
                    case Gatherer.EXPECT_ERROR_KEY:
                      expectError = (value === "true") ? true : false;
                      break;
                    case Gatherer.RAW_KEY:
                      raw = (value === "true") ? true : false;
                      break;
                    case Gatherer.HOOK_KEY:
                        hook = value
                        break;
                    case Gatherer.HOOK_TIMEOUT_KEY:
                      hookTimeout = parseInt(value)
                      break;
                    default:
                      console.log(`Warning: Unrecognized param ${key} in code block`);
                  }
                }
              });
            }
          }
  
          if(add) {
            data.push(new Script(this.extractCommand(child.value, raw), wait, timeout, hook, hookTimeout, expectError, child.position?.start.line));
          }
        }
      }
    }
  
    return data
  }
  
  extractCommand(rawString: string, raw: boolean): string {
    if(!raw) {
      let parts = rawString.split('\n')

      let inCommand = false;
      let inHeredoc = false;
    
      let commandParts = []
    
      let commandPart: string | undefined = ''
    
      do {
        commandPart = parts.shift()

        if(!commandPart) {
          break;
        }

        if(commandPart.startsWith('$' )) {
          inCommand = true;

          commandPart = commandPart.slice(2)
        }

        if(inCommand) {
          if(commandPart.indexOf('<<EOF') > -1) {
            inHeredoc = true
          }
          else if(inHeredoc) {
            if(commandPart.indexOf('EOF') > -1) {
              inHeredoc = false
            }
          }

          commandParts.push(commandPart)
        }

        if(!commandPart.endsWith('\\') && !inHeredoc) {
          inCommand = false;
        }
      } while (true);
    
      return commandParts.join('\n');
    }

    return rawString;
  }
}