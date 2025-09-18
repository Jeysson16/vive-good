import React from 'react';

import styles from './index.module.scss';

const Component = () => {
  return (
    <div className={styles.frame7}>
      <p className={styles.editarHBito}>Editar hábito</p>
      <div className={styles.group4}>
        <p className={styles.editarHBito}>Ver progreso</p>
        <p className={styles.eliminarHBito}>Eliminar hábito</p>
      </div>
    </div>
  );
}

export default Component;
