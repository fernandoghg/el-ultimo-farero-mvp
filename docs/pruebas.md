# Pruebas del MVP

Usa el ejecutable de consola de Godot 4.7.2. En PowerShell, establece `$godot` con su ruta, abre la raíz del proyecto e importa los recursos. Comprueba el código de salida y los prefijos de diagnóstico `ERROR:` y `SCRIPT ERROR:`, incluso cuando el proceso termina con código cero.

```powershell
& $godot --headless --path . --import
& $godot --headless --path . --script res://tests/personaje_camara.gd
& $godot --headless --path . --script res://tests/faro_interaccion.gd -- --game-language en --expect-locale=en
& $godot --headless --path . --script res://tests/desenlace.gd -- --check-exit --game-language en
```

| Área | Scripts bajo `tests/` |
| --- | --- |
| Movimiento, cámara y arte del farero | `personaje_camara.gd`, `keeper_visual.gd` |
| P1 y su arte | `luz_perdida.gd`, `lost_light_visual.gd` |
| P2 | `espejos_guardian.gd` |
| P3 | `fractal_un_rotor.gd`, `fractal_tres_rotores.gd`, `fractal_resolucion.gd` |
| Faro y puente | `faro_interaccion.gd`, `faro_v2_fisica.gd`, `restauracion_faro.gd`, `puente_reconstruccion.gd` |
| Inicio y final | `introduccion.gd`, `desenlace.gd` |

`circuit_fixture.gd` es el auxiliar compartido. Para la batería de 26 ejecuciones, lanza los 14 scripts en español, luego repite en inglés los de P1, P2, P3, interacción y restauración del faro, introducción y desenlace. Añade `-- --game-language en` en esas ejecuciones y `--expect-locale=en` en `faro_interaccion`. Ejecuta `desenlace` con `--check-exit` en ambos idiomas. La configuración de CI ejecuta cuatro casos, personaje/cámara, interacción con el faro en español e inglés y puente.

## Recorrido manual con soluciones

1. Pulsa **F5** y lee la introducción. Comprueba que WASD, Q/E e I están bloqueadas hasta empezar. Pulsa **Intro**.
2. Para P3, pulsa **I** en el pedestal triangular pequeño. Desde la posición inicial pulsa **I, I, A, I**, dejando terminar cada giro. Tras iluminarse los cristales pulsa **Esc**.
3. Para P2, rodea el muro en L por el sur, entra por el corredor oeste y pulsa **I** junto al espejo de dos marcas y después junto al de una marca. El haz debe alcanzar el receptor.
4. Vuelve al faro y comprueba el aviso de 2 de 3 circuitos. Para P1, acércate por el este al reflector de bronce del sureste y pulsa **I** una vez. El receptor debe iluminarse.
5. Junto a la torre, pulsa **I** de nuevo. Comprueba que se ilumina la lente, se reconstruye el puente y aparece una tarjeta final. Selecciona **Volver a jugar** y verifica que reaparece la introducción con los puzles reiniciados.
6. Completa otra partida y elige **Salir**. Repite con `--game-language en`. Para ejecutar desde un ZIP extraído, consulta la [guía de distribución](windows-distribution.md).
