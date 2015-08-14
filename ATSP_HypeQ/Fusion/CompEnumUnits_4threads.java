/*
 * main.c
 *
 *  Created on: 26/01/2011
 *      Author: einstein/carneiro
 */
import java.util.Scanner;
import java.util.*;
import java.io.*;

public class CompEnumUnits_4threads{

int MAX = 512;
int INFINITO = 999999;
int ZERO = 0;
int ONE = 1;

int _VAZIO_ = -1;
int _VISITADO_ = 1;
int _NAO_VISITADO_ = 0;

int qtd = 0, ret;
int custo = 0;
int N;
int melhor = INFINITO;
int upper_bound;

short [] path;

int nivelPreFixos, numThreads;

int[] mat;

EnumAccel enumAccel;

CompEnumUnits_4threads(int n){
  numThreads = 4;
  read();    
  System.out.println("\n\nEnumeracao com ObjetoAcelerador:\n\n");
  nivelPreFixos = n;
  upper_bound = INFINITO;
  callCompleteEnumUnits();
}

static{
  System.loadLibrary("proxyEnumDFS");
}

int proximo (int x){
  return x+1;
}

int anterior (int x){
  return x-1;
}

int mat (int i, int j){
  return mat[i*N+j];
}


void read(){
  Scanner entrada = new Scanner(System.in);
  int i , j ;
  N = entrada.nextInt();
  mat = new int [N*N];
  for( i = 0 ; i < (N*N) ; i++ ){
    mat[i]= entrada.nextInt();
  }
}

int calculaNPrefixos(int nVertice) {
	int  x = nVertice - 1;
	int i;
	for (i = 1; i < nivelPreFixos-1; ++i) {
		x *= nVertice - i-1;
	}
	return x;
}

boolean flag (int i){return (i==0?false:true);}

void fillFixedPaths() {
	int[] flag = new int[16];
	int[] vertice = new int [16]; 
	int cont = 0;
	int i, nivel; 


	for (i = 0; i < N; ++i) {
		flag[i] = 0;
		vertice[i] = -1;
	}

	vertice[0] = 0; 
	flag[0] = 1;
	nivel = 1;
	while (nivel >= 1){
		if (vertice[nivel] != -1) {
			flag[vertice[nivel]] = 0;
		}
		do {
			vertice[nivel]++;
		} while (vertice[nivel] < N && flag(flag[vertice[nivel]])); 

		if (vertice[nivel] < N) { 
			flag[vertice[nivel]] = 1;
			nivel++;
			if (nivel == nivelPreFixos) {
				for (i = 0; i < nivelPreFixos; ++i) {
					path[cont * nivelPreFixos + i] = (short)vertice[i];
				}
				cont++;
				nivel--;
			}
		} else {
			vertice[nivel] = -1;
			nivel--;
		}
	}
}




void callCompleteEnumUnits(){
  int nPreFixos = calculaNPrefixos(N);
System.out.println(""+nPreFixos);
  path = new short [nPreFixos * nivelPreFixos];
  int chunk = nPreFixos/numThreads; //para instancia 13: 2970
  
  fillFixedPaths(); 
  
  myThread[] threadPool = new myThread[numThreads];
  
  enumAccel = new EnumAccel();
  
//   for (int i=0; i<mat.length; i++) System.out.println(" "+mat[i]);
  
  enumAccel.setData(mat,nivelPreFixos,nPreFixos,N,path,numThreads);
  
  for (int i=0; i<numThreads; i++){
      threadPool[i] = new myThread(i); 
      threadPool[i].start();
  }
  
  for (int i=0; i<numThreads; i++){
    try{
      threadPool[i].join();
    }catch (InterruptedException e){}
  }
  
  qtd = enumAccel.getQTSol();
  upper_bound = enumAccel.getSolO();
  enumAccel.clearAll();
//   System.out.println("\n\n\n\t niveis preenchidos: "+nivelPreFixos);
// 
//   System.out.println("\t Numero de streams: "+numThreads);
//   System.out.println("\t Tamanho do stream: "+chunk);
  System.out.println("Quantidade de solucoes encontradas: "+ qtd);
  System.out.println("Otimo global: "+ upper_bound);

}

  public static void main(String args[]) {
    int niveis = 5;
//     System.out.println("CompEnumUnits");
    CompEnumUnits_4threads obj = new CompEnumUnits_4threads(niveis);
  }

  public class myThread extends Thread{
  //__global__ void dfs_cuda_UB_stream(int N,int stream_size, int *mat_d, short *preFixos_d, int nivelPrefixo, int upper_bound, int *sols_d, int *melhorSol_d)
    
    
      //register int idx = blockIdx.x * blockDim.x + threadIdx.x;
    int index;
    EnumAccel.Unit enumUnit;
    
    myThread(int index)
    {
      this.index = index;
      enumUnit = enumAccel.new Unit(index);      
    }
    public void run(){
      ret = enumUnit.callCompleteEnumUnits(index);
    }
  }
}
