# Farero V1 — integración validada y animación rígida

En los comandos de este documento, configura `$godot` y `$blender` con la ruta local del ejecutable correspondiente.

2026-11-07. La persona responsable confirma el modelo V1 como aprobado y autoriza su integración experimental con reposo y caminata simples. Tras probar el juego, la persona responsable aprueba visual y funcionalmente modelo, reposo, caminata y orientación. Autoriza commit, push y PR; no autoriza fusionar con main.

## Entorno y recursos conservados

La integración de la animación se preparó en una copia aislada de la base jugable.

Se copian selectivamente del prototipo aprobado: art_source/keeper_prototype/keeper_v1.blend, assets/keeper_prototype/keeper_v1.glb y su .import, model-metrics.json y tools/create_keeper_prototype.py. No se arrastran escenas de previsualización, configuración, documentación compartida o experimentos de otros árboles. El GLB y su fuente conservan geometría/materiales: 15.708 triángulos, 12 materiales, 7 piezas, altura 1,618625, ancho 0,866 y fondo 0,485. El juego sigue funcionando sin Blender.

## Inspección previa y jerarquía

Los pivotes exportados permiten una marcha de piezas rígidas. Coordenadas locales Godot, con frente +Z y origen a los pies:

| Pieza | Pivote aproximado |
| --- | --- |
| Torso | (0;0,84;0) |
| Head | (0;1,19;0) |
| Arm_L / Arm_R | (−0,245 / 0,245;1,09;−0,01) |
| Leg_L / Leg_R | (−0,11 / 0,11;0,56;0) |
| Lantern | (0,365;0,687;0,055) |

No hacen falta cambios de vértices, materiales, pivotes o Blender. Al iniciar, la escena visual agrupa torso, cabeza y brazos bajo UpperBodyMotion y vincula Lantern al brazo derecho preservando su transformación global de reposo. Las piernas conservan sus pivotes de cadera. Esta reorganización ocurre solo en las instancias visuales, no modifica el GLB compartido.

Limitación explicada antes de implementar: las piernas son grupos enteros con botas y pantalón, y los brazos no tienen codos separados. La marcha resultante es deliberadamente articulada y estilizada; no equivale a locomoción esquelética natural.

## Separación de responsabilidades

- `scripts/player.gd` **intacto**: WASD relativo a cámara, velocidad 4, gravedad, suspensión de controles, acciones bloqueadas y move_and_slide.
- `scenes/player.tscn`: elimina únicamente CapsuleMesh y su material, añade una instancia Visual. Conserva CharacterBody3D, script, floor_snap_length=0,2 y CapsuleShape3D de radio 0,3/altura 1,6, centro (0;0,8;0).
- `scenes/keeper_visual.tscn`: modelo aprobado y controlador exclusivo de representación.
- `scripts/keeper_visual.gd`: lee get_real_velocity después del movimiento, con prioridad física 10. No escribe posición, velocidad o rotación del CharacterBody3D, ni toca cámara, entradas o puzles.

La representación responde al desplazamiento efectivo y no a la tecla pulsada: quieto contra una pared deja de caminar; si resbala lateralmente, mira y anima según ese desplazamiento. No se añaden cuerpos físicos, colisiones, luces, esqueleto, AnimationTree o dependencias.

## Técnica de animación

**Reposo:** balanceo vertical del tren superior de ±0,002 unidades, sin mover las piernas ni el origen físico. Las manos y la linterna acompañan el balanceo. Los pies mantienen su transformación estable una vez terminada la transición.

**Marcha:** fase cíclica proporcional a distancia horizontal real (1,8 unidades por ciclo), piernas alternas hasta ±0,34 radianes, brazos opuestos más leves (0,23 y 0,18), pequeña estabilización de cabeza y oscilación del torso de hasta 0,022 unidades. Fundido reposo/marcha de unos 0,14 segundos. La frecuencia baja con el movimiento efectivo y se congela al detenerse; la pose vuelve suavemente a reposo.

