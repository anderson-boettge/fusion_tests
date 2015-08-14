#include <stdio.h>
#include <string.h>
#include <jni.h>
#include "EnumAccel.h"
/*
 * Class:     EnumAccel
 * Method:    setData
 * Signature: ([IIII[II)V
 */
JNIEXPORT jint JNICALL Java_EnumAccel_setData(JNIEnv *env, jobject jobj, jintArray mat, jint nivelPreF, jint nPreF, jint tam, jshortArray path, jint nS){
//      printf("setData::proxy");
     jint *a = (*env)->GetIntArrayElements(env, mat, 0);
     jint *p = (*env)->GetShortArrayElements(env, path, 0);
//      int i;
//      jsize len = (*env)->GetArrayLength(env, mat);
//      for (i=0;i<len;i++){
// 	printf("%d ", a[i]);
//      }
     
     int r = completeEnum(a, nivelPreF, nPreF, tam, p, nS);
     return (jint)r;
}

/*
 * Class:     EnumAccel
 * Method:    getResult
 * Signature: (II)V
 */
JNIEXPORT jint JNICALL Java_EnumAccel_getQTSol(JNIEnv *env, jobject jobj){
  int qt = getQT();
  //(*env)->ReleaseFloatArrayElements(env, upper, c, 0);
  return (jint)qt;
}

JNIEXPORT jint JNICALL Java_EnumAccel_getSolO(JNIEnv *env, jobject jobj){
  int sol = getSol();
  //(*env)->ReleaseFloatArrayElements(env, upper, c, 0);
  return (jint)sol;
  
}
/*
 * Class:     EnumAccel
 * Method:    getResult
 * Signature: (II)V
 */
JNIEXPORT void JNICALL Java_EnumAccel_clearAll(JNIEnv *env, jobject jobj){
  int c = clearAll();
  
}
  
/*
 * Class:     EnumAccel_Unit
 * Method:    creatStream
 * Signature: (I)V
 */
JNIEXPORT void JNICALL Java_EnumAccel_00024Unit_createStream (JNIEnv *env, jobject jobj, jint rank){

  int h = createStream(rank);
}

/*
 * Class:     EnumAccel_Unit
 * Method:    callCompleteEnumUnits
 * Signature: (I)I
 */

JNIEXPORT jint JNICALL Java_EnumAccel_00024Unit_callCompleteEnumUnits(JNIEnv *env, jobject jobj, jint rank){

  callCompleteEnumStreams(rank);
}
