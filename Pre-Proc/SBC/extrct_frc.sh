#!/bin/bash

echo " "
echo '===================================================================================================='
echo '================= generate shyfem forcing from Meteo SIMC data ====================================='
echo '================= analysis from COSMO-2I ; forecast +48h from COSMO-2I  ============================'
echo '=================     forecast from +49h to +72h from COSMO-5M ====================================='       
echo '===================================================================================================='
echo " "

###################### paths for input, tools and output files #################à
export path_out=$3

################# write starting and finish date ############## 
#strt_date=$1
#end_date=$2
typ=$4
mod=$5

############### flags #######################
fy=0
fd=0
f=0
c=0

############## files subfix ################à
if [ $mod == "2I" ]
then
  if [ $typ == "an" ] 
  then
	f_gsubfx="_analysis_2I.grb.gz"
	f_subfx="_analysis_2I.grb"
	f_subnc="_analysis_2I.nc"
	export lsm="lsm_2I.nc"
  elif [ $typ == "fc" ] 
  then 
	f_gsubfx="_forecast_2I.grb.gz"
	f_subfx="_forecast_2I.grb"
	f_subnc="_forecast_2I.nc"
	export lsm="lsm_2I.nc"
  fi
elif [ $mod == "5M" ] 
then
  if [ $typ == "an" ] 
  then
	f_gsubfx="_analysis_5M.grb.gz"
	f_subfx="_analysis_5M.grb"
	f_subnc="_analysis_5M.nc"
	export lsm="lsm_5M.nc"
  elif [ $typ == "fc" ] 
  then 
	f_gsubfx="_forecast_5M.grb.gz"
	f_subfx="_forecast_5M.grb"
	f_subnc="_forecast_5M.nc"
	export lsm="lsm_5M.nc"
  fi
else
  exit
fi

####################### delete pre-existing boundary and initial conditions files ##############
rm -f ${path_out}wp.fem ${path_out}tc.fem log_frc.txt wp.fem tc.fem 

######################## elaborate rho-grid data #############################
c=0

#-------------- manage dates ----------------------#
today=$1                                         # start of the forecast
dbefore=$(date +%Y%m%d -d "$today -1 days")      # day before today
sub=$2		                                 # day to subtract from today
strt_date=$(date +%Y%m%d -d "$today -$sub days") # day of initialization
end_date=$(date +%Y%m%d -d "$today +3 days")     # final date of forecast

