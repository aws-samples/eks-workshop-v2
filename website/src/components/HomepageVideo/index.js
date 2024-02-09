import React from 'react';
import styles from './styles.module.css'
import ReactPlayer from 'react-player'

export default function HomepageVideo() {
  return (
    <section className={styles.features}>
      <div className="container">
        <div className={styles.video}>
          <ReactPlayer controls url='https://www.youtube.com/watch?v=E956xeOt050' />
        </div>
      </div>
    </section>
  );
}
