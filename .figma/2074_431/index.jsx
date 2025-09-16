import React from 'react';

import styles from './index.module.scss';

const Component = () => {
  return (
    <div className={styles.main}>
      <div className={styles.autoWrapper}>
        <img src="../image/mflptaj0-fk2d54a.svg" className={styles.back} />
        <p className={styles.holaAnastacia}>Nuevo Hábito</p>
      </div>
      <div className={styles.image3}>
        <div className={styles.autoWrapper2}>
          <div className={styles.rectangle4192} />
          <p className={styles.dormirAntesDeLas10Pm}>Dormir antes de las 10 pm</p>
        </div>
        <div className={styles.rectangle4191}>
          <p className={styles.sueO}>Sueño</p>
        </div>
      </div>
      <div className={styles.taskbar}>
        <div className={styles.homeIndicator2}>
          <div className={styles.homeIndicator} />
        </div>
        <div className={styles.subtract}>
          <div className={styles.autoWrapper3}>
            <img src="../image/mflptaj0-7jlwx78.svg" className={styles.home} />
            <p className={styles.inicio}>Inicio</p>
          </div>
          <div className={styles.autoWrapper4}>
            <img src="../image/mflptaj0-i9eptoh.svg" className={styles.grid5} />
            <p className={styles.hBitos}>Hábitos</p>
          </div>
          <p className={styles.progreso}>Progreso</p>
          <div className={styles.autoWrapper5}>
            <img
              src="../image/mflptaj0-zoju6hk.svg"
              className={styles.profileCircle}
            />
            <p className={styles.perfil}>Perfil</p>
          </div>
          <img src="../image/mflptaj0-eo9ml63.svg" className={styles.group} />
        </div>
        <div className={styles.frame}>
          <img src="../image/mflptaj0-fplku9c.svg" className={styles.microphone2} />
        </div>
      </div>
    </div>
  );
}

export default Component;
