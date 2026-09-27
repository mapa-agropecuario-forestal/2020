# Análisis del desplazamiento de las clases ASP y PNE en el mapa 2020

Manuel Vargas, 2026-09-27

## Antecedentes

El 2026-09-17, Ana Julieta Calvo (MINAE) y Mauricio Gutiérrez (MAG), en coordinación con Germán Obando, reportaron que en un proceso de validación del mapa agropecuario y forestal 2020 (MAF2020, versión 3, publicada en el SNIT) encontraron desplazamientos entre:

- la clase 4, **Patrimonio Natural del Estado (PNE)**, del mapa y la capa vectorial vigente de PNE de SINAC, con desplazamientos "muy fuertes", de hasta ~600 m; y
- la clase 2, **Áreas Silvestres Protegidas (ASP)**, del mapa y la capa vectorial vigente de ASP, con desplazamientos pequeños (~9 m), atribuibles a la rasterización.

El 2026-09-18 enviaron tres capturas de pantalla (dos de PNE y una de ASP) y en una reunión virtual ese mismo día se acordó generar una **versión 4 del mapa 2020 sin las dos capas máscara (ASP y PNE)**, dejando que esos espacios se llenen con la información jerarquizada de las demás capas, y analizar la causa del problema. Entre las posibles causas se mencionaron la reproyección de las capas, las discrepancias entre versiones de las capas de SINAC publicadas a través del tiempo y el uso de `st_make_valid()`.

## Método

Se comparó, polígono por polígono, la versión de cada capa usada para generar el mapa 2020 con la versión publicada por el mismo servicio WFS de SINAC (`geos1pne.sirefor.go.cr`, capas `PNE:patrimonio_natural_del_estado` y `PNE:areas_silvestres_protegidas`) en junio de 2026:

| Capa | Versión usada en el mapa 2020 | Versión de comparación |
|---|---|---|
| PNE | Descargada el 2025-02-12 (1281 polígonos, EPSG:5367) | Descargada el 2026-06-18 (1306 polígonos) |
| ASP | Descargada el 2024-05-22 (173 polígonos, EPSG:5367) | Descargada el 2026-06-18 (174 polígonos) |

Los polígonos se emparejaron por **forma idéntica** (misma área, mismo número de vértices y mismo perímetro, redondeados al metro), lo que permite medir cuánto se movió cada polígono entre versiones aunque haya cambiado de identificador. Para cada pareja se calculó el desplazamiento del centroide. Además se verificó (a) que la rasterización reprodujo fielmente el insumo y (b) la magnitud de la transformación entre CR05 (EPSG:5367) y CR-SIRGAS (EPSG:8908).

El programa que reproduce el análisis es `programas/analisis-desplazamiento-asp-pne.R`; sus salidas son `salidas/desplazamiento-pne-2025-02-vs-2026-06.csv` y `salidas/desplazamiento-asp-2024-05-vs-2026-06.csv`.

## Resultados

### PNE: SINAC reposicionó una cuarta parte de los polígonos entre 2025 y 2026

| Métrica | Valor |
|---|---|
| Polígonos con forma idéntica en ambas versiones | 1250 |
| De ellos, desplazados más de 1 m | 330 (26 %) |
| Desplazados más de 100 m | 153 |
| Desplazados más de 300 m | 89 |
| Desplazados más de 600 m | 47 |
| Desplazados más de 1 km | 26 (máximo: 3.5 km) |
| Mediana del desplazamiento | 0 m (la mayoría de los polígonos no se movió) |
| Sin forma idéntica en la otra versión | 17 (solo en 2025) y 46 (solo en 2026) |

Los polígonos desplazados son sobre todo de las categorías "PARQUE NACIONAL" (232, sumando las dos grafías) y "FUERA ASP" (55). Se trata de polígonos derivados de planos catastrales, cuyo georreferenciamiento SINAC ha venido corrigiendo.

Los dos sitios de las capturas de pantalla de PNE corresponden a polígonos que cambiaron de posición entre versiones, con la misma área:

| Sitio | Plano | Área | Desplazamiento del centroide | Medido por MAG-MINAE |
|---|---|---|---|---|
| Captura 1 (Tronadora, Guanacaste) | G-0233612-1995 | 198.0 ha | 70 m (dx +70, dy −5), con cambio de orientación: en los vértices el desplazamiento es mayor | 214 m |
| Captura 2 (Guanacaste) | 2-39592-1962 | 40.7 ha | 572 m (dx +251, dy −514), traslación pura | 626 m |

**La rasterización fue fiel al insumo**: el raster de PNE del mapa (`datos/procesados/rasterizados/patrimonio-natural-estado.tif`) tiene el valor 204 en el centroide de la versión 2025 del plano 2-39592-1962 y NA en el centroide de la versión 2026. El mapa 2020 v3 refleja, entonces, la versión de febrero de 2025 del servicio de SINAC, que ya no coincide con la vigente.

### ASP: los polígonos no cambiaron; la diferencia es el efecto de la rasterización

Los 50 polígonos de parques nacionales, reservas biológicas y monumentos naturales presentes en ambas versiones son **idénticos** (desplazamiento 0.00 m, incluido el Parque Nacional Chirripó, sitio de la captura 3). En el sitio de la captura 3 el punto medido está a 6 m dentro del borde del polígono y el borde del raster está en la celda contigua: es el efecto esperado de rasterizar a celdas de 10 m con la regla del centro de celda de `terra::rasterize()`, que produce diferencias de hasta una celda respecto al vector.

Cambios de fuente entre versiones (no relacionados con el desplazamiento): en la versión de 2026 aparecen el Monumento Natural Zona de los Santos e Isla San Lucas como parque nacional (antes refugio nacional de vida silvestre), y el Parque Internacional La Amistad cambió de geometría.

