# Economy Systems

Relacionado: [[monog-gdd]], [[core-gameplay-loop]], [[datastore-profile-schema]], [[monetization-and-growth]]

## Monedas
| Moneda | Se gana | Se gasta |
|---|---|---|
| PensionCoins 💰 | Pensión pasiva, combates, bingo | Cajas de Asilo (250 / 1150 x5) |
| GigaGems 💎 | Bingo días 5 y 7, cada 5 rivales | Caja de Gemas (120, Raro+) |
| Tickets 🎟 | Bienvenida, bingo días 3 y 7 | 1 caja gratis |
| Tickets Épicos ⭐ | Caja de Inicio (Robux) | 1 caja Épico+ |

## Pensión (ingreso pasivo)
- Por segundo: suma de `pensión de la rareza × (1 + 0,1 × (nivel − 1))` de los OGs equipados.
- × multiplicador social: +15 % por amigo conectado en el servidor, máximo +75 %.
- Offline: hasta 2 h al 50 %; con el pase «Pensión Offline Ampliada», 24 h al 100 %.

## Rompibles (núcleo estilo Pet Simulator)
Aparecen en los marcadores `BreakableSpawn` de cada zona (hasta 18 por zona, reaparecen cada 2 s). Tocar uno manda a los OGs equipados a atacarlo; al romperlo siguen con el más cercano.

| Tipo | Vida | Monedas | Peso | Gemas |
|---|---|---|---|---|
| Montón de monedas | 40 | 12 | 70 % | — |
| Cofre de la abuela | 260 | 90 | 24 % | 5 % de 2 💎 |
| Caja fuerte de pensiones | 1800 | 700 | 6 % | 50 % de 10 💎 |

Vida y monedas × multiplicador de zona (1, 6, 40, 250). Daño por segundo = suma del ATK de los OGs equipados. Si ayudan varios jugadores, el premio se reparte según el daño de cada uno.

## Zonas
Se compran en orden en su portal: Playa de los Jubilados 2.500 💰, Ciber-Asilo 30.000 💰, Galaxia OG 300.000 💰. Solo se puede atacar en zonas desbloqueadas.

## Caramelos de abuela (exploración)
Hasta 30 caramelos de neón aparecen en los marcadores `CandySpawn` del mapa y reaparecen cada 4 s. Al tocarlos: 8–20 💰 × (1 + 0,15 por nivel de rival superado), 2 % de un ticket o 1 % de 5 💎. El servidor valida la distancia y los quita antes de pagar.

## Reglas
- Todo cambio de moneda pasa por `DataService.adjust`, que rechaza decimales, saldo negativo y más de 10¹².
- Se cobra **antes** de tirar del gacha: si el cobro falla, no hay tirada.
- Los valores viven en `GameConfig` (`Gacha`, `Pension`, `Battle`, `Daily`), nunca en el código de los servicios.
