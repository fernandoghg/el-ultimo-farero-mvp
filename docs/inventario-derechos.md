# Inventario de derechos · MVP-05C

Fernando Garcia-Herrera Gomez, propietario y responsable del proyecto, ha aprobado MIT para el código y la configuración técnica propios y CC BY 4.0 para el arte y los contenidos originales autorizados. Se permite reutilizar, modificar, distribuir y usar comercialmente el material cubierto conforme a las licencias. El repositorio público previsto es [fernandoghg/el-ultimo-farero-mvp](https://github.com/fernandoghg/el-ultimo-farero-mvp) y tendrá un historial independiente del repositorio privado de desarrollo. [Manifiesto por archivo](manifiesto-derechos.md) · [Web del autor](https://fernandoghg.com).

## Declaración del propietario

> El código, modelos y textos de El último farero se desarrollaron para este proyecto con herramientas propias y asistencia de IA, sin que yo haya incorporado recursos ajenos descargados.

| Aspecto | Qué acredita |
| --- | --- |
| Procedencia declarada | Desarrollo específico para el proyecto, con herramientas propias y asistencia de IA. La declaración cubre la incorporación de recursos por parte del propietario. |
| Evidencia técnica | El diario, los constructores, las fuentes Blender, los catálogos y las exportaciones sostienen la procedencia documentada. El cotejo de hashes acredita integridad, no autoría. |
| Derechos acreditados | Quedan documentadas la identidad y la decisión del titular sobre la concesión de los derechos propios que pueda otorgar. Las licencias de terceros se acreditan mediante sus avisos. |
| Incertidumbres residuales | Siguen sin desglosarse la autoría humana, la originalidad protegible y las condiciones de algunas salidas de IA por archivo o fragmento. La declaración se registra como evidencia adicional y se mantienen los 106 archivos B. |

## Qué respalda cada categoría

| Categoría | Criterio aplicado |
| --- | --- |
| **A** | Origen documentado y suficiente para el tratamiento propuesto. Incluye datos técnicos, envoltorios de integración simples, documentos de control con alcance separado y avisos de terceros identificados. |
| **B** | La publicación parece viable por la procedencia local y la evidencia técnica. Quedan por confirmar los derechos de aportaciones humanas, las condiciones aplicables de IA o la ausencia de otros fragmentos con términos distintos. |
| **C** | Una laguna material de procedencia o una posible restricción impide proponer su publicación hasta resolverla. La ausencia de un registro por línea o de todos los prompts no basta por sí sola para clasificar en C. |

Las categorías califican la evidencia. El criterio de licencias está aprobado y la publicación requiere una autorización separada. Los documentos de control y los avisos conservan el tratamiento específico de su fila.

## Arte, procedencia y aportación humana documentada

| Familia | Evidencia técnica de origen | Decisión o aportación documentada |
| --- | --- | --- |
| Terreno V2 | `tools/create_island_terrain_v2.py` construye vértices, superficies y materiales de forma local con Blender. La integración cotejó los recursos con el prototipo aprobado. | Aprobación de geometría, hierba, acantilados e iluminación. La integración documenta asistencia de IA. [Terreno V2](island-terrain-integration.md). |
| Isla V3.2 y roca de llegada | `tools/export_island_v32.py` selecciona y exporta las mallas de los dos .blend de mantenimiento. La revisión local localizó los constructores experimentales V3 y V3.1. Las posiciones de vértices y los índices de las once mallas coincidieron con las exportaciones experimentales. | Aprobación de la dirección artística V3.2 y 8/8 comprobaciones. La integración documenta autoría local con asistencia de IA. El cotejo acredita la línea geométrica y la documentación describe el acabado final. [Isla V3.2](island-v32-consolidation.md). |
| Farero | `tools/create_keeper_prototype.py` construye las piezas, materiales y jerarquía. La animación de piezas rígidas reside en Godot. | Selección del modelo, aceptación de reposo, marcha y orientación tras la revisión humana. La creación asistida por IA está documentada. [Farero](keeper-animation-experiment.md) · [Diario, 7 de noviembre](ai-development-log.md). |
| Faros V1 y V2 | Los dos constructores perfilan torre y lente con geometría paramétrica. El exportador y el extractor conectan los .blend, los GLB y las cuatro mallas TRES. | Aprobación del aspecto V2, lente encendida y colocación de colisiones. V1 queda como referencia. La autoría local está documentada y la intervención de IA por variante queda sin desglose. [Faros](lighthouse-v2-integration.md). |
| Reflector P1/P2 | `tools/create_reflector_art.py` construye pedestal, marco y conjunto rotatorio con primitivas y mallas locales. P2 instancia el arte aprobado de P1. | Aprobación de la dirección piedra y bronce, pedestal fijo y seguimiento visual. Consta el generador local dentro del desarrollo asistido. [Reflector](lost-light-art-integration.md) · [Diario, 7 y 15 de noviembre](ai-development-log.md). |

El diario documenta decisiones de la persona responsable sobre concepto, cámara, controles, reglas de puzles, orden libre, iluminación, requisitos de localización y revisión del resultado. La documentación identifica aportación de agentes al desarrollo y asistencia de IA de forma expresa en V2, V3.2 y el farero. La procedencia técnica enlaza fuentes y generadores. La aprobación visual o funcional acredita una decisión humana, pero por sí sola no identifica quién creó la expresión final ni sus cesiones. La concesión se limita a derechos que el titular pueda otorgar sobre las aportaciones protegibles. La asistencia de IA no acredita por sí sola autoría humana u originalidad. El manifiesto conserva las incertidumbres residuales sin reclamar exclusividad sobre salidas puramente automáticas. [Diario técnico](ai-development-log.md) · [Ley de Propiedad Intelectual, art. 5](https://www.boe.es/buscar/act.php?id=BOE-A-1996-8930#a5).

## Reglas por archivo y excepciones

- **Código y datos técnicos.** MIT para el GDScript, Python, shaders, pruebas, configuración, importadores y metadatos propios que identifique el manifiesto, en la medida en que sean protegibles. En los shaders, MIT abarca la implementación completa, incluidas constantes y valores por defecto escritos en el código. Las mallas y escenas que lo usan tienen su propia fila.
- **Escenas Godot.** Para que el alcance sea reproducible sin interpretar propiedades una a una, se aplica **CC BY 4.0 para las quince escenas con composición expresiva**, como archivos completos en la medida en que su contenido sea propio y protegible. Incluye la disposición visual, los subrecursos incorporados y los parámetros del archivo como conjunto. **MIT para cinco ensamblajes técnicos**: `new_game.tscn`, `player.tscn`, `keeper_visual.tscn`, `stone_bronze_reflector.tscn` e `island_terrain.tscn`. El `ExtResource` es un enlace. La escena, el script, el GLB o el material de destino conserva su propia licencia. La revisión no detectó scripts incrustados en las escenas.
- **Recursos TRES.** CC BY 4.0 para `scenes/story_card.tres` y las cuatro mallas de faro `TowerArt.tres` y `LensArt.tres`, con sus materiales incorporados. MIT para `assets/island_terrain_v2_materials/terrain.tres`, que contiene un nombre y la referencia técnica al shader, sin parámetros artísticos propios en ese archivo.
- **Catálogos PO.** CC BY 4.0 para los valores expresivos `msgstr` de las entradas con `msgid` no vacío. MIT para las claves `msgid` y la cabecera identificada por `msgid ""`, si fueran protegibles. Ambos catálogos tienen la misma lista de claves. La documentación acredita su integración y revisión, y la declaración del propietario incluye los textos del proyecto. La autoría, la originalidad y las condiciones de las aportaciones asistidas en ambos idiomas conservan la calificación B.
- **Documentación.** CC BY 4.0 para prosa y diagramas propios dentro de las filas correspondientes, incluida la guía de Windows y el README escrito para acompañar los avisos de Godot. MIT para los bloques cercados con etiqueta `powershell` de las guías con esa excepción indicada en el manifiesto. Las citas, enlaces, avisos y otros materiales de terceros conservan sus derechos. Los archivos de licencia y atribución, este inventario y su manifiesto son documentos de alcance y avisos.

## Terceros y ejecución

Los dos avisos locales de Godot 4.7.2 coinciden con los hashes de la entrega auditada. Para redistribuir el motor y sus componentes, deben acompañarse el aviso MIT y el inventario oficial de terceros, que cubre también las fuentes integradas. El flujo de CI referencia `actions/checkout` fijado a una revisión con licencia MIT. Blender y Python son herramientas externas, con GPL y términos PSF y de terceros, respectivamente. Los archivos de arte revisados son salidas de los generadores o exportaciones, y quedan separados de la licencia de las herramientas. [Avisos de Godot](../third_party/godot/COPYRIGHT.txt) · [Licencia oficial de checkout](https://github.com/actions/checkout/blob/d23441a48e516b6c34aea4fa41551a30e30af803/LICENSE).

En las siete fuentes Blender no se encontraron bibliotecas vinculadas, imágenes externas o empaquetadas, tipografías externas, sonidos ni textos incrustados. Los siete GLB identifican el exportador Khronos de Blender y carecen de imágenes, texturas y URI externas. Estas comprobaciones respaldan la ausencia de insumos empaquetados visibles y no permiten descartar una posible copia manual anterior.

**No se identificaron recursos C con la evidencia revisada.** Si una confirmación cambia esa conclusión, la última columna del manifiesto identifica la relación con la ejecución. Por ejemplo, los dos GLB V3.2 están referenciados directamente por `scenes/main.tscn`; su retirada impediría distribuir el MVP tal como está. Sus fuentes Blender pueden excluirse del juego ejecutable, con pérdida de capacidad de edición o reexportación. Las referencias V1 del faro y V2 del terreno están fuera de la cadena de arranque y del preset. Si se retiran componentes de esa referencia, la exclusión debe abarcar sus dependencias y documentación asociada. Se requiere volver a comprobar la importación y la exportación tras cualquier recorte que se autorice.

## Pendientes de publicación

Con la evidencia disponible no se ha identificado un impedimento concreto sobre un archivo. Las partidas B mantienen las incertidumbres indicadas en sus filas. Si aparece una restricción identificable, habrá que resolverla o excluir el recurso tras comprobar sus dependencias. El nombre y la URL pública ya están definidos. Sigue pendiente autorizar expresamente la publicación de la copia independiente. La distribución Windows requiere autorización propia. [Procedimiento de publicación](publicacion.md).

## Registro de revisión MVP-05B · 2026-11-22

Se cotejaron los 170 SHA-256 iniciales, el inventario, el diario, los generadores, los catálogos y las referencias de escenas. Se abrieron las siete fuentes en Blender 5.2.3 LTS con scripts automáticos desactivados y sin guardado. Se inspeccionaron las siete cabeceras GLB y se comparó la geometría V3.2 con las dos exportaciones experimentales locales. El primer inventario documental solo identificaba al exportador de V3.2. El cotejo experimental permitió enlazar además la construcción geométrica. Se verificó estáticamente la cadena de arranque y exportación. Esta revisión documental no ejecutó Godot ni instaló o incorporó dependencias. Los borradores MVP-04B se conservan byte por byte en la carpeta de respaldo indicada en el manifiesto.
