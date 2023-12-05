import React, {Component, type ReactNode} from 'react';
import ReactTooltip from 'react-tooltip';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome'
import { faClipboard } from '@fortawesome/free-solid-svg-icons'

import styles from './styles.module.css';

interface Props {
  output: string;
}

export default function Terminal({
  output,
}: Props): JSX.Element {
  let decodedOutput = atob(output);

  const outputParts = decodedOutput.split('\n')

  let sections : Array<TerminalSection> = []

  let section = new TerminalSection()

  let appendNext = false;

  let allCommands = "";

  for(let i = 0; i < outputParts.length; i++) {
    let currentLine = outputParts[i]

    if(!appendNext) {
      if(currentLine.startsWith('$ ')) {
        section = new TerminalSection()
        sections.push(section)

        currentLine = currentLine.substring(2)
      }

      if(section.processLine(currentLine)) {
        allCommands = `${allCommands}\n${currentLine}`
      }
    }
  }

  const handler = () => {
    navigator.clipboard.writeText(`${allCommands}\n`)
  }

  return (
    <div className={styles.browserWindow}>
      <div className={styles.browserWindowHeader}>
        <div className={styles.buttons}>
          
          <span className={styles.dot} style={{background: '#f25f58'}} />
          <span className={styles.dot} style={{background: '#fbbe3c'}} />
          <span className={styles.dot} style={{background: '#58cb42'}} />
        </div>
        <div className={styles.browserWindowMenuIcon}>
          <div className={styles.copyAll}>
            <FontAwesomeIcon icon={faClipboard} onClick={handler} data-tip="Copy all commands" />
            <ReactTooltip place="top" effect="float" border={true} />
          </div>
        </div>
      </div>

      <div className={styles.browserWindowBody}>
        { sections.map(element => {
          return element.render()
        })}
      </div>
    </div>
  );
}

class TerminalSection {
  protected contexts: Array<TerminalContext> = [];
  private context : TerminalContext;
  private commandContext : TerminalCommand;
  private inHeredoc = false;
  private commandString : string = "";
  private inCommand = true;

  constructor() {
    this.context = this.commandContext = new TerminalCommand();
    this.contexts.push(this.context)
  }

  switchContext(context: TerminalContext) {
    this.contexts.push(context)

    this.context = context;
  }

  addLine(line: string) {
    this.context.addLine(line)
  }

  processLine(currentLine: string) : boolean {
    let processed = false;

    this.context.addLine(currentLine);

    if(this.inCommand) {
      this.commandString += currentLine;
      processed = true;
    }

    if(currentLine.indexOf('<<EOF') > -1) {
      this.inHeredoc = true
    }
    else if(this.inHeredoc) {
      if(currentLine.indexOf('EOF') > -1) {
        this.inHeredoc = false
      }
    }
    
    if(!currentLine.endsWith('\\') && !this.inHeredoc) {
      this.context = new TerminalOutput()
      this.contexts.push(this.context)

      this.inCommand = false;
    }

    return processed;
  }

  render() {
    const commandString = this.commandContext.getCommand()
    const handler = () => {
      navigator.clipboard.writeText(commandString)
    }

    return (
      <section className={styles.terminalBody} data-tip="Copy command" onClick={handler}>
        {this.contexts.map(element => {
          return (element.render())
        })}
      </section>
    )
  }
  
}

class TerminalContext {
  protected lines: Array<string> = [];

  addLine(line: string) {
    this.lines.push(line)
  }

  render() {
    return (<div></div>)
  }

  hasLines() {
    return this.lines.length > 0
  }
}

class TerminalCommand extends TerminalContext {
  private isMultiLine = false;

  addLine(line: string) {
    super.addLine(line)
  }

  getCommand() {
    return this.lines.join('\n')
  }

  render() {
    return (
      <div>
        <div className={styles.terminalPrompt}>
        <span className={styles.terminalPromptLocation}>~</span>
        <span className={styles.terminalPromptBling}>$</span>
        {this.renderCommand(this.lines[0], false)}
      </div>
      { this.lines.slice(1).map(element => {
        return (<div className={styles.terminalPrompt}>{this.renderCommand(element, true)}</div>)
      })
      }
      </div>
    )
  }

  renderCommand(command: string, indent: boolean) {
    let output = command;

    return (<span className={styles.terminalPromptCommand}>{output}</span>)
  }
}

class TerminalOutput extends TerminalContext {
  render() {
    return (
      <div className={styles.terminalOutput}><pre>
        { this.lines.join('\n')}
      </pre>
    </div>
    )
  }
}
