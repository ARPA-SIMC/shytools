#!/bin/bash

echo " "
echo '==================================================================================='
echo '================= generate shyfem boundary and initial conditions ================='
echo "================ from Adriac model: 3 days analysis + 3 days forecast ============="
echo '==================================================================================='
echo " "

###################### paths for input, tools and output files #################à
export path_out=$3

############### flags #######################
f=0
c=0

############## files subfix ################à
f_gsubfx="_adriac_1km_his_an.nc.gz"
f_subfx="_adriac_1km_his_an.nc"
int_bnd="lat_lon_bound.txt"      #### open boundary nodes coordinate on which to interpolate data ####

################## name temporary files ################################à
export rho_data="rho_tmp_data_an.nc"

##----------------- mask file --------------------------#
rhomask="/lhome/swan/Adriac/Grid/adriac_grd_1km_1.5m.nc"

#------------------------- manage dates -------------------------#
today=$1                                         # start of the forecast
dafter=$(date +%Y%m%d -d "$today +1 days")      # day after today
sub=$2		                                 # day to subtract from today
strt_date=$(date +%Y%m%d -d "$today -$sub days") # day of initialization
end_date=$(date +%Y%m%d -d "$today +3 days")     # final date of forecast

####################### delete pre-existing boundary and initial conditions files ##############
rm -f ${path_out}boundn.fem ${path_out}tempn.fem ${path_out}saltn.fem ${path_out}uv3d.fem log_bnd.txt
rm -f ${path_out}boundin_*.fem ${path_out}tempin_*.fem ${path_out}saltin_*.fem ${path_out}uvin3d_*.fem
rm -f $rho_data #$uv_data

#------------------ copy and cut rho mask ------------------------------------#
cp $rhomask $path_out
ncks -d xi_rho,20,230 -d eta_rho,580,720 ${path_out}adriac_grd_1km_1.5m.nc out.nc
mv out.nc ${path_out}adriac_grd_1km_1.5m.nc

######################## elaborate rho-grid data #############################
c=0
while [[ $strt_date < $dafter ]]
do

	path_in="/fs/archive/swan/Adriac/Preoperativo/Forecast/"$strt_date"/"
	echo " "
	echo "============================================================"
	echo "============= Adriac analysis day $strt_date ==============="
	echo "============================================================"

	if [ -f $path_in$strt_date$f_gsubfx ]
	then 
		cp $path_in$strt_date$f_gsubfx $path_out	
	elif [ -f $path_in$strt_date$f_subfx ]
	then
		cp $path_in$strt_date$f_subfx $path_out
	fi

	f_gin=$path_out$strt_date$f_gsubfx
	f_in=$path_out$strt_date$f_subfx
	export f_ncl_in=$strt_date$f_subfx

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
	fi

	############ cut NetCDF dataset ####################################
	ncks -d xi_rho,20,230 -d eta_rho,580,720 $f_in out.nc
        mv out.nc $f_in

	if [ $c -eq 0 ] 
	then

		echo " "
		echo "===== first timestep ======="
         	init_date=$strt_date

		#################### estrai variabili primo time step ################
		ncks -O -d ocean_time,23 -v zeta,temp,salt,u_eastward,v_northward $f_in $rho_data

		############### Seaoverland on variables to extract boundary data ###############
		python3 adria_SOL_rho.py $rho_data ${path_out}adriac_grd_1km_1.5m.nc 

		############## interpolate variables on the open bundary #############
		nc2fem -vars zeta -single $int_bnd $rho_data >> log_bnd.txt
		mv out.fem ${c}_tmp_boundn.fem
		nc2fem -vars temp -single $int_bnd $rho_data >> log_bnd.txt
		mv out.fem ${c}_tmp_tempn.fem
		nc2fem -vars salt -single $int_bnd $rho_data >> log_bnd.txt
		mv out.fem ${c}_tmp_saltn.fem
		nc2fem -vars u_eastward,v_northward -single $int_bnd $rho_data >> log_bnd.txt
		mv out.fem ${c}_tmp_uv3d.fem

		###################### generate initial conditions ###################
		nc2fem -vars zeta $rho_data >> log_init.txt
		mv out.fem boundin_$init_date.fem	
		nc2fem -vars temp $rho_data >> log_init.txt
		mv out.fem tempin_$init_date.fem
		nc2fem -vars salt $rho_data >> log_init.txt
		mv out.fem saltin_$init_date.fem
		nc2fem -vars u_eastward,v_northward  $rho_data >> log_init.txt
		mv out.fem uvin3d_$init_date.fem

		########## append files in a final FILE #####################
		cat ${c}_tmp_boundn.fem >> boundn.fem
		cat ${c}_tmp_tempn.fem >> tempn.fem
		cat ${c}_tmp_saltn.fem >> saltn.fem
		cat ${c}_tmp_uv3d.fem >> uv3d.fem

		######### remove temporary files ####################
		rm -f ${c}_tmp_boundn.fem ${c}_tmp_tempn.fem ${c}_tmp_saltn.fem ${c}_tmp_uv3d.fem 
		rm -f $rho_data #$uv_data 
		rm -f $f_in

		##---------- advance date -----------------------#
		let c=c+1
		strt_date=$(date +%Y%m%d -d "$strt_date +1 day")

		echo "... done"
		echo "============="
		
		continue
	else

		echo " "
		echo "============="
		echo "=== day "$c"... "  

		########### estrai variabili per altri time-step ############
		ncks -O -v zeta,temp,salt,u_eastward,v_northward $f_in $rho_data

		############### Seaoverland on variables to extract boundary data ###############
		python3 adria_SOL_rho.py $rho_data ${path_out}adriac_grd_1km_1.5m.nc
	fi
	
	############## interpolate variables on the open boundary ##############
	nc2fem -vars zeta -single $int_bnd $rho_data >> log_bnd.txt
	mv out.fem ${c}_tmp_boundn.fem
	nc2fem -vars temp -single $int_bnd $rho_data >> log_bnd.txt
	mv out.fem ${c}_tmp_tempn.fem
	nc2fem -vars salt -single $int_bnd $rho_data >> log_bnd.txt
	mv out.fem ${c}_tmp_saltn.fem
	nc2fem -vars u_eastward,v_northward -single $int_bnd $rho_data >> log_bnd.txt
	mv out.fem ${c}_tmp_uv3d.fem

	############### append files in a final FILE #################à
	cat ${c}_tmp_boundn.fem >> boundn.fem
	cat ${c}_tmp_tempn.fem >> tempn.fem
	cat ${c}_tmp_saltn.fem >> saltn.fem	
	cat ${c}_tmp_uv3d.fem >> uv3d.fem

	######### remove temporary files ####################
	rm -f ${c}_tmp_boundn.fem ${c}_tmp_tempn.fem ${c}_tmp_saltn.fem ${c}_tmp_uv3d.fem 
	rm -f $rho_data 
	rm -f $f_in

	echo "... done"
	echo "============="

	let c=c+1
        strt_date=$(date +%Y%m%d -d "$strt_date +1 day")
