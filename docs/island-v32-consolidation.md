# Consolidación V3.2 de la primera isla

En los comandos de este documento, configura `$blender` con la ruta local del ejecutable correspondiente.

La persona responsable aprobó la dirección artística V3.2 y confirmó **8/8 comprobaciones manuales satisfactorias en F5**. La integración se preparó en `rama de integración` a partir de `revisión comprobada`.

## Prueba manual con F5

En este hito F5 cargaba la isla V3.2 desde `scenes/main.tscn`. En el MVP, F5 abre la introducción desde `scenes/new_game.tscn`.

1. Usa **WASD** para caminar con relación a la cámara y **Q/E** para girarla 90°. Comprueba la marcha, el reposo y la orientación del farero, y recorre los senderos.
2. **P1 · La luz perdida.** Acércate por el este al reflector de bronce del sector sureste. Pulsa **I** una vez y verifica el giro suave de la placa y la llegada del haz al receptor. Repite la pulsación para comprobar que el reflector resuelto se mantiene fijo.
3. **P2 · Los espejos del guardián.** Rodea el muro en L por el sur y entra en el corredor oeste. Pulsa **I** junto al espejo de dos marcas y después junto al de una marca. Comprueba que el haz enlaza ambos espejos y llega al receptor.
4. **P3 · El eco del infinito.** Pulsa **I** ante el pedestal triangular pequeño. **A/D** seleccionan un rotor, **I** lo gira y **Esc** sale de la inspección. Desde el estado inicial, usa **I, I, A, I**, con una pausa entre giros. Comprueba que se iluminan los cristales del monumento, aparece la confirmación y regresa la cámara de exploración.
5. Ante el faro, prueba **I** antes de completar los tres circuitos para ver el contador temporal y el puente cerrado. Tras completar los tres, vuelve al faro y pulsa **I** de nuevo. Comprueba la lente encendida, espera la reconstrucción y cruza a pie a la isla de llegada. Prueba el regreso.

## Inventario para una futura PR

| Categoría | Archivos | Función |
| --- | --- | --- |
| Escena principal | `scenes/main.tscn` | Conserva los nodos, posiciones, scripts y conexiones de la partida e incorpora la presentación V3.2. |
| Recursos de ejecución | `assets/island_v32/` | Dos GLB con las mallas visibles, sus dos archivos de importación, cinco shaders, un include y sus UID. |
| Fuentes de mantenimiento | `art_source/island_v32/island.blend`, `art_source/island_v32/landing_cliff.blend`, `tools/export_island_v32.py` | Mallas aprobadas de la isla y de la roca de llegada, con exportación reproducible. |
| Pruebas y documentación | `tests/puente_reconstruccion.gd`, este documento y `docs/ai-development-log.md` | La prueba del puente mide ahora la malla visible de cada orilla y conserva las aserciones funcionales. |

La escena principal usa directamente los GLB y shaders del directorio de producción. El terreno V2 ya versionado sigue disponible como referencia histórica. Los cinco volúmenes visuales provisionales permanecen ocultos en la escena principal y conservan los contratos de geometría asociados a las pruebas.

La futura PR debe seguir la lista de la tabla. `experiments/` conserva V3, V3.1 y V3.2, las copias de sus recursos, los generadores experimentales, la guía F6 y la copia de la escena base `revisión comprobada` para comparar. La escena V3 pasa a heredar de esa copia local y mantiene la referencia visual de las variantes posteriores. `build/` y `.godot/` quedan ignorados y contienen capturas, galerías, registros de rendimiento y auxiliares temporales. Deben excluirse también los cambios previos de solo finales de línea de `project.godot` y de los importadores existentes. Los archivos locales se conservan para revisión.

## Reexportar los recursos

Desde la raíz del proyecto y con Blender 5.2.3 LTS:

```powershell
& $blender --background --factory-startup --python-exit-code 1 --python tools/export_island_v32.py
```

El script selecciona las mallas aprobadas de las fuentes Blender de mantenimiento y escribe ambos GLB de producción. Los modelos y materiales son propios, creados localmente con asistencia de IA. Los archivos Blender y el exportador utilizan recursos locales.

## Límites de la comprobación

La validación gráfica se ejecutó con Forward+ y RTX 4070. Las nubes son capas estáticas. La prueba de la junta del puente mide su eje central en la geometría visible y las pruebas funcionales comprueban la colisión, las protecciones laterales y el cruce en ambos sentidos.
