# Mapa de referencia de tierras agropecuarias y de cobertura forestal de Costa Rica para el año 2020

Este repositorio contiene un mapa de referencia de tierras agropecuarias y de cobertura forestal de Costa Rica para el año 2020, junto con el código fuente y la documentación utilizados para generarlo.

## Versiones del mapa

| Versión | Fecha | Cambio respecto a la versión anterior | Archivo raster |
|---|---|---|---|
| 1 | 2025-03 | Versión inicial, con las 18 clases. | `salidas/mapa-agropecuario-forestal-2020.tif` |
| 2 | 2025-09 | Se omiten los humedales (Registro Nacional de Humedales y cuerpos de agua REDD). | `salidas/mapa-agropecuario-forestal-2020-v2.tif` |
| 3 | 2025-10 | Se reincorporan los cuerpos de agua REDD (clase 3, "Cuerpo de agua"). Es la versión publicada en el SNIT. | `salidas/mapa-agropecuario-forestal-2020-v3.tif` |
| 4 | 2026-09 | Se omiten las capas máscara de Áreas Silvestres Protegidas (ASP, clase 2) y de Patrimonio Natural del Estado (PNE, clase 4). | `salidas/mapa-agropecuario-forestal-2020-v4.tif` |

Cada versión nueva se genera con copias `-vN` de los programas que cambiaron; los programas sin sufijo corresponden a la versión 1. Los archivos de estilo de QGIS de cada versión están en `qgis/bak/`.

## Flujo de trabajo

1. Remuestreo de capas raster: `programas/remuestreo.R` / `programas/remuestreo-v3.R`
    - Entradas
        - Directorio de capas raster originales: `datos/originales/raster`
    - Salidas
        - Directorio de capas remuestreadas: `datos/procesados/remuestreados`

2. Rasterización de capas vectoriales: `programas/rasterizacion.R`
    - Entradas
        - Directorio de capas vectoriales originales: `datos/originales/vectoriales`
    - Salidas
        - Directorio de capas rasterizadas: `datos/procesados/rasterizados`

3. Combinación de capas remuestreadas y rasterizadas: `programas/combinacion.R` / `programas/combinacion-v2.R` / `programas/combinacion-v3.R` / `programas/combinacion-v4.R`
    - Entradas
        - Directorio de capas rasterizadas: `datos/procesados/rasterizados`
        - Directorio de capas remuestreadas: `datos/procesados/remuestreados`
    - Salidas
        - Archivo raster de capa de uso agropecuario forestal inicial: `salidas/mapa-agropecuario-forestal-2020-inicial.tif` / `salidas/mapa-agropecuario-forestal-2020-inicial-v2.tif` / `salidas/mapa-agropecuario-forestal-2020-inicial-v3.tif` / `salidas/mapa-agropecuario-forestal-2020-inicial-v4.tif`

4. Reclasificación de la capa combinada: `programas/reclasificacion.R` / `programas/reclasificacion-v2.R` / `programas/reclasificacion-v3.R` / `programas/reclasificacion-v4.R`
    - Entradas
        - Archivo raster de capa de uso agropecuario forestal inicial: `salidas/mapa-agropecuario-forestal-2020-inicial.tif` / `salidas/mapa-agropecuario-forestal-2020-inicial-v2.tif` / `salidas/mapa-agropecuario-forestal-2020-inicial-v3.tif` / `salidas/mapa-agropecuario-forestal-2020-inicial-v4.tif`
    - Salidas
        - Archivo raster de capa de uso agropecuario forestal inicial reclasificada: `salidas/mapa-agropecuario-forestal-2020-inicial-reclasificado.tif` / `salidas/mapa-agropecuario-forestal-2020-inicial-reclasificado-v2.tif` / `salidas/mapa-agropecuario-forestal-2020-inicial-reclasificado-v3.tif` / `salidas/mapa-agropecuario-forestal-2020-inicial-reclasificado-v4.tif`

5. Compresión de la capa reclasificada: `programas/compresion-salidas.sh` / `programas/compresion-salidas-v2.sh` / `programas/compresion-salidas-v3.sh` / `programas/compresion-salidas-v4.sh`
    - Entradas
        - Archivo raster de capa de uso agropecuario forestal inicial reclasificada: `salidas/mapa-agropecuario-forestal-2020-inicial-reclasificado.tif` / `salidas/mapa-agropecuario-forestal-2020-inicial-reclasificado-v2.tif` / `salidas/mapa-agropecuario-forestal-2020-inicial-reclasificado-v3.tif` / `salidas/mapa-agropecuario-forestal-2020-inicial-reclasificado-v4.tif`
    - Salidas
        - Archivo raster de capa de uso agropecuario forestal (comprimida): `salidas/mapa-agropecuario-forestal-2020.tif` / `salidas/mapa-agropecuario-forestal-2020-v2.tif` / `salidas/mapa-agropecuario-forestal-2020-v3.tif` / `salidas/mapa-agropecuario-forestal-2020-v4.tif`

