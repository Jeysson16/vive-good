import React from 'react';

import styles from './index.module.scss';

const Component = () => {
  return (
    <div className={styles.onBoarding02}>
      <p className={styles.saltar}>Saltar</p>
      <img
        src="../image/mfk2xdmx-6ksxk0d.png"
        className={styles.imageRemovebgPreview}
      />
      <div className={styles.autoWrapper}>
        <div className={styles.slider}>
          <div className={styles.ellipse19} />
          <div className={styles.ellipse20} />
        </div>
        <div className={styles.vector2}>
          <div className={styles.vector}>
            <div className={styles.ellipse18} />
          </div>
        </div>
      </div>
      <p className={styles.detectaSintomas}>
        &nbsp;&nbsp;&nbsp;Detecta
        <br />
        &nbsp;&nbsp;&nbsp;Sintomas
      </p>
      <p className={styles.identificaLosSignosT}>
        Identifica los signos tempranos de gastritis a tiempo
      </p>
      <div className={styles.frame13}>
        <img
          src="../image/mfk2xdmw-l7cinyr.svg"
          className={styles.iconsArrowLeft2Line}
        />
        <div className={styles.frame14} />
        <img
          src="../image/mfk2xdmw-9ff2ou8.svg"
          className={styles.iconsArrowLeft2Line}
        />
      </div>
    </div>
  );
}

export default Component;
