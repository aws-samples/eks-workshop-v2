import React, { useState, useEffect } from 'react';
import styles from './styles.module.css';
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";
import { faArrowUpRightFromSquare, faTimes } from "@fortawesome/free-solid-svg-icons";
import useDocusaurusContext from '@docusaurus/useDocusaurusContext';

const notificationConfig = {
  prefix: "Live:",
  text: "Hands-on EKS Workshop Series -",
  linkText: "Register",
  linkUrl: "https://aws-experience.com/emea/smb/events/series/get-hands-on-with-amazon-eks?trk=d42ffbaa-d60a-4513-8a79-0bf36b9f33ce&sc_channel=el"
};

const GlobalNotification = () => {
  const [isVisible, setIsVisible] = useState(false);
  const [isAnimating, setIsAnimating] = useState(false);
  const { siteConfig } = useDocusaurusContext();

  // Don't render if notification is disabled via customFields
  if (!siteConfig.customFields.showNotification) return null;

  useEffect(() => {
    const dismissedData = localStorage.getItem('eks-workshop-notification-dismissed');
    
    if (!dismissedData) {
      // Not dismissed yet
      setIsVisible(true);
      setTimeout(() => setIsAnimating(true), 100);
      return;
    }
    
    try {
      const { timestamp } = JSON.parse(dismissedData);
      const now = new Date().getTime();
      const daysSinceDismissed = (now - timestamp) / (1000 * 60 * 60 * 24);
      
      if (daysSinceDismissed > 7) {
        // Expired, show notification again
        localStorage.removeItem('eks-workshop-notification-dismissed');
        setIsVisible(true);
        setTimeout(() => setIsAnimating(true), 100);
      }
    } catch (e) {
      // If there's any error parsing (old format), show notification
      localStorage.removeItem('eks-workshop-notification-dismissed');
      setIsVisible(true);
      setTimeout(() => setIsAnimating(true), 100);
    }
  }, []);

  const handleDismiss = () => {
    setIsAnimating(false);
    setTimeout(() => {
      setIsVisible(false);
      
      // Store dismissal with timestamp
      const dismissalData = {
        timestamp: new Date().getTime()
      };
      
      localStorage.setItem('eks-workshop-notification-dismissed', JSON.stringify(dismissalData));
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