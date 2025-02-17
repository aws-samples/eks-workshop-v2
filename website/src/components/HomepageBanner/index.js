import React from 'react';
import styles from './styles.module.css';
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";
import { faArrowUpRightFromSquare } from "@fortawesome/free-solid-svg-icons";

const HomepageBanner = () => {
  return (
    <div className={styles.banner}>
      <span className={styles.bannerText}>
      Simplify Kubernetes with <b>Amazon EKS Auto Mode</b>:{" "}
        <a 
          href="https://aws-experience.com/emea/smb/events/series/simplifying-kubernetes-operations-with-amazon-eks-auto-mode?trk=e3d0398c-e0e9-4665-af82-a2e8124a6db8&sc_channel=el"
          target="_blank"
        >
          Webinar <FontAwesomeIcon
            icon={faArrowUpRightFromSquare}
            className={styles.linkIcon}
          />
        </a>
      </span>
    </div>
  );
};

export default HomepageBanner;
