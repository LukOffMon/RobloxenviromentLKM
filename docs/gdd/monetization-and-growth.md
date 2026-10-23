# Monetization and Growth

**Meta:** 50 000 000 Robux netos · Relacionado: [[economy-systems]], [[core-gameplay-loop]], [[progression-tree]]

## La cuenta que hay que mover
```
Robux netos/día ≈ DAU × conversión a pagador × gasto medio por pagador × 0.7
```
Roblox se queda ~30 % de cada game pass / developer product, así que 50 M netos ≈ **71 M brutos**.

| Plazo | Robux netos / día | Ejemplo de DAU necesario (2 % pagan, 120 R$ de media) |
|---|---|---|
| 12 meses | ~137 000 | ~82 000 DAU |
| 24 meses | ~68 500 | ~41 000 DAU |

Conclusión: el cuello de botella es **retención y DAU**, no el precio. Primero un bucle que enganche; después monetizar.

## Métricas que deciden todo (Creator Hub → Analytics)
| Métrica | Mínimo para que el algoritmo empuje | Bueno |
|---|---|---|
| Retención D1 | 20 % | 35 %+ |
| Retención D7 | 5 % | 12 %+ |
| Sesión media | 10 min | 20 min+ |
| Conversión a pagador | 1 % | 3 %+ |

Cada sistema nuevo se especifica con la plantilla [[feature-spec]] indicando qué métrica mueve.

## Fuentes de ingreso
1. **Developer Products** (consumibles): monedas, boosts temporales, revivir. Se procesan **solo** en `MarketplaceService.ProcessReceipt` del servidor, idempotentes por `PurchaseId` y guardados antes de devolver `PurchaseGranted`.
2. **Game Passes** (permanentes): x2 monedas, VIP, slot extra de inventario. Comprobados en el servidor con `UserOwnsGamePassAsync` y cacheados por sesión.
3. **Pagos por engagement de Premium / Creator Rewards**: tiempo jugado por usuarios Premium; crece con la retención.
4. **Anuncios recompensados y suscripciones**: cuando el juego tenga audiencia estable.

## Catálogo de MonOG (del GDD)
| Tipo | Producto | Precio | Clave en `GameConfig` |
|---|---|---|---|
| Developer Product | Poción de Expreso Doble (x3 XP 30 min) | R$ 49 | `Products.ExpressoDoble` |
| Developer Product | Caja de Inicio (Épico asegurado) | R$ 89 | `Products.StarterBox` |
| Developer Product | Caja de Asilo x1 / x5 / x10 | R$ 79 / 349 / 699 | `Products.AsylumBox1/5/10` |
| Game Pass | Enfermero Automático (XP pasiva) | R$ 299 | `GamePasses.AutoTrainer` |
| Game Pass | Pensión Offline Ampliada (24 h al 100 %) | R$ 399 | `GamePasses.OfflinePension` |
| Game Pass | VIP Director del Asilo (etiqueta dorada en el chat) | R$ 799 | `GamePasses.VipDirector` |
| Game Pass | Aura Legendaria «Abuelo Cuántico» | R$ 1200 | `GamePasses.QuantumAura` |

### Cómo activarlos
1. Publica el juego y abre el Creator Hub → tu experiencia → **Monetization**.
2. Crea cada Developer Product y Game Pass con el nombre y precio de la tabla.
3. Copia su Id en `src/shared/Configurations/GameConfig.luau` (sustituye el `Id = 0`).
4. Los botones de compra aparecen solos en el Edificio de Adopción; con `Id = 0` siguen ocultos.

### Cajas de pago y la ley
Las cajas aleatorias de Robux solo se muestran si `PolicyService` dice que el jugador puede comprarlas (`ArePaidRandomItemsRestricted = false`); en los países donde están restringidas, el jugador solo ve las cajas de moneda del juego. Las probabilidades se publican siempre antes de abrir.

**Pendiente del GDD:** silla de ruedas con cohetes y zona VIP del pase VIP; aura de vapor de té para el top del servidor.

## Reglas de diseño
- Nada de pay-to-win que rompa el bucle de los no pagadores: ellos generan el DAU que atrae a los pagadores.
- Ofertas en momentos de emoción (subir de nivel, perder por poco, desbloquear región en [[world-building]]).
- Primer producto barato (≤ 25 R$) para convertir pagadores; luego escalera de precios.
- Todo precio y recompensa vive en `GameConfig`, nunca hardcodeado en scripts.

## Crecimiento
- Icono y miniaturas: probar variantes con las pruebas A/B de miniaturas del Creator Hub.
- Actualizaciones semanales con [[v1.0.0-alpha|patch notes]] visibles en el juego.
- Eventos de tiempo limitado y códigos para redes sociales.
- Invitaciones a amigos con recompensa (`SocialService`).
