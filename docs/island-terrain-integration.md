# Integración jugable de la isla V2-Materiales

En los comandos de este documento, configura `$godot` y `$blender` con la ruta local del ejecutable correspondiente.

2026-11-06. La persona responsable aprueba geometría, superficie verde, acantilados e iluminación corregida de V2-Materiales. Tras revisar el juego integrado, confirma movimiento del personaje y uso de puzles, y autoriza commit, push y Pull Request. No autoriza fusionar con main. No se aprueban por extensión los antiguos experimentos de la integración.

## Rama y conservación

La integración se preparó en una copia aislada que conservó los experimentos anteriores. Se validó la isla con sus nuevos materiales desde el proyecto jugable.

## Recursos trasladados

Ocho archivos son idénticos mediante SHA-256 al prototipo aprobado:

- art_source/island_terrain_v2/island_v2.blend
- assets/island_terrain_v2/island_v2.glb
- assets/island_terrain_v2/island_v2.glb.import
- assets/island_terrain_v2/model-metrics.json
- assets/island_terrain_v2_materials/terrain.gdshader
- assets/island_terrain_v2_materials/terrain.gdshader.uid
- assets/island_terrain_v2_materials/terrain.tres
- tools/create_island_terrain_v2.py

El nuevo scenes/island_terrain.tscn hereda la instancia GLB y asigna el material aprobado a IslandTerrainV2 mediante override declarativo: visible tanto en editor como durante el juego, sin scripts de aplicación tardía. La geometría conserva 2.846 triángulos, 1.425 vértices de autoría, cuatro superficies y dimensiones 15,218 × 5,05 × 15,539. No tiene cuerpos físicos, luces ni cámaras. El material procedural no requiere texturas, UV nuevas ni dependencias. Los recursos fueron creados localmente con asistencia de IA, sin incorporar contenido descargado ni conexiones al juego.

Se excluyen V1 del terreno, previsualizaciones, selectores, galerías HTML, capturas, análisis y documentos compartidos del prototipo. Permanecen en origen. No se trasladan rocas ni materiales de la antigua fase 5.1. Las referencias V1 del faro existentes en main no se alteran.

## Cambios en main.tscn

- Se elimina solo el BoxMesh del suelo original y su asignación a Ground. Ground mantiene su transformación, Body y BoxShape3D de 12 × 0,4 × 12. Se conserva Material_ground porque aún lo usan otras mallas.
- Se añade una instancia IslandTerrain con transformación identidad y el recurso aprobado. No hay dos superficies superpuestas.
- El Environment cambia únicamente ambient_light_source de SKY (3, sin Sky asignado) a COLOR (2), ambient_light_color a (0,78;0,83;0,90) y ambient_light_energy a 0,65. Fondo, tonemapping, reflexión, direccional, energía 1,2, orientación y sombras se conservan.
- No se cambian scripts de juego, cámara, personaje, posiciones, soluciones, colisiones, progreso, faro ni puente. project.godot y CI permanecen intactos.

## Pruebas y revisión

Godot 4.7.2.stable.official.ed1daf0bf, Forward+, RTX 4070. Importación sin errores. Suite completa: **17/17 ejecuciones finales satisfactorias** (las diez suites existentes y las variantes de idioma correspondientes). Cubre personaje/cámara, física del faro V2, interacción es/en, 27 estados del fractal, P1, P2, seis órdenes de progreso, activación manual única, reconstrucción y cruce del puente.

La prueba original de puente falló inicialmente porque obtenía el borde visual del antiguo Ground.get_aabb(), ahora vacío. Se adapta tests/puente_reconstruccion.gd para comprobar que Ground no conserva malla, calcular el borde físico original y medir el contorno real del nuevo collar en Z=−3. Se conserva la comprobación exacta entre segmentos y destino, más todas las pruebas de barreras, activación, reconstrucción única, cruces y perímetros.

La primera comprobación nueva exigía superficie visual a menos de 1 mm del extremo físico y detectó el retranqueo del bisel aprobado. La medición de la sección real da **X=5,revisión comprobada**, frente al inicio físico del puente X=6: **0,revisión comprobada unidades** de remate visual. La prueba exige que no se invada el puente y que el retranqueo no exceda el bisel original de 0,035. La geometría no se modifica para ocultarlo. No aparece hueco físico: la colisión original llega a X=6 y los cruces reales pasan. Revisar este pequeño remate durante la validación humana.