Se precalculan los vértices inferiores de las botas y se compensa solo la transformación visual de cada pierna para evitar atravesar el plano local de apoyo, con elevación del pie de hasta 0,045. No se desplaza la cápsula ni se cambian colisiones. No es IK ni una consulta de terreno por pie.

**Orientación:** frente +Z dirigido a la velocidad horizontal real; rotación visual exponencial breve por el camino angular corto. El giro de cámara sin movimiento no gira al personaje. Al detenerse se conserva la dirección objetivo previa y se termina suavemente la rotación pendiente. Q/E sigue siendo responsabilidad exclusiva de la cámara existente.

La linterna mantiene su transformación local constante respecto a Arm_R (aproximadamente 0,12;−0,403;0,065). Solo se balancea con ese brazo; su posición lateral permanece fuera del torso. La prueba compara sus envolventes laterales, además de verificar que no se suelta de la mano.

## Validación realizada

Godot **4.7.2.stable.official.ed1daf0bf**, Forward+, RTX 4070. Importación final sin errores.

- **17/17 pruebas existentes satisfactorias**, incluidas variantes español/inglés: personaje/cámara, faro V2, interacción, fractal de uno/tres rotores, 27 configuraciones y solución única, P1, P2, seis órdenes de restauración, activación única y reconstrucción/cruce del puente.
- **Nueva prueba `tests/keeper_visual.gd` satisfactoria**: 16 direcciones relativas a cuatro cuadrantes de cámara, alternancia de piernas, reposo con pies estables, regreso gradual a reposo, fase proporcional a distancia a velocidades distintas, parada real contra pared manteniendo la tecla, suspensión de controles, conservación de cápsula, ausencia de cuerpos/luz/esqueleto nuevos, vínculo y separación lateral de linterna.
- Ampliación de esa prueba también satisfactoria: transición inicial no instantánea y Q mientras se camina, con seguimiento suave de la dirección real y sin cambios angulares bruscos durante el giro de cámara.
- La escena principal, cámara, control, faro, puente, puzles, traducciones y CI conservan su contenido respecto a main. Solo cambia la escena visual del jugador y se añaden recursos/controlador/pruebas/documentación de este experimento.
- `git diff --check` y revisión de espacios de archivos nuevos correctos.

No hubo errores nuevos de implementación, importación o pruebas durante este incremento. Godot normalizó finales de línea de algunos metadatos existentes; se comprueba igualdad de contenido y se conserva el formato previo. No se afirma aprobación visual por los resultados automatizados.

## Revisión visual del juego real

Abre el **project.godot de la copia del proyecto** y pulsa F5. En este hito la escena inicial era scenes/main.tscn y el jugador aparecía en su posición original (−2;0,1;2). La integración se comprobó en la escena jugable, con la cámara habitual.

Capturas locales nativas **1280×720**, en build/keeper-integration:

- idle-view0..3.png y walking-view0..3.png: reposo y marcha en los cuatro ángulos habituales.
- direction-move_back/left/right.png: otras direcciones, con entradas reales.
- beside-lighthouse.png: personaje junto al faro y su mensaje de interacción.
- lighthouse-active-bridge-ready.png: los tres circuitos resueltos por sus controladores, activación con I y puente listo.

`comparison.html` organiza los trece PNG. `walk-cycle.avi` contiene aproximadamente seis segundos a 60 FPS, generados con el grabador nativo de Godot, cámara y velocidad originales, entradas reales y sin aplicar poses de captura manuales. Sirve como evidencia para revisar la animación, no como aprobación humana o benchmark de rendimiento. Estos resultados, logs y auxiliares quedan ignorados en build/.

La inspección de los PNG muestra el modelo en reposo y en distintas poses, con linterna vinculada y faro/puente conservados. En una trayectoria se observa deslizamiento junto al bloque azul: el controlador visual reduce la marcha y orienta hacia la velocidad real, no fuerza la dirección de la tecla. Se mantiene la oclusión parcial por el pedestal fractal desde alguno de los ángulos. La persona responsable ya ha probado el juego y aprobado reposo, caminata y orientación; el clip queda como evidencia local y el checklist como guía de regresión futura. No se atribuye una puntuación o una ejecución exhaustiva de ese checklist.

