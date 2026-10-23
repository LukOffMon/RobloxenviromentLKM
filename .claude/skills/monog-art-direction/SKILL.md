---
name: monog-art-direction
description: Visual style rules for MonOG Pocket Seniors (Toon-Cyber night, neon palette, chibi grandparents, juicy UI). Use whenever creating or changing anything players see — UI panels, HUD, buttons, gacha or battle effects, pets/OG models, map props, lighting, thumbnails or promo art — so every piece looks like the same game.
---

# Dirección de arte de MonOG

Fuente de verdad: `docs/gdd/art-direction.md`. Código de referencia: `src/client/UI/Theme.luau`, `src/client/UI/OGVisuals.luau`, `src/client/Controllers/AtmosphereController.luau`, `src/client/Controllers/PetController.luau`.

## Reglas
- **Paleta cerrada.** Usa `Theme.Colors` (Night, Cyber, Panel, Lime, Amber, Gold, Pink, Cyan, Red); no inventes colores sueltos. El color de rareza siempre sale de `Theme.rarityColor`.
- **UI con `Theme`.** Construye con `Theme.create`, `Theme.label`, `Theme.button`, `Theme.corner`, `Theme.stroke`. Toda ventana nueva es un `Panel`. Texto en FredokaOne con contorno.
- **Juiciness.** Cualquier recompensa o acción importante lleva al menos dos de estos: `Theme.squish`, `Sounds.play`, `AtmosphereController.flash` o `AtmosphereController.punch`. Los momentos raros (Legendario o más) llevan los cuatro.
- **Capas (ZIndex, modo Sibling).** HUD 1–5 · paneles 20 · entrenamiento 40 · cinemáticas 50–86 · avisos 100.
- **Emojis.** Solo los que existen en la fuente de Roblox. 🪙 y 🩴 no se ven: usa 💰 y 👡. Comprueba en Studio cualquier emoji nuevo.
- **Móvil primero.** Botones de al menos 44 px, acciones a media altura a la izquierda, nada en la esquina inferior derecha (botón de saltar) ni en la inferior izquierda (joystick).
- **Personajes chibi-cabezón.** Cabeza ≈ 1,3 × cuerpo, ojos con brillo, mejillas, andador (dorado y de neón en la Edición Dorada), aro de rareza en el suelo. Un arquetipo nuevo necesita su entrada en `OGVisuals`.
- **Mapa.** De noche, neón con moderación (pocas PointLight), `Anchored` y `CastShadow = false` en decoración pequeña. Las piezas de juego se identifican por etiqueta, no por nombre (ver `docs/lore/world-building.md`).
- **Iluminación.** La controla `AtmosphereController` en runtime. Para cambiar el look global, edita sus constantes, no el Lighting del place.

## Antes de dar algo por terminado
1. `./scripts/check.ps1` en verde.
2. Mirarlo en Studio (place de prueba: `rojo build playtest.project.json`) y hacer captura.
3. Si cambia el estilo, actualiza `docs/gdd/art-direction.md`.
