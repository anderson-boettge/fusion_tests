#include <stdio.h>
#include <stdlib.h>
#include <sys/time.h>
#include <cuda.h>

#include "MultiAccel.h"
#include "MultiAccel_Calc.h"



__global__ void mult_mat(float *matA, float *matB, float *result_d, int ncol, int nRows, int stream) {
	int idx = blockIdx.x * blockDim.x + threadIdx.x;
	int idy = blockIdx.y * blockDim.y + threadIdx.y;
	int nPr = stream*ncol*nRows;
	float res=0;
	for(int i=0; i<ncol; i++){
	  res += matA[ncol*idy+i] * matB[i*ncol+idx];
	}
	result_d[nPr+idy*ncol+idx] = res;
}


int pool_h, rowA_h, colB_h, nRows_h;
float *matA_d, *matB_d, *result_d;
float *matA_h, *matB_h, *result_h;
cudaStream_t vectorOfStreams[4];

JNIEXPORT void JNICALL Java_MultiAccel_setDataCall
  (JNIEnv *env, jobject jobj, jfloatArray matA, jfloatArray matB, jint rowA, jint colB, jint pool){
    
    matA_h = env->GetFloatArrayElements(matA,0);
    jsize len = env->GetArrayLength(matA);
    cudaMalloc((void **) &matA_d, len*sizeof(float));
    
    matB_h = env->GetFloatArrayElements(matB,0);
    len = env->GetArrayLength(matB);
    cudaMalloc((void **) &matB_d, len*sizeof(float));
    cudaMemcpy(matB_d, matB_h, sizeof(float)*len, cudaMemcpyHostToDevice);
   /* 
    printf("\n\nMatB recebida>>>>>>>");
    for(int i=0;i<len;i++)
      printf("%.2f ", matB_h[i]);
    printf("<<<<<<<MatB recebida\n\n");
    */
    result_h = (float*) malloc(sizeof(float)*len);
    cudaMalloc((void **) &result_d, rowA*colB*sizeof(float));
    
    rowA_h = rowA;
    colB_h = colB;
    pool_h = pool;
  }

JNIEXPORT jfloatArray JNICALL Java_MultiAccel_getResult
  (JNIEnv *env, jobject jobj){
    jfloatArray result = env->NewFloatArray(rowA_h*colB_h);
    jfloat *narr = env->GetFloatArrayElements(result, NULL);
    
    cudaDeviceSynchronize();
    
    narr = result_h;
    
    env->ReleaseFloatArrayElements(result, narr,0);
    cudaFree(matA_d);
    cudaFree(matB_d);
    cudaFree(result_d);
//     free(matA_h);
//     free(matB_h);
//     free(result_h);
    return(jfloatArray) result;
  }
  
JNIEXPORT void JNICALL Java_MultiAccel_00024Calc_multiplyCall
  (JNIEnv *env, jobject jobj, jfloatArray matA, jfloatArray matB, jint nRows, jint colB, jint index, jint gx,
		  jint gy, jint gz, jint bx, jint by, jint bz){
  dim3 block(bx,by,bz);	
  dim3 grid(gx,gy,gz);

  mult_mat<<<grid,block,0,vectorOfStreams[index]>>>
			  (&matA_d[nRows*index*colB],matB_d,result_d, colB, nRows,index);
			  
  cudaMemcpyAsync(&result_h[nRows*index*colB], &result_d[nRows*index*colB],
			  colB*nRows*sizeof(float),cudaMemcpyDeviceToHost, vectorOfStreams[index]);
}

/*
 * Class:     MultiAccel
 * Method:    createStream
 * Signature: (I)V
 */
JNIEXPORT void JNICALL Java_MultiAccel_00024Calc_createStream
  (JNIEnv *env, jobject jobj, jint index, jfloatArray matA, jint initialIdx, jint size){ 
  
  cudaStreamCreate(&vectorOfStreams[index]);
  cudaMemcpyAsync(&matA_d[initialIdx],&matA_h[initialIdx],size*sizeof(float),cudaMemcpyHostToDevice,vectorOfStreams[index]);

  }
