# Fase 4.5 — Los espejos del guardián

Prototipo en `rama de integración`, sobre main/revisión de integración. Validación manual **10/10 comprobaciones correctas, sin observaciones**, confirmada por el responsable: cuatro parejas/una solución, cadena física por ambas placas, muro, confirmación/señal/estabilización, es/en, reutilización óptica y ausencia de regresiones.

Cierre autorizado: commit, push sin forzar, PR a main y squash exclusivamente tras verificaciones locales y GitHub Actions satisfactorias. Conservar rama remota, actualizar main por fast-forward y comprobar igualdad con la referencia remota de la rama principal y árbol limpio. Detenerse ante anomalías. No comenzar integración de progreso/faro u otra fase.

## Montaje y reglas

Sector oeste: fuente en (-5,5; 0; -0,3), espejo de una marca en (-4,5; 0; -0,3), espejo de dos marcas en (-4,5; 0; 1,2) y receptor en (0,6; 0; 1,2). Haz a altura 1,2. Un muro de piedra en L bloquea la línea directa fuente→receptor; su cara corta detiene el desvío inicial hacia el norte. El recorrido correcto rodea el extremo sur del muro. No se desplazan objetos existentes, suelo, límites o cámaras.

Acceso desde el inicio: caminar hacia el sur hasta Z≈2,8, después al oeste hasta X≈-5,25; desde ese corredor se llega primero al espejo de dos marcas y después al de una marca. Hay salida de vuelta por el mismo recorrido, sin salto ni cruce de obstáculos. La suite recorre esa ruta con movimiento y colisiones reales. Las zonas de interacción quedan separadas de P1, pedestal fractal y faro.

Cada espejo alterna dos diagonales instantáneas mediante una pulsación nueva de I a una distancia máxima de una unidad. Solo cambia el espejo más cercano, identificado por el aviso. Se puede girar el segundo antes de recibir luz y corregir ambos sin penalización antes de resolver. Una o dos barras claras identifican los espejos; sus nombres aparecen localizados en el aviso. El indicador dorado bajo la segunda placa solo se muestra al recibir luz por la primera; pulsa brevemente al comenzar esa recepción.

Se exige la secuencia física fuente→primer espejo→segundo espejo→cara sensible del receptor. Hay tres tramos finitos de hasta seis unidades y como máximo dos reflexiones en orden fijo. El primer impacto interrumpe cada tramo. Una ruta directa al receptor, una placa ausente, un obstáculo o un cristal que solo brilla no resuelven. El avatar mantiene sus colisiones de movimiento, pero no corta el haz óptico.

Una única pareja de las cuatro posibles llega al receptor. La recepción ilumina el cristal, muestra un pulso y aviso de 0,8 s, emite `GuardianMirrors.resolved` una sola vez y estabiliza espejos y trayectoria durante la sesión. Reiniciar la escena reinicia el montaje. No se conecta a P1/P3, faro o puente. El suministro autónomo es una excepción temporal explícita al diseño de progreso futuro.

## Reutilización y límites

`scripts/light_geometry.gd` comparte únicamente consulta física, cálculo de reflexión dentro de la placa y colocación de una malla de haz. P1 delega esas mismas operaciones sin cambiar sus reglas, estado, controles o señal. Los controladores permanecen independientes; no hay gestor de puzles, grafo de rebotes o arquitectura óptica genérica.

Primitivas, materiales sencillos y textos PO es/en. Sin dependencias, servicios, telemetría, sonidos o shaders personalizados. Sin cambios de CI, zoom, guardado, progreso o condiciones nuevas del faro. Pulido audiovisual pendiente. Las capturas no acreditan comprensión humana, rendimiento cuantitativo o legibilidad desde todos los ángulos.

## Pruebas

```powershell
Godot --headless --path . --script tests/espejos_guardian.gd
Godot --headless --path . --script tests/espejos_guardian.gd -- --game-language en
```

La suite evalúa las cuatro parejas en escenas independientes, una válida, continuidad/extremos de los tramos, bloqueo directo por el muro y bloqueos artificiales en cada tramo; exige ambos espejos físicos aunque el receptor brille. Comprueba recepción independiente de materiales, giros individuales/reversibilidad, pulsación mantenida/heredada/eco, suspensión contextual, señal única, pulso breve, estabilización y persistencia. Incluye acceso/salida con movimiento real, reinicio de escena, textos es/en completos y proyección de los elementos a 1280 × 720.

Regresión: P1 es/en, resolución fractal es/en (27 configuraciones, una válida), inspección de un rotor es/en, tres rotores es/en, personaje/cámara, faro es/en y puente. Catorce ejecuciones headless en total. En la versión final todas terminan con salida 0, cero fallos y sin errores de Godot; importación satisfactoria. La suite gráfica es/en también pasa con Godot 4.7.2 y Forward+ a 1280 × 720, con capturas revisadas. Resultados y correcciones en el diario. Durante el prototipo no se ejecutó CI remota; el cierre exige Actions satisfactorio en la PR antes del squash.

Para capturas, ejecutar la suite sin `--headless`, con `-- --capture` y, para inglés, `-- --game-language en --capture`. Escribe en build/ ignorado; usa la cámara normal a 45°. Los ajustes de orientación del arnés de movimiento no alteran el juego.

## Checklist manual de referencia, 1280 × 720 — validación 10/10

El responsable confirma diez comprobaciones correctas y sin observaciones. Los siete puntos agrupados siguientes permanecen como procedimiento de repetición; no se altera la puntuación comunicada ni se atribuye a pruebas automáticas.

1. F5 en Godot 4.7.2. Rodear el muro por el sur hasta el corredor oeste. Identificar fuente, muro en L, dos placas y receptor; explicar por qué no existe conexión directa y dónde termina inicialmente el haz.
2. Identificar una/dos marcas y leer sus avisos. Girar primero el espejo sin luz: solo cambia su orientación, no resuelve. Mantener I y cambiar de espejo sin soltar: no debe repetirse ni heredarse un giro. Soltar y volver a pulsar sí debe actuar.
3. Llevar la luz al segundo espejo y observar su indicador. Antes de tocar la segunda placa, predecir el siguiente tramo. Seguir la trayectoria continua y su respuesta inmediata, sin depender solo del color.
4. Antes de resolver, corregir orientaciones sin penalización; alejarse y regresar conserva estados. Resolver ilumina el receptor, confirma brevemente y estabiliza ambos espejos. Repetir I no altera el resultado. Reiniciar la escena recupera el estado inicial.
5. Recorrer y abandonar la zona antes/después y usar Q/E: ambos espejos accesibles sin atravesar obstáculos ni quedar atrapado. Evaluar ocultaciones por muro/avatar y legibilidad; no introducir zoom.
6. Probar «La luz perdida», A/D/I/Esc en el fractal y activación manual del faro con cruce del puente antes/después de P2. Ningún puzle debe resolver otro ni activar automáticamente el faro.
7. Repetir en inglés con `Godot --path . -- --game-language en`. Revisar pista, nombres por marcas, recepción y estabilización sin claves o recortes. Registrar comprensión y legibilidad aparte de corrección lógica.

Los obstáculos adicionales y placas desactivadas de las pruebas son fixtures, no mecánicas de mover obstáculos. El montaje normal tiene exactamente dos estados por reflector y se enclava al recibir correctamente.
