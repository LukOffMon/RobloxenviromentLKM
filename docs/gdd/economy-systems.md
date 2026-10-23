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

## Reglas
- Todo cambio de moneda pasa por `DataService.adjust`, que rechaza decimales, saldo negativo y más de 10¹².
- Se cobra **antes** de tirar del gacha: si el cobro falla, no hay tirada.
- Los valores viven en `GameConfig` (`Gacha`, `Pension`, `Battle`, `Daily`), nunca en el código de los servicios.
