# Economy Systems

Relacionado: [[core-gameplay-loop]], [[datastore-profile-schema]]

| Fuente / Sumidero | Valor | Autoridad |
|---|---|---|
| Moneda del mundo | atributo `Value` de la parte (por defecto 1) | Servidor |
| Límite de monedas | `GameConfig.Economy.MaxCoins` = 1 000 000 000 | Servidor |

## Reglas
- Toda modificación pasa por `DataService.addCoins`, que rechaza valores no enteros, negativos por debajo de 0 o por encima del máximo.
- La moneda se destruye **antes** de pagarse para impedir el doble cobro por peticiones simultáneas.
