import React from 'react';
import clsx from 'clsx';
import styles from './styles.module.css';

const FeatureList = [
  {
    title: 'Accelerated path',
    Svg: require('@site/static/img/accelerate.svg').default,
    description: (
      <>
        Navigate through the features of Amazon Elastic Kubernetes Services quickly.
      </>
    ),
  },
  {
    title: 'Self-Paced',
    Svg: require('@site/static/img/self-paced.svg').default,
    description: (
      <>
        Learn at your own pace using practical examples.
      </>
    ),
  },
  {
    title: 'Modular',
    Svg: require('@site/static/img/modules.svg').default,
    description: (
      <>
        Customize your learning path by focusing on the features that matter most to you.
      </>
    ),
  },
];

function Feature({Svg, title, description}) {
  return (
    <div className={clsx('col col--4')}>
      <div className="text--center">
        <Svg className={styles.featureSvg} role="img" />
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
