import React from 'react';

import styles from './index.module.scss';

const Component = () => {
  return (
    <div className={styles.main}>
      <img src="../image/mfm0jil5-ykta5bj.png" className={styles.image9} />
      <div className={styles.taskbar}>
        <div className={styles.homeIndicator2}>
          <div className={styles.homeIndicator} />
        </div>
        <div className={styles.subtract}>
          <div className={styles.autoWrapper}>
            <img src="../image/mfm0jil3-jajsnve.svg" className={styles.home} />
            <p className={styles.inicio}>Inicio</p>
          </div>
          <div className={styles.autoWrapper2}>
            <img src="../image/mfm0jil3-t3dsovf.svg" className={styles.grid5} />
            <p className={styles.hBitos}>Hábitos</p>
          </div>
          <p className={styles.progreso}>Progreso</p>
          <div className={styles.autoWrapper3}>
            <img
              src="../image/mfm0jil3-8dg9ed8.svg"
              className={styles.profileCircle}
            />
            <p className={styles.perfil}>Perfil</p>
          </div>
          <img src="../image/mfm0jil3-udm3wx8.svg" className={styles.group} />
        </div>
        <div className={styles.frame}>
          <img src="../image/mfm0jil3-onog97j.svg" className={styles.microphone2} />
        </div>
      </div>
    </div>
  );
}

export default Component;
