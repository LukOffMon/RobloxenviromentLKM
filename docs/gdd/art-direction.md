# Dirección de arte «Toon-Cyber»

Relacionado: [[monog-gdd]], [[og-catalog]], [[world-building]] · Código: `src/client/UI/Theme.luau`, `src/client/UI/OGVisuals.luau`

## Paleta
| Uso | Colores |
|---|---|
| Fondo / entorno | Azul medianoche `#0B0E14`, púrpura cyber `#1A0933`, verde lima `#39FF14` |
| Interfaz | Naranja ámbar `#FF8C00`, dorado neón `#FFD700`, blanco puro |
| Acentos | Rosa neón `#FF3EA5`, cian `#20E3E0`, rojo `#FF2A4D` |

Brillos de rareza en [[og-catalog]].

## Ambiente
`AtmosphereController` fija en el cliente la noche violeta: niebla (Atmosphere), bloom suave para el neón, saturación +0,28 y cielo con 6000 estrellas. Ofrece `flash(color)` (destello de rareza) y `punch()` (golpe de cámara), que usan el gacha, los especiales, los críticos y los K.O.

## Interfaz
- Fuente FredokaOne; botones con contorno oscuro, degradado y efecto *squish & stretch* al pulsar.
- Barra superior: PensionCoins (salta al subir), GigaGems (icono que oscila) y tickets.
- Columna de acciones a la izquierda, a media altura, lejos del joystick y del botón de salto: Asilo, Mis OGs, Entrenar, Combatir, Bingo.
- Teclas en PC: Espacio o E para el chanclazo.
- Emojis: solo los que existen en la fuente de Roblox (🪙 y 🩴 no se ven; usar 💰 y 👡).

## Personajes (chibi-cabezón)
Cabeza grande y cuerpo compacto, al estilo de las mascotas de Roblox. Por ahora se construyen con piezas básicas en el cliente (`PetController`): piel, pelo, ojos, gafas, bigote o barba y un accesorio (moño, sombrero de charro neón, gorra, cinta, casco). Los Legendarios o mejores emiten partículas; los Shiny llevan traje dorado.

**Siguiente paso de arte:** sustituir las primitivas por MeshParts modeladas (Blender o `generate_mesh` del MCP de Studio) con el mismo contrato de colores.

Las mascotas llevan brillo en los ojos, mejillas, andador (dorado de neón si son Shiny), aro de rareza en el suelo (arcoíris en Transcendentes) y saltitos con squish & stretch.

## Cinemática del gacha
1. Zoom a la puerta del asilo y tres «¡TOC!» con temblor.
2. La luz del color de la rareza sale por las rendijas; desde Legendario, la puerta vibra.
3. La puerta sale volando, confeti y el anuncio «¡ABUELO <RAREZA> CONSEGUIDO!».