Auditoría local comparada con la escena original de la referencia remota de la rama principal: **674 nodos previos** conservan clases, transformaciones locales, capas/máscaras físicas y propiedades de sus CollisionShape3D. El Mesh de la escena jugable es el mismo recurso importado del GLB aprobado y el override es exactamente el material trasladado. **2.025 muestras** del suelo (rejilla 0,25 en X/Z ±5,5) encuentran tanto superficie física como apoyo visual. Es un muestreo estático, no una prueba exhaustiva de toda la navegación.

Se generan cuatro capturas **del juego real scenes/main.tscn**, no de una escena de diagnóstico, a 1280 × 720, usando sus cámaras y giros normales. El auxiliar local solo instancia main, audita, deja caer el personaje y detiene su proceso para obtener encuadres estables; no sustituye luz, suelo ni objetos. Se revisan los cuatro ángulos: el verde conserva variación, los cantiles muestran detalle en sombra y el faro, los puzles y el puente mantienen su lectura geométrica. La activación y la inspección interactiva se cubren en las suites; requieren además recorrido humano final.

Los errores observados fueron la suposición obsoleta de la prueba, su tolerancia inicial ajena al bisel y un error de inferencia de tipo en un comprobador temporal, corregido antes de ejecutarlo. Godot normalizó finales de línea de dos .glb.import del faro; se verificó que no había cambios de contenido y se conservó su formato original. No se modificó el faro.

Git diff --check y revisión de espacios de archivos añadidos: correctos. Recursos nuevos limitados a los ocho aprobados y su escena de integración; no se incluyen capturas, HTML, scripts temporales o builds. Informes, hashes, capturas y logs se conservan localmente bajo build/terrain-integration/, ignorado por Git. La suite tiene su registro inicial y la repetición final de puente, sin ocultar el fallo inicial.

## Ejecución y reproducción

Abrir **el project.godot del proyecto**, y pulsar F5. Alternativamente:

```powershell
& $godot --path .
```

La ejecución requiere únicamente Godot. Fuente creada con Blender 5.2.3 LTS; para regenerar geometría/exportación en una copia de trabajo (sobrescribe sus salidas, no es necesario para jugar):

```powershell
& $blender --background --python tools/create_island_terrain_v2.py
```

El script usa solo bpy/bmesh y biblioteca estándar, exporta GLB 2.0 y escribe métricas. Los materiales finales están en terrain.gdshader/terrain.tres y se conservan fuera del GLB, aplicados por island_terrain.tscn; regenerar geometría no los hornea ni sustituye. art_source/.gdignore evita importar Blender automáticamente. No regenerar el recurso aprobado solo para ejecutar el juego.

## Checklist de revisión y validación recibida

La persona responsable confirma validación visual de la integración y funcionamiento del movimiento y los puzles. No se atribuye una puntuación ni una ejecución manual completa del siguiente checklist; se conserva como guía de revisión antes de fusionar.

1. F5: comprobar verde, piedra y sombras desde los cuatro giros Q/E, sin cambiar cámara.
2. Recorrer bordes y acceso al puente; revisar especialmente el pequeño remate del bisel.
3. Interactuar con P1, P2 y la inspección fractal; comprobar haces, símbolos y cristales.
4. Resolver los tres circuitos, activar con una nueva I, observar reconstrucción y cruzar de ida y vuelta.
5. Revisar mensajes en español/inglés y confirmar que el aspecto coincide con el prototipo aprobado.

Persisten la restricción de colisiones cuadradas originales, la plataforma de destino sin nuevo terreno y la incidencia menor ya aceptada de juntas del faro. No se investiga ni amplía su alcance. No hay medición fiable de coste temporal GPU del shader; no se afirma mejora de rendimiento. Integración validada para publicación mediante commit y PR; merge pendiente de autorización expresa.
## Publicación autorizada

Repetición previa a publicación completada: importación correcta y 17/17 ejecuciones automatizadas satisfactorias con Godot 4.7.2; git diff --check correcto. La superficie superior sigue siendo predominantemente rectangular para respetar el suelo y sus colisiones existentes: los acantilados cambian la silueta inferior, pero esta variante no convierte la meseta en un contorno orgánico libre. No se incorporan los antiguos experimentos de terreno o iluminación ni resultados de diagnóstico. La PR debe conservar explícitas estas limitaciones y permanecer sin fusionar hasta nueva autorización.
