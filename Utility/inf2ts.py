#=================================================================#
#==== extract volume mean t/s time series from .inf file==========#
#=================================================================#
from datetime import datetime
from datetime import timedelta 
import matplotlib.pyplot as plt
import pandas as pd
import numpy as np

############################## some plot configurations ###################
plt.rc('axes', labelsize=30)
plt.rc('xtick', labelsize=15)
plt.rc('ytick', labelsize=15)

#------------ matching names -------------
match = (" temp:")
match1 = ("total_volume:")
match2 = (" salt:")

#------------- variables ------------
tot_vol = []
tot_temp= []
tot_salt= []
date = []
date0=datetime.strptime('2010-01-01::00:00:00','%Y-%m-%d::%H:%M:%S')

#------- read total_volume, timstep and integrated salt and temperature from .inf -------#
i=0
fnum=("0000","0001","0002","0003","0004","0005","0006","0007","0008","0009","0010")
#j=0
for j in range(len(fnum)):
  #--------------- maybe adding standard input for prefix is better --------------#
  with open("NBS_ER_chunk_"+fnum[j]+".inf") as fin:
    #print(' : {}', fin.name)
    for line in fin:
        #------------ total volume and adjust date to human readable ---------#
        if match1 in line:
            line = line.split()
            dt=int(line[1])
            date.append(date0 + timedelta(seconds=dt))
            tot_vol.append(float(line[2]))
        #------------- compute basin mean temperature -------------#
        if match in line:
            line = line.split()
            temp = float(line[2])
            tot_temp.append(temp/tot_vol[i])
        #------------- compute basin mean salinity ----------------#
        if match2 in line:
            line = line.split()
            salt = float(line[2])
            tot_salt.append(salt/tot_vol[i])
            i=i+1

#-------------- plot basin means ------------#

# total volume
#--------- fit data with a line ----------
x_val = np.linspace(0,1,len(tot_vol))
coeff_v = np.polyfit(x_val,tot_vol,1)
poly_eqn = np.poly1d(coeff_v)
y_hat = poly_eqn(x_val)

plt.figure(1)
ax = plt.gca()
ax.grid(which='major', axis='both', linestyle='--',alpha=0.7)
plt.title("total volume",fontsize=25)
plt.xlabel("date")
plt.ylabel("volume [m^3]")
plt.figtext(0.15,0.92,'trend = %6.3f m^3/t'%(coeff_v[0]),fontsize=20)
plt.plot(date,tot_vol,linewidth=2,alpha=0.5)
plt.plot(date,y_hat,linewidth=1,color='black')
# temperature
#--------- fit data with a line ----------
x_val = np.linspace(0,1,len(tot_temp))
coeff_t = np.polyfit(x_val,tot_temp,1)
poly_eqn = np.poly1d(coeff_t)
y_hat = poly_eqn(x_val)
print(coeff_t)
plt.figure(2)
ax = plt.gca()
ax.grid(which='major', axis='both', linestyle='--',alpha=0.7)
plt.title("basin mean temperature",fontsize=25)
plt.xlabel("date")
plt.ylabel("temperature [deg C]")
plt.figtext(0.15,0.92,'trend = %6.3f degC/t'%(coeff_t[0]),fontsize=20)
plt.plot(date,tot_temp,linewidth=3,color='red')
plt.plot(date,y_hat,linewidth=1,color='black')
# salinity
#--------- fit data with a line ----------
x_val = np.linspace(0,1,len(tot_salt))
coeff_s = np.polyfit(x_val,tot_salt,1)
poly_eqn = np.poly1d(coeff_s)
y_hat = poly_eqn(x_val)

plt.figure(3)
ax = plt.gca()
ax.grid(which='major', axis='both', linestyle='--',alpha=0.7)
plt.title("basin mean salinity",fontsize=25)
plt.xlabel("date")
plt.ylabel("salinity [psu]")
plt.figtext(0.15,0.92,'trend = %6.3f psu/t'%(coeff_s[0]),fontsize=20)
plt.plot(date,tot_salt,linewidth=3,color='darkgreen')
plt.plot(date,y_hat,linewidth=1,color='black')
plt.show()

               

