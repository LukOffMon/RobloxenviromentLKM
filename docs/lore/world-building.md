# World Building

Relacionado: [[monog-gdd]], [[art-direction]], [[npcs-and-quests]]

## Escenario
Mundo de día, cartoon y colorido, inspirado en Pet Simulator: zonas en fila separadas por portales de pago. El pueblo inicial (Zona 1) concentra el Edificio de Adopción, la Arena y el podio.

| Zona | Rol | Estado |
|---|---|---|
| Plaza Central / Arena | Hub social en el centro del mundo: Arena hexagonal con gradas abierta al sur, focos y `BattlePad`; podio del top 3 al sureste; Edificio de Adopción al norte (gacha); futuro Bazar | 🟢 en Studio |
| Zona 1: El Parque | Inicio, al sur de la plaza: césped, árboles cartoon, flores, 4 bancos de entrenamiento, palomas robóticas y el `SpawnLocation` | 🟢 en Studio |
| Zona 3: Ciber-Asilo | Mid-late game: pasillos de cristal, hidromasaje, cápsulas criogénicas. Ahora: portal al oeste con cápsulas | ⏳ portal cerrado |
| Zona 4: Galaxia OG | Estación espacial con gravedad cero. Ahora: portal al este con estrellas y planeta | ⏳ portal cerrado |

Constructor del mapa: `scripts/studio/build_monog_map.luau` (se ejecuta en Studio con el MCP). El mundo está centrado en X = +800 para no solaparse con Isla Origen, que se conserva archivada en `ServerStorage/Archive_IslaOrigen`.

## Contrato con el código (etiquetas de CollectionService)
| Etiqueta | Dónde | Qué hace el código |
|---|---|---|
| `GachaDoor` | Puerta del Edificio de Adopción | Prompt «Abrir Caja de Asilo» |
| `TrainingBench` | Asientos de los bancos del parque | Prompt «Entrenar» |
| `BattlePad` | Plataforma en el centro de la Arena | Prompt «¡Combatir!» |
| `PodiumSlot` + atributo `Rank` 1–3 | Pedestales del podio | Nombre y nivel del top 3 del servidor |
| `ZoneGate` + atributo `Zone` 2–4 | Pared del portal entre zonas | Cartel con nombre y precio, prompt de compra; se abre solo para quien la pagó |
| `BreakableSpawn` + atributo `Zone` | Marcadores invisibles, 15–25 por zona | Ahí aparecen montones de monedas, cofres y cajas fuertes |

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
