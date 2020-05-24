
import os
import csv
import re
from pathlib import Path
import matplotlib.pyplot as plt
import matplotlib.patches as mpatches
from matplotlib import cm

import numpy as np
import statistics 


from mpl_toolkits.mplot3d import Axes3D

all_files_node_level = os.listdir("test_results/")


for a in all_files_node_level:
    print('_________________________')

    all_files_log_level = os.listdir("test_results/"+ str(a))
    log_files = filter(lambda x: x[-10:] == 'remote.txt', all_files_log_level)
    all_average_time_to_commit = []
    all_latency= []

   
    for e in log_files:
        print('---------------------------')

        print('file ' + str(e))
        print('node ' + str(a))
        latency = re.search( r'(.*?)-(.*?)', Path(e).stem, re.M|re.I)
        print('         latency '+ str( float(latency.group(1))))

        with open("test_results/" + str(a) +"/"+str(e), "r") as a_file:

            term_nbr=0            
            number_of_values=0
            all_time_to_commit= []
            
            for line in a_file:

                readyToServ = re.search( r'ready to serve client requests', line.strip(), re.M|re.I)
                matchObj1 = re.search( r'time spent = (.*?)(ms|s), (.*?), response type = /etcdserverpb.KV/Put', line.strip(), re.M|re.I)
                matchObj2 = re.search( r'term (\d{1,10})', line.strip(), re.M|re.I)


                if readyToServ:
                    print ('         ' + str(readyToServ.group(0)) )

                if matchObj1:
                    number_of_values+=1

                    if matchObj1.group(2) == 'ms':
                        all_time_to_commit.append(float(matchObj1.group(1)))

                        print ('         Time to commit ' + str(float(matchObj1.group(1))) + ' ms' )

                    elif matchObj1.group(2) == 's':
                        all_time_to_commit.append(float(matchObj1.group(1)) * 1000)

                        print ('         Time to commit ' + str(float(matchObj1.group(1)) * 1000) + ' ms')

                    elif matchObj1.group(2) == 'µs':
                        all_time_to_commit.append(float(matchObj1.group(1)) * 0.001)
                        print ('         Time to commit ' + str(float(matchObj1.group(1)) * 0.001) + ' ms')


                if matchObj2:
                    if float(matchObj2.group(1)) > term_nbr:
                        term_nbr= float(matchObj2.group(1))
                

     

        print('         ___________________________')
        if all_time_to_commit:
            print('         Average time to commit '+ str(statistics.mean(all_time_to_commit)))
            all_average_time_to_commit.append(statistics.mean(all_time_to_commit))

            print('         Variance time to commit '+ str(statistics.variance(all_time_to_commit)))
        else:

            all_average_time_to_commit.append(float(0))
        
        all_latency.append(float(latency.group(1)))

        print('         Number of puts '+ str(number_of_values))
        print('         Elapsed terms '+ str(term_nbr))  

        a_file.close
    plt.plot(all_latency, all_average_time_to_commit )

plt.show()
    


    
