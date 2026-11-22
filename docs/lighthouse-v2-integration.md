# Faro V2 — integración aprobada y reproducción

En los comandos de este documento, configura `$godot` y `$blender` con la ruta local del ejecutable correspondiente.

## 2026-11-05 - Aprobación visual final y preparación de PR

El responsable confirma correctos aspecto del faro, lente y encendido, visibilidad e integración, sin observaciones, con la iluminación original de main. Se autoriza commit, publicación de la integración y PR hacia main tras verificaciones. **No se autoriza fusionar la PR.**

Se mantiene el pequeño parpadeo residual de juntas como incidencia visual menor aceptada provisionalmente, no bloqueante. No se investiga ni modifica. La aprobación no incluye terreno, geometría rocosa o iluminación experimental 5.1.

## Registro de la iteración anterior


Variante artística aprobada **5/5**, integración funcional **6/6**. Esta guía selecciona el contenido aplicable de las guías anteriores; no adopta terreno, roca o iluminación global de 5.1.

## Modelo y contrato funcional

Torre propia de piedra estilizada, cuadrada y estrechada, mampostería con biseles, coronación metálica, cristales y lente cálida. Altura 3,9, base aproximada 1,1 y coronación máxima 1,126; 6 272 triángulos, nueve superficies de torre y una de lente. V1 compacta era de 2,4 de alto y 10 520 triángulos. La mayor silueta de V2 aporta presencia sin cambiar el encuadre.

Main conserva su escena original y referencia lighthouse.tscn; esta carga assets/lighthouse_tall/TowerArt.tres y LensArt.tres. Materiales embebidos, sin recursos externos. Se mantienen origen global (3;0;−3), orientación, Tower Y=1, Beacon Y=2,2, script lighthouse.gd y radio de interacción 2. El script original sigue cambiando el material de Beacon y encendiendo la única OmniLight al activar con 3/3 y una nueva I; mantiene señal única y reconstrucción del puente.

| Colisión | Tamaño X × Y × Z | Centro local | Altura cubierta |
| --- | --- | --- | --- |
| TowerCollision, BoxShape3D | 1,1 × 3,2 × 1,1 | (0;1,6;0) | 0..3,2 |
| BeaconCollision, BoxShape3D | 1,14 × 0,7 × 1,14 | (0;3,55;0) | 3,2..3,9 |

Un StaticBody3D y dos cajas, sin colisiones generadas de la malla. El corredor junto al monumento queda en 0,65 para la cápsula de diámetro 0,6: estrecho, previamente validado y cubierto por la prueba física. No se desplazan objetos para ensancharlo.

OmniLight local **(0;3,484;0)**, global **(3;3,484;−3)**, alineada con el centro de la lente. Color (1;0,8;0,3), energía 2, alcance 4, apagada inicialmente. No se modifica el ambiente global de main.

V1 permanece en scenes/reference/lighthouse_v1.tscn y assets/lighthouse/, junto con su fuente. No se referencia desde main ni se carga durante la partida. La previsualización redundante lighthouse_tall_preview.tscn queda excluida. Los .blend se excluyen del importador mediante art_source/.gdignore; Godot ejecuta e importa el proyecto sin Blender instalado.

## Procedencia y herramientas

Recursos propios de autoría paramétrica local; sin modelos, texturas, add-ons, dependencias o servicios externos y sin costes recurrentes. No se decide aquí la licencia de distribución futura del proyecto. Fuentes V1 y V2 conservadas, no regeneradas durante la separación.

- Blender 5.2.3 LTS, hash e13b728c6880, utilizado en la autoría de los modelos.
- Godot 4.7.2.stable.official.ed1daf0bf con Forward+.
- art_source/lighthouse/lighthouse.blend y art_source/lighthouse_tall/lighthouse.blend, más GLB y recursos extraídos de cada variante.

## Regeneración explícita desde la raíz dla copia de trabajo

Los constructores sobrescriben únicamente los recursos propios de su variante. Conservar ediciones manuales antes de regenerar. El exportador permite reexportar un .blend editado sin reconstruirlo. No se ejecutan estas operaciones en partida.

```powershell
# Reconstruir V2 desde su constructor.
& $blender --background --factory-startup --python tools/create_lighthouse_tall.py
# Alternativa: exportar la fuente V2 existente sin remodelar.
& $blender --background art_source/lighthouse_tall/lighthouse.blend --python tools/export_lighthouse.py -- assets/lighthouse_tall/lighthouse.glb
& $godot --headless --path . --import
& $godot --headless --path . --script tools/extract_lighthouse.gd -- --tall

# V1, solo si se necesita regenerar su referencia.
& $blender --background --factory-startup --python tools/create_lighthouse.py
& $godot --headless --path . --import
& $godot --headless --path . --script tools/extract_lighthouse.gd
```

Los ArrayMesh extraídos duplican y empaquetan materiales para evitar dependencia del orden de carga de subrecursos del GLB. Conservar los GLB, .import y .blend aunque no formen parte del árbol jugable. El .blend no se importa automáticamente.

## Validación e incidencia

La suite tests/faro_v2_fisica.gd cubre cuatro aproximaciones, volumen superior, corredor, acceso al puente, alineación lente/luz y activación única. Se mantienen las demás suites. [Resultados y capturas de esta separación](lighthouse-v2-separation.md).

Pequeño parpadeo residual de juntas: incidencia visual menor, aceptada provisionalmente y no bloqueante. No se investiga ni modifica en esta tarea. [Corrección mínima de cámara aprobada](camera-follow-settling.md). No se adopta por extensión ningún otro experimento visual.
