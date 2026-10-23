# Catálogo de OGs y gacha

Relacionado: [[monog-gdd]], [[battle-system]], [[art-direction]] · Código: `src/shared/Configurations/OGCatalog.luau`

## Rarezas y probabilidades por tirada
| Rareza | Probabilidad | Brillo | Pensión base/s |
|---|---|---|---|
| Común | 55 % | Gris cobre | 1 |
| Raro | 30 % | Turquesa neón | 3 |
| Épico | 11 % | Violeta neón | 8 |
| Legendario | 3,8 % | Dorado solar | 25 |
| Mítico | 0,19 % | Rojo carmesí con partículas | 90 |
| Transcendente | 0,01 % | Arcoíris / verde lima | 400 |

- **Contador de piedad:** la tirada 1000 sin Transcendente lo garantiza; al salir uno, el contador vuelve a 0.
- **Shiny / Edición Dorada:** 0,5 % por tirada, solo estético (traje dorado y más brillo).
- Las probabilidades se muestran en el Edificio de Adopción antes de abrir: es obligatorio en Roblox para objetos aleatorios.

## Arquetipos
| Id | Nombre | Rareza | Especial |
|---|---|---|---|
| VecinoReganon | Vecino Regañón | Común | ¡Bájale a la Música! (1,8×) |
| AbueloDomino | Abuelo del Dominó | Común | Capicúa (2 golpes de 0,9×) |
| AbuelaCosturera | Abuela Costurera Bélica | Raro | Chanclazo Teledirigido (2,2×) |
| AbueloCartero | Cartero Jubilado Turbo | Raro | Correo Certificado (3 golpes de 0,8×) |
| DonChente | Don Chente «El Charro Inmortal» | Épico | Grito Vicente (1,4× a todos) |
| MaestroMarcial | Maestro Marcial Retirado | Épico | Patada del Jubilado (2,8×) |
| SenseiTanaka | Sensei Tanaka «100 Añejos» | Legendario | Sombra de Bastón (5 golpes de 0,75×) |
| CientificoLoco | Científico Loco de la Posguerra | Legendario | Fórmula de Juventud Inestable (1,7× a todos) |
| ViajeroIntergalactico | Viajero Intergaláctico | Mítico | Dentadura Orbital (2,1× a todos) |
| CiberAbuelo | Ciber-Abuelo MonOG-01 | Transcendente | Sobrecarga de Pensión (3× a todos) |

Los Id van sin tildes ni ñ porque son claves de datos guardados. Para añadir un arquetipo: entrada en `OGCatalog.luau`, aspecto en `src/client/UI/OGVisuals.luau` y fila aquí.

## Cajas
| Caja | Coste | Garantía |
|---|---|---|
| Caja de Asilo | 250 PensionCoins | — |
| Caja de Asilo x5 | 1150 PensionCoins | — |
| Caja de Gemas | 120 GigaGems | Raro o mejor |
| Ticket gratis | 1 ticket (bingo, bienvenida) | — |
| Ticket Épico | 1 ticket épico (Caja de Inicio de Robux) | Épico o mejor |

Si el asilo está lleno (60 OGs), una compra de Robux devuelve las tiradas sobrantes como tickets, así no se pierde nada pagado.
