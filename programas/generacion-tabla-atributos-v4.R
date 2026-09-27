#
# GENERACIÓN DE LA TABLA DE ATRIBUTOS DEL RASTER (VERSIÓN 4)
#
# Escribe el archivo .vat.dbf (y su .vat.cpg) que QGIS y ArcGIS usan como
# tabla de atributos del raster. En las versiones 1 a 3 esta tabla se
# generó manualmente con QGIS; aquí se genera con código para que sea
# reproducible. Las columnas y los valores replican los de la versión 3,
# sin las clases 2 (ASP) y 4 (PNE), que se omiten en la versión 4.
#
# Debe ejecutarse DESPUÉS de generacion-estadisticas-v4.R: cuando existe
# el .vat.dbf, terra lee el raster como categórico y freq() devuelve
# etiquetas en lugar de códigos.
#


# PAQUETES
library(here)
library(foreign)


# PARÁMETROS GENERALES

# Archivo raster de capa de uso agropecuario forestal (comprimida)
ARCHIVO_RASTER_USO_AGROPECUARIO_FORESTAL <-
  here("salidas", "mapa-agropecuario-forestal-2020-v4.tif")

# Archivos de la tabla de atributos
ARCHIVO_VAT_DBF <- paste0(ARCHIVO_RASTER_USO_AGROPECUARIO_FORESTAL, ".vat.dbf")
ARCHIVO_VAT_CPG <- paste0(ARCHIVO_RASTER_USO_AGROPECUARIO_FORESTAL, ".vat.cpg")


# PROCESAMIENTO

cat("Generando tabla de atributos ...\n")

# Tabla de atributos (clases, fuentes y colores de qgis/colores.txt)
tabla_atributos <- data.frame(
  VALUE = c(1, 3, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18),
  CLASS = c(
    "Red vial",
    # "Parque nacional, reserva biológica o monumento natural", (se omite en v4)
    "Cuerpo de agua",
    # "Patrimonio natural del estado", (se omite en v4)
    "Caña",
    "Banano",
    "Café",
    "Cacao",
    "Pasto",
    "Palma",
    "Piña",
    "Cultivo",
    "Páramo",
    "Plantación forestal",
    "Cobertura forestal",
    "Suelo desnudo",
    "Zona urbana",
    "Sin información"
  ),
  SOURCE = c(
    "MOPT",
    # "SINAC", (ASP, se omite en v4)
    "Secretaría REDD+",
    # "SINAC", (PNE, se omite en v4)
    "Empresa privada",
    "Empresa privada",
    "Empresa privada",
    "IICA",
    "MOCUPP-UCR",
    "MOCUPP-PRIAS",
    "MOCUPP-PRIAS",
    "IGN",
    "Secretaría REDD+",
    "FONAFIFO",
    "SINAC",
    "Secretaría REDD+",
    "Secretaría REDD+",
    "Secretaría REDD+"
  ),
  RED   = c(248, 180, 255, 240, 115, 255, 255, 255, 255, 190, 100,  85,  38, 220, 246, 255),
  GREEN = c(  0, 230, 170, 240,  38, 210, 255, 161,  80, 205, 255, 255, 105, 220, 217, 255),
  BLUE  = c(  0, 250,   0,   0,   0, 125, 166,  20,   0,   0, 150,   0,   0, 220, 223, 255),
  ALPHA = rep(255, 16),
  stringsAsFactors = FALSE
)

# Escritura del .dbf y del .cpg (codificación UTF-8, como en la versión 3)
write.dbf(tabla_atributos, ARCHIVO_VAT_DBF)
writeLines("UTF-8", ARCHIVO_VAT_CPG, sep = "")

# Despliegue del resultado
print(tabla_atributos)

cat("Finalizado\n\n")

cat("FIN\n")