6. Generación de estadísticas: `programas/generacion-estadisticas.R` / `programas/generacion-estadisticas-v2.R` / `programas/generacion-estadisticas-v3.R` / `programas/generacion-estadisticas-v4.R`
    - Entradas
        - Archivo raster de capa de uso agropecuario forestal (comprimida): `salidas/mapa-agropecuario-forestal-2020.tif` / `salidas/mapa-agropecuario-forestal-2020-v2.tif` / `salidas/mapa-agropecuario-forestal-2020-v3.tif` / `salidas/mapa-agropecuario-forestal-2020-v4.tif`
    - Salidas
        - Archivo CSV con estadísticas: `salidas/estadisticas.csv` / `salidas/estadisticas-v2.csv` / `salidas/estadisticas-v3.csv` / `salidas/estadisticas-v4.csv`

7. Generación de la tabla de atributos del raster (a partir de la versión 4; en las versiones anteriores se generó con QGIS): `programas/generacion-tabla-atributos-v4.R`
    - Entradas
        - Archivo raster de capa de uso agropecuario forestal (comprimida): `salidas/mapa-agropecuario-forestal-2020-v4.tif`
    - Salidas
        - Tabla de atributos: `salidas/mapa-agropecuario-forestal-2020-v4.tif.vat.dbf` y `salidas/mapa-agropecuario-forestal-2020-v4.tif.vat.cpg`

8. Generación de los archivos PNG de las cuatro versiones del mapa, con una misma plantilla (título, leyenda, contorno del país, escala y norte): `programas/generacion-png.R` (acepta como argumento el número de versión; sin argumento genera las cuatro)
    - Entradas
        - Archivos raster de capa de uso agropecuario forestal (comprimida): `salidas/mapa-agropecuario-forestal-2020.tif` / `salidas/mapa-agropecuario-forestal-2020-v2.tif` / `salidas/mapa-agropecuario-forestal-2020-v3.tif` / `salidas/mapa-agropecuario-forestal-2020-v4.tif`
        - Contorno de Costa Rica: `datos/originales/vectoriales/costarica.gpkg`
        - Contornos de Nicaragua y Panamá: `datos/originales/vectoriales/paises-vecinos-natural-earth.gpkg` (capa "Admin 0 – Countries" 1:10 M de [Natural Earth](https://www.naturalearthdata.com/), dominio público, descargada el 2026-09-27 y reproyectada a EPSG:5367; opcional)
    - Salidas
        - Archivos PNG: `salidas/mapa-agropecuario-forestal-2020-v1.png` / `salidas/mapa-agropecuario-forestal-2020-v2.png` / `salidas/mapa-agropecuario-forestal-2020-v3.png` / `salidas/mapa-agropecuario-forestal-2020-v4.png`

9. Verificación de la versión 4 respecto a la versión 3: `programas/verificacion-v4.R`
    - Entradas
        - `salidas/mapa-agropecuario-forestal-2020-v3.tif` y `salidas/mapa-agropecuario-forestal-2020-v4.tif`
    - Salidas
        - Matriz de transición de clases entre versiones: `salidas/transicion-v3-v4.csv`

Programas auxiliares:

- `programas/descarga-capas-wfs.qmd`: descarga de capas vectoriales desde servicios WFS.

## Manejo del contenedor Docker

### Generación de la imagen a partir del archivo Dockerfile

```shell
# Generación de la imagen Docker a partir del archivo Dockerfile
docker build -t mapa-agropecuario-forestal-2020 .
```

### Ejecución del contenedor

```shell
# Ejecución del contenedor Docker
# (el directorio local debe especificarse en la opción -v)
# (el archivo con variables de ambiente debe especificarse en la opción --env-file)
docker run -d --name mapa-agropecuario-forestal-2020 \
  -p 8787:8787 \
  -v ~/mapa-agropecuario-forestal/2020/github:/home/rstudio \
  --env-file ~/mapa-agropecuario-forestal-2020.env \
  mapa-agropecuario-forestal-2020
```
  
### Acceso al contenedor (username=rstudio, password=agropecuario)

[http://localhost:8787](http://localhost:8787)

### Detención, inicio y borrado del contenedor

```shell
# Detención del contenedor Docker
docker stop mapa-agropecuario-forestal-2020

# Inicio del contenedor Docker
docker start mapa-agropecuario-forestal-2020

# Borrado del contenedor Docker
docker rm mapa-agropecuario-forestal-2020
```

### Ejemplo de contenido del archivo `~/mapa-agropecuario-forestal-2020.env`

```shell
# Clave para ingresar a RStudio
PASSWORD=agropecuario
```
