# Separación del faro V2 y cámara — resultados

## 2026-11-05 - Aprobación visual final y preparación de PR

El responsable confirma correctos aspecto del faro, lente y encendido, visibilidad e integración, sin observaciones, con la iluminación original de main. Se autoriza commit, publicación de la integración y PR hacia main tras verificaciones. **No se autoriza fusionar la PR.**

Se mantiene el pequeño parpadeo residual de juntas como incidencia visual menor aceptada provisionalmente, no bloqueante. No se investiga ni modifica. La aprobación no incluye terreno, geometría rocosa o iluminación experimental 5.1.

**Validación local 2026-11-05:** importación Godot 4.7.2 y 17/17 ejecuciones satisfactorias, salida 0, cero fallos y sin errores. Incluye seis órdenes de restauración, soluciones P1/P2/P3, personaje/cámara, faro, puente y física V2. Referencias completas, 22 hashes aprobados y 43 archivos pendientes originales intactos; main.tscn, project.godot y CI sin diferencias. Git diff --check satisfactorio. No se realizan experimentos nuevos; no hubo errores de producto, importación o pruebas en esta preparación. Publicación autorizada; merge expresamente pendiente.

## Registro de la iteración anterior


El 3 de noviembre se autorizó preparar una copia aislada con el faro V2 y los ajustes de cámara.

## Conservación e integridad

La verificación cotejó por hash los 43 archivos pendientes del árbol previo antes y después de preparar esta integración. Los experimentos se conservaron en su copia original.

La copia build/consolidation-audit-revisión comprobada permanece en el árbol original: **42/42 archivos verificados por SHA-256**, parche, manifiesto y archivo main conservados. Los 22 archivos aprobados se copiaron desde ella y coinciden byte a byte tras importar y ejecutar las pruebas. El informe anterior y el diario actualizado de auditoría permanecen también conservados; no se trasladaron documentos compartidos en bloque.

## Archivos aprobados trasladados

| Ruta |
| --- |
| `scenes/lighthouse.tscn` |
| `scripts/isometric_camera.gd` |
| `tests/personaje_camara.gd` |
| `art_source/.gdignore` |
| `art_source/lighthouse/lighthouse.blend` |
| `art_source/lighthouse_tall/lighthouse.blend` |
| `assets/lighthouse/LensArt.tres` |
| `assets/lighthouse/TowerArt.tres` |
| `assets/lighthouse/lighthouse.glb` |
| `assets/lighthouse/lighthouse.glb.import` |
| `assets/lighthouse_tall/LensArt.tres` |
| `assets/lighthouse_tall/TowerArt.tres` |
| `assets/lighthouse_tall/lighthouse.glb` |
| `assets/lighthouse_tall/lighthouse.glb.import` |
| `scenes/reference/lighthouse_v1.tscn` |
| `tests/faro_v2_fisica.gd` |
| `tests/faro_v2_fisica.gd.uid` |
| `tools/create_lighthouse.py` |
| `tools/create_lighthouse_tall.py` |
| `tools/export_lighthouse.py` |
| `tools/extract_lighthouse.gd` |
| `tools/extract_lighthouse.gd.uid` |

Main.tscn, project.godot y CI no tienen diferencias contra main. Faro, progreso, puzles, personaje y puente conservan sus scripts anteriores; solo se modifica el script de seguimiento aprobado. V1 no está cargada en partida: proceso nuevo con ResourceLoader.has_cached sobre escena/mallas V1, cero fallos. La única OmniLight queda en su posición aprobada. No hay nuevas dependencias externas.

## Experimentos excluidos

| Ruta del árbol original | Tratamiento |
| --- | --- |
| `scenes/main.tscn` | Se mantiene la versión exacta de main. |
| `docs/phase-5-1-validation.md` | No trasladado; conservado en el original y snapshot. |
| `materials/island_rim.tres` | No trasladado; conservado en el original y snapshot. |
| `materials/island_rock.tres` | No trasladado; conservado en el original y snapshot. |
| `materials/island_terrain.tres` | No trasladado; conservado en el original y snapshot. |
| `meshes/island_rock.tres` | No trasladado; conservado en el original y snapshot. |
| `scenes/island_visuals.tscn` | No trasladado; conservado en el original y snapshot. |
| `scenes/lighthouse_tall_preview.tscn` | No trasladado; conservado en el original y snapshot. |
| `tools/bake_island_rock.gd` | No trasladado; conservado en el original y snapshot. |
| `tools/bake_island_rock.gd.uid` | No trasladado; conservado en el original y snapshot. |

No se trasladan los materiales de terreno, roca, envolventes, generador o ajustes globales de luz. Se conserva el suelo funcional y toda la iluminación original de main, sin compensaciones estéticas.

## Revisión selectiva de los diez documentos compartidos

| Documento original | Decisión y motivo |
| --- | --- |
| README.md | Se parte de main y se añade el estado aprobado y enlaces vigentes. No se copian secciones experimentales. |
| docs/architecture.md | Base main más dependencias efectivas, colisiones/luz y límite de cámara. |
| docs/game-design.md | Base main más aprobación V2 y alcance, sin adoptar el entorno 5.1. |
| docs/roadmap.md | Base main más consolidación y pendientes; continuidad y publicación conservadas. |
| docs/ai-development-log.md | Historial de main intacto más entrada de separación, error de finales de línea, decisiones y resultados. |
| docs/lighthouse-v2-integration.md | Guía reescrita con dimensiones, contrato Beacon, reproducción V1/V2, versiones y aceptación vigente. |
| docs/camera-follow-settling.md | Guía reescrita con umbral, evidencia histórica rotulada, pruebas e incidencia aceptada. |
| docs/lighthouse-art-prototype.md | No trasladada: historia V1 y contexto experimental; su procedimiento necesario se integra en la guía vigente. Original preservado. |
| docs/lighthouse-tall-variant.md | No trasladada: comparación antigua y previsualización ya redundante; dimensiones/reproducción se integran en la guía vigente. Original preservado. |
| docs/lighthouse-joint-flicker-diagnosis.md | No trasladada: diagnóstico experimental histórico; se conserva el ajuste aprobado y la incidencia sin reabrir investigación. Original preservado. |

