import React from 'react';

import styles from './index.module.scss';

const Component = () => {
  return (
    <div className={styles.taskbar}>
      <div className={styles.subtract}>
        <div className={styles.autoWrapper}>
          <img src="../image/mfkj00ff-icof0or.svg" className={styles.home} />
          <p className={styles.inicio}>Inicio</p>
        </div>
        <div className={styles.autoWrapper2}>
          <img src="../image/mfkj00ff-polbsnu.svg" className={styles.grid5} />
          <p className={styles.hBitos}>Hábitos</p>
        </div>
        <p className={styles.progreso}>Progreso</p>
        <div className={styles.autoWrapper3}>
          <img
            src="../image/mfkj00ff-ybd7z6j.svg"
            className={styles.profileCircle}
          />
          <p className={styles.perfil}>Perfil</p>
        </div>
        <img src="../image/mfkj00ff-fevpwux.svg" className={styles.group} />
      </div>
      <div className={styles.frame}>
        <img src="../image/mfkj00ff-xp0rkry.svg" className={styles.microphone2} />
      </div>
    </div>
  );
}

export default Component;
