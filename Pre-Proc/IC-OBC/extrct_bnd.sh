#!/bin/bash

echo " "
echo '======================================================================='
echo '================= generate shyfem boundary and initial conditions ================='
echo '======================================================================='
echo " "

###################### paths for input, tools and output files #################à
export path_rho="/fs/scratch/mare_exp/jacopo/PRE_PROC/OCEAN_FORCING/"
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
f_gsubfx="_adriaroms_his_2km.nc.gz"
f_subfx="_adriaroms_his_2km.nc"
export f_uv_in="rot_vel.nc"
int_bnd="lat_lon_bound.txt"      #### open boundary nodes coordinate on which to interpolate data ####

################## name temporary files ################################à
export rho_data="rho_tmp_data.nc"
uv_data="uv_tmp_data.nc"

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
rm -f ${path_out}boundn.fem ${path_out}tempn.fem ${path_out}saltn.fem ${path_out}uv3d.fem log_bnd.txt
rm -f ${path_out}boundin_*.fem ${path_out}tempin_*.fem ${path_out}saltin_*.fem ${path_out}uvin3d_*.fem
rm -f $rho_data $uv_data

######################## elaborate rho-grid data #############################
c=0
for i in "${date[@]}"
do

	path_in="/fs/archive/swan/OPERATIVO/FORECAST/"${date[$(($c+1))]}"/"
	echo $path_in

	if [ -f $path_in${date[$c]}$f_gsubfx ]
	then 
		cp $path_in${date[$c]}$f_gsubfx $path_out	
	elif [ -f $path_in${date[$c]}$f_subfx ]
	then
		cp $path_in${date[$c]}$f_subfx $path_out
	fi

	f_gin=$path_out${date[$c]}$f_gsubfx
	f_in=$path_out${date[$c]}$f_subfx
	export f_ncl_in=${date[$c]}$f_subfx

	############# check if file exists #######################
	if [ ! -f $f_gin ] && [ ! -f $f_in ] 
	then
		echo " "
		echo "file "$f_gin" or "$f_in" does not exists"
		echo "it may be a problem or not, the choice is yours"
		echo "if this is at the end of the LOG it's ok"
		let c=c+1	
		break
	fi
	###################### gunzip input file ####################à
	if [ ! -f $f_in ]
	then
		gunzip $f_gin
		#unpigz $f_gin
	fi

	############ cut NetCDF dataset ####################################
	ncks -d xi_rho,20,80 -d eta_rho,300,360 -d xi_v,20,80 -d eta_v,300,360 -d xi_u,20,80 -d eta_u,300,360 $f_in out.nc
        mv out.nc $f_in


	############ call routine to rotate velocity data ##################
	ncl -Q rotate_uv.ncl

	#################################à correct roms level #########
	if [ ${date[$c]} -eq 20180117 ]
        then
            ncap2 -s "zeta=zeta+0.15" $f_in out.nc
            mv out.nc $f_in
        fi

	if [ $c -eq 0 ] 
	then

		echo " "
		echo "===== first timestep ======="
		init_date=${date[$(($c+1))]}

		#################### estrai variabili primo time step ################
		ncks -O -d ocean_time,23 -v zeta,temp,salt,mask_rho $f_in $rho_data
		ncks -O -d ocean_time,23 -v u,v,mask_rho $path_out$f_uv_in $uv_data

		#ncl -Q fill_ssh.ncl
		############### Seaoverland on variables to extract boundary data ###############
		python3 adria_SOL_rho.py $rho_data
		python3 adria_SOL_uv.py $uv_data

		############## interpolate variables on the open bundary #############
		nc2fem -vars zeta -single $int_bnd $rho_data >> log_bnd.txt
		mv out.fem ${c}_tmp_boundn.fem
		nc2fem -vars temp -single $int_bnd $rho_data >> log_bnd.txt
		mv out.fem ${c}_tmp_tempn.fem
		nc2fem -vars salt -single $int_bnd $rho_data >> log_bnd.txt
		mv out.fem ${c}_tmp_saltn.fem
		nc2fem -vars u,v -single $int_bnd $uv_data >> log_bnd.txt
		mv out.fem ${c}_tmp_uv3d.fem

		###################### generate initial conditions ###################
		nc2fem -vars zeta $rho_data >> log_init.txt
		mv out.fem boundin_$init_date.fem	
		nc2fem -vars temp $rho_data >> log_init.txt
		mv out.fem tempin_$init_date.fem
		nc2fem -vars salt $rho_data >> log_init.txt
		mv out.fem saltin_$init_date.fem
		nc2fem -vars u,v  $uv_data >> log_init.txt
		mv out.fem uvin3d_$init_date.fem

		########## append files in a final FILE #####################
		cat ${c}_tmp_boundn.fem >> boundn.fem
		cat ${c}_tmp_tempn.fem >> tempn.fem
		cat ${c}_tmp_saltn.fem >> saltn.fem
		cat ${c}_tmp_uv3d.fem >> uv3d.fem

		######### remove temporary files ####################
		rm -f ${c}_tmp_boundn.fem ${c}_tmp_tempn.fem ${c}_tmp_saltn.fem ${c}_tmp_uv3d.fem 
		rm -f $rho_data $uv_data 
		rm -f $path_out$f_uv_in
		rm -f $f_in

		############### gzip input file ########################
		#gzip $f_in
		#pigz $f_in

		let c=c+1

		echo "... done"
		echo "============="
		
		continue
	else

		echo " "
		echo "============="
		echo "=== day "$c"... "  

		########### estrai variabili per altri time-step ############
		ncks -O -v zeta,temp,salt,mask_rho $f_in $rho_data
		ncks -O -v u,v,mask_rho $path_out$f_uv_in $uv_data

		#ncl -Q fill_ssh.ncl
		############### Seaoverland on variables to extract boundary data ###############
		python3 adria_SOL_rho.py $rho_data
		python3 adria_SOL_uv.py $uv_data
	fi
	
	############## interpolate variables on the open boundary ##############
	nc2fem -vars zeta -single $int_bnd $rho_data >> log_bnd.txt
	mv out.fem ${c}_tmp_boundn.fem
	nc2fem -vars temp -single $int_bnd $rho_data >> log_bnd.txt
	mv out.fem ${c}_tmp_tempn.fem
	nc2fem -vars salt -single $int_bnd $rho_data >> log_bnd.txt
	mv out.fem ${c}_tmp_saltn.fem
	nc2fem -vars u,v -single $int_bnd $uv_data >> log_bnd.txt
	mv out.fem ${c}_tmp_uv3d.fem

	############### append files in a final FILE #################à
	cat ${c}_tmp_boundn.fem >> boundn.fem
	cat ${c}_tmp_tempn.fem >> tempn.fem
	cat ${c}_tmp_saltn.fem >> saltn.fem	
	cat ${c}_tmp_uv3d.fem >> uv3d.fem

	######### remove temporary files ####################
	rm -f ${c}_tmp_boundn.fem ${c}_tmp_tempn.fem ${c}_tmp_saltn.fem ${c}_tmp_uv3d.fem 
	rm -f $rho_data $uv_data 
	rm -f $path_out$f_uv_in	
	rm -f $f_in

	#################### gzip nput file ########################
	#gzip $f_in
	#pigz $f_in

	echo "... done"
	echo "============="

	let c=c+1
done

##################### move output in path_out ##################
mv boundn.fem tempn.fem saltn.fem uv3d.fem $path_out
mv boundin_$init_date.fem tempin_$init_date.fem saltin_$init_date.fem uvin3d_$init_date.fem $path_out

echo " " 
echo "================================================================"
echo "=================== end of the procedure ======================="
echo "================================================================"
