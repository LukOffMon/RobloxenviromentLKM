# Sistema de combate «Turn-Based Comedy»

Relacionado: [[monog-gdd]], [[og-catalog]], [[progression-tree]] · Código: `src/shared/Logic/BattleLogic.luau`, `src/server/Services/BattleService.luau`

## Reglas
- Hasta 3 OGs por bando. Cada ronda actúan todos los vivos por velocidad (SPD); en empate, primero el jugador.
- Cada acción suma carga; a la 3.ª se lanza el **ataque especial** del arquetipo.
- El ataque básico es el «Bastonazo» (1×). Los ataques de un objetivo van al rival con menos vida.
- Daño = `ATK × poder × 100 / (100 + 2·DEF) × variación(0,9–1,1)`, con un mínimo de 1. Crítico: 10 % de probabilidad, ×1,5.
- Límite de 30 rondas. Si se llega, gana el bando con más porcentaje de vida.
- El servidor simula el combate completo y manda el registro de eventos; el cliente solo lo anima (sin trampas posibles).

## Rivales NPC (Arena Central)
- Nivel de rival 1–2: 1 rival · 3–4: 2 rivales · 5 en adelante: 3 rivales.
- La rareza del rival sube cada 4 niveles y su nivel ≈ 2 × nivel de rival.
- **Victoria:** `60 + 40 × nivel` PensionCoins, +10 XP a cada OG del equipo y se desbloquea el siguiente rival. Cada 5 niveles, +50 GigaGems.
- **Derrota:** +5 XP de consuelo a cada OG.

## Presentación
Cartas con barra de vida, números elásticos (los críticos en dorado), cartel con el nombre del especial y K.O. en el que la carta sale girando con el sonido «uuhhh». Botones para jugar a ×2 y para saltar la animación.

## Pendiente
- Llevar el combate a la Arena 3D con gradas para espectadores (momentos para TikTok).
- PvP y el Torneo Mundial de Veteranos cada 4 h.
