import React from "react";
import clsx from "clsx";
import Link from "@docusaurus/Link";
import useDocusaurusContext from "@docusaurus/useDocusaurusContext";
import Layout from "@theme/Layout";
import HomepageFeatures from "@site/src/components/HomepageFeatures";
import HomepageVideo from "@site/src/components/HomepageVideo";
import Translate from "@docusaurus/Translate";

import styles from "./index.module.css";

function HomepageHeader() {
  const { siteConfig } = useDocusaurusContext();
  return (
    <header className={clsx("hero hero--primary", styles.heroBanner)}>
      <div className="container">
        <h1 className="hero__title">
          <Translate id="homePage.title" description="The home page title">
            {siteConfig.title}
          </Translate>
        </h1>
        <p className="hero__subtitle">
          <Translate id="homePage.tagline" description="The home page tagline">
            {siteConfig.tagline}
          </Translate>
        </p>
        <div className={styles.buttons}>
          <Link
            className="button button--secondary button--lg"
            to="/docs/introduction"
          >
            <Translate
              id="homePage.getStarted"
              description="The home page get started"
            >
              Get Started!
            </Translate>
          </Link>
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
        <HomepageVideo />
      </main>
    </Layout>
  );
}
