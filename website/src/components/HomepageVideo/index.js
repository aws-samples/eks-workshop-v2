import React from "react";
import styles from "./styles.module.css";
import ReactPlayer from "react-player";

export default function HomepageVideo() {
  return (
    <section className={styles.features}>
      <div className="container">
        <div className={styles.video}>
          <ReactPlayer
            controls
            src="https://www.youtube-nocookie.com/embed/E956xeOt050"
            width={640}
            height={360}
          />
        </div>
      </div>
    </section>
  );
}
