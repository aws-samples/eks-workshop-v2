import React, {type ReactNode} from 'react';

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
  command = command.split('\\').join('\\ \n')

  function copyToClipboard(e) {
    navigator.clipboard.writeText(command)
  }

  let base64ToStringNew = atob(output)

  return (
  <div className={styles.terminal}>
    <section className={styles.terminal__bar}>
      <div className={styles.bar__buttons}>
        <button className={`${styles.bar__button} ${styles.bar__button__exit}`}>&nbsp;</button>
        <button className={styles.bar__button}>&nbsp;</button>
        <button className={styles.bar__button}>&nbsp;</button>
      </div>
    </section>
    <section className={styles.terminal__body} onClick={copyToClipboard}>
      <div className={styles.terminal__prompt}>
        <span className={styles.terminal__prompt__user}>eks-workshop:</span>
        <span className={styles.terminal__prompt__location}>~</span>
        <span className={styles.terminal__prompt__bling}>$</span>
        <span className={styles.terminal__prompt__cursor}></span>
        <span className={styles.terminal__prompt__command}>{command}</span>
      </div>
      <div className={styles.terminal__output}><pre>
        {base64ToStringNew}
        </pre>
      </div>
    
    </section>
  </div>
  );
}