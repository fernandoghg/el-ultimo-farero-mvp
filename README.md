# El último farero: Los mundos del infinito

El último farero es una aventura fantástica isométrica 2.5D para **Windows x86-64**. Explora una isla flotante, restaura tres circuitos de luz en cualquier orden y enciende el faro para reconstruir el puente.

El **MVP está completo**. Incluye una introducción, una isla jugable, *La luz perdida*, *Los espejos del guardián* y *El eco del infinito*, el faro, el puente y un desenlace con opciones para volver a jugar o salir. Se puede jugar en español e inglés, sin conexión. El desarrollo activo terminó con el MVP. El proyecto carece de un compromiso de mantenimiento, soporte o nuevas versiones.

## Ejecutar desde el código fuente

Importa `project.godot` en el editor estándar de **Godot 4.7.2** y pulsa **F5**. El proyecto usa GDScript y Forward+ con Vulkan. Para iniciar desde PowerShell, configura `$godot` con la ruta del ejecutable de consola y ejecuta `& $godot --path .` desde la raíz. Añade `-- --game-language en` para iniciar en inglés. Los modelos editables se prepararon con Blender 5.2.3 LTS. Blender y Python se usan para la autoría y regeneración del arte.

Pulsa **Intro** para empezar. **WASD** mueve al farero, **Q/E** gira la cámara e **I** interactúa. En el pedestal de los rotores, usa **A/D** para seleccionar, **I** para girar y **Esc** para volver a explorar. Consulta la [guía del jugador en español e inglés](docs/windows-player-guide.txt).

## Distribución y pruebas

El preset **Windows x86-64** exporta `ElUltimoFarero.exe` y `ElUltimoFarero.pck`. Usa las plantillas estándar de la misma versión de Godot. La [guía de distribución](docs/windows-distribution.md) explica cómo exportar, montar el ZIP con los avisos del motor y comprobar el resultado.

Importa primero con `& $godot --headless --path . --import`. Ejecuta, por ejemplo, `& $godot --headless --path . --script res://tests/desenlace.gd`. La [guía de pruebas](docs/pruebas.md) describe la batería completa, las variantes de idioma y el recorrido manual.

## Organización

| Ruta | Contenido |
| --- | --- |
| `project.godot`, `export_presets.cfg` | Configuración del proyecto y exportación Windows |
| `scenes/`, `scripts/`, `translations/` | Escenas, lógica del juego y catálogos español/inglés |
| `assets/`, `art_source/` | Recursos de Godot, modelos GLB y fuentes editables de Blender |
| `tools/`, `tests/`, `.github/workflows/` | Regeneración artística, pruebas locales e integración continua |
| `docs/`, `third_party/godot/` | Documentación técnica y avisos del motor |

Consulta el [diseño](docs/game-design.md), la [arquitectura](docs/architecture.md), la [privacidad](docs/privacy-security.md) y la [hoja de ruta](docs/roadmap.md).

## Autoría y reutilización

**Repositorio público previsto** [fernandoghg/el-ultimo-farero-mvp](https://github.com/fernandoghg/el-ultimo-farero-mvp). La publicación está pendiente de autorización y se hará en un repositorio independiente del repositorio privado de desarrollo.

El proyecto es de **Fernando Garcia-Herrera Gomez**. Se desarrolló con agentes de IA bajo supervisión humana, con asistencia en código, escenas, herramientas, arte y documentación. El [diario técnico](docs/ai-development-log.md) registra decisiones y validaciones. [Web del autor](https://fernandoghg.com).

El código y la configuración propios se distribuyen bajo [MIT](LICENSE). El arte, los mensajes localizados y los demás contenidos originales identificados se distribuyen bajo [Creative Commons Attribution 4.0 International](LICENSE-ASSETS.md). El [manifiesto](docs/manifiesto-derechos.md) delimita los archivos y las excepciones. Se permiten la modificación, la redistribución y el uso comercial bajo las condiciones correspondientes. El código fuente completo de un juego derivado puede mantenerse privado. Consulta la [atribución](ATTRIBUTION.md) y los [avisos de Godot y sus componentes](third_party/godot/COPYRIGHT.txt).
