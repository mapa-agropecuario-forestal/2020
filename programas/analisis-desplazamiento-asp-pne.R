#
# ANÁLISIS DEL DESPLAZAMIENTO DE LAS CAPAS DE ASP Y PNE
#
# MAG-MINAE reportaron (2026-09-17) que la clase 4 (Patrimonio Natural del
# Estado, PNE) del mapa 2020 v3 aparece desplazada hasta ~600 m respecto a
# la capa vectorial vigente de SINAC, y la clase 2 (ASP) ~9 m.
#
# Este programa compara, polígono por polígono, la versión de cada capa
# usada para generar el mapa 2020 con la versión publicada por el mismo
# servicio WFS de SINAC (geos1pne.sirefor.go.cr) en junio de 2026, y
# verifica que la rasterización y la transformación de coordenadas no
# introdujeron desplazamientos.
#
# Los polígonos se emparejan por FORMA IDÉNTICA (misma área, mismo número
# de vértices y mismo perímetro, redondeados al metro), lo que permite
# medir cuánto se movió cada polígono entre versiones, aunque haya cambiado
# de identificador.
#
# Insumos (no versionados, en datos/originales/vectoriales):
#   - patrimonio-natural-estado.gpkg           (WFS SINAC, 2025-02-12, usado en el mapa)
#   - patrimonio-natural-estado-2026-06.gpkg   (WFS SINAC, 2026-06-18)
#   - areas-silvestres-protegidas.gpkg         (WFS SINAC, 2024-05-22, usado en el mapa)
#   - areas-silvestres-protegidas-2026-06.gpkg (WFS SINAC, 2026-06-18)
#
# Salidas (en salidas/):
#   - desplazamiento-pne-2025-02-vs-2026-06.csv
#   - desplazamiento-asp-2024-05-vs-2026-06.csv
#


# PAQUETES
library(here)
library(dplyr)
library(readr)
library(sf)
library(terra)


# PARÁMETROS GENERALES

DIRECTORIO_CAPAS_VECTORIALES_ORIGINALES <-
  here("datos", "originales", "vectoriales")
DIRECTORIO_CAPAS_RASTERIZADAS <-
  here("datos", "procesados", "rasterizados")

ARCHIVO_PNE_MAPA <-
  here(DIRECTORIO_CAPAS_VECTORIALES_ORIGINALES, "patrimonio-natural-estado.gpkg")
ARCHIVO_PNE_2026 <-
  here(DIRECTORIO_CAPAS_VECTORIALES_ORIGINALES, "patrimonio-natural-estado-2026-06.gpkg")
ARCHIVO_ASP_MAPA <-
  here(DIRECTORIO_CAPAS_VECTORIALES_ORIGINALES, "areas-silvestres-protegidas.gpkg")
ARCHIVO_ASP_2026 <-
  here(DIRECTORIO_CAPAS_VECTORIALES_ORIGINALES, "areas-silvestres-protegidas-2026-06.gpkg")

ARCHIVO_RASTER_PNE <-
  here(DIRECTORIO_CAPAS_RASTERIZADAS, "patrimonio-natural-estado.tif")
ARCHIVO_RASTER_ASP <-
  here(DIRECTORIO_CAPAS_RASTERIZADAS, "areas-silvestres-protegidas.tif")

ARCHIVO_CSV_PNE <-
  here("salidas", "desplazamiento-pne-2025-02-vs-2026-06.csv")
ARCHIVO_CSV_ASP <-
  here("salidas", "desplazamiento-asp-2024-05-vs-2026-06.csv")

# Categorías de manejo de ASP incluidas en el mapa (clase 2)
CATEGORIAS_ASP <- c("Parque Nacional", "Reserva Biologica", "Monumento Natural")

# Umbrales de desplazamiento (m) para el resumen
UMBRALES <- c(1, 10, 50, 100, 300, 600, 1000)

# Sitios de las capturas de pantalla enviadas por MAG-MINAE (2026-09-18),
# en CRTM05 (EPSG:5367)
SITIOS <- data.frame(
  sitio = c("Captura 1 (PNE, Tronadora)", "Captura 2 (PNE, Guanacaste)", "Captura 3 (ASP, Chirripó)"),
  plano = c("G-0233612-1995", "2-39592-1962", NA),
  x = c(410409.67, 350256.99, 559801.19),
  y = c(1152529.08, 1202468.42, 1037045.89)
)


# FUNCIONES