#--------------------------------- START LOOP to build analysis ----------------------#
while [[ $strt_date < $today ]]
do
	echo " "
	echo "======================================="
    	echo "=== "$strt_date" ... analysis "  
	echo "======================================="
	echo " "

	if [ $typ == "an" ]
	then
		s=0
	   if [ $mod == "2I" ]
	   then
		./download_cosmo_analysis.sh $strt_date ${path_out}
	   elif [ $mod == "5M" ]
	   then
		./download_cosmo_analysis_5M.sh $strt_date ${path_out}
	   fi
	elif [ $typ == "fc" ]
	then
		s=1
	   if [ $mod == "2I" ]
	   then
		./download_cosmo_forecast.sh $strt_date ${path_out}
	   elif [ $mod == "5M" ]
	   then
		./download_cosmo_forecast_5M.sh $strt_date ${path_out}
	   fi
		
	fi
	
	f_gin=$path_out$strt_date$f_gsubfx
	f_in=$path_out$strt_date$f_subfx
	f_nc=$path_out$strt_date$f_subnc
	export f_ncl_in=$strt_date$f_subnc


	###################### convert grib to netcdf ######################
	ncl_convert2nc $f_in -no-sc -u >/dev/null
	mv $strt_date$f_subnc $path_out
	#dat=$(date -d "$strt_date -1 days" +%Y-%m-%d)
	dat=$(date -d "$strt_date" +%Y-%m-%d)

	if [ $typ == "an" ] 
	then
		###################### renames variables and dimensions of NC file ##################
		ncrename -h -d g10_y_2,lon -d g10_x_1,lat -d initial_time0_hours,time $f_nc
		ncrename -h -v g10_lat_1,lat -v g10_lon_2,lon -v initial_time0_hours,time $f_nc
		ncrename -h -v PRMSL_GDS10_MSL_13,PRS -v U_GRD_GDS10_HTGL_13,U10M -v V_GRD_GDS10_HTGL_13,V10M $f_nc
		#ncrename -h -v .NSWRS_GDS10_SFC_13,QS -v TMP_GDS10_HTGL_13,TMP -v DPT_GDS10_HTGL_13,DPT -v T_CDC_GDS10_SFC_13,TCC $f_nc	
		ncrename -h -v TMP_GDS10_HTGL_13,TMP -v DPT_GDS10_HTGL_13,DPT -v T_CDC_GDS10_SFC_13,TCC $f_nc
	elif [ $typ == "fc" ]
	then
		###################### renames variables and dimensions of NC file of arkimet data ##################
		ncrename -h -d g10_y_2,lon -d g10_x_1,lat -d forecast_time0,time $f_nc
		ncrename -h -v g10_lat_1,lat -v g10_lon_2,lon -v forecast_time0,time $f_nc
		ncrename -h -v PRMSL_GDS10_MSL,PRS -v U_GRD_GDS10_HTGL,U10M -v V_GRD_GDS10_HTGL,V10M $f_nc
		ncrename -h -v TMP_GDS10_HTGL,TMP -v DPT_GDS10_HTGL,DPT -v T_CDC_GDS10_SFC,TCC $f_nc
		
		ncatted -O -a long_name,time,o,c,"initial time" $f_nc
		ncatted -O -a units,time,o,c,"hours since $dat 00:00" $f_nc
	fi

	#------------------------ cut NetCDF data ------------------
        if [ $mod == "2I" ]
        then
	   ncks -d lon,249,340 -d lat,440,573 $f_nc out.nc
        elif [ $mod == "5M" ]
	then
	   ncks -d lon,585,645 -d lat,300,365 $f_nc out.nc
	fi
	mv out.nc $f_nc

	########################## remove the last timestep in every file ########################
	ncks -d time,0,23 $f_nc out.nc
	ncap2 -s "TCC=TCC/100" out.nc prova.nc
	ncap2 -O -s "TMP=TMP-273.15" prova.nc out.nc
	ncap2 -O -s "DPT=DPT-273.15" out.nc prova.nc
    	mv prova.nc out.nc
	ncatted -O -a long_name,TMP,o,c,air_temperature out.nc
	mv out.nc $f_nc

	############ call routine to rotate wind velocity data ##################
	ncl -Q rot_wnd_vel_SOL.ncl

	########### call SOL routine to extrapolate data along the coast #######################
	python3 jacopo_cosmo.py $f_nc $lsm

	############## interpolate variables on a regular grid ##############
	nc2fem -vars U10M,V10M,PRS $f_nc >> log_frc.txt
	mv out.fem ${c}_tmp_wp.fem
	nc2fem -vars TMP,TMP,DPT,TCC $f_nc >> log_frc.txt
	mv out.fem ${c}_tmp_tc.fem
	shyelab -newstring "solar radiation [W/m**2]" ${c}_tmp_tc.fem >> log_frc.txt
	mv out.fem ${c}_tmp_tc.fem

	############### append files in a final FILE #################à
	cat ${c}_tmp_wp.fem >> wp.fem
	cat ${c}_tmp_tc.fem >> tc.fem

	######### remove temporary files ####################
	rm -f ${c}_tmp_wp.fem ${c}_tmp_tc.fem 

	#################### delete input file ########################
	rm $f_in $f_nc

	echo "... done"
	echo "============="

	let c=c+1
	strt_date=$(date +%Y%m%d -d "$strt_date +1 day")
done
#------------------ END LOOP on analysis --------------------------------------#

#===================================================================================#

#-------------------- produce and append forecast --------------------------- #

echo " "
echo "=================================="
echo "=== COSMO-2I forecast up to +48h ="
echo "============ $today =============="  
echo "=================================="
echo " "

#---------- change nomenclature for forecast --------------#
f_gsubfx="_forecast_2I.grb.gz"
f_subfx="_forecast_2I.grb"
f_subnc="_forecast_2I.nc"

#------------- download COSMO-2I forecast -----------------#
./download_cosmo_forecast.sh $today ${path_out} 

f_in=$path_out$today$f_subfx
f_nc=$path_out$today$f_subnc
export f_ncl_in=$today$f_subnc

###################### convert grib to netcdf ######################
ncl_convert2nc $f_in -no-sc -u >/dev/null
mv $today$f_subnc $path_out
dat=$(date -d "$today" +%Y-%m-%d)
echo "$dat"

###################### renames variables and dimensions of NC file of arkimet data ##################
ncrename -h -d g10_y_2,lon -d g10_x_1,lat -d forecast_time0,time $f_nc
ncrename -h -v g10_lat_1,lat -v g10_lon_2,lon -v forecast_time0,time $f_nc
ncrename -h -v PRMSL_GDS10_MSL,PRS -v U_GRD_GDS10_HTGL,U10M -v V_GRD_GDS10_HTGL,V10M $f_nc
ncrename -h -v TMP_GDS10_HTGL,TMP -v DPT_GDS10_HTGL,DPT -v T_CDC_GDS10_SFC,TCC $f_nc
	
ncatted -O -a long_name,time,o,c,"initial time" $f_nc
ncatted -O -a units,time,o,c,"hours since $dat 00:00" $f_nc

#------------------------ cut NetCDF data ------------------
ncks -d lon,249,340 -d lat,440,573 $f_nc out.nc