Este informe es nuevo. No se incorpora como guía vigente el informe anterior de auditoría, que describía una separación aún no ejecutada. La trazabilidad completa permanece en el original.

## Validación técnica real

Godot **4.7.2.stable.official.ed1daf0bf**, importación satisfactoria desde caché nueva, sin errores o advertencias en el registro final de importación. Las 17 ejecuciones concluyen con salida 0 y cero fallos/errores:

| Suite | Ejecuciones |
| --- | --- |
| restauracion_faro | es/en: seis órdenes, deduplicación, bloqueo, activación única y reinicio |
| espejos_guardian | es/en: cuatro combinaciones, una solución y obstáculos |
| luz_perdida | es/en: dos orientaciones, una solución y trayectorias |
| fractal_resolucion | es/en: 27 configuraciones, una solución |
| fractal_un_rotor | es/en |
| fractal_tres_rotores | es/en: 27 configuraciones e independencia |
| personaje_camara | Seguimiento, umbral y giros Q/E |
| faro_interaccion | es/en |
| puente_reconstruccion | Reconstrucción y cruce |
| faro_v2_fisica | Cuatro aproximaciones, altura sólida, corredor, acceso al puente, lente/luz y activación única |

Importación y 17 logs en build/check-*.log; runner local build/run-checks.ps1. Auditoría adicional de carga fría en build/runtime-audit.log: V1 ausente, V2 directa, cero fallos. El fixture de captura resuelve los circuitos y activa mediante I, sin saltarse el contrato de activación; registra apagado state=0/bridge=0 y encendido state=1/bridge=2. No sustituye una nueva partida manual completa.

Se verifican referencias estáticas de recursos y enlaces documentales locales, ausencia de archivos necesarios y de rutas experimentales de ejecución. Git diff --check satisfactorio. Índices de ambos árboles vacíos; no hay eliminaciones, commits, cambios en main o publicación. Los archivos de autoría y recursos aprobados son idénticos al snapshot; no se regenera ningún modelo.

## Comparación gráfica

Ocho capturas nuevas, **1280 × 720**, cuatro orientaciones y faro apagado/encendido, Vulkan/Forward+ con RTX 4070. Cámara, iluminación y materiales no se modifican para capturar. Se usa el mismo auxiliar y posición del personaje que en las ocho referencias anteriores. build/comparison.html alterna ambos conjuntos a tamaño nativo, sin recorte o ampliación; imágenes y logs permanecen ignorados, no candidatos a versionar.

La silueta, proporciones, posición y coronación de V2 se conservan; la lente cálida es reconocible encendida en las cuatro vistas. Los haces y símbolos luminosos siguen visibles en estas capturas. El puente se ve despejado y reconstruido al encender. No aparecen nuevas oclusiones geométricas: se conservan los solapes isométricos existentes.

**Diferencia importante para validación humana:** main produce sombras mucho más oscuras que el ambiente experimental 5.1. En la orientación 1, con el faro apagado, la cara en sombra pierde gran parte del detalle de mampostería; la orientación 2 también presenta contraste fuerte. No puede afirmarse equivalencia artística completa con la versión validada bajo 5.1. Se conserva exactamente lo solicitado y se presenta esta limitación, sin retocar luz, materiales o cámara. El tono de piedra en luz directa se percibe más cálido; terreno plano y ausencia de roca son la exclusión prevista.

Contadores nuevos, escena completa al capturar: draw calls 112..177 y primitivas 60 134..87 848. Referencias 5.1: 130..201 y 60 494..88 328. La reducción incluye retirar decoración/superficies experimentales y pasadas visibles; no es un benchmark GPU ni una optimización del faro.

## Incidencia y validación pendiente

Artística V2 5/5, funcional 6/6; cámara 3/4 manuales según comunicación del responsable, sin atribuir qué comprobación faltó. Pequeño parpadeo residual de juntas: **menor, aceptado provisionalmente, no bloqueante**. No se investiga ni modifica durante la separación.

1. Abrir project.godot de esta copia de trabajo, confirmar 1280×720 y revisar apagado/encendido en cuatro vistas con Q/E; valorar especialmente la mampostería en sombra de la orientación 1.
2. Caminar y detenerse junto al faro, reanudar y girar: comprobar seguimiento y comodidad sin exigir ausencia total del parpadeo aceptado.
3. Rodear la base, recorrer el paso junto al monumento y acercarse al puente; confirmar colisión y acceso a interacción.
4. Resolver P1/P2/P3, comprobar 3/3 y una nueva I, lente/luz coherentes, reconstrucción única y cruce del puente.
5. Confirmar que el aspecto con iluminación original es aceptable antes de adoptar o publicar esta rama. No avanzar al entorno ni corregir iluminación sin autorización.

La entrega para revisión se compuso de 8 archivos modificados y 22 nuevos. La aprobación visual y funcional se documenta en los hitos posteriores.