### Causas descartadas

- **Reproyección.** Ambas capas ya venían del servicio en EPSG:5367 (CR05 / CRTM05), el CRS del mapa, por lo que `st_transform(5367)` no modificó coordenadas. La transformación CR05 → CR-SIRGAS (EPSG:5367 → 8908; operación "CR05 to CR-SIRGAS (1)" de PROJ, exactitud declarada 0.5 m) mueve los puntos de prueba entre 0.01 y 0.14 m, tres órdenes de magnitud por debajo de los desplazamientos observados.
- **`st_make_valid()`.** Corrige la topología de polígonos inválidos (anillos que se cruzan, etc.) sin trasladar geometrías; no puede producir desplazamientos de cientos de metros con la forma intacta.
- **Rasterización.** Solo explica diferencias de hasta una celda (10 m), como las observadas en ASP.

## Conclusiones

1. El desplazamiento de la clase PNE del MAF2020 v3 se debe a que **SINAC corrigió la posición de unos 330 polígonos (26 %) de su capa de PNE entre febrero de 2025 y junio de 2026**. El mapa reproduce fielmente la versión de febrero de 2025.
2. Las diferencias en la clase ASP (~9 m) son el **efecto normal de la rasterización** a 10 m; los polígonos de parques nacionales, reservas biológicas y monumentos naturales no cambiaron entre versiones.
3. Ni la reproyección ni `st_make_valid()` intervienen en el problema.
4. Las capas de PNE y ASP son capas administrativas que cambian en el tiempo (sobre todo PNE), a diferencia de las capas de uso de la tierra derivadas de sensores remotos. Tiene sentido la decisión de MAG-MINAE de **excluirlas del mapa como máscaras** y consultarlas como capas vectoriales independientes en el visor geoespacial, siempre en su versión vigente.

## Versión 4 del mapa 2020

La versión 4 se generó con la misma rutina de la versión 3, omitiendo las capas de PNE (código intermedio 204) y ASP (202) en la combinación jerárquica (`programas/combinacion-v4.R`, `programas/reclasificacion-v4.R`). Ninguna otra capa cambió. Ver el resultado de la verificación en la sección siguiente y el README del repositorio.

### Verificación de la versión 4 (`programas/verificacion-v4.R`)

- Misma grilla que la versión 3: 35 194 filas × 37 212 columnas, celdas de 10 m, EPSG:5367.
- La versión 4 tiene 16 clases (ya no existen las clases 2 ni 4) y es **idéntica a la versión 3 en todas las celdas** donde la versión 3 no tenía las clases 2 ni 4 (0 celdas cambiadas fuera de esas dos clases).
- Las celdas que ocupaban las clases 2 y 4 pasaron a las clases de las capas subyacentes (`salidas/transicion-v3-v4.csv`):

| Clase de la versión 3 | Área | Destino principal en la versión 4 |
|---|---|---|
| 2, Parque nacional, reserva biológica o monumento natural | 661 222 ha | Cobertura forestal 94.6 %, pasto 3.3 %, páramo 1.1 %, suelo desnudo 0.5 %, cultivo 0.2 %, otras 0.3 % |
| 4, Patrimonio natural del estado | 33 871 ha | Cobertura forestal 87.8 %, pasto 8.0 %, cultivo 2.4 %, suelo desnudo 0.4 %, cuerpo de agua 0.4 %, caña 0.4 %, otras 0.6 % |

- 68 889 celdas (689 ha; 0.01 % del mapa) quedaron sin dato en la versión 4 porque en ellas solo las capas de ASP o PNE tenían información (por ejemplo, islotes y franjas costeras fuera de la cobertura del mapa REDD).
- En los tres sitios de las capturas de pantalla la versión 4 tiene la clase 15 (cobertura forestal), donde la versión 3 tenía las clases 4, 15 y 2, respectivamente.

### Estadísticas de la versión 4 (`salidas/estadisticas-v4.csv`)

| Código | Clase | Hectáreas | Proporción |
|---|---|---|---|
| 1 | Red vial | 7 346 | 0.14 % |
| 3 | Cuerpo de agua | 24 881 | 0.49 % |
| 5 | Caña | 62 582 | 1.23 % |
| 6 | Banano | 54 367 | 1.06 % |
| 7 | Café | 93 459 | 1.83 % |
| 8 | Cacao | 973 | 0.02 % |
| 9 | Pasto | 1 356 524 | 26.56 % |
| 10 | Palma | 73 715 | 1.44 % |
| 11 | Piña | 65 103 | 1.27 % |
| 12 | Cultivo | 329 010 | 6.44 % |
| 13 | Páramo | 7 400 | 0.14 % |
| 14 | Plantación forestal | 28 446 | 0.56 % |
| 15 | Cobertura forestal | 2 910 756 | 56.99 % |
| 16 | Suelo desnudo | 35 915 | 0.70 % |
| 17 | Zona urbana | 46 394 | 0.91 % |
| 18 | Sin información | 10 999 | 0.22 % |

Productos de la versión 4 en `salidas/`: `mapa-agropecuario-forestal-2020-v4.tif` (GeoTIFF comprimido con ZSTD), `mapa-agropecuario-forestal-2020-v4.tif.vat.dbf` (tabla de atributos), `mapa-agropecuario-forestal-2020-v4.png`, `estadisticas-v4.csv`, `transicion-v3-v4.csv`; estilo de QGIS en `qgis/bak/mapa-agropecuario-forestal-2020-v4.qml`.

## Pendiente

- Validar la versión 4 con la malla de puntos de control que preparan MAG-MINAE.
- Aplicar el mismo cambio al mapa 2023 cuando MAG-MINAE lo confirmen.

