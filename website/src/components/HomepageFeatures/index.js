import React from "react";
import clsx from "clsx";
import styles from "./styles.module.css";
import useBaseUrl from "@docusaurus/useBaseUrl";
import Translate from "@docusaurus/Translate";

const FeatureList = [
  {
    title: (
      <Translate
        id="homePage.feature.acceleratedPath.title"
        description="The title of 'Accelerated path' feature"
      >
        Accelerated path
      </Translate>
    ),
    image: "/img/workshop.webp",
    description: (
      <Translate
        id="homePage.feature.acceleratedPath.description"
        description="The description of 'Accelerated path' feature"
      >
        Navigate through the features of Amazon Elastic Kubernetes Services
        quickly.
      </Translate>
    ),
  },
  {
    title: (
      <Translate
        id="homePage.feature.selfPaced.title"
        description="The title of 'Self-paced' feature"
      >
        Self-paced
      </Translate>
    ),
    image: "/img/self_paced.webp",
    description: (
      <Translate
        id="homePage.feature.acceleratedPath.description"
        description="The description of 'Self-paced' feature"
      >
        Learn at your own pace using practical examples.
      </Translate>
    ),
  },
  {
    title: (
      <Translate
        id="homePage.feature.modular.title"
        description="The title of 'Modular' feature"
      >
        Modular
      </Translate>
    ),
    image: "/img/path.webp",
    description: (
      <Translate
        id="homePage.feature.modular.description"
        description="The description of 'Modular' feature"
      >
        Customize your learning path by focusing on the features that matter
        most to you.
      </Translate>
    ),
  },
];

function Feature({ image, title, description }) {
  return (
    <div className={clsx("col col--4")}>
      <div className="text--center">
        <img src={useBaseUrl(image)} alt={description} />
      </div>
      <div className="text--center padding-horiz--md">
        <h3>{title}</h3>
        <p>{description}</p>
      </div>
    </div>
  );
}

export default function HomepageFeatures() {
  return (
    <section className={styles.features}>
      <div className="container">
        <div className="row">
          {FeatureList.map((props, idx) => (
            <Feature key={idx} {...props} />
          ))}
        </div>
      </div>
    </section>
  );
}
