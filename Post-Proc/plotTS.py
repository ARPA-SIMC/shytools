#==========================================#
#===== plot Shyfem time series ============#
#==========================================#
# -*- coding: utf-8 -*-

#-------- under development ------------#

# add argparse to choose correct variables and names

import pandas as pd
import sys
import matplotlib.pyplot as plt

fin = sys.argv[1]

ts = pd.read_csv(fin,sep="\s+|::",usecols=[0,1,2],parse_dates=[[0,1]],engine='python',infer_datetime_format=True)
ts.columns=["date","values"]

plt.figure(1)
ax = plt.gca()
ax.grid(which='major', axis='both', linestyle='--',alpha=0.7)
plt.title('sea level PG',fontsize=25)
plt.xlabel("Time")
plt.ylabel('sea level [m]')
plt.plot(ts['date'],ts['values'])
#plt.ylim((0,40))
plt.show()
