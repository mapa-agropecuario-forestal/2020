# En creacion-ambiente-gdal.sh se crea un ambiente conda con los programas de gdal
# Puede activarse con: conda activate gdal

gdal_translate -co compress=zstd -co zstd_level=9 \
  ../salidas/mapa-agropecuario-forestal-2020-inicial-reclasificado.tif \
  ../salidas/mapa-agropecuario-forestal-2020.tif
rm ../salidas/mapa-agropecuario-forestal-2020-inicial.tif
rm ../salidas/mapa-agropecuario-forestal-2020-inicial-reclasificado.tif
