# Integración funcional del reflector artístico P1

En los comandos de este documento, configura `$godot` y `$blender` con la ruta local del ejecutable correspondiente.

Fecha: 2026-11-07. Diseño artístico e integración jugable aprobados por el responsable: siete comprobaciones manuales satisfactorias (7/7). Se autorizan commit, push y PR; la fusión requiere autorización expresa posterior.

## Base y conservación

La integración se preparó en una copia aislada desde la revisión aprobada del prototipo.

Del prototipo aprobado se copian exclusivamente GLB, .import, métricas, fuente .blend y generador Blender. No se trasladan project.godot, previsualizaciones, cambios documentales antiguos, experimentos de iluminación, capturas o auxiliares. El prototipo de origen contiene cambios locales adicionales que se conservan allí. SHA-256 de los recursos y estado de Git de los árboles anteriores se registran en build/p1-integration/preservation.json, ignorado.

Herramientas: Godot 4.7.2.stable.official.ed1daf0bf, Forward+ en RTX 4070; modelo propio generado previamente con Blender 5.2.3 LTS. No se remodela ni se regenera el modelo durante esta integración; copia binaria comprobada. Sin recursos externos, descargas, instalaciones o costes.

## Integración y fuente de verdad

La escena principal sigue siendo scenes/main.tscn, sin modificaciones. Su instancia de scenes/lost_light.tscn carga ahora scenes/stone_bronze_reflector.tscn como hijo Reflector/Visual. Se eliminan únicamente Stand y Post provisionales del reflector; los de fuente/receptor permanecen. La antigua Plate queda invisible como referencia del plano óptico y para conservar el contrato de las pruebas de encuadre existentes: no duplica el renderizado.

El controlador scripts/lost_light.gd permanece idéntico a main. Conserva la única variable orientation, dos estados −45°/+45°, tecla I con pulsación nueva, interacción a 1,25, trazado físico y resolución/señal única. El pivote Reflector/Pivot permanece en (0;1,2;0) y cambia inmediatamente. El mecanismo sigue situado en (3,8;0;3). No se alteran colisiones: cilindro R=0,4, H=1,6, centro local Y=0,8, ni la lógica de luz, progreso, faro o puente.

scripts/reflector_visual.gd lee únicamente el ángulo del pivote existente. Inicializa la malla sin transición al estado vigente y, cuando cambia el objetivo, anima RotatingAssembly durante 0,35 s con interpolación sinusoidal. Pedestal permanece fijo. No escribe sobre el pivote, orientation, solved, el haz o el progreso. El último ángulo se almacena solo para detectar cambios, sin un segundo estado de puzle. Si llega otra interacción antes del final, cancela el tween anterior y continúa desde el ángulo visual actual hacia el nuevo objetivo, sin colas. Una resolución lógica no cancela el movimiento visual pendiente.

**Consecuencia intencionada:** haz, receptor y señal responden inmediatamente, mientras el bronce termina su giro. No se retrasa la resolución para esperar una animación; así se conserva la respuesta lógica autorizada. Una vez resuelto, el controlador original bloquea nuevas orientaciones y la malla termina asentándose.

La escena reutilizable contiene solo el GLB y este adaptador visual, con una referencia configurable al pivote lógico. Puede instanciarse más adelante en P2 sin duplicar modelo/materiales; P2 no se integra ni se modifica en este incremento.

## Recursos y archivos afectados

| Archivo o grupo | Finalidad |
| --- | --- |
| scenes/lost_light.tscn | Sustitución visual exclusiva del reflector |
| scenes/stone_bronze_reflector.tscn | Componente reutilizable sin física |
| scripts/reflector_visual.gd y .uid | Seguimiento visual del pivote y tween de 0,35 s |
| assets/reflector_art_v1/ancient_reflector_v1.glb y .import | Modelo aprobado ejecutable sin Blender |
| assets/reflector_art_v1/model-metrics.json | Dimensiones y recuentos |
| art_source/reflector_art_v1/ancient_reflector_v1.blend | Fuente editable conservada |
| tools/create_reflector_art.py | Regeneración local |
| tests/lost_light_visual.gd y .uid | Prueba adicional de integración |
| README, docs/roadmap.md, docs/ai-development-log.md y este informe | Uso, trazabilidad y validación |

