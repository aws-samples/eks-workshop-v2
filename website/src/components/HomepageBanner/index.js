import React from 'react';
import styles from './styles.module.css';
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";
import { faArrowUpRightFromSquare } from "@fortawesome/free-solid-svg-icons";

const HomepageBanner = () => {
  return (
    <div className={styles.banner}>
      <span className={styles.bannerText}>
        <b>Virtual Workshop Experience</b> — Get Hands On with Amazon EKS:{" "}
        <a 
          href="https://aws-experience.com/emea/smb/events/series/get-hands-on-with-amazon-eks?trk=d42ffbaa-d60a-4513-8a79-0bf36b9f33ce&sc_channel=el"
          target="_blank"
        >
          Event Series <FontAwesomeIcon
            icon={faArrowUpRightFromSquare}
            className={styles.linkIcon}
          />
        </a>
      </span>
    </div>
  );
};

export default HomepageBanner;
