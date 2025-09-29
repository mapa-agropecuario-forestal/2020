# En creacion-ambiente-gdal.sh se crea un ambiente conda con los programas de gdal
# Puede activarse con: conda activate gdal

gdal_translate -co compress=zstd -co zstd_level=9 \
  ../salidas/mapa-agropecuario-forestal-2020-inicial-reclasificado-v2.tif \
  ../salidas/mapa-agropecuario-forestal-2020-v2.tif
rm ../salidas/mapa-agropecuario-forestal-2020-inicial-v2.tif
rm ../salidas/mapa-agropecuario-forestal-2020-inicial-reclasificado-v2.tif
