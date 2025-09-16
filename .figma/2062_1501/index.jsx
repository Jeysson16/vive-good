import React from 'react';

import styles from './index.module.scss';

const Component = () => {
  return (
    <div className={styles.splash}>
      <img
        src="../image/mfk2rff1-hczdp84.png"
        className={styles.imageRemovebgPreview}
      />
      <p className={styles.viveGood3}>
        <span className={styles.viveGood}>Vive</span>
        <span className={styles.viveGood2}>Good</span>
      </p>
      <p className={styles.version103}>
        <span className={styles.version10}>Version</span>
        <span className={styles.version102}>&nbsp;1.0</span>
      </p>
    </div>
  );
}

export default Component;
