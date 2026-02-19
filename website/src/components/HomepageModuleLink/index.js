import React from "react";
import clsx from "clsx";
import styles from "./styles.module.css";
import useBaseUrl from "@docusaurus/useBaseUrl";
import useDocusaurusContext from "@docusaurus/useDocusaurusContext";
import Link from "@docusaurus/Link";

export default function HomepageModuleLink(props) {
  const { siteConfig } = useDocusaurusContext();
  
  return (
      <div className={clsx("hero hero--primary", styles.heroBanner)}>
        <div className="container">
          <div className={styles.pathSelection}>
          <div className={clsx(styles.pathCard, props.disabled && styles.disabled)}>
            <h3>Amazon EKS Essentials<span className={styles.newBadge}>New</span></h3>
            <p>Streamlined learning paths powered by Amazon EKS Auto Mode</p>
            <Link
              className="button button--primary button--lg"
              to="/docs/fastpaths/setup"
            >
              Start here
            </Link>
            <div className={styles.moduleLinks}>
              {siteConfig.customFields.secondaryNav.autoModeGroup.items.map((item, i) => (
                <Link key={i} to={item.to} className={styles.moduleLink}>{item.label}</Link>
              ))}
            </div>
          </div>
          <div className={styles.pathCard}>
            <h3>Amazon EKS - Modular</h3>
            <p>Comprehensive modules covering critical Amazon EKS features and integrations</p>
            <Link
              className="button button--secondary button--lg"
              to="/docs/introduction"
            >
              Explore
            </Link>
            <div className={styles.moduleLinks}>
              {siteConfig.customFields.secondaryNav.eksGroup.items.map((item, i) => (
                <Link key={i} to={item.to} className={styles.moduleLink}>{item.label}</Link>
              ))}
            </div>
          </div>
          
          </div>
        </div>
      </div>
  );
}
