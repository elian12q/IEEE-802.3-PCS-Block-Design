# IEEE-802.3-PCS-Block-Design

Bloque de la subcapa de codificacipon física (PCS) según las especificaciones de la cláusula 36 del estándar IEEE 802.3. Este diseño se centra exclusivamente en los módulos de Transmisor, Sincronizador y Receptor. 

Cada uno de estos módulos ha sido diseñado y probado individualmente. La conexión de la subcapa PCS con estos módulos también ha sido verificada y funciona de manera adecuada. Para validar el diseño, se realizaron pruebas separadas en cada módulo y una prueba con junta en la subcapa PCS en modo loopback, donde las salidas tx_code_group se conectan a las entradas rx_code_group, permitiendo que los datos transmitidos se reenvíen en la dirección opuesta.
