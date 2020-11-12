#!/bin/bash

echo " "
echo '==========================================================================='
echo '================= generate shyfem forcing from Meteo data ================='
echo '==========================================================================='
echo " "

###################### paths for input, tools and output files #################à
export path_out=$3

################# write starting and finish date ############## 
strt_date=$1
end_date=$2

############### flags #######################
fy=0
fd=0
f=0
c=0

############## files subfix ################à
f_gsubfx="_analysis_I2.grb.gz"
f_subfx="_analysis_I2.grb"
f_subnc="_analysis_I2.nc"
export lsm="lsm_I2.nc"

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

	path_in="/fs/archive/swan/COSMO/I2_ANALYSES/"
	echo $path_in
	s=0

	############################## copy file in your directory ####################à
	if [ -f $path_in${date[$c]}$f_gsubfx ]
	then
			cp $path_in${date[$c]}$f_gsubfx $path_out
	elif [ -f $path_in${date[$c]}$f_subfx ]
	then
			cp $path_in${date[$c]}$f_subfx $path_out
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
		unpigz $f_gin
	fi

	###################### de-cumulate precipitation variable ############
	vg6d_transform --comp-stat-proc=1:1 --comp-step='0 01'  $f_in outcum.grib
	mv outcum.grib $f_in

	###################### convert grib to netcdf ######################
	ncl_convert2nc $f_in -no-sc -u >/dev/null
	mv ${date[$c]}$f_subnc $path_out
	dat=$(date -d "${date[$c]} -1 days" +%Y-%m-%d)

	if [ $s -eq 0 ] 
	then
		###################### renames variables and dimensions of NC file ##################
		ncrename -h -d g10_y_2,lon -d g10_x_1,lat -d initial_time0_hours,time $f_nc
		ncrename -h -v g10_lat_1,lat -v g10_lon_2,lon -v initial_time0_hours,time $f_nc
		ncrename -h -v A_PCP_GDS10_SFC_13,PRC $f_nc
	elif [ $s -eq 1 ]
	then
		###################### renames variables and dimensions of NC file of arkimet data ##################
		ncrename -h -d g10_y_2,lon -d g10_x_1,lat -d forecast_time0,time $f_nc
		ncrename -h -v g10_lat_1,lat -v g10_lon_2,lon -v forecast_time0,time $f_nc
		ncrename -h -v A_PCP_GDS10_SFC_acc1h,PRC $f_nc
		
		ncatted -O -a long_name,time,o,c,"initial time" $f_nc
		ncatted -O -a units,time,o,c,"hours since $dat 00:00" $f_nc
	fi

	########################## remove the last timestep in every file ########################
	#ncks -d time,0,23 $f_nc out.nc
	ncap2 -s "PRC=PRC*24" $f_nc prova.nc
    	mv prova.nc out.nc
	#ncatted -O -a long_name,TMP,o,c,air_temperature out.nc
	mv out.nc $f_nc


	############## interpolate variables on a regular grid ##############
	nc2fem -domain 3.25472094E-02,2.49269716E-02,11.5,44,13.5,46 -vars PRC $f_nc >> log_prc.txt
	mv out.fem ${c}_tmp_prc.fem

	############### append files in a final FILE #################à
	cat ${c}_tmp_prc.fem >> prc.fem

	######### remove temporary files ####################
	rm -f ${c}_tmp_prc.fem

	#################### delete input file ########################
	rm $f_in $f_nc

	echo "... done"
	echo "============="

	let c=c+1
done

##################### move output in path_out ##################
mv prc.fem $path_out

echo " " 
echo "================================================================"
echo "=================== end of the procedure ======================="
echo "================================================================"
