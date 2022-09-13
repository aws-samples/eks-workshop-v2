import React, {type ReactNode} from 'react';
import ReactTooltip from 'react-tooltip';

import styles from './styles.module.css';

interface Props {
  children: ReactNode;
  command: string;
  output: string,
}

export default function Terminal({
  children,
  command,
  output,
}: Props): JSX.Element {
  const commandParts = command.split('\\')

  const firstLine = commandParts[0]
  const otherParts = commandParts.slice[1]

  function copyToClipboard(e) {
    navigator.clipboard.writeText(command)
  }

  let base64ToStringNew = atob(output)

  return (
    <div className={styles.browserWindow}>
      <div className={styles.browserWindowHeader}>
        <div className={styles.buttons}>
          <span className={styles.dot} style={{background: '#f25f58'}} />
          <span className={styles.dot} style={{background: '#fbbe3c'}} />
          <span className={styles.dot} style={{background: '#58cb42'}} />
        </div>
        <div className={styles.browserWindowMenuIcon}>
          <div>
            <span className={styles.bar} />
            <span className={styles.bar} />
            <span className={styles.bar} />
          </div>
        </div>
      </div>

      <div className={styles.browserWindowBody}>
        <section className={styles.terminalBody} onClick={copyToClipboard} data-tip data-for="copy-hint">
          <div className={styles.terminalPrompt}>
            <span className={styles.terminalPromptUser}>eks-workshop:</span>
            <span className={styles.terminalPromptLocation}>~</span>
            <span className={styles.terminalPromptBling}>$</span>
            <span className={styles.terminalPromptCursor}></span>
            <span className={styles.terminalPromptCommand}>{firstLine}</span>
          </div>
          {otherParts && otherParts.map((object, i) => <div className={styles.terminalPrompt}>{object}</div>)}
          <div className={styles.terminalOutput}><pre>
            {base64ToStringNew}
            </pre>
          </div>
        
        </section>
        <ReactTooltip id="copy-hint" place="right" effect='solid'>
          <span>Click to copy</span>
        </ReactTooltip>
      </div>
    </div>
  );
}