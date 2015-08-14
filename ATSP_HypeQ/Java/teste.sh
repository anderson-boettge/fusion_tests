#!/bin/bash
#rm -f saida*.txt

for contador in $(seq $1)
  do 
(time (time java CompleteEnumerationThread < 15.txt) 2>> saida15.txt)

sleep 1;

done

