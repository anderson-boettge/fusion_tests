#!/bin/bash
rm -f saida*.txt

for contador in $(seq $1)
  do 
(time java CompEnumUnits < 11.txt) 2>> saida11.txt

sleep 1;

done

for contador in $(seq $1)
  do 
(time java CompEnumUnits < 12.txt) 2>> saida12.txt

sleep 1;

done

for contador in $(seq $1)
  do 
(time java CompEnumUnits < 13.txt) 2>> saida13.txt

sleep 1;

done
																																																																																																																																																																																																																																																														
for contador in $(seq $1)
  do 
(time java CompEnumUnits < 14.txt) 2>> saida14.txt

sleep 1;

done

for contador in $(seq $1)
  do 
(time java CompEnumUnits < 15.txt) 2>> saida15.txt

sleep 1;

done

