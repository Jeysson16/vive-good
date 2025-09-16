import React from 'react';

import styles from './index.module.scss';

const Component = () => {
  return (
    <div className={styles.searchFilter}>
      <div className={styles.searchBox}>
        <img src="../image/mfkr03gs-zvmy3rq.svg" className={styles.bg} />
        <p className={styles.buscar}>Buscar...</p>
      </div>
      <img src="../image/mfkr03gs-6gt08ru.svg" className={styles.filter} />
    </div>
  );
}

export default Component;