done

#====================== pre-proc Adriac Forecast for Shyfem =====================#
f_gsubfx="_adriac_1km_his_fc.nc.gz"
f_subfx="_adriac_1km_his_fc.nc"
export rho_data="rho_tmp_data_fc.nc"

path_in="/fs/archive/swan/Adriac/Preoperativo/Forecast/"$today"/"
echo " "
echo "=================================================="
echo "============= forecast from $today ==============="
echo "=================================================="

if [ -f $path_in$today$f_gsubfx ]
then 
	cp $path_in$today$f_gsubfx $path_out	
elif [ -f $path_in$today$f_subfx ]
then
	cp $path_in$today$f_subfx $path_out
fi

f_gin=$path_out$today$f_gsubfx
f_in=$path_out$today$f_subfx
export f_ncl_in=$today$f_subfx

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
fi

############ cut NetCDF dataset ####################################
ncks -d xi_rho,20,230 -d eta_rho,580,720 $f_in out.nc
mv out.nc $f_in

########### estrai variabili per altri time-step ############
ncks -O -v zeta,temp,salt,u_eastward,v_northward $f_in $rho_data

############### Seaoverland on variables to extract boundary data ###############
python3 adria_SOL_rho.py $rho_data ${path_out}adriac_grd_1km_1.5m.nc

############## interpolate variables on the open boundary ##############
nc2fem -vars zeta -single $int_bnd $rho_data >> log_bnd.txt
mv out.fem ${c}_tmp_boundn.fem
nc2fem -vars temp -single $int_bnd $rho_data >> log_bnd.txt
mv out.fem ${c}_tmp_tempn.fem
nc2fem -vars salt -single $int_bnd $rho_data >> log_bnd.txt
mv out.fem ${c}_tmp_saltn.fem
nc2fem -vars u_eastward,v_northward -single $int_bnd $rho_data >> log_bnd.txt
mv out.fem ${c}_tmp_uv3d.fem

############### append files in a final FILE #################à
cat ${c}_tmp_boundn.fem >> boundn.fem
cat ${c}_tmp_tempn.fem >> tempn.fem
cat ${c}_tmp_saltn.fem >> saltn.fem	
cat ${c}_tmp_uv3d.fem >> uv3d.fem

######### remove temporary files ####################
rm -f ${c}_tmp_boundn.fem ${c}_tmp_tempn.fem ${c}_tmp_saltn.fem ${c}_tmp_uv3d.fem 
rm -f $rho_data 
rm -f $f_in

echo "... done"
echo "============="


##################### move output in path_out ##################
mv boundn.fem tempn.fem saltn.fem uv3d.fem $path_out
mv boundin_$init_date.fem tempin_$init_date.fem saltin_$init_date.fem uvin3d_$init_date.fem $path_out
rm -f ${path_out}adriac_grd_1km_1.5m.nc

echo " " 
echo "================================================================"
echo "=================== end of the procedure ======================="
echo "================================================================"
