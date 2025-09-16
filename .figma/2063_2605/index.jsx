import React from 'react';

import styles from './index.module.scss';

const Component = () => {
  return (
    <div className={styles.loginActive2}>
      <img src="../image/mfk9naqd-pamc328.svg" className={styles.back} />
      <div className={styles.inputFields}>
        <p className={styles.iniciaSesiN}>
          Inicia
          <br />
          Sesión
        </p>
        <div className={styles.iconText}>
          <img src="../image/mfk9naqd-61ppxna.svg" className={styles.emailIcon} />
          <p className={styles.josephRenMailCom}>JosephRen@Mail.Com</p>
        </div>
        <img src="../image/mfk9naqd-b2a7k5i.svg" className={styles.password} />
        <p className={styles.aOlvidasteTuContrase}>¿Olvidaste tu contraseña?</p>
        <div className={styles.rectangle29}>
          <p className={styles.iniciarSesiN}>Iniciar Sesión</p>
        </div>
      </div>
      <p className={styles.aTodaviaNoTienesUnaC4}>
        <span className={styles.aTodaviaNoTienesUnaC}>
          ¿Todavia no tienes una cuenta?
        </span>
        <span className={styles.aTodaviaNoTienesUnaC2}>&nbsp;</span>
        <span className={styles.aTodaviaNoTienesUnaC3}>Regístrate</span>
      </p>
      <img src="https://via.placeholder.com/414x1" className={styles.lowerText} />
    </div>
  );
}

export default Component;
