# Seguimiento de cámara — ajuste aprobado

La corrección aprobada añade FOLLOW_SETTLE_DISTANCE=0.0025 a scripts/isometric_camera.gd. Después de la interpolación exponencial original, si la distancia del foco al objetivo es estrictamente menor que 0,0025, iguala el foco a la posición objetivo. La posición orbital se calcula después; no se compara la distancia física cámara/personaje con este umbral.

Se conserva follow_speed=8, giro de 90°, tween de 0,45 s, inclinación y proyección. El ajuste adicional queda por debajo del umbral, aproximadamente 0,1 píxel a 720 de alto y tamaño ortográfico 18. Al reanudar el movimiento se utiliza la misma fórmula exponencial.

## Evidencia histórica y aceptación

La reproducción previa a 1280×720 registró error de foco anterior 0,001652 a 0,714 s y 0,000150 a 1,015 s. Tras la corrección, cero exacto desde la muestra 0,710 hasta 2,011 s; las capturas tardías corregidas fueron idénticas entre sí. Esto describe muestras discretas de aquella validación, no garantiza ausencia de aliasing en movimiento. Las evidencias originales permanecen en el árbol experimental y su copia de conservación; no se trasladan ni se requieren para ejecutar el proyecto.

Validación manual comunicada: **3/4 comprobaciones**, sin identificar aquí cuál fue la restante. Pequeño parpadeo residual de juntas aceptado provisionalmente como incidencia menor no bloqueante. No se investiga, no se promete su eliminación y no se modifican mallas, materiales, sombras o antialiasing.

tests/personaje_camara.gd conserva sus comprobaciones anteriores y añade velocidad a 30/60/120 pasos, asentamiento exacto, estabilidad, ambos lados del umbral, reanudación y cuatro giros en cada sentido. [Resultados actuales y checklist](lighthouse-v2-separation.md).
