import { rejects } from "assert";
import * as child from "child_process";
import * as os from "os";

export interface Shell {
  exec: (
    command: string,
    timeout: number,
    expect: boolean,
    additionalEnv: { [key: string]: string | undefined },
  ) => Promise<ExecutionResult>;
}

export class ExecutionResult {
  constructor(public output: string) {}
}

export class DefaultShell implements Shell {
  private environment: { [key: string]: string | undefined } = process.env;

  static ENV_MARKER: string = "%%% ENV %%%";

  constructor(private beforeEach: string) {}

  exec(
    command: string,
    timeout: number = 300,
    expect: boolean = false,
    additionalEnv: { [key: string]: string | undefined },
  ): Promise<ExecutionResult> {
    if (!command) {
      throw new Error("Command should not be empty");
    }

    const prefix = this.beforeEach === "" ? "" : `${this.beforeEach} &&`;

    try {
      const buffer: Buffer = child.execSync(
        `${prefix} set -e && ${command} && echo '${DefaultShell.ENV_MARKER}' && env`,
        {
          timeout: timeout * 1000,
          killSignal: "SIGKILL",
          stdio: ["inherit", "pipe", "pipe"],
          shell: "/bin/bash",
          env: {
            ...this.environment,
            ...additionalEnv,
          },
        },
      );

      const output = String(buffer);

      const parts = output.split(os.EOL);

      let processingEnv = false;
      let processingFunction = false;
      let env: { [key: string]: string } = {};

      for (let step = 0; step < parts.length; step++) {
        const line = parts[step];

        if (processingEnv) {
          if (processingFunction) {
            if (line.startsWith("{")) {
              processingFunction = false;
            }
          } else {
            let key = `${line.substr(0, line.indexOf("="))}`;
            let val = `${line.substr(line.indexOf("=") + 1)}`;

            if (key.startsWith("BASH_FUNC")) {
              processingFunction = true;
            } else if (!(key in additionalEnv)) {
              env[key] = val;
            }
          }
        } else {
          if (line === DefaultShell.ENV_MARKER) {
            processingEnv = true;
          }
        }
      }

      let finalOutput = "";

      let outputParts = buffer.toString().split(DefaultShell.ENV_MARKER);

      if (outputParts.length > 1) {
        finalOutput = outputParts[0];
      }

      if (processingEnv) {
        this.environment = {
          ...this.environment,
          ...env,
        };
      }

      return Promise.resolve(new ExecutionResult(finalOutput));
    } catch (e: any) {
      if (e.code) {
        throw new ShellTimeout(
          `Timed out after ${timeout} seconds`,
          e.stdout,
          e.stderr,
          timeout,
        );
      }

      if (!expect) {
        throw new ShellError(
          e.status,
          `Command failed: ${command}`,
          e.stdout,
          e.stderr,
          e.output,
        );
      }

      return Promise.resolve(new ExecutionResult(e.output));
    }
  }
}

export class ShellError extends Error {
  constructor(
    public code: number,
    message: string,
    public stdout: string,
    public stderr: string,
    public output: string,
  ) {
    super(message);

    Object.setPrototypeOf(this, ShellError.prototype);
  }
}

export class ShellTimeout extends Error {
  constructor(
    message: string,
    public stdout: string,
    public stderr: string,
    public timeout: number,
  ) {
    super(message);

    Object.setPrototypeOf(this, ShellTimeout.prototype);
  }
}
