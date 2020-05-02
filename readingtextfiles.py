import os
import csv
import re
from pathlib import Path
import matplotlib.pyplot as plt


time_to_be_commited_val_X= []
time_to_be_commited_val_Y= []

time_to_leader_election_val= {}

all_files = os.listdir("1234/")
txt_files = filter(lambda x: x[-4:] == '.txt', all_files)

for e in txt_files:
    print(Path(e).stem)
    latency = re.search( r'(.*?)-(.*?)', Path(e).stem, re.M|re.I)
    print(latency.group(1))

    with open("1234/" + str(e), "r") as a_file:
        for line in a_file:

            matchObj1 = re.search( r'time spent = (.*?)ms, (.*?), response type = /etcdserverpb.KV/Put', line.strip(), re.M|re.I)
            
            if matchObj1:
                time_to_be_commited_val_X.append(float(latency.group(1)))
                time_to_be_commited_val_Y.append(float(matchObj1.group(1)))
                print (matchObj1.group(1))
            
    
    a_file.close



#min_lista=zip(*min_lista)

##with open('innovators.csv', 'w', newline='') as file:
  ##  writer = csv.writer(file)
    ##writer.writerows(min_lista)

if len(time_to_be_commited_val_X) == len(time_to_be_commited_val_Y):
    plt.plot(time_to_be_commited_val_X, time_to_be_commited_val_Y)
    plt.ylabel('Time to be commited (ms)')
    plt.xlabel('Latency (ms) | Var(X)= 0 ms')
    plt.show()
else:
    print("x and y lists are of diffrent length")
#plt.savefig('books_read.png')

