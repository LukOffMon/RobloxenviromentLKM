# Core Gameplay Loop

**Estado:** v0.1.0-monog · Relacionado: [[monog-gdd]], [[economy-systems]], [[progression-tree]], [[battle-system]]

## Primeros 180 segundos
1. El jugador entra con 300 PensionCoins y **una Caja de Asilo gratis**: el Edificio de Adopción se abre solo.
2. Cinemática ¡TOC, TOC, TOC! y su primer OG, que se equipa solo y empieza a seguirle como mascota.
3. Su OG ya cobra pensión por segundo; con 250 monedas puede abrir otra caja.

## Bucle principal
1. **Entrenar** (30 s): «Chanclazo Timing» en el Gimnasio; los aciertos dan XP al OG.
2. **Combatir** (1–2 min): el escuadrón de 3 OGs pelea contra el rival de la Arena; ganar da monedas y XP.
3. **Coleccionar**: gastar monedas y gemas en Cajas de Asilo ([[og-catalog]]).
4. **Volver mañana**: Bingo Matutino con racha de 7 días.

## Principio de diseño
El servidor es la única fuente de verdad. El cliente solo expresa intención y muestra estado ([[client-server-network-map]]).
