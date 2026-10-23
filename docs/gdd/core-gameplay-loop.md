# Core Gameplay Loop

**Estado:** borrador v1.0.0-alpha · Relacionado: [[economy-systems]], [[progression-tree]]

## Bucle principal
1. **Explorar** el mundo y localizar monedas (partes con la etiqueta `Coin`).
2. **Recoger** monedas: el cliente envía `CollectCoin`; el servidor valida distancia y etiqueta ([[AntiExploit-protocol]]).
3. **Progresar**: cada moneda otorga monedas y 1 punto de experiencia ([[progression-tree]]).
4. **Gastar** monedas en el inventario ([[economy-systems]]).

## Principio de diseño
El servidor es la única fuente de verdad. El cliente solo expresa intención y muestra estado ([[client-server-network-map]]).
