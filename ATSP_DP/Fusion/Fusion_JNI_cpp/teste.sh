#!/bin/bash

for contador in {1..32}
do 
       (time (time java -Djava.library.path=. DFS_main < 15.txt) 2>>sai15.txt)
done
