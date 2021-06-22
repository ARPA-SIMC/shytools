#!/bin/bash
#
# --------------------------------------------------------------------------------------------------
#  Set dates
# --------------------------------------------------------------------------------------------------
#yesterday=$(date -d "$today 1 day ago" +%Y%m%d)

startdate=$1
initdate=$(date -d "${startdate}" +%Y-%m-%d)
enddate=$(date -d "${startdate} +1 days" +%Y-%m-%d)
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
#[[ -f ${yesterday}_analysis.grb ]] && rm ${yesterday}_analysis.grb
#[[ -f ${yesterday}_analysis.grb ]] && rm ${yesterday}_analysis.grb

# --------------------------------------------------------------------------------------------------
#  Update arkimet query configuration files
# --------------------------------------------------------------------------------------------------

cat > query.analysis.UGRD << EOF
origin: GRIB1,80,,22 or GRIB1,80,,21
reftime:>=$initdate 00:00, <=$enddate 00:00
level:GRIB1,105,10
product:GRIB1,80,2,33
proddef: GRIB:tod=0
EOF

cat > query.analysis.VGRD << EOF
origin: GRIB1,80,,22 or GRIB1,80,,21
reftime:>=$initdate 00:00, <=$enddate 00:00
level:GRIB1,105,10
product:GRIB1,80,2,34
proddef: GRIB:tod=0
EOF

cat > query.analysis.DPT << EOF
origin: GRIB1,80,,22 or GRIB1,80,,21
reftime:>=$initdate 00:00, <=$enddate 00:00
level:GRIB1,105,2
product:GRIB1,80,2,17
proddef: GRIB:tod=0
EOF

cat > query.analysis.TCDC << EOF
origin: GRIB1,80,,22 or GRIB1,80,,21
reftime:>=$initdate 00:00, <=$enddate 00:00
level:GRIB1,1
product:GRIB1,80,2,71
proddef: GRIB:tod=0
EOF

cat > query.analysis.PRMSL << EOF
origin: GRIB1,80,,22 or GRIB1,80,,21
reftime:>=$initdate 00:00, <=$enddate 00:00
level:GRIB1,102
product:GRIB1,80,2,2
proddef: GRIB:tod=0
EOF

cat > query.analysis.TMP << EOF
origin: GRIB1,80,,22 or GRIB1,80,,21
reftime:>=$initdate 00:00, <=$enddate 00:00
level:GRIB1,105,2
product:GRIB1,80,2,11
proddef: GRIB:tod=0
EOF

#cat > query.analysis.PRC << EOF
#origin:GRIB1,80,,12 
#reftime:>=$initdate 00:00, <=$enddate 00:00
#level:GRIB1,1
#product:GRIB1,80,2,61
#proddef: GRIB:tod=1
#timerange: GRIB1,0,0h or GRIB1,0,1h or GRIB1,0,2h or GRIB1,0,3h or GRIB1,0,4h or GRIB1,0,5h or GRIB1,0,6h or GRIB1,0,7h or GRIB1,0,8h or GRIB1,0,9h or GRIB1,0,10h or GRIB1,0,11h or GRIB1,0,12h or GRIB1,0,13h or GRIB1,0,14h or GRIB1,0,15h or GRIB1,0,16h or GRIB1,0,17h or GRIB1,0,18h or GRIB1,0,19h or GRIB1,0,20h or GRIB1,0,21h or GRIB1,0,22h or GRIB1,0,23h or GRIB1,0,24h
#EOF

#timerange:Timedef,0h,254


# --------------------------------------------------------------------------------------------------
#  Extract COSMO analysis
# --------------------------------------------------------------------------------------------------
#log -n "extract COSMO analysis" $LOGFILE

arki-query --data --file=query.analysis.UGRD  http://arkimet.metarpa:8090/dataset/cosmo_5M_med_arc >  ${initdate}_analysis_5M.grb
arki-query --data --file=query.analysis.VGRD  http://arkimet.metarpa:8090/dataset/cosmo_5M_med_arc >> ${initdate}_analysis_5M.grb
arki-query --data --file=query.analysis.DPT   http://arkimet.metarpa:8090/dataset/cosmo_5M_med_arc >> ${initdate}_analysis_5M.grb
arki-query --data --file=query.analysis.TCDC  http://arkimet.metarpa:8090/dataset/cosmo_5M_med_arc >> ${initdate}_analysis_5M.grb
arki-query --data --file=query.analysis.PRMSL http://arkimet.metarpa:8090/dataset/cosmo_5M_med_arc >> ${initdate}_analysis_5M.grb
arki-query --data --file=query.analysis.TMP   http://arkimet.metarpa:8090/dataset/cosmo_5M_med_arc >> ${initdate}_analysis_5M.grb
#arki-query --data --file=query.analysis.PRC   http://arkimet.metarpa:8090/dataset/cosmo_5M_med_arc >> ${initdate}_analysis_5M.grb

mv ${initdate}_analysis_5M.grb ${startdate}_analysis_5M.grb
mv ${startdate}_analysis_5M.grb $path