Modelo sin cambios: 0,54874 × 1,59000 × 0,93800 unidades, 10.705 triángulos, dos mallas y siete materiales sin texturas. Piedra cálida, bronce envejecido y superficie de estaño simplificada. El modelo no incluye luces ni colisiones. El generador conserva la separación Pedestal/RotatingAssembly y pivote a 1,2.

## Validación real

- Importación Godot 4.7.2 satisfactoria, sin errores.
- 18/18 ejecuciones existentes satisfactorias: restauracion_faro, espejos_guardian, luz_perdida, fractal_resolucion, fractal_un_rotor, fractal_tres_rotores y faro_interaccion en es/en (14), más personaje_camara, puente_reconstruccion, faro_v2_fisica y keeper_visual (4). Ninguna prueba existente se modifica.
- Prueba nueva lost_light_visual en es/en: ambas satisfactorias. Total final: 20/20 ejecuciones headless. Comprueba correspondencia con el pivote, poses intermedias y finales, pulsaciones sucesivas durante giro, tecla mantenida, pedestal fijo, colisión original y ausencia de física visual, persistencia al alejarse/volver, resolución única, crédito único, bloqueo posterior y continuidad del tween tras resolver. Obstáculo temporal solo en prueba para permitir alternar sin resolver.
- La prueba original P1 mantiene una única solución entre dos estados y bloqueo por obstáculos; las de P2/P3 mantienen una entre cuatro/27. Restauración comprueba seis órdenes, deduplicación y activación posterior del faro/puente; faro físico y puente verifican accesos, activación y reconstrucción. Se conservan controles y animación del protagonista.
- Ejecución gráfica Forward+ de la prueba nueva con capturas: salida 0, sin errores. Ocho PNG de 1280 × 720: initial-view0..3 y solved-view0..3. Instancias de main real, entrada normal de I y cámara original; solo se recoloca al jugador en memoria para capturar cerca del mecanismo y se elige cada ángulo. No hay escena diagnóstica sustituyendo al juego.
- Revisión técnica de los cuatro ángulos en ambas poses: se ven pedestal/montaje, fuente/receptor y trayectoria; no se aprecia intersección grave con terreno. Se conserva la lectura de canto en dos vistas según la pose. No se considera aprobada la animación por haber pasado pruebas o capturas estáticas.
- git diff --check, inventario selectivo, conservación de recursos originales y ausencia de cambios en scripts funcionales se comprueban al cerrar. Las diferencias de finales de línea generadas en cuatro .import existentes se normalizan solo tras verificar identidad de contenido con HEAD.

### Incidencias de verificación

La primera ejecución de la prueba nueva comparaba radio/altura con igualdad exacta y falló por representación decimal del recurso Godot. Se corrigió únicamente esa comparación nueva usando is_equal_approx; el recurso físico siempre estuvo intacto. La primera pasada del ejecutor auxiliar obtuvo 17/18 regresiones porque omitía --expect-locale=en, requerido por faro_interaccion al seleccionar inglés. Se corrigió la invocación, no la prueba, y se repitió esa ejecución con resultado satisfactorio. Los primeros registros se conservan en build; el informe final no oculta estas incidencias.

## Ejecutar con F5 y checklist manual

