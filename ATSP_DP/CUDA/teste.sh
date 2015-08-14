#!/bin/bash

for contador in {1..20}
do 
       (time (time ./a.out < 14.txt) 2>>sai14.txt)
done

for contador in {1..10}
do 
       (time (time ./a.out < 15.txt) 2>>sai15.txt)
done
