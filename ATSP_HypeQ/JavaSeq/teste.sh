#!/bin/bash
rm -f saida*.txt

for contador in $(seq $1)
  do 
(time (time java EnumerationDFS < 13.txt) 2>> saida13.txt)

sleep 1;

done