### Reproducir las comprobaciones

Desde la raíz del proyecto:

```powershell
$engine = $godot
& $engine --headless --path . --editor --import --quit
& $engine --headless --path . --script res://tests/keeper_visual.gd
New-Item -ItemType Directory -Force build/keeper-integration
& $engine --path . --resolution 1280x720 --script res://build/keeper-integration/capture_keeper_animation.gd
& $engine --path . --resolution 1280x720 --fixed-fps 60 --write-movie build/keeper-integration/walk-cycle.avi --script res://build/keeper-integration/capture_keeper_animation.gd -- --clip
```

El capturador se conserva como auxiliar local ignorado en build/keeper-integration y no se incluye en la PR ni se ejecuta con F5; los comandos de captura requieren ese archivo local. Una copia limpia puede validar el juego con F5 y ejecutar la prueba keeper_visual sin ese auxiliar. Las capturas estáticas recolocan al jugador solo en memoria para probar escenarios; no guardan esas posiciones. El clip emplea las entradas normales sin recolocaciones o poses manuales.

La regeneración de la fuente estática sigue disponible con Blender 5.2.3 LTS:

```powershell
& $blender --background --factory-startup --python tools/create_keeper_prototype.py
```

Ese comando sobrescribe solo sus recursos de modelo; no se ejecutó durante esta integración ni es necesario para jugar. Las animaciones están en el controlador Godot y no en el GLB. Se conserva la limitación ya documentada del generador: resultados geométricos equivalentes, no garantía de GLB idéntico byte a byte. Recursos propios creados localmente con asistencia de IA, sin descargas, servicios ni costes nuevos.

## Limitaciones aceptadas y checklist de regresión

- Marcha de figura articulada: sin rodillas/codos flexibles, plantado físico de pies, IK o root motion. Puede percibirse deslizamiento de botas, especialmente al cambiar dirección o parar. Requiere valoración visual.
- Ancho aprobado de 0,866 frente a diámetro físico de 0,6: brazos o linterna pueden penetrar visualmente objetos al rozarlos, aunque se evita cruzar el torso. No se amplía la colisión para compensarlo.
- El ajuste de pies considera el plano local del personaje, no apoyo independiente sobre bordes/escalones. No se añaden salto, carrera o adaptación compleja al terreno.
- No se optimizan los 15.708 triángulos/27 superficies ni se atribuye un presupuesto de rendimiento definitivo al modelo. La linterna no añade una luz física.

Prueba manual breve:

1. Recorrer WASD en los cuatro giros Q/E; probar reversas y diagonales. Juzgar ritmo, oscilación, transición y suavidad de orientación a distancia de juego.
2. Detenerse y girar solo la cámara: comprobar pies estables y conservación de orientación. Mantener movimiento contra un muro y observar que cesa la marcha al quedar bloqueado.
3. Revisar la linterna al cambiar dirección y rozar obstáculos: vínculo con la mano, separación del cuerpo y posibles penetraciones del entorno.
4. Entrar en inspección fractal, girar/seleccionar y salir con Esc; confirmar que no queda marcha residual. Resolver P1/P2/P3 en cualquier orden.
5. Activar el faro con 3/3 y una nueva I, reconstruir y cruzar el puente; revisar textos en español e inglés.

Aprobación visual y funcional recibida. Se autorizan commit, push y PR tras repetir las comprobaciones; el merge requiere autorización expresa posterior. Los copias de trabajo anteriores permanecen conservados.
## Consolidación autorizada — 2026-11-07

Se revisa la referencia remota de la rama principal antes de publicar y se repiten importación, suite completa (17 ejecuciones existentes) y prueba específica de animación. Resultado de esta repetición: importación sin errores y 18/18 ejecuciones satisfactorias (17 regresiones y keeper_visual), con git diff --check correcto. Los resultados se guardan en build/keeper-publication. Capturas, AVI, HTML y auxiliares diagnósticos permanecen locales e ignorados. Se conserva la configuración de CI existente; no se amplía su alcance en esta consolidación. Las menciones anteriores a aprobación pendiente describen el proceso previo a la validación humana recibida.
