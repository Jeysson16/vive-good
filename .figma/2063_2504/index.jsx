import React from 'react';

import styles from './index.module.scss';

const Component = () => {
  return (
    <div className={styles.loginEmpty}>
      <img src="../image/mfk9nane-9t7ghn6.svg" className={styles.back} />
      <div className={styles.inputFields}>
        <p className={styles.iniciaSesiN}>
          Inicia
          <br />
          Sesión
        </p>
        <div className={styles.iconText}>
          <img src="../image/mfk9nane-7y8tkyg.svg" className={styles.emailIcon} />
          <p className={styles.correoElectrNico}>Correo electrónico</p>
        </div>
        <div className={styles.rectangle31}>
          <img src="../image/mfk9nane-rk2wc1w.svg" className={styles.lockIcon} />
          <p className={styles.contraseA}>Contraseña</p>
          <img src="../image/mfk9nane-203l45w.svg" className={styles.eyeOffIcon} />
        </div>
        <p className={styles.aOlvidasteTuContrase}>¿Olvidaste tu contraseña?</p>
        <div className={styles.rectangle29}>
          <p className={styles.iniciarSesiN}>Iniciar Sesión</p>
        </div>
      </div>
      <div className={styles.lowerText}>
        <p className={styles.aTodaviaNoTienesUnaC4}>
          <span className={styles.aTodaviaNoTienesUnaC}>
            ¿Todavia no tienes una cuenta?
          </span>
          <span className={styles.aTodaviaNoTienesUnaC2}>&nbsp;</span>
          <span className={styles.aTodaviaNoTienesUnaC3}>Regístrate</span>
        </p>
        <div className={styles.line3} />
      </div>
    </div>
  );
}

export default Component;
