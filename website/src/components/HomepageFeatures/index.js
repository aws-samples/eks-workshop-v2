import React from 'react';
import clsx from 'clsx';
import styles from './styles.module.css'
import useBaseUrl from '@docusaurus/useBaseUrl';

const FeatureList = [
  {
    title: 'Accelerated path',
    image: '/img/workshop.png',
    description: (
      <>
        Navigate through the features of Amazon Elastic Kubernetes Services quickly.
      </>
    ),
  },
  {
    title: 'Self-Paced',
    image: '/img/self_paced.png',
    description: (
      <>
        Learn at your own pace using practical examples.
      </>
    ),
  },
  {
    title: 'Modular',
    image: '/img/path.png',
    description: (
      <>
        Customize your learning path by focusing on the features that matter most to you.
      </>
    ),
  },
];

function Feature({image, title, description}) {
  return (
    <div className={clsx('col col--4')}>
      <div className="text--center">
        <img src={useBaseUrl(image)} />
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
