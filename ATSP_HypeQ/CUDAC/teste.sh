#!/bin/bash
#rm -f saida*.txt

for contador in {1..15}
  do 
(time (time ./CompleteEnumerationStream < 15.txt) 2>>sai15.txt)

sleep 1;

done