# Lee una capa y agrega llave de forma (área, vértices, perímetro).
# Las coordenadas se usan tal como las entrega el servicio: las descargas de
# 2026 se pidieron en EPSG:8908 (CR-SIRGAS) y las del mapa están en
# EPSG:5367 (CR05), pero la transformación entre ambos mueve las coordenadas
# apenas ~0.06 m (ver paso 4) y los polígonos no modificados por SINAC tienen
# coordenadas numéricamente idénticas en ambas descargas. Reproyectar con
# st_transform() perturbaría áreas y perímetros (la transformación Helmert
# incluye un factor de escala) y rompería el emparejamiento por forma, por
# lo que solo se declara el CRS 5367.
leer_con_llave <- function(archivo) {
  capa <- st_read(archivo, quiet = TRUE) |>
    st_set_crs(5367) |>
    suppressWarnings()
  capa |>
    mutate(
      area_m2 = as.numeric(st_area(capa)),
      perimetro_m = as.numeric(st_length(st_cast(st_boundary(capa), "MULTILINESTRING"))),
      vertices = mapply(function(g) nrow(st_coordinates(g)), st_geometry(capa)),
      llave = paste(round(area_m2), vertices, round(perimetro_m), sep = "|"),
      cx = st_coordinates(st_centroid(st_geometry(capa)))[, 1],
      cy = st_coordinates(st_centroid(st_geometry(capa)))[, 2]
    )
}

# Empareja dos versiones por llave de forma y calcula el desplazamiento
comparar_versiones <- function(capa_mapa, capa_2026, atributos) {
  a <- capa_mapa |> st_drop_geometry() |> distinct(llave, .keep_all = TRUE)
  b <- capa_2026 |> st_drop_geometry() |> distinct(llave, .keep_all = TRUE)
  comparacion <- a |>
    select(all_of(atributos), area_m2, vertices, llave, cx_mapa = cx, cy_mapa = cy) |>
    inner_join(
      b |> select(llave, cx_2026 = cx, cy_2026 = cy),
      by = "llave"
    ) |>
    mutate(
      dx_m = cx_2026 - cx_mapa,
      dy_m = cy_2026 - cy_mapa,
      desplazamiento_m = sqrt(dx_m^2 + dy_m^2)
    ) |>
    arrange(desc(desplazamiento_m))
  list(
    comparacion = comparacion,
    solo_mapa = sum(!(a$llave %in% b$llave)),
    solo_2026 = sum(!(b$llave %in% a$llave))
  )
}

# Resumen por umbrales
resumir <- function(comparacion, nombre) {
  cat(sprintf("\n%s\n", nombre))
  cat(sprintf("  Polígonos con forma idéntica en ambas versiones: %d\n", nrow(comparacion)))
  cat(sprintf("  Mediana del desplazamiento: %.1f m; máximo: %.1f m\n",
              median(comparacion$desplazamiento_m), max(comparacion$desplazamiento_m)))
  for (u in UMBRALES) {
    cat(sprintf("  Desplazados más de %5d m: %4d\n", u, sum(comparacion$desplazamiento_m > u)))
  }
}


# PROCESAMIENTO

# 1. PNE

cat("1/4 Comparando versiones de PNE (2025-02 vs 2026-06) ...\n")

pne_mapa <- leer_con_llave(ARCHIVO_PNE_MAPA)
pne_2026 <- leer_con_llave(ARCHIVO_PNE_2026)
cat(sprintf("  Polígonos: %d (2025-02) vs %d (2026-06)\n", nrow(pne_mapa), nrow(pne_2026)))

pne <- comparar_versiones(pne_mapa, pne_2026, c("plano", "nombre_asp", "categoria", "distrito"))
resumir(pne$comparacion, "PNE: desplazamiento del centroide entre versiones")
cat(sprintf("  Sin forma idéntica en la otra versión: %d (solo 2025-02), %d (solo 2026-06)\n",
            pne$solo_mapa, pne$solo_2026))

cat("\n  Desplazados (> 1 m) por categoría:\n")
pne$comparacion |>
  filter(desplazamiento_m > 1) |>
  count(categoria, sort = TRUE) |>
  head(10) |>
  print()

cat("\n  Mayores desplazamientos:\n")
pne$comparacion |>
  select(plano, nombre_asp, categoria, area_ha = area_m2, desplazamiento_m) |>
  mutate(area_ha = round(area_ha / 10000, 1), desplazamiento_m = round(desplazamiento_m)) |>
  head(10) |>
  print()

write_csv(pne$comparacion |> select(-llave), ARCHIVO_CSV_PNE)

cat("Finalizado\n\n")


# 2. ASP (solo las categorías del mapa)

cat("2/4 Comparando versiones de ASP (2024-05 vs 2026-06) ...\n")

