#!/bin/bash

for contador in {1..10}
do 
      (java Multiply ../matrizA_1024x1024 ../matrizB_1024x1024 >> tempos1024.txt)
done
