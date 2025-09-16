import React from 'react';

import styles from './index.module.scss';

const Component = () => {
  return (
    <div className={styles.registerEmpty}>
      <img src="../image/mfk9nalo-rl2ubkr.svg" className={styles.back} />
      <div className={styles.inputFields}>
        <p className={styles.creaTuCuenta}>
          Crea tu
          <br />
          Cuenta
        </p>
        <div className={styles.iconText}>
          <img src="../image/mfk9nalo-5in7ugf.svg" className={styles.userIcon} />
          <p className={styles.nombresYApellidos}>Nombres y Apellidos</p>
        </div>
        <div className={styles.iconText2}>
          <img src="../image/mfk9nalo-jre2acb.svg" className={styles.emailIcon} />
          <p className={styles.nombresYApellidos}>Correo electrónico</p>
        </div>
        <div className={styles.rectangle31}>
          <img src="../image/mfk9nalo-sqn2gf5.svg" className={styles.lockIcon} />
          <p className={styles.contraseA}>Contraseña</p>
          <img src="../image/mfk9nalo-75u8x3y.svg" className={styles.eyeOffIcon} />
        </div>
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
