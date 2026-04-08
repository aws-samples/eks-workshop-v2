import React from "react";
import { Tooltip as ReactTooltip } from "react-tooltip";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";
import { faClipboard } from "@fortawesome/free-solid-svg-icons";

import styles from "./styles.module.css";
import { translate } from "@docusaurus/Translate";

const copyCommand = translate({
  id: "terminal.copyCommand",
});

const copyAllCommands = translate({
  id: "terminal.copyAllCommands",
});

interface Props {
  output: string;
}

export default function Terminal({ output }: Props): JSX.Element {
  const decodedOutput = atob(output);

  const outputParts = decodedOutput.split("\n");

  const sections: Array<TerminalSection> = [];

  let section = new TerminalSection(0);

  const appendNext = false;

  let allCommands = "";

  for (let i = 0; i < outputParts.length; i++) {
    let currentLine = outputParts[i];

    if (!appendNext) {
      if (currentLine.startsWith("$ ")) {
        section = new TerminalSection(i);
        sections.push(section);

        currentLine = currentLine.substring(2);
      }

      if (section.processLine(currentLine)) {
        allCommands = `${allCommands}\n${currentLine}`;
      }
    }
  }

  const handler = () => {
    triggerCopy(`${allCommands}\n`);
  };

  return (
    <div className={styles.browserWindow}>
      <div className={styles.browserWindowHeader}>
        <div className={styles.buttons}>
          <span className={styles.dot} style={{ background: "#f25f58" }} />
          <span className={styles.dot} style={{ background: "#fbbe3c" }} />
          <span className={styles.dot} style={{ background: "#58cb42" }} />
        </div>
        <div className={styles.browserWindowMenuIcon}>
          <div className={styles.copyAll}>
            <FontAwesomeIcon
              icon={faClipboard}
              onClick={handler}
              data-tooltip-id={`copy-all`}
            />
            <ReactTooltip id="copy-all" content={copyAllCommands} />
          </div>
        </div>
      </div>

      <div className={styles.browserWindowBody}>
        {sections.map((element) => {
          return element.render();
        })}
      </div>
      <ReactTooltip id="copy-command" content={copyCommand} />
    </div>
  );
}

class TerminalSection {
  protected contexts: Array<TerminalContext> = [];
  private context: TerminalContext;
  private commandContext: TerminalCommand;
  private inHeredoc = false;
  private commandString: string = "";
  private inCommand = true;
  private index: number;

  constructor(index: number) {
    this.index = index;

    this.context = this.commandContext = new TerminalCommand();
    this.contexts.push(this.context);
  }

  switchContext(context: TerminalContext) {
    this.contexts.push(context);

    this.context = context;
  }

  addLine(line: string) {
    this.context.addLine(line);
  }

  processLine(currentLine: string): boolean {
    let processed = false;

    this.context.addLine(currentLine);

    if (this.inCommand) {
      this.commandString += currentLine;
      processed = true;
    }

    if (currentLine.indexOf("<<EOF") > -1) {
      this.inHeredoc = true;
    } else if (this.inHeredoc) {
      if (currentLine.indexOf("EOF") > -1) {
        this.inHeredoc = false;
      }
    }

    if (!currentLine.endsWith("\\") && !this.inHeredoc) {
      this.context = new TerminalOutput();
      this.contexts.push(this.context);

      this.inCommand = false;
    }

    return processed;
  }

  render() {
    const commandString = this.commandContext.getCommand();
    const handler = () => {
      triggerCopy(commandString);
    };

    return (
      <section
        key={this.index}
        className={styles.terminalBody}
        data-tooltip-id="copy-command"
        data-tooltip-float={true}
        onClick={handler}
      >
        {this.contexts.map((element, index) => {
          return element.render(index);
        })}
      </section>
    );
  }
}

function triggerCopy(text: string) {
  navigator.clipboard.writeText(text.trim());

  window.parent.postMessage(`eks-workshop-terminal:${text}`, "*");
}

class TerminalContext {
  protected lines: Array<string> = [];

  addLine(line: string) {
    if (line.length === 0) {
      line = " ";
    }

    this.lines.push(line);
  }

  render(index: number) {
    return <div></div>;
  }

  hasLines() {
    return this.lines.length > 0;
  }
}

class TerminalCommand extends TerminalContext {
  private isMultiLine = false;

  addLine(line: string) {
    super.addLine(line);
  }

  getCommand() {
    return this.lines.join("\n");
  }

  render(index: number) {
    return (
      <div key={index}>
        <div className={styles.terminalPrompt}>
          <span className={styles.terminalPromptLocation}>~</span>
          <span className={styles.terminalPromptBling}>$</span>
          {this.renderCommand(this.lines[0], false)}
        </div>
        {this.lines.slice(1).map((element, lineIndex) => {
          return (
            <div key={lineIndex} className={styles.terminalPrompt}>
              {this.renderCommand(element, true)}
            </div>
          );
        })}
      </div>
    );
  }

  renderCommand(command: string, indent: boolean) {
    const output = command;

    return <span className={styles.terminalPromptCommand}>{output}</span>;
  }
}

class TerminalOutput extends TerminalContext {
  render(index: number) {
    return (
      <div key={index} className={styles.terminalOutput}>
        <pre>{this.lines.join("\n")}</pre>
      </div>
    );
  }
}
