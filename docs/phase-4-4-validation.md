# Fase 4.4 — La luz perdida

Prototipo en `rama de integración`, sobre `main`/revisión de integración. Validación manual **10/10 comprobaciones correctas**, confirmada por el responsable. Aprueba montaje, trayectoria/obstáculos, solución única, confirmación/señal/estabilización, es/en y ausencia de regresiones en controles, cámara, fractal, faro y puente. La independencia entre puzles es intencionada; su integración con la progresión y el faro se abordará después.

Cierre autorizado: commit, push sin forzar, PR a main y squash si verificaciones locales y Actions son satisfactorias; conservar rama remota y sincronizar main mediante fast-forward. Ante anomalías o fallos, detenerse e informar. No iniciar otra fase.

## Montaje y funcionamiento

El montaje ocupa la zona sureste libre: fuente en (1,8; 0; 3), reflector en (3,8; 0; 3), receptor en (3,8; 0; 4,8) y superficie inerte en (3,8; 0,65; 1,2). El haz está a altura 1,2. Las bases y colisiones quedan dentro del terreno existente, sin desplazar caminos, pedestal, monumento, faro o puente. Se puede observar y accionar desde el lado este del reflector.

Una pulsación nueva de I dentro de 1,25 unidades alterna dos diagonales de 90°. Inicialmente el haz termina en la superficie inerte. La otra orientación refleja hacia el receptor. El cambio es instantáneo; no hay estados de animación intermedios. Antes de resolver se puede corregir sin penalización. Mantener I o entrar con I pulsada no repite el giro; durante la inspección fractal no se acepta esta interacción.

La fuente dorada, el haz continuo, la placa clara orientable y el receptor con marco de rombo usan primitivas y materiales sencillos. El receptor se ilumina y emite un pulso expansivo de 0,8 s al recibir. El aviso localizado confirma la recepción; después indica estabilización. El trayecto aceptado y el reflector quedan enclavados hasta reiniciar la escena. No hay sonidos, partículas, shaders personalizados o recursos externos.

El controlador local realiza dos consultas físicas finitas de cuatro unidades: fuente→reflector y reflexión→primer obstáculo. Calcula la reflexión sobre la normal de la placa, exige contacto dentro de sus dimensiones y recepción por la cara sensible del receptor. La misma trayectoria alimenta la geometría visible. Proximidad, pulsación, índice y material luminoso no sustituyen estas comprobaciones. El avatar se excluye de la consulta óptica, pero mantiene sus colisiones de movimiento. No hay infraestructura óptica genérica ni rebotes recursivos.

La señal local `LostLight.resolved` se emite una sola vez y no tiene conexiones de progreso. P3 conserva su suministro autónomo; I ante el faro y su conexión al puente permanecen intactos. P2 y la secuencia de energía siguen pendientes. No hay guardado, zoom, dependencias o cambios de CI.

## Pruebas y revisión técnica

Ejecutar desde la raíz con Godot 4.7.2:

```powershell
Godot --headless --path . --script tests/luz_perdida.gd
Godot --headless --path . --script tests/luz_perdida.gd -- --game-language en
```

La suite comprueba ambas orientaciones y una única válida; extremos del haz; obstáculos en ambos tramos; receptor fuera de trayectoria y cara posterior; independencia de visibilidad/material; pulsaciones fuera de alcance, heredadas, mantenidas y eco; ciclo reversible con receptor bloqueado; suspensión de controles; conservación al alejarse; señal única, pulso breve y enclavamiento; reinicio de sesión y textos es/en. Retirar un obstáculo permite resolver sin una nueva pulsación, demostrando evaluación continua de la recepción.

La regresión incluye resolución fractal es/en (27 configuraciones, una válida), inspección de un rotor es/en, mecanismo de tres rotores es/en, personaje/cámara, faro es/en y puente. Los resultados reales se registran en el diario técnico. CI conserva su cobertura anterior y no se modifica; se exige Actions satisfactorio en la PR antes de fusionar.

Para capturas técnicas ejecutar la suite con ventana y `-- --capture`, añadiendo `--game-language en` para inglés. Guarda inicio y resolución a 1280 × 720 en `build/lost-light-*.png`, ignorado por Git. No modifica la cámara; sitúa el avatar junto al reflector. Esta revisión no sustituye aceptación de jugabilidad ni mide rendimiento.

## Checklist manual de referencia — validación humana 10/10

El responsable comunica diez comprobaciones correctas. Los seis puntos agrupados siguientes se conservan como procedimiento de repetición, sin convertirlos en un resultado distinto.

1. Abrir `project.godot` con Godot 4.7.2, F5, ventana 1280 × 720. Acercarse al montaje sureste por el lado este. Identificar fuente, placa, superficie inerte y receptor; explicar dónde termina inicialmente el haz y predecir su desvío antes de pulsar I.
2. Leer la pista «Conduce la luz hasta el cristal marcado». Pulsar I: comprobar cambio inmediato de orientación y trayectoria hasta el receptor, iluminación, pulso breve y aviso de recepción. Mantener I y volver a pulsar: no debe desestabilizarse.
3. Antes de resolver, alejarse y volver; aproximarse manteniendo I desde fuera: no debe girar por herencia. Soltar y volver a pulsar sí debe actuar. Tras resolver, alejarse y volver conserva el montaje; reiniciar la escena lo reinicia.
4. Recorrer ambos lados accesibles del montaje y girar la cámara con Q/E: no debe bloquear caminos ni exigir un ángulo exacto. Revisar que el avatar no oculta permanentemente la placa y que fuente, haz y objetivo se distinguen por su forma y luminosidad.
5. Probar P3 con A/D/I/Esc y activar manualmente el faro para reconstruir/cruzar el puente, antes y después de resolver P1. No debe haber activación automática o cambios de controles/cámara.
6. Repetir en inglés con `Godot --path . -- --game-language en`: «Guide the light to the marked crystal», avisos sin claves ni recortes. Registrar comprensión y legibilidad por separado de corrección lógica.

Los bloqueos artificiales de la suite no son una mecánica de mover obstáculos en la partida. La reversibilidad anterior a la solución se verifica automáticamente con un obstáculo que impide enclavar; el montaje jugable normal se estabiliza en cuanto recibe correctamente.

## Limitaciones

Geometría y materiales provisionales; el montaje cuenta con aceptación manual 10/10. El pulido audiovisual y el zoom siguen aplazados. La solución se conserva solo durante la sesión. El suministro autónomo de P3 y la activación directa del faro son excepciones temporales expresamente conservadas; esta fase no integra progreso.
