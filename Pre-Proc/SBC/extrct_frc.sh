#!/bin/bash

echo " "
echo '==========================================================================================='
echo '================= generate shyfem forcing from Meteo data COSMO 2I version================='
echo '==========================================================================================='
echo " "

###################### paths for input, tools and output files #################à
export path_out=$3

################# write starting and finish date ############## 
strt_date=$1
end_date=$2
typ=$4

############### flags #######################
fy=0
fd=0
f=0
c=0

############## files subfix ################à
if [ $typ == "an" ] 
then
	f_gsubfx="_analysis_2I.grb.gz"
	f_subfx="_analysis_2I.grb"
	f_subnc="_analysis_2I.nc"
	#export lsm="lsm_I2.nc"
elif [ $typ == "fc" ] 
then 
	f_gsubfx="_forecast_2I.grb.gz"
	f_subfx="_forecast_2I.grb"
	f_subnc="_forecast_2I.nc"
	#export lsm="lsm_I2.nc"
fi

############################### extracts chosen dates ####################
month=(01 02 03 04 05 06 07 08 09 10 11 12)
year=(2014 2015 2016 2017 2018 2019)

for y in "${year[@]}"
do
	rem=$((${year[$fy]} % 4))  
    fm=0
    for m in "${month[@]}"
    do
		if [ $m -eq 4 ] || [ $m -eq 6 ] || [ $m -eq 9 ] || [ $m -eq 11 ] 
		then
			day=(01 02 03 04 05 06 07 08 09 10 11 12 13 14 15 16 17 18 19 20 21 \
			22 23 24 25 26 27 28 29 30)
		elif [ $m -eq 2 ]
		then
			if [ $rem -eq 0 ]  ########## check if leap year #################
			then
				day=(01 02 03 04 05 06 07 08 09 10 11 12 13 14 15 16 17 18 19 20 21 \
				22 23 24 25 26 27 28 29)
			else  
				day=(01 02 03 04 05 06 07 08 09 10 11 12 13 14 15 16 17 18 19 20 21 \
				22 23 24 25 26 27 28)
			fi
		else
			day=(01 02 03 04 05 06 07 08 09 10 11 12 13 14 15 16 17 18 19 20 21 \
			22 23 24 25 26 27 28 29 30 31)
		fi 
		fd=0
		for d in "${day[@]}"
		do
		    date_tmp[$f]=${year[$fy]}${month[$fm]}${day[$fd]}
			if [ ${date_tmp[$f]} -ge $strt_date ] && [ ${date_tmp[$f]} -le $end_date ]
			then
				date[$c]=${date_tmp[$f]}
				echo ${date[$c]}
				let c=c+1
			fi
			let f=f+1
			let fd=fd+1
		done
		let fm=fm+1
    done
let fy=fy+1
done

echo " " 
echo '================================================================='
echo '==================== elaborate data ===================='
echo '================================================================='
echo " "

####################### delete pre-existing boundary and initial conditions files ##############
rm -f ${path_out}wp.fem ${path_out}tc.fem log_frc.txt 

######################## elaborate rho-grid data #############################
c=0
for i in "${date[@]}"
do
	echo " "
    	echo "============="
    	echo "=== day "$c"... "  

	if [ $typ == "an" ]
	then
		s=0
		./download_cosmo_analysis.sh ${date[$c]} ${path_out}
	elif [ $typ == "fc" ]
	then
		s=1
		./download_cosmo_forecast.sh ${date[$c]} ${path_out}
	fi
	
	f_gin=$path_out${date[$c]}$f_gsubfx
	f_in=$path_out${date[$c]}$f_subfx
	f_nc=$path_out${date[$c]}$f_subnc
	export f_ncl_in=${date[$c]}$f_subnc

	#################### record size file ################
	if [ -f $f_gin ]
	then
		size=$(du -k $f_gin | cut -f1)
	elif [ -f $f_in ]
	then
		size=$(du -k $f_in | cut -f1)	
	fi
	
	echo $size

	############# check if file exists and have the appropriate size #######################
	if  ( [ ! -f $f_gin ] && [ ! -f $f_in ] ) || ( [ $size -lt 70000 ] ) 
	then
		echo " "
		echo "try to download forecast data from arkimet"

		./download_cosmo_forecast.sh ${date[$c]} ${path_out}
		s=1
		size_fc=$(du -k $f_in | cut -f1)


		if [ $size_fc -eq 0 ]
		then
			echo " "
			echo "file "$f_gin" or "$f_in" does not exists"
			echo "it may be a problem or not, the choice is yours"
			echo "if this is at the end of the LOG it's ok"
			let c=c+1	
			break
		fi
	fi
	###################### gunzip input file #####################
	if [ ! -f $f_in ]
	then
		gunzip $f_gin
	fi

	###################### convert grib to netcdf ######################
	ncl_convert2nc $f_in -no-sc -u >/dev/null
	mv ${date[$c]}$f_subnc $path_out
	#dat=$(date -d "${date[$c]} -1 days" +%Y-%m-%d)
	dat=$(date -d "${date[$c]}" +%Y-%m-%d)

	if [ $s -eq 0 ] 
	then
		###################### renames variables and dimensions of NC file ##################
		ncrename -h -d g10_y_2,lon -d g10_x_1,lat -d initial_time0_hours,time $f_nc
		ncrename -h -v g10_lat_1,lat -v g10_lon_2,lon -v initial_time0_hours,time $f_nc
		ncrename -h -v PRMSL_GDS10_MSL_13,PRS -v U_GRD_GDS10_HTGL_13,U10M -v V_GRD_GDS10_HTGL_13,V10M $f_nc
		#ncrename -h -v .NSWRS_GDS10_SFC_13,QS -v TMP_GDS10_HTGL_13,TMP -v DPT_GDS10_HTGL_13,DPT -v T_CDC_GDS10_SFC_13,TCC $f_nc	
		ncrename -h -v TMP_GDS10_HTGL_13,TMP -v DPT_GDS10_HTGL_13,DPT -v T_CDC_GDS10_SFC_13,TCC $f_nc
	elif [ $s -eq 1 ]
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
	ncks -d lon,249,340 -d lat,440,573 $f_nc out.nc
	mv out.nc $f_nc

	########################## remove the last timestep in every file ########################
	#ncks -d time,0,23 $f_nc out.nc
	ncap2 -s "TCC=TCC/100" out.nc prova.nc
	ncap2 -O -s "TMP=TMP-273.15" prova.nc out.nc
	ncap2 -O -s "DPT=DPT-273.15" out.nc prova.nc
    	mv prova.nc out.nc
	ncatted -O -a long_name,TMP,o,c,air_temperature out.nc
	mv out.nc $f_nc

	############ call routine to rotate wind velocity data ##################
	ncl -Q rot_wnd_vel_SOL.ncl

	########### call SOL routine to extrapolate data along the coast #######################
	#python jacopo_cosmo.py $f_nc $lsm

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

	#------------ attach cosmo 5M forecast ---------------
	

	#################### delete input file ########################
	rm $f_in $f_nc

	echo "... done"
	echo "============="

	let c=c+1
done

##################### move output in path_out ##################
mv wp.fem tc.fem $path_out

echo " " 
echo "================================================================"
echo "=================== end of the procedure ======================="
echo "================================================================"
