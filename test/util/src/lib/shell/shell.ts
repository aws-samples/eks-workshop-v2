import { rejects } from 'assert';
import * as child from 'child_process';

export interface Shell {
  exec:(command: string, timeout: number, expect: boolean) => Promise<ExecutionResult>
}

export class ExecutionResult {
  constructor(public output: string) { 
  }
}

export class DefaultShell implements Shell {

  exec(command: string, timeout: number = 300, expect: boolean = false) : Promise<ExecutionResult> {
    try {
      const buffer: Buffer = child.execSync(command, {
        timeout: timeout * 1000,
        killSignal: 'SIGKILL',
        stdio: 'pipe',
        shell: '/bin/bash'
      });

      return Promise.resolve(new ExecutionResult(String(buffer)));
    }
    catch(e: any) {
      if(e.code) {
        throw new ShellTimeout(`Timed out after ${timeout} seconds`, e.stdout, e.stderr, timeout)
      }

      throw new ShellError(e.status, e.message, e.stdout, e.stderr)
    }
  }
}

export class ShellError extends Error {
  constructor(public code: number, message: string, public stdout: string, public stderr: string) {
    super(message);

    Object.setPrototypeOf(this, ShellError.prototype);
  }
}

export class ShellTimeout extends Error {
  constructor(message: string, public stdout: string, public stderr: string, public timeout: number) {
    super(message);

    Object.setPrototypeOf(this, ShellTimeout.prototype);
  }
}