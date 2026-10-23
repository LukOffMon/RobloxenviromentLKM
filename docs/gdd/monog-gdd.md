---
estado: en desarrollo
metrica: retención D1
---
# MonOG: Pocket Seniors — GDD maestro

Fuente: «MON OG» (GDD del autor, 11 páginas). Esta nota resume el diseño y marca qué está construido. Detalle por sistema en las notas enlazadas.

- **Plataforma:** Roblox (PC, móvil, consola y tablet)
- **Género:** simulador de colección + crianza + combates por turnos + tycoon incremental
- **Público:** 8–22 años; humor absurdo, colección y competitividad
- **Propuesta única:** el «Pokémon de la tercera edad»: coleccionar, entrenar y combatir con abuelos de distintos arquetipos

Leyenda: ✅ hecho · 🟡 parcial · ⏳ pendiente

## Bucles de juego
| Bucle | Diseño | Estado |
|---|---|---|
| Micro (0–30 s) | «Chanclazo Timing»: pulsar al ritmo en el Gimnasio para subir stats | ✅ [[core-gameplay-loop]] |
| Core (5–15 min) | Escuadrón de 3 OGs → Arena → combate por turnos → PensionCoins | ✅ contra NPC · ⏳ PvP · [[battle-system]] |
| Meta (días) | Rebirth del asilo: alas temáticas y multiplicadores permanentes | ⏳ [[progression-tree]] |
| Gacha | Cajas de Asilo con cinemática ¡TOC, TOC, TOC! | ✅ [[og-catalog]] |
| Pasivo | Pensión por segundo de los OGs equipados | ✅ [[economy-systems]] |

## Retención
| Sistema | Estado |
|---|---|
| Bingo Matutino (racha de 7 días; romperla reinicia la cartilla) | ✅ |
| Torneo Mundial de Veteranos cada 4 h con trofeos en la base | ⏳ |
| Penalización de pensión por faltar a torneos | ⏳ |
| Auras de vapor de té y bastón legendario para el top | 🟡 aura del pase «Abuelo Cuántico» |
| Variantes Shiny / Edición Dorada (0,5 %) | ✅ |

## Monetización
Tabla de productos, precios y cómo crearlos en [[monetization-and-growth]]. Probabilidades y piedad en [[og-catalog]].

## Viralidad
| Sistema | Estado |
|---|---|
| K.O. cómico: el abuelo sale volando con sonido de caricatura | ✅ en el visor de combate |
| +15 % de pensión por amigo en el servidor (máx. +75 %) | ✅ |
| Bazar de Antigüedades (trading con impuesto del 5 %) | ⏳ |
| Estatuas doradas del top 3 en la plaza | 🟡 podio con nombres; estatuas pendientes |

## Técnica
- Servidor autoritativo: gacha, daño, recompensas y compras solo en el servidor. Ver [[client-server-network-map]] y [[AntiExploit-protocol]].
- Datos: DataService propio con *session locking* (equivale a ProfileService). Esquema en [[datastore-profile-schema]]. Se descartó Knit: la arquitectura de servicios y controladores ya cubre lo mismo sin dependencias.
- Móvil: StreamingEnabled (radio 256, mínimo 128, LowMemory), UI para dos pulgares, mascotas dibujadas en el cliente.
- Arte y UI: [[art-direction]]. Mapa: [[world-building]].

## Riesgos (del análisis del GDD)
- **Onboarding:** si en 180 s no hay gancho, se van. ➜ Caja gratis al entrar y el Asilo se abre solo. ✅
- **D1→D7 plano:** ➜ torneos cada 4 h y expediciones. ⏳
- **Monetizar solo con pociones rompe la economía:** ➜ cosméticos y pases de conveniencia; nada de pagar para ganar.
- **Combates poco espectaculares:** ➜ falta llevarlos a la Arena 3D para que otros jugadores los vean y graben. ⏳