asp_mapa <- leer_con_llave(ARCHIVO_ASP_MAPA) |> filter(cat_manejo %in% CATEGORIAS_ASP)
asp_2026 <- leer_con_llave(ARCHIVO_ASP_2026) |> filter(cat_manejo %in% CATEGORIAS_ASP)
cat(sprintf("  Polígonos PN/RB/MN: %d (2024-05) vs %d (2026-06)\n", nrow(asp_mapa), nrow(asp_2026)))

asp <- comparar_versiones(asp_mapa, asp_2026, c("codigo", "nombre_asp", "cat_manejo"))
resumir(asp$comparacion, "ASP: desplazamiento del centroide entre versiones")
cat(sprintf("  Sin forma idéntica en la otra versión: %d (solo 2024-05), %d (solo 2026-06)\n",
            asp$solo_mapa, asp$solo_2026))
cat("  Solo en 2024-05:", paste(asp_mapa$nombre_asp[!(asp_mapa$llave %in% asp_2026$llave)], collapse = "; "), "\n")
cat("  Solo en 2026-06:", paste(asp_2026$nombre_asp[!(asp_2026$llave %in% asp_mapa$llave)], collapse = "; "), "\n")

write_csv(asp$comparacion |> select(-llave), ARCHIVO_CSV_ASP)

cat("Finalizado\n\n")


# 3. Fidelidad de la rasterización en los sitios reportados

cat("3/4 Verificando la rasterización en los sitios de las capturas ...\n")

raster_pne <- rast(ARCHIVO_RASTER_PNE)
raster_asp <- rast(ARCHIVO_RASTER_ASP)

for (i in which(!is.na(SITIOS$plano))) {
  p <- SITIOS$plano[i]
  fila <- pne$comparacion |> filter(plano == p) |> slice(1)
  valor_mapa <- extract(raster_pne, cbind(fila$cx_mapa, fila$cy_mapa))[1, 1]
  valor_2026 <- extract(raster_pne, cbind(fila$cx_2026, fila$cy_2026))[1, 1]
  cat(sprintf("  %s, plano %s: desplazamiento %.0f m (dx %.0f, dy %.0f)\n",
              SITIOS$sitio[i], p, fila$desplazamiento_m, fila$dx_m, fila$dy_m))
  cat(sprintf("    Raster PNE en el centroide de la versión usada en el mapa: %s (se espera 204: la rasterización siguió al insumo)\n",
              ifelse(is.na(valor_mapa), "NA", valor_mapa)))
  cat(sprintf("    Raster PNE en el centroide de la versión 2026-06:         %s (NA si el desplazamiento supera el tamaño del polígono)\n",
              ifelse(is.na(valor_2026), "NA", valor_2026)))
}

# Sitio de ASP: distancia del punto al borde del polígono y valor del raster
punto_asp <- st_sfc(st_point(c(SITIOS$x[3], SITIOS$y[3])), crs = 5367)
chirripo <- asp_mapa |> filter(nombre_asp == "Chirripo")
distancia_borde <- as.numeric(st_distance(st_boundary(chirripo), punto_asp))
cat(sprintf("  %s: el punto está a %.1f m del borde del polígono; raster ASP en el punto: %s\n",
            SITIOS$sitio[3], distancia_borde,
            extract(raster_asp, cbind(SITIOS$x[3], SITIOS$y[3]))[1, 1]))
cat(sprintf("    Chirripó, desplazamiento entre versiones: %.2f m\n",
            (asp$comparacion |> filter(nombre_asp == "Chirripo"))$desplazamiento_m[1]))

cat("Finalizado\n\n")


# 4. Magnitud de la transformación CR05 (EPSG:5367) -> CR-SIRGAS (EPSG:8908)

cat("4/4 Verificando la magnitud de la transformación CR05 -> CR-SIRGAS ...\n")

puntos <- st_sfc(
  st_point(c(349630, 1202612)),
  st_point(c(410129, 1151735)),
  st_point(c(559801, 1037046)),
  crs = 5367
)
puntos_8908 <- st_transform(puntos, 8908)
diferencias <- sqrt(rowSums((st_coordinates(puntos_8908) - st_coordinates(puntos))^2))
cat(sprintf("  Diferencia de coordenadas al pasar de 5367 a 8908: %s m\n",
            paste(round(diferencias, 2), collapse = ", ")))
cat(sprintf("  CRS de los insumos: PNE %s, ASP %s\n",
            st_crs(pne_mapa)$epsg, st_crs(asp_mapa)$epsg))

cat("Finalizado\n\n")

cat("FIN\n")
