import React from 'react';

import styles from './index.module.scss';

const Component = () => {
  return (
    <div className={styles.welcome}>
      <img
        src="../image/mfk4mx9s-sur5c5u.png"
        className={styles.imageRemovebgPreview}
      />
      <p className={styles.bienvenidoAViveGood4}>
        <span className={styles.bienvenidoAViveGood}>
          Bienvenido a<br />
        </span>
        <span className={styles.bienvenidoAViveGood2}>Vive</span>
        <span className={styles.bienvenidoAViveGood3}>Good</span>
      </p>
      <div className={styles.autoLayoutVertical}>
        <div className={styles.typeButtonType2Prima}>
          <p className={styles.iniciarSesiN}>Iniciar Sesión</p>
        </div>
        <div className={styles.typeButtonType2Secon}>
          <p className={styles.registrarse}>Registrarse</p>
        </div>
      </div>
    </div>
  );
}

export default Component;
