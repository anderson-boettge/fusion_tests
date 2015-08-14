# Makefile
# Generic Makefile for making cuda programs
#
BIN               := libproxyEnumDFS
 
# flags
CUDA_INSTALL_PATH := /usr/local/cuda
CUDA_SDK_PATH     := /home/anderson/NVIDIA_Samples
JDK_PATH	  := /usr/lib/jvm/java-7-openjdk-i386
INCLUDES += -I. -I$(CUDA_INSTALL_PATH)/include -I$(CUDA_SDK_PATH)/common/inc -I$(JDK_PATH)/include -I$(JDK_PATH)/include/linux
LIBS              := -L$(CUDA_INSTALL_PATH)/lib -L.
CFLAGS            := -O2 -m32 -fPIC -MMD -MP
LDFLAGS           := -lrt -lm -lcudart 
# compilers
JAVAC		  := javac
JAVAH		  := javah
NVCC              := nvcc
CC                := gcc
LINKER            := gcc
# files
J_SOURCES	  := $(wildcard *.java)
C_SOURCES         := $(wildcard *.c)
#CLASS_FILES	  := $(patsubst %.java, %.class, $(J_SOURCES))
CLASS_FILES	  := $(wildcard *.class)
CU_SOURCES        := $(wildcard *.cu)
HEADERS           := $(wildcard *.h)
C_OBJS            := $(patsubst %.c, %.o, $(C_SOURCES))
CU_OBJS           := $(patsubst %.cu, %.o, $(CU_SOURCES))
ALL_OBJS	  := $(wildcard *.o)
 
$(BIN):	$(C_OBJS) $(CU_OBJS) $(HEADERS)
	$(LINKER) -m32 -shared -fPIC -o $(BIN).so *.o $(LDFLAGS) $(INCLUDES) $(LIBS) #$(ALL_OBJS)
 
$(C_OBJS): $(C_SOURCES) $(HEADERS) $(CU_OBJS)
	$(CC) *.c -c $(CFLAGS) $(INCLUDES) #-MF libProxy.o.d $(C_SOURCES) 
 
$(CU_OBJS): $(CU_SOURCES) $(HEADERS)
	$(NVCC) -Xptxas="-v" -arch sm_30 -c *.cu $(INCLUDES) #$(CU_SOURCES) 
 
java: clean $(J_SOURCES)
	$(JAVAC) $(J_SOURCES)
	$(JAVAH) -jni -classpath ./ Main #$(CLASS_FILES)

clean:
	rm -f $(BIN) *.o *.so *~ *.o.d *.class
