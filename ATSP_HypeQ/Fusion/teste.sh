#!/bin/bash

for contador in {1..15}
do 
       (time (time java -Djava.library.path=. CompEnumUnits_4threads < 12.txt) 2>>sai12.txt)
done

for contador in {1..15}
do 
       (time (time java -Djava.library.path=. CompEnumUnits_4threads < 13.txt) 2>>sai13.txt)
done

for contador in {1..15}
do 
       (time (time java -Djava.library.path=. CompEnumUnits_4threads < 15.txt) 2>>sai15.txt)
done

