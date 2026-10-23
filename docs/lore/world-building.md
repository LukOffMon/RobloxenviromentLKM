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

| `CandySpawn` | Marcadores invisibles por todo el mapa (40–60) | Ahí aparecen los caramelos de abuela ([[economy-systems]]) |

## Etiquetas de animación (WorldFXController, en el cliente)
| Etiqueta | Efecto | Atributos |
|---|---|---|
| `Spin` | Gira sobre Y | `SpinSpeed` (grados/s, 45) |
| `Bob` | Flota arriba y abajo | `BobHeight` (1), `BobSpeed` (1) |
| `Sway` | Se mece (copas de árboles) | `SwayAngle` (4) |
| `NeonPulse` | Late de brillo | `PulseSpeed` (1.5) |
| `Blink` | Bombillas en cadena (marquesinas) | `BlinkIndex` 1..N |
| `RainbowCycle` | Color arcoíris en bucle | — |
| `Walker` | Deambula (palomas robóticas) | `WanderRadius` (10) |

Funcionan sobre BasePart o Model con PrimaryPart y se pueden combinar (p. ej. `Spin` + `Bob`). Solo se animan a menos de 220 studs de la cámara.

Todo vive bajo `Workspace/MonOGWorld`. Ajustes de streaming: radio 256, mínimo 128, `LowMemory`.
