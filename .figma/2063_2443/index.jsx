import React from 'react';

import styles from './index.module.scss';

const Component = () => {
  return (
    <div className={styles.registerActive2}>
      <img src="../image/mfk9namf-jaggb37.svg" className={styles.back} />
      <div className={styles.inputFields}>
        <p className={styles.creaTuCuenta}>
          Crea tu
          <br />
          Cuenta
        </p>
        <div className={styles.iconText}>
          <img src="../image/mfk9namf-veuithn.svg" className={styles.userIcon} />
          <p className={styles.josephRen}>Joseph Ren</p>
        </div>
        <div className={styles.iconText2}>
          <img src="../image/mfk9namf-avi706z.svg" className={styles.emailIcon} />
          <p className={styles.josephRen}>Joseph Ren@Mail.Com</p>
        </div>
        <img src="../image/mfk9namf-noh7tlt.svg" className={styles.password} />
        <div className={styles.rectangle29}>
          <p className={styles.registrar}>Registrar</p>
        </div>
      </div>
      <div className={styles.lowerText}>
        <p className={styles.aYaTienesUnaCuentaIn4}>
          <span className={styles.aYaTienesUnaCuentaIn}>
            ¿Ya tienes una cuenta?
          </span>
          <span className={styles.aYaTienesUnaCuentaIn2}>&nbsp;</span>
          <span className={styles.aYaTienesUnaCuentaIn3}>Inicia Sesión</span>
        </p>
        <div className={styles.line3} />
      </div>
    </div>
  );
}

export default Component;
