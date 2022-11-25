#!/usr/bin/env node

import { Command } from "commander";
import { MarkdownSh } from "./lib/markdownsh.js";

interface Opts {
  glob: string,
  debug: boolean,
  dryRun: boolean,
  timeout: number,
  hookTimeout: number,
  junitReport: string,
}

const testCommand = new Command('test');
testCommand.argument('<path>', 'file path to Markdown content')
  .description('Runs a test suite against the given content path')
  .option('-g, --glob <pattern>', 'Glob for tests to include ex. content/chapter1/*', '')
  .option('-d, --debug', 'Enable debug output')
  .option('--dry-run', 'Run test but do not execute scripts')
  .option<number>('-t, --timeout <timeout>', 'Timeout for the test run in seconds', (value) => parseInt(value), 800)
  .option<number>('--hook-timeout <timeout>', 'Default timeout for hooks to complete in seconds', (value) => parseInt(value), 300)
  .option('-j, --junit-report <path>', 'Enables JUnit output format with report at the specified path', '')
  .option('-w, --work-dir <path>', 'Path to working directory where commands will be executed', '')
  .action(async (path, options: Opts) => {
    let markdownSh = new MarkdownSh(options.glob, options.debug)
    await markdownSh.test(path, options.dryRun, options.timeout, options.hookTimeout, options.junitReport)
  })

const planCommand = new Command('plan')
  .description('Shows what markdown.sh will parse for a given set of Markdown without executing')
  .argument('<path>', 'file path to Markdown content')
  .option('-g, --glob <pattern>', 'Glob for tests to include ex. content/chapter1/*', '')
  .action(async (path, options: Opts) => {
    let markdownSh = new MarkdownSh(options.glob, options.debug)
    await markdownSh.plan(path)
  });

const program = new Command();
program
  .description('Automated test framework for Markdown that contains shell scripts')
  .addCommand(testCommand).addCommand(planCommand);

await program.parse();