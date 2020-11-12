#!/bin/bash
#
# --------------------------------------------------------------------------------------------------
#  Set dates
# --------------------------------------------------------------------------------------------------
#yesterday=$(date -d "$today 1 day ago" +%Y%m%d)
str_date=$1
initdate=$(date -d "${str_date}" +%Y-%m-%d)
#enddate=$(date -d "$2" +%Y-%m-%d)
#outdate=$1
#enddate=$(date -d "$1 -1 days" +%Y-%m-%d)
path=$2
# --------------------------------------------------------------------------------------------------
#  Change to local working directory
# --------------------------------------------------------------------------------------------------
#cd "$(dirname "$(readlink -f "$0")")"

# --------------------------------------------------------------------------------------------------
#  Remove previous GRIB
# --------------------------------------------------------------------------------------------------
#[[ -f ${yesterday}_forecast.grb ]] && rm ${yesterday}_forecast.grb
#[[ -f ${yesterday}_forecast.grb ]] && rm ${yesterday}_forecast.grb

# --------------------------------------------------------------------------------------------------
#  Update arkimet query configuration files
# --------------------------------------------------------------------------------------------------

cat > query.forecast.UGRD << EOF
origin:GRIB1,80,,12
reftime: ==$initdate 00:00
level:GRIB1,105,10
product:GRIB1,80,2,33
proddef: GRIB:tod=1

EOF

cat > query.forecast.VGRD << EOF
origin:GRIB1,80,,12
reftime: ==$initdate 00:00
level:GRIB1,105,10
product:GRIB1,80,2,34
proddef: GRIB:tod=1

EOF

cat > query.forecast.DPT << EOF
origin:GRIB1,80,,12
reftime: ==$initdate 00:00
level:GRIB1,105,2
product:GRIB1,80,2,17
proddef: GRIB:tod=1

EOF

cat > query.forecast.TCDC << EOF
origin:GRIB1,80,,12
reftime: ==$initdate 00:00
level:GRIB1,1
product:GRIB1,80,2,71
proddef: GRIB:tod=1

EOF

cat > query.forecast.PRMSL << EOF
origin:GRIB1,80,,12
reftime: ==$initdate 00:00
level:GRIB1,102
product:GRIB1,80,2,2
proddef: GRIB:tod=1

EOF

cat > query.forecast.TMP << EOF
origin:GRIB1,80,,12
reftime: ==$initdate 00:00
level:GRIB1,105,2
product:GRIB1,80,2,11
proddef: GRIB:tod=1

EOF

#cat > query.forecast.PRC << EOF
#origin:GRIB1,80,,12 
#reftime:>=$initdate 00:00, <=$enddate 00:00
#level:GRIB1,1
#product:GRIB1,80,2,61
#proddef: GRIB:tod=1
#timerange: GRIB1,0,0h or GRIB1,0,1h or GRIB1,0,2h or GRIB1,0,3h or GRIB1,0,4h or GRIB1,0,5h or GRIB1,0,6h or GRIB1,0,7h or GRIB1,0,8h or GRIB1,0,9h or GRIB1,0,10h or GRIB1,0,11h or GRIB1,0,12h or GRIB1,0,13h or GRIB1,0,14h or GRIB1,0,15h or GRIB1,0,16h or GRIB1,0,17h or GRIB1,0,18h or GRIB1,0,19h or GRIB1,0,20h or GRIB1,0,21h or GRIB1,0,22h or GRIB1,0,23h or GRIB1,0,24h
#EOF

#timerange:Timedef,0h,254


# --------------------------------------------------------------------------------------------------
#  Extract COSMO forecast
# --------------------------------------------------------------------------------------------------
#log -n "extract COSMO forecast" $LOGFILE

arki-query --data --file=query.forecast.UGRD  http://arkimet.metarpa:8090/dataset/cosmo_2I_arc >  ${initdate}_forecast_2I.grb
arki-query --data --file=query.forecast.VGRD  http://arkimet.metarpa:8090/dataset/cosmo_2I_arc >> ${initdate}_forecast_2I.grb
arki-query --data --file=query.forecast.DPT   http://arkimet.metarpa:8090/dataset/cosmo_2I_arc >> ${initdate}_forecast_2I.grb
arki-query --data --file=query.forecast.TCDC  http://arkimet.metarpa:8090/dataset/cosmo_2I_arc >> ${initdate}_forecast_2I.grb
arki-query --data --file=query.forecast.PRMSL http://arkimet.metarpa:8090/dataset/cosmo_2I_arc >> ${initdate}_forecast_2I.grb
arki-query --data --file=query.forecast.TMP   http://arkimet.metarpa:8090/dataset/cosmo_2I_arc >> ${initdate}_forecast_2I.grb
#arki-query --data --file=query.forecast.PRC   http://arkimet.metarpa:8090/dataset/cosmo_2I_arc >> ${initdate}_forecast_2I.grb

mv ${initdate}_forecast_2I.grb ${str_date}_forecast_2I.grb
mv ${str_date}_forecast_2I.grb $path
