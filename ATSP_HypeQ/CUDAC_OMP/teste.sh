#!/bin/bash

for contador in {1..32}
do 
       (time (time ./a.out < 12.txt) 2>>sai12.txt)
done

for contador in {1..32}
do 
	(time(time ./a.out < 13.txt) 2>> sai13.txt)
done

for contador in {1..22}
do
	(time (time ./a.out < 14.txt) 2>>sai14.txt)
done

for contador in {1..10}
do 
	(time (time ./a.out < 15.txt) 2>>sai15.txt)
done
