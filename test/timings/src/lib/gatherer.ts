import fs from 'fs';
import path from 'path'
import YAML from 'yaml'
import {unified} from 'unified'
import remarkParse from 'remark-parse'
import remarkFrontmatter, { Root } from 'remark-frontmatter'
import remarkGfm from 'remark-gfm'

export class Lab {
  constructor(public title: string, public parts: string[], public directory: string, public file: string, public estimatedLabTimeSeconds: number) { 
  }
}

export class Gatherer {
  static TITLE_KEY: string = 'title';

  static INDEX_PAGES : Array<string> = ['_index.md', 'index.en.md', 'index.md']

  private parser = unified()
    .use(remarkParse)
    .use(remarkGfm)
    .use(remarkFrontmatter);

  public async gather(directory: string): Promise<Lab[]> {
    let result : Lab[] = [];

    if(!fs.existsSync(directory)) {
      throw new Error(`Directory '${directory}' not found`)
    }

    await this.walk(directory, result, [])

    return Promise.resolve(result);
  }

  private async walk(directory: string, results: Lab[], titleParts: string[], currentLab?: Lab) {
    const files = fs.readdirSync(directory);

    let title = 'Unknown'

    let newTitleParts = [...titleParts]

    if(files.includes("index.md")) {
      const file = `${directory}/index.md`

      const data = await fs.promises.readFile(file, 'utf8');

      const parsed = await this.parser.parse(data)

      const { children } = parsed
      let child = children[0]

      if(child) {
        if (child.type === 'yaml') {
          let value = child.value

          let obj = YAML.parse(value)
          title = obj[Gatherer.TITLE_KEY]

          if(!currentLab) {
            if(obj['sidebar_custom_props']) {
              let props = obj['sidebar_custom_props']

              if(props['module']) {
                let estimatedLabTimeSeconds = 0;

                if(props['estimatedLabTimeSeconds']) {
                  estimatedLabTimeSeconds = props['estimatedLabTimeSeconds'];
                }

                currentLab = new Lab(title, titleParts, directory, file, estimatedLabTimeSeconds);
                results.push(currentLab);

                return;
              }
            }
          }
        }
      }
    }

    newTitleParts.push(title);

    for(const item of files) {
      let itemPath = path.join(directory, item);

      let stats = fs.statSync(itemPath);

      if (stats.isDirectory()) {
        await this.walk(itemPath, results, newTitleParts, currentLab);
      }
    }
  }
}
