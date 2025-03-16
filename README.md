# Mapa de referencia de tierras agropecuarias y de cobertura forestal de Costa Rica para el año 2020

Este repositorio contiene un mapa de referencia de tierras agropecuarias y de cobertura forestal de Costa Rica para el año 2020, junto con el código fuente y la documentación utilizados para generarlo.

## Flujo de trabajo

1. Remuestreo de capas raster: `programas/remuestreo.R`
    - Entradas
        - Directorio de capas raster originales: `datos/originales/raster`
    - Salidas
        - Directorio de capas remuestreadas: `datos/procesados/remuestreados`

2. Rasterización de capas vectoriales: `programas/rasterizacion.R`
    - Entradas
        - Directorio de capas vectoriales originales: `datos/originales/vectoriales`
    - Salidas
        - Directorio de capas rasterizadas: `datos/procesados/rasterizados`

3. Combinación de capas remuestreadas y rasterizadas: `programas/combinacion.R`
    - Entradas
        - Directorio de capas rasterizadas: `datos/procesados/rasterizados`
        - Directorio de capas remuestreadas: `datos/procesados/remuestreados`
    - Salidas
        - Archivo raster de capa de uso agropecuario forestal inicial: `salidas/mapa-agropecuario-forestal-2020-inicial.tif`

4. Reclasificación de la capa combinada: `programas/reclasificacion.R`
    - Entradas
        - Archivo raster de capa de uso agropecuario forestal inicial: `salidas/mapa-agropecuario-forestal-2020-inicial.tif`
    - Salidas
        - Archivo raster de capa de uso agropecuario forestal inicial reclasificada: `salidas/mapa-agropecuario-forestal-2020-inicial-reclasificado.tif`

5. Compresión de la capa reclasificada: `programas/compresion-salidas.sh`
    - Entradas
        - Archivo raster de capa de uso agropecuario forestal inicial reclasificada: `salidas/mapa-agropecuario-forestal-2020-inicial-reclasificado.tif`
    - Salidas
        - Archivo raster de capa de uso agropecuario forestal (comprimida): `salidas/mapa-agropecuario-forestal-2020.tif`

6. Generación de estadísticas: `programas/generacion-estadisticas.R`
    - Entradas
        - Archivo raster de capa de uso agropecuario forestal (comprimida): `salidas/mapa-agropecuario-forestal-2020.tif`
    - Salidas
        - Archivo CSV con estadísticas: `salidas/estadisticas.csv`

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
