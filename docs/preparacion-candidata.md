# Preparación de la copia independiente · MVP-04B

Se preparó el árbol desde un manifiesto de la revisión autorizada. La exportación Git se cotejó con el listado de blobs de esa revisión. Ningún archivo del proyecto se tomó de carpetas locales sin versionar. La copia contiene código, recursos jugables, las siete fuentes Blender, referencias históricas depuradas, configuración y pruebas. La sobrecapa documental incorpora los borradores de licencia, el inventario, las guías y los avisos oficiales de Godot.

## Reconstruir el árbol

1. Confirma la revisión autorizada y prepara una copia de trabajo limpia para leerla.
2. Enumera los archivos versionados con `git ls-tree -r -z REVISION` y extrae exclusivamente esos blobs mediante `git archive --format=zip REVISION` en un directorio temporal fuera de Git.
3. Copia los archivos desde esa extracción, vuelve a guardar los siete modelos con Blender y aplica la sobrecapa documental revisada. Verifica la lista resultante y sus hashes. El material de preparación y las evidencias quedan fuera de la copia candidata.
4. Escanea el contenido y los metadatos, comprueba los enlaces locales y verifica la ausencia de metadatos Git. Ejecuta los pasos de [pruebas](pruebas.md) y [exportación Windows](windows-distribution.md) desde un duplicado temporal para que la candidata siga limpia.

## Saneamiento de Blender

Blender 5.2.3 LTS abrió cada original extraído en memoria, con ejecución automática de scripts desactivada. La ruta anterior estaba en `FileSelectParams.directory` del selector del espacio **Shading**. El primer guardado dejó bytes de la ruta anterior tras el terminador. Se rellenó el campo completo con bytes neutros mediante la API RNA de Blender, se dejó el marcador relativo `//` y se guardó de nuevo sin compresión para verificar todo el bloque. Blender conservó los espacios de trabajo. En cinco modelos se marcó un bloque de material sin usuarios para que Blender lo conservara al guardar.

| Fuente bajo `art_source/` | Objetos | Mallas | Materiales | Resultado |
| --- | ---: | ---: | ---: | --- |
| `island_terrain_v2/island_v2.blend` | 1 | 1 | 5 | Abierta y comprobada |
| `island_v32/island.blend` | 10 | 10 | 27 | Abierta y comprobada |
| `island_v32/landing_cliff.blend` | 1 | 1 | 0 | Abierta y comprobada |
| `keeper_prototype/keeper_v1.blend` | 8 | 7 | 13 | Abierta y comprobada |
| `lighthouse/lighthouse.blend` | 2 | 2 | 10 | Abierta y comprobada |
| `lighthouse_tall/lighthouse.blend` | 2 | 2 | 11 | Abierta y comprobada |
| `reflector_art_v1/ancient_reflector_v1.blend` | 3 | 2 | 8 | Abierta y comprobada |

La reapertura comprobó la ruta relativa, geometría, topología, objetos, transformaciones, materiales, colecciones y parámetros de escena. Para cada modelo, Blender generó el mismo GLB de comparación antes y después. Ese GLB se usó únicamente como comprobación temporal. Los GLB del juego se conservaron desde el manifiesto Git, byte por byte.

## Resultados de verificación

### Archivos y privacidad

La candidata en el corte MVP-04B contenía **170 archivos**. Se conservaron los 160 nombres del inventario versionado y se añadieron diez archivos documentales y avisos, incluidos los borradores de licencia. Se excluyeron los metadatos y el historial Git, las carpetas de trabajo sin versionar, capturas, auxiliares locales, temporales, cachés, ejecutables y ZIP. Los siete .import y los .uid versionados se conservan porque son metadatos de recursos. Los recursos GLB de referencia se mantienen junto a sus fuentes editables.

| Tipos | Cantidad |
| --- | ---: |
| GDScript y scripts Python | 38 |
| Escenas y recursos TSCN/TRES | 26 |
| Shaders e inclusiones | 7 |
| Fuentes Blender y GLB | 14 |
| Catálogos PO y métricas JSON | 5 |
| UID y metadatos de importación GLB | 45 |
| Configuración del proyecto, exportación, CI y exclusiones | 5 |
| Markdown, guías, avisos y borrador LICENSE | 30 |

Se inspeccionaron documentación, configuración, escenas, fuentes Blender sin compresión, cabeceras y contenido de los GLB y recursos del PCK, incluidos los bloques comprimidos de Godot. La búsqueda abarcó correos, perfiles Windows, rutas, referencias privadas y patrones de credenciales. El resultado final no detectó coincidencias privadas ni secretos. Los dos avisos oficiales de Godot coinciden con las copias de referencia por SHA-256. El inventario de terceros contiene tres direcciones públicas procedentes del aviso oficial y se conservó íntegro. La revisión cubre formatos y patrones comprobados.

### Pruebas y exportación

Godot 4.7.2 oficial importó el proyecto sin errores. Pasaron **26 ejecuciones headless de 14 suites**, incluidas 10 variantes en inglés y dos casos de salida. La exportación release con el preset Windows x86-64 produjo un PE x86-64 y un PCK separado. El ZIP pasó su verificación CRC y el ejecutable arrancó desde el paquete extraído, en headless, con argumentos de idioma español e inglés. Las pruebas se ejecutaron usando una carpeta y un perfil de Godot independientes.

Se verificaron las sumas de las **91 entradas** del PCK y sus nombres coincidieron con el paquete MVP-03 validado. El ejecutable coincidió byte por byte. Se cotejaron los recursos jugables con los blobs de origen. Los siete GLB son idénticos. La única diferencia en 127 archivos de texto de origen consiste en los finales de línea CRLF fijados para la copia de Windows. El kit se ejecutó dos veces con el árbol definitivo. Coincidieron los 170 nombres y 163 archivos quedaron idénticos byte por byte. Los siete .blend variaron en bytes y superaron las mismas comprobaciones de contenido y la misma comparación GLB. Algunos recursos serializados de Godot también pueden variar entre ejecuciones. Esta fase no repitió la validación manual en hardware, cuyo resultado anterior está en la [guía de distribución](windows-distribution.md).

La documentación posterior recoge el alcance MIT y CC BY 4.0 y la atribución del proyecto. La lista de 171 rutas, las incertidumbres sobre IA y los SHA-256 por archivo constan en el [manifiesto MVP-05D](manifiesto-derechos.md). El repositorio público previsto es [fernandoghg/el-ultimo-farero-mvp](https://github.com/fernandoghg/el-ultimo-farero-mvp). Sigue pendiente la autorización de [publicación](publicacion.md).
