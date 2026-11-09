import { expect } from "chai";
import { DefaultShell, ShellError } from "../src/lib/shell/shell.js";

async function expectFailure(
  shell: DefaultShell,
  command: string,
): Promise<ShellError> {
  try {
    await shell.exec(command, 30, false, {});
  } catch (e) {
    expect(e).to.be.instanceOf(ShellError);
    return e as ShellError;
  }
  throw new Error(`Expected command to fail: ${command}`);
}

describe("DefaultShell", () => {
  let shell: DefaultShell;

  beforeEach(() => {
    shell = new DefaultShell("");
  });

  it("runs a single-line command", async () => {
    const result = await shell.exec("echo hello", 30, false, {});
    expect(result.output).to.equal("hello\n");
  });

  it("runs a multi-line command with line continuations", async () => {
    const result = await shell.exec(
      "echo \\\n  hello \\\n  world",
      30,
      false,
      {},
    );
    expect(result.output).to.equal("hello world\n");
  });

  it("runs a heredoc whose delimiter is the last line", async () => {
    const result = await shell.exec(
      "cat <<EOF | tr a-z A-Z\nfirst line\nsecond line\nEOF",
      30,
      false,
      {},
    );
    expect(result.output).to.equal("FIRST LINE\nSECOND LINE\n");
  });

  it("detects failure of a heredoc command", async () => {
    const error = await expectFailure(
      shell,
      "cat <<EOF | grep missing\nfoo\nEOF",
    );
    expect(error.code).to.equal(1);
  });

  it("fails on a failing command", async () => {
    const error = await expectFailure(shell, "false");
    expect(error.code).to.equal(1);
  });

  it("fails when an earlier line of a multi-line command fails", async () => {
    const error = await expectFailure(shell, "false\necho should-not-run");
    expect(error.stdout.toString()).to.not.contain("should-not-run");
  });

  it("fails when the first part of a final && list fails", async () => {
    const error = await expectFailure(shell, "(exit 3) && echo unreachable");
    expect(error.code).to.equal(3);
  });

  it("returns output instead of throwing when an error is expected", async () => {
    const result = await shell.exec("echo oops && false", 30, true, {});
    expect(result.output.toString()).to.contain("oops");
  });

  it("carries exported environment variables to later commands", async () => {
    await shell.exec("export MDSH_TEST_VAR=carried", 30, false, {});
    const result = await shell.exec("echo $MDSH_TEST_VAR", 30, false, {});
    expect(result.output).to.equal("carried\n");
  });
});
