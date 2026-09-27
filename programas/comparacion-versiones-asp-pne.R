#
# COMPARACIÓN DE VERSIONES DE LAS CAPAS DE ASP Y PNE DE SINAC
#
# Compara la versión vigente de las capas de Áreas Silvestres Protegidas
# (ASP) y Patrimonio Natural del Estado (PNE) del WFS de SINAC
# (geos1pne.sirefor.go.cr, que alimenta el nodo SINAC del SNIT) con las
# versiones usadas en los mapas 2020 y 2023, para determinar si hay
# diferencias. Complementa a analisis-desplazamiento-asp-pne.R.
#
# Versiones (todas descargadas del mismo servicio WFS):
#   PNE: 2025-02-12 (mapa 2020) · 2026-06-18 (mapa 2023) · 2026-09-27 (vigente)
#   ASP: 2024-05-22 (mapa 2020) · 2026-06-18 (mapa 2023) · 2026-09-27 (vigente)
#
# Emparejamiento: dos polígonos de versiones distintas se consideran "el
# mismo polígono" si tienen igual número de vértices y la misma área y
# perímetro dentro de una tolerancia RELATIVA (TOLERANCIA_RELATIVA, con un
# piso absoluto de 1 m² / 1 m). La tolerancia es necesaria porque las
# coordenadas de la descarga de 2026-09-27 difieren ~0.07 m de las
# anteriores para polígonos que no cambiaron (efecto del paso
# CR05 <-> CR-SIRGAS en el servidor), lo que altera áreas y perímetros en
# proporción al tamaño del polígono. Un polígono emparejado se considera
# DESPLAZADO si su centroide se movió más de UMBRAL_DESPLAZAMIENTO_M.
#
# Insumos (no versionados, en datos/originales/vectoriales):
#   patrimonio-natural-estado.gpkg, patrimonio-natural-estado-2026-06.gpkg,
#   patrimonio-natural-estado-2026-09-27.gpkg, areas-silvestres-protegidas.gpkg,
#   areas-silvestres-protegidas-2026-06.gpkg, areas-silvestres-protegidas-2026-09-27.gpkg
#
# Salidas (en salidas/):
#   comparacion-versiones-{pne,asp}-resumen.csv (resumen por par de versiones)
#   comparacion-versiones-{pne,asp}-<a>-vs-<b>.csv (detalle por polígono)
#


# PAQUETES
library(here)
library(dplyr)
library(readr)
library(sf)


# PARÁMETROS GENERALES

DIRECTORIO_CAPAS_VECTORIALES_ORIGINALES <-
  here("datos", "originales", "vectoriales")
DIRECTORIO_SALIDAS <- here("salidas")

VERSIONES_PNE <- list(
  list(etiqueta = "2025-02", uso = "mapa 2020",         archivo = "patrimonio-natural-estado.gpkg"),
  list(etiqueta = "2026-06", uso = "mapa 2023",         archivo = "patrimonio-natural-estado-2026-06.gpkg"),
  list(etiqueta = "2026-09", uso = "vigente 2026-09-27", archivo = "patrimonio-natural-estado-2026-09-27.gpkg")
)
VERSIONES_ASP <- list(
  list(etiqueta = "2024-05", uso = "mapa 2020",         archivo = "areas-silvestres-protegidas.gpkg"),
  list(etiqueta = "2026-06", uso = "mapa 2023",         archivo = "areas-silvestres-protegidas-2026-06.gpkg"),
  list(etiqueta = "2026-09", uso = "vigente 2026-09-27", archivo = "areas-silvestres-protegidas-2026-09-27.gpkg")
)

# Pares a comparar (índices en las listas anteriores): vigente vs cada mapa,
# y mapa 2023 vs mapa 2020 para completar la serie
PARES <- list(c(1, 3), c(2, 3), c(1, 2))

# Categorías de manejo de ASP incluidas en el mapa (clase 2)
CATEGORIAS_ASP <- c("Parque Nacional", "Reserva Biologica", "Monumento Natural")

TOLERANCIA_RELATIVA <- 1e-4  # 0.01 % del área y del perímetro
UMBRAL_DESPLAZAMIENTO_M <- 1
UMBRALES <- c(1, 10, 100, 600)


# FUNCIONES

# Lee una capa (coordenadas tal como las entrega el servicio, CRS 5367) y
# calcula área, perímetro, vértices y centroide de cada polígono
leer_capa <- function(archivo) {
  capa <- st_read(archivo, quiet = TRUE) |>
    st_set_crs(5367) |>
    suppressWarnings() |>
    st_cast("MULTIPOLYGON") |>
    suppressWarnings()
  capa |>
    mutate(
      area_m2 = as.numeric(st_area(capa)),
      perimetro_m = as.numeric(st_length(st_cast(st_boundary(capa), "MULTILINESTRING"))),
      vertices = mapply(function(g) nrow(st_coordinates(g)), st_geometry(capa)),
      cx = st_coordinates(st_centroid(st_geometry(capa)))[, 1],
      cy = st_coordinates(st_centroid(st_geometry(capa)))[, 2]
    ) |>
    st_drop_geometry()
}