1. Abre **project.godot** con Godot 4.7.2 y pulsa **F5**. En este hito se ejecutaba directamente la isla, con los controles de exploración.
2. Desde el inicio, dirigirse al sector de la isla con la columna roja y el pequeño muro gris: P1 está hacia coordenadas positivas X/Z. Buscar la fuente dorada, el nuevo reflector de bronce y el receptor celeste. Rodear el bloque azul si se interpone. Acercarse al reflector hasta ver «Pulsa I para orientar el reflector».
3. Antes de I, observar la posición inicial: el haz termina en el muro inerte. Girar Q/E y comprobar escala junto al farero y legibilidad en los cuatro ángulos.
4. Pulsar I una vez: el marco debe girar suavemente durante 0,35 s, sin mover la piedra. El haz cambia inmediatamente hacia el receptor y aparece la confirmación original. Valorar fluidez y coherencia; las capturas estáticas no sustituyen esta comprobación.
5. Mantener/repetir I tras resolver: queda estabilizado, sin señales ni crédito repetidos. Alejarse y volver; conserva el resultado. P1 por sí solo no activa el faro ni reconstruye el puente.
6. Para observar otra vez el giro y la pose inicial, reiniciar F5. **No puede alternarse indefinidamente en la escena inicial despejada:** el primer giro correcto resuelve y bloquea, como antes. Las pruebas automatizadas usan un obstáculo temporal para verificar reorientaciones rápidas antes de resolver, sin introducir esa mecánica en el juego.
7. Resolver también P2/P3 y activar el faro con una pulsación nueva de I; comprobar puente y cruce. Repetir los mensajes en inglés si se desea con -- --game-language en.

Se revisaron el estado inicial y el resuelto desde cuatro orientaciones. Las capturas y la galería de esa revisión quedaron como evidencia local.

## Comandos reproducibles

Desde la raíz del proyecto, PowerShell:

~~~powershell
$engine = $godot
& $engine --headless --editor --path . --import --quit
& $engine --headless --path . --script res://tests/lost_light_visual.gd
& $engine --headless --path . --script res://tests/lost_light_visual.gd -- --game-language en
& $engine --headless --path . --script res://tests/faro_interaccion.gd -- --game-language en --expect-locale=en
& $engine --path . --resolution 1280x720 --script res://tests/lost_light_visual.gd -- --capture
& $blender --background --factory-startup --python tools/create_reflector_art.py
git diff --check
~~~

Las otras suites se ejecutan con el mismo patrón --script res://tests/NOMBRE.gd; las variantes en inglés añaden -- --game-language en. Faro requiere además --expect-locale=en. Regenerar con Blender sobrescribe sus propios .blend/GLB/métricas y exige reimportación; no es necesario para jugar ni se ejecutó durante este traslado. El exportador crea GLB 2.0 sin texturas, luces, animaciones o cámaras.

## Limitaciones pendientes

Espejo PBR sin reflexión planar real, detalles pequeños poco legibles a distancia y vistas de canto. El marco sobresale ligeramente del cilindro físico, como la placa original (radio visual aproximadamente 0,48 frente a R=0,4); se mantienen las colisiones autorizadas y pueden darse pequeñas intersecciones visuales con brazos/linterna al rozarlo. Fuente, receptor y muro continúan provisionales. No se altera cámara, iluminación, isla, personaje ni P2/P3 para acomodar el modelo. Validación manual de la integración recibida: 7/7 comprobaciones satisfactorias. Se autoriza publicar la rama y crear PR, sin fusionar ni activar auto-merge.

## Consolidación autorizada

El responsable confirma la validación manual satisfactoria de las siete comprobaciones de la integración. Se conservan el modelo aprobado, el pedestal fijo, el giro de 0,35 s y todas las reglas/colisiones originales. La publicación exige repetir importación, 18 regresiones y las dos ejecuciones específicas es/en, con git diff --check correcto. No se incorporan capturas, HTML, vídeos, temporales ni resultados de build. Las evidencias enlazadas arriba son locales e ignoradas; una copia limpia usa F5 y los comandos de prueba documentados. No se modifica CI ni se amplía funcionalidad. Merge y auto-merge no autorizados.

Repetición técnica final previa a publicación: importación Godot 4.7.2 sin errores y 20/20 ejecuciones headless satisfactorias (18 existentes más P1 visual es/en). git diff --check correcto. No se ha modificado el código aprobado durante este cierre.
