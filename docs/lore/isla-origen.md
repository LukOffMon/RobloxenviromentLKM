---
estado: probando
metrica: retención D1
fecha: 2026-10-22
---
# Isla Origen

Relacionado: [[world-building]] · [[npcs-and-quests]] · [[core-gameplay-loop]]

Primera zona del archipiélago (niveles 1–3). Enseña a andar, recoger monedas y saltar, con monedas abundantes para que el jugador suba de nivel en los primeros minutos.

## Cómo se construye
El mundo vive en el place de Studio, no en git. La zona se genera con `scripts/studio/build-isla-origen.luau`: se pega en la barra de comandos de Studio o se ejecuta con `execute_luau` del MCP. Es repetible: borra la versión anterior y la vuelve a crear igual.

Cambios globales que hace el script: elimina el `Baseplate`, pone `Workspace.FallenPartsDestroyHeight = -50` (quien cae reaparece enseguida), `Lighting.ClockTime = 14` y un `Atmosphere` azul claro.

## Recorrido del jugador
1. **Spawn** (`0, 51, 44`) en el borde sur de la isla principal.
2. **Pasillo de bienvenida**: 10 monedas en línea recta hacia el centro. Coincide con la misión de la Guardiana Iza («Recoge 10 monedas»).
3. **Cristal de Origen**: hito central luminoso rodeado por un anillo de 12 monedas.
4. **Exploración**: 8 monedas sueltas por la isla entre árboles y rocas.
5. **Ruta de saltos**: 4 plataformas desde el borde norte, cada una 2 studs más alta, con una moneda encima.
6. **Islote de recompensa** (`0, 59, -124`): anillo de 8 monedas y una moneda grande de valor 5.

Total: 43 monedas, 47 de valor.

## Instancias
| Ruta | Qué es |
|---|---|
| `Workspace.IslaOrigen` | `Model` de la zona |
| `IslaOrigen.Spawn` | `SpawnLocation` |
| `IslaOrigen.Coins.Coin_NN` | Monedas: etiqueta `Coin`, atributo `Value` (1, o 5 la grande) |
| `IslaOrigen.Platforms.JumpPlatform1–4` | Plataformas de salto ancladas |
| `IslaOrigen.Decor` | `CristalOrigen`, árboles y rocas |
| `IslaOrigen.Markers.GuardianaIza` | Marcador invisible: etiqueta `NpcSpawn`, atributo `NpcId = "GuardianaIza"` |
| `Workspace.Terrain` | Isla principal (radio 60) e islote (radio 16) de hierba y roca |

## Pendiente
- El cliente aún no envía `CollectCoin` al tocar una moneda: hasta entonces las monedas se ven pero no se recogen.
- Las monedas recogidas no reaparecen.
- La Guardiana Iza es solo un marcador; falta el NPC y su misión.