# Empareja los polígonos de a con los de b por vértices + área + perímetro
# (con tolerancia); si hay varios candidatos, toma el de centroide más cercano
emparejar <- function(a, b, atributos) {
  a <- a |> mutate(id_a = row_number())
  b <- b |> mutate(id_b = row_number())
  candidatos <- a |>
    select(id_a, vertices, area_a = area_m2, perimetro_a = perimetro_m, cx_a = cx, cy_a = cy) |>
    inner_join(
      b |> select(id_b, vertices, area_b = area_m2, perimetro_b = perimetro_m, cx_b = cx, cy_b = cy),
      by = "vertices", relationship = "many-to-many"
    ) |>
    filter(
      abs(area_a - area_b) <= pmax(1, TOLERANCIA_RELATIVA * area_a),
      abs(perimetro_a - perimetro_b) <= pmax(1, TOLERANCIA_RELATIVA * perimetro_a)
    ) |>
    mutate(desplazamiento_m = sqrt((cx_b - cx_a)^2 + (cy_b - cy_a)^2)) |>
    arrange(desplazamiento_m) |>
    distinct(id_a, .keep_all = TRUE) |>
    distinct(id_b, .keep_all = TRUE)
  parejas <- candidatos |>
    inner_join(a |> select(id_a, all_of(atributos)), by = "id_a") |>
    transmute(
      across(all_of(atributos)),
      area_m2 = area_a, vertices,
      cx_a, cy_a, cx_b, cy_b,
      dx_m = cx_b - cx_a, dy_m = cy_b - cy_a, desplazamiento_m
    ) |>
    arrange(desc(desplazamiento_m))
  list(
    parejas = parejas,
    solo_a = a |> filter(!(id_a %in% candidatos$id_a)),
    solo_b = b |> filter(!(id_b %in% candidatos$id_b))
  )
}

# Compara dos versiones y devuelve una fila de resumen (imprime el detalle)
comparar <- function(nombre_capa, va, vb, a, b, atributos, prefijo_csv) {
  cat(sprintf("\n%s: %s (%s) -> %s (%s)\n", nombre_capa, va$etiqueta, va$uso, vb$etiqueta, vb$uso))
  e <- emparejar(a, b, atributos)
  p <- e$parejas
  resumen <- data.frame(
    capa = nombre_capa,
    version_a = va$etiqueta, uso_a = va$uso, version_b = vb$etiqueta, uso_b = vb$uso,
    poligonos_a = nrow(a), poligonos_b = nrow(b),
    area_total_ha_a = round(sum(a$area_m2) / 1e4, 1),
    area_total_ha_b = round(sum(b$area_m2) / 1e4, 1),
    emparejados = nrow(p),
    sin_cambio = sum(p$desplazamiento_m <= UMBRAL_DESPLAZAMIENTO_M),
    desplazados_1m = sum(p$desplazamiento_m > 1),
    desplazados_10m = sum(p$desplazamiento_m > 10),
    desplazados_100m = sum(p$desplazamiento_m > 100),
    desplazados_600m = sum(p$desplazamiento_m > 600),
    desplazamiento_max_m = round(max(p$desplazamiento_m), 1),
    solo_en_a = nrow(e$solo_a),
    solo_en_b = nrow(e$solo_b),
    area_solo_en_a_ha = round(sum(e$solo_a$area_m2) / 1e4, 1),
    area_solo_en_b_ha = round(sum(e$solo_b$area_m2) / 1e4, 1)
  )
  cat(sprintf("  Polígonos: %d -> %d; área total: %.0f -> %.0f ha\n",
              resumen$poligonos_a, resumen$poligonos_b, resumen$area_total_ha_a, resumen$area_total_ha_b))
  cat(sprintf("  Emparejados (misma forma): %d; sin cambio (<= %g m): %d\n",
              resumen$emparejados, UMBRAL_DESPLAZAMIENTO_M, resumen$sin_cambio))
  for (u in UMBRALES) cat(sprintf("  Desplazados más de %4d m: %4d\n", u, sum(p$desplazamiento_m > u)))
  cat(sprintf("  Desplazamiento máximo: %.0f m\n", resumen$desplazamiento_max_m))
  cat(sprintf("  Solo en %s: %d polígonos (%.0f ha); solo en %s: %d polígonos (%.0f ha)\n",
              va$etiqueta, resumen$solo_en_a, resumen$area_solo_en_a_ha,
              vb$etiqueta, resumen$solo_en_b, resumen$area_solo_en_b_ha))
  write_csv(p, file.path(DIRECTORIO_SALIDAS, sprintf("%s-%s-vs-%s.csv", prefijo_csv, va$etiqueta, vb$etiqueta)))
  list(resumen = resumen, emparejamiento = e)
}


