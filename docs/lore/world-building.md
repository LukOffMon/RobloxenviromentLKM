# World Building

Relacionado: [[monog-gdd]], [[art-direction]], [[npcs-and-quests]]

## Escenario
Un mundo abierto Toon-Cyber de noche, dividido en 4 áreas de progresión alrededor de una gran plaza central.

| Zona | Rol | Estado |
|---|---|---|
| Plaza Central / Arena | Hub social: Arena hexagonal con gradas, podio del top 3, Edificio de Adopción (gacha), futuro Bazar | 🟡 en el script, sin aplicar en Studio |
| Zona 1: El Parque | Inicio: césped, árboles cartoon, bancos de entrenamiento, palomas robóticas | 🟡 igual |
| Zona 3: Ciber-Asilo | Mid-late game: pasillos de cristal, hidromasaje, cápsulas criogénicas | ⏳ portal cerrado |
| Zona 4: Galaxia OG | Estación espacial con gravedad cero | ⏳ portal cerrado |

Constructor del mapa: `scripts/studio/build_monog_map.luau` (se ejecuta en Studio con el MCP).

## Contrato con el código (etiquetas de CollectionService)
| Etiqueta | Dónde | Qué hace el código |
|---|---|---|
| `GachaDoor` | Puerta del Edificio de Adopción | Prompt «Abrir Caja de Asilo» |
| `TrainingBench` | Asientos de los bancos del parque | Prompt «Entrenar» |
| `BattlePad` | Plataforma en el centro de la Arena | Prompt «¡Combatir!» |
| `PodiumSlot` + atributo `Rank` 1–3 | Pedestales del podio | Nombre y nivel del top 3 del servidor |
| `ZoneGate` + atributo `Zone` 3–4 | Portales de zonas futuras | Cartel «Próximamente» |

Todo vive bajo `Workspace/MonOGWorld`. Ajustes de streaming: radio 256, mínimo 128, `LowMemory`.
