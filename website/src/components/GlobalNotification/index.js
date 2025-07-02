import React, { useState, useEffect } from 'react';
import styles from './styles.module.css';
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";
import { faArrowUpRightFromSquare, faTimes } from "@fortawesome/free-solid-svg-icons";
import notificationConfig from '../../config/notification.json';

const GlobalNotification = () => {
  const [isVisible, setIsVisible] = useState(false);
  const [isAnimating, setIsAnimating] = useState(false);

  // Don't render if notification is disabled in config
  if (!notificationConfig.enabled) return null;

  useEffect(() => {
    const dismissed = localStorage.getItem('eks-workshop-notification-dismissed');
    if (!dismissed) {
      setIsVisible(true);
      setTimeout(() => setIsAnimating(true), 100);
    }
  }, []);

  const handleDismiss = () => {
    setIsAnimating(false);
    setTimeout(() => {
      setIsVisible(false);
      localStorage.setItem('eks-workshop-notification-dismissed', 'true');
    }, 300);
  };

  if (!isVisible) return null;

  return (
    <div className={`${styles.notification} ${isAnimating ? styles.notificationVisible : ''}`}>
      <span className={styles.notificationText}>
        <b>{notificationConfig.prefix}</b> {notificationConfig.text}{" "}
        <a 
          href={notificationConfig.linkUrl}
          target="_blank"
          rel="noopener noreferrer"
        >
          {notificationConfig.linkText} <FontAwesomeIcon
            icon={faArrowUpRightFromSquare}
            className={styles.linkIcon}
          />
        </a>
      </span>
      <button 
        className={styles.dismissButton}
        onClick={handleDismiss}
        aria-label="Dismiss notification"
      >
        <FontAwesomeIcon icon={faTimes} />
      </button>
    </div>
  );
};

export default GlobalNotification;