# PROCESAMIENTO

# 1. PNE

cat("1/2 Comparando versiones de PNE ...\n")

pne <- lapply(VERSIONES_PNE, function(v) leer_capa(here(DIRECTORIO_CAPAS_VECTORIALES_ORIGINALES, v$archivo)))
for (i in seq_along(pne)) {
  cat(sprintf("  %s (%s): %d polígonos, %.0f ha\n", VERSIONES_PNE[[i]]$etiqueta, VERSIONES_PNE[[i]]$uso,
              nrow(pne[[i]]), sum(pne[[i]]$area_m2) / 1e4))
}

resumen_pne <- list()
for (par in PARES) {
  r <- comparar("PNE", VERSIONES_PNE[[par[1]]], VERSIONES_PNE[[par[2]]], pne[[par[1]]], pne[[par[2]]],
                c("plano", "nombre_asp", "categoria", "distrito"), "comparacion-versiones-pne")
  resumen_pne[[length(resumen_pne) + 1]] <- r$resumen
  if (identical(par, c(2L, 3L)) || identical(par, c(2, 3))) {
    cat("\n  Mayores desplazamientos entre el mapa 2023 y la versión vigente:\n")
    r$emparejamiento$parejas |>
      transmute(plano, nombre_asp, categoria, area_ha = round(area_m2 / 1e4, 1), desplazamiento_m = round(desplazamiento_m)) |>
      head(10) |>
      print()
    cat("\n  Polígonos nuevos en la versión vigente (mayores):\n")
    r$emparejamiento$solo_b |>
      transmute(plano, nombre_asp, categoria, area_ha = round(area_m2 / 1e4, 1)) |>
      arrange(desc(area_ha)) |>
      head(10) |>
      print()
  }
}
write_csv(bind_rows(resumen_pne), file.path(DIRECTORIO_SALIDAS, "comparacion-versiones-pne-resumen.csv"))

# Sitios de las capturas de MAG-MINAE en las tres versiones
cat("\n  Planos de las capturas de pantalla (centroide en cada versión):\n")
for (p in c("G-0233612-1995", "2-39592-1962")) {
  for (i in seq_along(pne)) {
    f <- pne[[i]] |> filter(trimws(plano) == p)
    for (j in seq_len(nrow(f))) {
      cat(sprintf("    %s  %s: centroide (%.0f, %.0f), %.1f ha\n", p, VERSIONES_PNE[[i]]$etiqueta,
                  f$cx[j], f$cy[j], f$area_m2[j] / 1e4))
    }
  }
}

cat("Finalizado\n\n")


# 2. ASP (categorías del mapa)

cat("2/2 Comparando versiones de ASP (parques nacionales, reservas biológicas y monumentos naturales) ...\n")

asp <- lapply(VERSIONES_ASP, function(v) {
  leer_capa(here(DIRECTORIO_CAPAS_VECTORIALES_ORIGINALES, v$archivo)) |>
    filter(cat_manejo %in% CATEGORIAS_ASP)
})
for (i in seq_along(asp)) {
  cat(sprintf("  %s (%s): %d polígonos, %.0f ha\n", VERSIONES_ASP[[i]]$etiqueta, VERSIONES_ASP[[i]]$uso,
              nrow(asp[[i]]), sum(asp[[i]]$area_m2) / 1e4))
}

resumen_asp <- list()
for (par in PARES) {
  r <- comparar("ASP (PN/RB/MN)", VERSIONES_ASP[[par[1]]], VERSIONES_ASP[[par[2]]], asp[[par[1]]], asp[[par[2]]],
                c("codigo", "nombre_asp", "cat_manejo"), "comparacion-versiones-asp")
  resumen_asp[[length(resumen_asp) + 1]] <- r$resumen
  if (nrow(r$emparejamiento$solo_a) > 0)
    cat("    Solo en", VERSIONES_ASP[[par[1]]]$etiqueta, ":",
        paste(sprintf("%s (%.0f ha)", r$emparejamiento$solo_a$nombre_asp, r$emparejamiento$solo_a$area_m2 / 1e4), collapse = "; "), "\n")
  if (nrow(r$emparejamiento$solo_b) > 0)
    cat("    Solo en", VERSIONES_ASP[[par[2]]]$etiqueta, ":",
        paste(sprintf("%s (%.0f ha)", r$emparejamiento$solo_b$nombre_asp, r$emparejamiento$solo_b$area_m2 / 1e4), collapse = "; "), "\n")
}
write_csv(bind_rows(resumen_asp), file.path(DIRECTORIO_SALIDAS, "comparacion-versiones-asp-resumen.csv"))

cat("Finalizado\n\n")

cat("FIN\n")
