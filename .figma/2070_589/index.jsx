import React from 'react';

import styles from './index.module.scss';

const Component = () => {
  return (
    <div className={styles.profile}>
      <img src="../image/mfn8h0zw-wqhhukt.png" className={styles.ellipse46} />
      <p className={styles.jeyssonSNchezR}>Jeysson Sánchez R.</p>
      <img src="../image/mfn8h0zw-rnym98v.png" className={styles.image2} />
      <div className={styles.taskbar}>
        <div className={styles.homeIndicator2}>
          <div className={styles.homeIndicator} />
        </div>
        <div className={styles.subtract}>
          <div className={styles.autoWrapper}>
            <img src="../image/mfn8h0zs-hxf4gwn.svg" className={styles.home} />
            <p className={styles.inicio}>Inicio</p>
          </div>
          <div className={styles.autoWrapper2}>
            <img src="../image/mfn8h0zs-81h3nxe.svg" className={styles.grid5} />
            <p className={styles.hBitos}>Hábitos</p>
          </div>
          <p className={styles.progreso}>Progreso</p>
          <div className={styles.autoWrapper3}>
            <img
              src="../image/mfn8h0zs-i5ad6yz.svg"
              className={styles.profileCircle}
            />
            <p className={styles.perfil}>Perfil</p>
          </div>
          <img src="../image/mfn8h0zs-fd1utvu.svg" className={styles.group} />
        </div>
        <div className={styles.frame}>
          <img src="../image/mfn8h0zs-7315d36.svg" className={styles.microphone2} />
        </div>
      </div>
    </div>
  );
}

export default Component;