#--------------- do some variables conversions ------------
ncap2 -s "TCC=TCC/100" out.nc prova.nc
ncap2 -O -s "TMP=TMP-273.15" prova.nc out.nc
ncap2 -O -s "DPT=DPT-273.15" out.nc prova.nc
mv prova.nc out.nc
ncatted -O -a long_name,TMP,o,c,air_temperature out.nc
mv out.nc $f_nc

############ call routine to rotate wind velocity data ##################
ncl -Q rot_wnd_vel_SOL.ncl

########### call SOL routine to extrapolate data along the coast #######################
python3 jacopo_cosmo.py $f_nc $lsm

############## interpolate variables on a regular grid ##############
nc2fem -vars U10M,V10M,PRS $f_nc >> log_frc.txt
mv out.fem fc_2I_tmp_wp.fem
nc2fem -vars TMP,TMP,DPT,TCC $f_nc >> log_frc.txt
mv out.fem fc_2I_tmp_tc.fem
shyelab -newstring "solar radiation [W/m**2]" fc_2I_tmp_tc.fem >> log_frc.txt
mv out.fem fc_2I_tmp_tc.fem

############### append files in a final FILE #################à
cat fc_2I_tmp_wp.fem >> wp.fem
cat fc_2I_tmp_tc.fem >> tc.fem

######### remove temporary files ####################
rm -f fc_2I_tmp_wp.fem fc_2I_tmp_tc.fem 

#################### delete input file ########################
rm $f_in $f_nc

echo "... done"
echo "============="

echo " "
echo "=================================="
echo "=== COSMO-5M forecast up to +72h ="
echo "============ $today =============="  
echo "=================================="
echo " "

#---------- change nomenclature for forecast --------------#
f_gsubfx="_forecast_5M.grb.gz"
f_subfx="_forecast_5M.grb"
f_subnc="_forecast_5M.nc"
export lsm="lsm_5M.nc"

#------------- download COSMO-2I forecast -----------------#
./download_cosmo_forecast_5M.sh $today ${path_out} 

f_in=$path_out$today$f_subfx
f_nc=$path_out$today$f_subnc
export f_ncl_in=$today$f_subnc

###################### convert grib to netcdf ######################
ncl_convert2nc $f_in -no-sc -u >/dev/null
mv $today$f_subnc $path_out
dat=$(date -d "$today" +%Y-%m-%d)
echo "$dat"

###################### renames variables and dimensions of NC file of arkimet data ##################
ncrename -h -d g10_y_2,lon -d g10_x_1,lat -d forecast_time0,time $f_nc
ncrename -h -v g10_lat_1,lat -v g10_lon_2,lon -v forecast_time0,time $f_nc
ncrename -h -v PRMSL_GDS10_MSL,PRS -v U_GRD_GDS10_HTGL,U10M -v V_GRD_GDS10_HTGL,V10M $f_nc
ncrename -h -v TMP_GDS10_HTGL,TMP -v DPT_GDS10_HTGL,DPT -v T_CDC_GDS10_SFC,TCC $f_nc
	
ncatted -O -a long_name,time,o,c,"initial time" $f_nc
ncatted -O -a units,time,o,c,"hours since $dat 00:00" $f_nc

#------------------------ cut NetCDF data ------------------
ncks -d lon,585,645 -d lat,300,365 $f_nc out.nc

#--------------- do some variables conversions ------------
ncap2 -s "TCC=TCC/100" out.nc prova.nc
ncap2 -O -s "TMP=TMP-273.15" prova.nc out.nc
ncap2 -O -s "DPT=DPT-273.15" out.nc prova.nc
mv prova.nc out.nc
ncatted -O -a long_name,TMP,o,c,air_temperature out.nc
mv out.nc $f_nc

############ call routine to rotate wind velocity data ##################
ncl -Q rot_wnd_vel_SOL.ncl

########### call SOL routine to extrapolate data along the coast #######################
python3 jacopo_cosmo.py $f_nc $lsm

############## interpolate variables on a regular grid ##############
nc2fem -vars U10M,V10M,PRS $f_nc >> log_frc.txt
mv out.fem fc_5M_tmp_wp.fem
nc2fem -vars TMP,TMP,DPT,TCC $f_nc >> log_frc.txt
mv out.fem fc_5M_tmp_tc.fem
shyelab -newstring "solar radiation [W/m**2]" fc_5M_tmp_tc.fem >> log_frc.txt
mv out.fem fc_5M_tmp_tc.fem

############### append files in a final FILE #################à
cat fc_5M_tmp_wp.fem >> wp.fem
cat fc_5M_tmp_tc.fem >> tc.fem

######### remove temporary files ####################
rm -f fc_5M_tmp_wp.fem fc_5M_tmp_tc.fem 

#################### delete input file ########################
rm $f_in $f_nc

echo "... done"
echo "============="


##################### move output in path_out ##################
mv wp.fem tc.fem $path_out

echo " " 
echo "================================================================"
echo "=================== end of the procedure ======================="
echo "================================================================"
