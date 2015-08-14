testmain : java link.o
	nvcc -shared -o libmulti.so Multi.o -L/usr/local/cuda-6.5/lib64 -lcudart; clear
	
link.o : Multi.cpp
	nvcc -Xcompiler -fpic -m64 -x cu -I$(JAVA_HOME)/include -I$(JAVA_HOME)/include/linux -I. -dc Multi.cpp -o Multi.o
	
java : 
	javac *.java; javah MultiAccel
clean :
	rm -f *.o *.so *.class *.h
	
#nvcc -x cu -arch=sm_35 -I. -dc dfs_final.cu -o dfs_final.o


#nvcc -x cu -arch=sm_35 -I/usr/lib/jvm/java-7-openjdk-i386/include -I/usr/lib/jvm/java-7-openjdk-i386/include/linux -I. -dc proxy.cpp -o proxy.o
#nvcc -x cu -arch=sm_35 -I. -dc dfs_final.cu -o dfs_final.o
#nvcc -arch=sm_35 -dlink -lcudadevrt proxy.o dfs_final.o -o gpuCode.o
#g++ -shared -Wl,-soname,libdfs.so -o libdfs.so proxy.o dfs_final.o gpuCode.o -L/usr/local/cuda/lib -Wall -lcudart
#java -Djava.library.path=. DFS_main < 11.txt

#objdump -DR libdfs.so
#/usr/lib/jvm/java-7-openjdk-i386/include