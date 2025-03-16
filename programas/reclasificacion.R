#
# RECLASIFICACIÓN DE CAPAS RASTER
#


# PAQUETES
library(here)
library(terra)


# PARÁMETROS GENERALES

# Archivo raster de capa de uso agropecuario forestal inicial
ARCHIVO_RASTER_USO_AGROPECUARIO_FORESTAL <-
  here("salidas", "mapa-agropecuario-forestal-2020-inicial.tif")

# Archivo raster de capa de uso agropecuario forestal inicial reclasificada
ARCHIVO_RASTER_USO_AGROPECUARIO_FORESTAL_RECLASIFICADO <-
  here("salidas", "mapa-agropecuario-forestal-2020-inicial-reclasificado.tif")


# PROCESAMIENTO

# Lectura del archivo raster de capa de uso agropecuario forestal
agropecuario_forestal_terra <- 
  rast(ARCHIVO_RASTER_USO_AGROPECUARIO_FORESTAL)

cat("Reclasificando ...\n")

# Matriz de reclasificación
matriz_reclasificacion <- 
  matrix(
    c(
      201, 201, 1,  # Red Vial Nacional
      202, 202, 2,  # Áreas Silvestres Protegidas
      203, 203, 3,  # Registro Nacional de Humedales
      101, 101, 3,  # REDD Cuerpos de agua
      204, 204, 4,  # Patrimonio Natural del Estado
      205, 205, 5,  # Caña
      206, 206, 6,  # Banano
      207, 207, 7,  # Café
      213, 213, 8,  # Cacao
      208, 208, 9,  # Pastos
      102, 102, 9,  # REDD Pastos
      209, 209, 10, # Palma
      210, 210, 11, # Piña
      211, 211, 12, # Cultivos
      104, 104, 12, # REDD Cultivos permanentes
      103, 103, 12, # REDD Cultivos anuales
      105, 105, 13, # REDD Páramos
      214, 214, 14, # Plantaciones forestales
      212, 212, 15, # Cobertura forestal
      106, 106, 15, # REDD Bosques
      107, 107, 16, # REDD Suelos desnudos
      108, 108, 17, # REDD Áreas urbanas
      109, 109, 18  # REDD Sin información
    ), 
    ncol = 3, byrow = TRUE
  )

# Reclasificación
agropecuario_forestal_terra_reclasificado <-
  classify(agropecuario_forestal_terra, matriz_reclasificacion, right=NA)

# Escritura
writeRaster(
  agropecuario_forestal_terra_reclasificado,
  ARCHIVO_RASTER_USO_AGROPECUARIO_FORESTAL_RECLASIFICADO,
  overwrite=TRUE
)

cat("Finalizado\n\n")

cat("FIN\n")