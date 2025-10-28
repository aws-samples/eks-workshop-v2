import React from "react";
import clsx from "clsx";
import Link from "@docusaurus/Link";
import useDocusaurusContext from "@docusaurus/useDocusaurusContext";
import Layout from "@theme/Layout";
import HomepageFeatures from "@site/src/components/HomepageFeatures";
import HomepageVideo from "@site/src/components/HomepageVideo";

import styles from "./index.module.css";

function HomepageHeader() {
  const { siteConfig } = useDocusaurusContext();
  
  return (
    <header className={clsx("hero hero--primary", styles.heroBanner)}>
      <div className="container">
        <h1 className="hero__title">{siteConfig.title}</h1>
        <p className="hero__subtitle">{siteConfig.tagline}</p>
        <div className={styles.pathSelection}>
          <div className={styles.pathCard}>
            <h3>Amazon EKS Auto Mode <span className={styles.newBadge}>New</span></h3>
            <p>Streamlined learning paths powered by Amazon EKS Auto Mode</p>
            <Link
              className="button button--secondary button--lg"
              to="/docs/fastpaths/setup"
            >
              Get Started
            </Link>
            <div className={styles.moduleLinks}>
              {siteConfig.customFields.secondaryNav.autoModeGroup.items.map((item, i) => (
                <Link key={i} to={item.to} className={styles.moduleLink}>{item.label}</Link>
              ))}
            </div>
          </div>
          <div className={styles.pathCard}>
            <h3>Amazon EKS</h3>
            <p>Comprehensive learning path covering critical Amazon EKS features and integrations</p>
            <Link
              className="button button--primary button--lg"
              to="/docs/introduction"
            >
              Get Started
            </Link>
            <div className={styles.moduleLinks}>
              {siteConfig.customFields.secondaryNav.eksGroup.items.map((item, i) => (
                <Link key={i} to={item.to} className={styles.moduleLink}>{item.label}</Link>
              ))}
            </div>
          </div>
          
        </div>
      </div>
    </header>
  );
}

export default function Home() {
  const { siteConfig } = useDocusaurusContext();
  return (
    <Layout
      title={siteConfig.title}
      description="Amazon Web Services workshop for Elastic Kubernetes Service"
    >
      <HomepageHeader />
      <main>
        <HomepageFeatures />
      </main>
    </Layout>
  );
}
