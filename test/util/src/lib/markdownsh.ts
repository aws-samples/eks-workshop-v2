import { Category, Gatherer, Page, Script } from "./gatherer/gatherer.js";
import Mocha, { Suite, Test } from 'mocha'
import path from 'path'
import GlobToRegExp from 'glob-to-regexp'
import { assert } from 'chai'
import { DefaultShell, Shell, ShellError, ShellTimeout } from "./shell/shell.js";
import fs from 'fs'

export class MarkdownSh {
  private gatherer = new Gatherer();
  private shell = new DefaultShell();

  constructor(private glob: string,
    private debug: boolean) { 
  }

  async plan(directory: string) {
    let root = await this.gatherer.gather(directory)

    if(!root) {
      console.log('No tests found')
    }
    else {
      console.log(JSON.stringify(root, undefined, 2))
    }
  }

  async test(directory: string,
      dryRun: boolean, 
      timeout: number, 
      hookTimeout: number, 
      junitReport: string) {
    const mochaOpts : Mocha.MochaOptions = {
      timeout: timeout * 1000,
    };

    if(junitReport !== '') {
      mochaOpts.reporter = 'mocha-junit-reporter'
      mochaOpts.reporterOptions = {
        mochaFile: junitReport,
        includePending: true,
        testCaseSwitchClassnameAndName: true
      }
    }

    const mocha = new Mocha(mochaOpts);

    let root;
    
    try {
      root = await this.gatherer.gather(path.normalize(directory))
    }
    catch(e: any) {
      console.log(`Error load tests: ${e.message}`)
      process.exit(1)
    }

    if(!root) {
      console.log('No tests found')
    }
    else {
      await this.buildTestSuites(path.normalize(directory), root, mocha.suite, hookTimeout, dryRun)

      try {
        await this.runMochaTests(mocha)
      }
      catch(e: any) {
        process.exit(1)
      }
    }
  }

  private runMochaTests(mocha: Mocha): Promise<void> {
    return new Promise((resolve, reject) => {
      mocha.run((failures) => {
        if (failures) reject('at least one test is failed, check detailed execution report')
        resolve();
      });
    });
  }

  private async buildTestSuites(rootDirectory: string, category: Category, parentSuite: Suite, hookTimeout: number, dryRun: boolean) {
    const suite = Mocha.Suite.create(parentSuite, category.title)

    if(!category.run) {
      return suite;
    }
  
    var addTests = true;
  
    if(category.path !== undefined && this.glob !== '') {
      var relativePath = path.relative(rootDirectory, category.path)
      var re = GlobToRegExp(this.glob, { extended: true });
  
      if(!re.exec(relativePath)) {
        addTests = false;
      }
    }
  
    if(addTests) {
      for(const test in category.pages) {
        suite.addTest(this.buildTests(category.pages[test], category, hookTimeout, dryRun))
      }
  
      if(category.path !== undefined) {
        this.suiteHooks(category, suite, hookTimeout, dryRun)
      }
    }
  
    for(const child in category.children) {
      await this.buildTestSuites(rootDirectory, category.children[child], suite, hookTimeout, dryRun)
    }
  
    return suite;
  }

  private buildTests(page: Page, category: Category, hookTimeout: number, dryRun: boolean): Test {
    let skip = false;

    if(page.scripts.length == 0) {
      skip = true;
    }

    return new CustomTest(page, category, hookTimeout, this.debug, dryRun, this.shell)
  }

  private suiteHooks(record: Category, suite: Suite, hookTimeout: number, dryRun: boolean) {
    const suiteDir = path.dirname(record.path)
  
    const hookPath = `${record.path}/tests/hook-suite.sh`
    
    if(fs.existsSync(hookPath)) {
      let func = async (hookPath: string, hook: string, hookTimeout: number, dryRun: boolean) => {
        this.debugMessage(`Calling suite ${hook} hook`)
  
        if(!dryRun) {
          let response = await this.shell.exec(`bash ${hookPath} ${hook}`, hookTimeout, false)

          this.debugMessage(response.output)
        }
      
        this.debugMessage(`Completed suite ${hook} hook`)
      
        return Promise.resolve();
      }

      suite.beforeAll('Suite Before Hook', async function() {
        return await func(hookPath, 'before', hookTimeout, dryRun)
      });
      suite.afterAll('Suite After Hook', async function() {
        return await func(hookPath, 'after', hookTimeout, dryRun)
      });
    }
  }

  private debugMessage(message: string) {
    if(this.debug) {
      console.log(message)
    }
  }
}

class CustomTest extends Test {
  constructor(page: Page, category: Category, globalHookTimeout: number, private debug: boolean, private dryRun: boolean, private shell: Shell) {
    super(page.title, async () => {
      let failed = false;
      if(page.scripts.length == 0) {
        this.skip();
      }
  
      for(const i in page.scripts){
        let testCase = page.scripts[i]
  
        if(failed === undefined) {
          failed = false
        }
        
        if(failed === false) {
          try {
            let hookTimeout = globalHookTimeout
  
            if(testCase.hookTimeout > 0) {
              hookTimeout = testCase.hookTimeout
            }
  
            await this.hook(testCase, category, 'before', hookTimeout)
  
            try {
              await this.executeShell(testCase.command, testCase.timeout, testCase.expectError)
            }
            catch(e: any) {
              e.message = `Error running test case command at line ${testCase.lineNumber}`
  
              throw e
            }
  
            await this.hook(testCase, category, 'after', hookTimeout)
  
            if(testCase.wait > 0) {
              await this.sleep(testCase.wait * 1000)
            }
          } catch (e: any) {

            if(e instanceof ShellTimeout) {
              console.log(e.message)
              console.log('Command timed out')
              console.log(`stdout: \n${e.stdout}`)
              console.log(`stderr: \n${e.stderr}`)
              assert.fail(`Script failed to complete within ${e.timeout} seconds`)
            }
            else if(e instanceof ShellError) {
              if(!testCase.expectError) {
                console.log(e.message)
                console.log(`Command returned error code ${e.code}`)
                console.log(`stdout: \n${e.stdout}`)
                console.log(`stderr: \n${e.stderr}`)
                assert.fail("Script exit with an error code");
              }
            }
            else {
              assert.fail(`An unknown error occurred: ${e.message}`);
            }
          }
        }
        else {
          this.skip()
        }
      }
    });
  }

  async hook(testCase: Script, category: Category, hook: string, timeout: number) {
    if(testCase.hook) {
      this.debugMessage(`Calling ${hook} hook ${testCase.hook}`)

      const hookPath = `${category.path}/tests/hook-${testCase.hook}.sh`;
  
      try {
        const response = await this.executeShell(`bash ${hookPath} ${hook}`, timeout, false)
  
        this.debugMessage(`Completed ${hook} hook ${testCase.hook}`)
      }
      catch(e: any) {
        e.message = `Error running '${hook}' hook at ${hookPath}`
  
        throw e
      }
    }
  }

  async executeShell(command: string, timeout: number, expectError: boolean) {

    this.debugMessage(`Executing shell:
  Command ${command}
  Timeout ${timeout}
  `)
  
    if (!this.dryRun) {
      let response = await this.shell.exec(command, timeout, expectError)
  
      this.debugMessage(response.output)
    }
  }

  async sleep(ms: number): Promise<void> {
    if(this.dryRun) {
      return Promise.resolve();
    }
  
    return new Promise((resolve) => {
      setTimeout(resolve, ms);
    });
  }

  private debugMessage(message: string) {
    if(this.debug) {
      console.log(message)
    }
  }
  
}