import React, { useEffect } from 'react';
import { useLocation } from '@docusaurus/router';
import useDocusaurusContext from '@docusaurus/useDocusaurusContext';
import Link from '@docusaurus/Link';
import styles from './styles.module.css';

export default function SecondaryNav() {
  const location = useLocation();
  const { siteConfig } = useDocusaurusContext();
  
  const isAutoMode = location.pathname.includes('/fastpaths/');
  const isTraditional = location.pathname.includes('/docs/') && !isAutoMode;
  const isHomePage = location.pathname === '/' || location.pathname === '/docs/';
  
  const { eksGroup, autoModeGroup } = siteConfig.customFields.secondaryNav;
  
  // Remember the last page for each context
  useEffect(() => {
    if (isTraditional) {
      localStorage.setItem('lastTraditionalPage', location.pathname);
    } else if (isAutoMode) {
      localStorage.setItem('lastAutoModePage', location.pathname);
    }
  }, [location.pathname, isTraditional, isAutoMode]);
  
  // Get the last visited page or default
  const getTargetPage = (context) => {
    if (typeof window === 'undefined') {
      return context === 'autoMode' ? '/docs/fastpaths/setup' : '/docs/introduction';
    }
    if (context === 'autoMode') {
      return localStorage.getItem('lastAutoModePage') || '/docs/fastpaths/setup';
    } else {
      return localStorage.getItem('lastTraditionalPage') || '/docs/introduction';
    }
  };
  
  if (isHomePage) {
    return null;
  }
  
  if (isTraditional) {
    return (
      <div className={styles.secondaryNavContainer}>
        <div className={styles.navSection}>
          {eksGroup.items.map((item, i) => {
            const isActive = location.pathname.startsWith(item.to);
            return (
              <Link key={i} to={item.to} className={isActive ? styles.activeLink : ''}>{item.label}</Link>
            );
          })}
        </div>
        <div className={styles.contextSwitcher}>
          <Link to={getTargetPage('autoMode')}>Switch to Auto Mode →</Link>
        </div>
      </div>
    );
  }
  
  if (isAutoMode) {
    return (
      <div className={styles.secondaryNavContainer}>
        <div className={styles.navSection}>
          {autoModeGroup.items.map((item, i) => {
            const isActive = location.pathname.startsWith(item.to);
            return (
              <Link key={i} to={item.to} className={isActive ? styles.activeLink : ''}>{item.label}</Link>
            );
          })}
        </div>
        <div className={styles.contextSwitcher}>
          <Link to={getTargetPage('traditional')}>Switch to Amazon EKS →</Link>
        </div>
      </div>
    );
  }
  
  return null;
}
