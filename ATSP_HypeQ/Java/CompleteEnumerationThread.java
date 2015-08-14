/*
 * main.c
 *
 *  Created on: 26/01/2011
 *      Author: einstein/carneiro
 */
import java.util.Scanner;
public class CompleteEnumerationThread{

int MAX = 512;
int INFINITO = 999999;
int ZERO = 0;
int ONE = 1;

int _VAZIO_ = -1;
int _VISITADO_ = 1;
int _NAO_VISITADO_ = 0;

int qtd = 0;
int custo = 0;
int N;
int melhor = INFINITO;
int upper_bound;

int [] path;

int nivelPrefixo;

int[] mat;

CompleteEnumerationThread(int n){
 nivelPrefixo = n;
 upper_bound = INFINITO;
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

int calculaNPrefixos(int nivelPrefixo, int nVertice) {
	int  x = nVertice - 1;
	int i;
	for (i = 1; i < nivelPrefixo-1; ++i) {
		x *= nVertice - i-1;
	}
	return x;
}

boolean flag (int i){return (i==0?false:true);}

void fillFixedPaths(int nivelPrefixo) {
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
			if (nivel == nivelPrefixo) {
				for (i = 0; i < nivelPrefixo; ++i) {
					path[cont * nivelPrefixo + i] = vertice[i];
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




void callCompleteEnumThreads(int nivelPreFixos){

	//myThread qtd_threads_streams;
  int numThreads = 4;
  
  int nPreFixos = calculaNPrefixos(nivelPreFixos,N);
  
//   System.out.println("nPreFIxos: "+ nPreFixos);	
  
  path = new int [nPreFixos * nivelPreFixos];
	
	/* Variaveis para os streams*/
	/* O número de streams será igual ao nPreFixos/4 */
	//const int chunk = 192*10;
  int chunk = nPreFixos/4; //para instancia 13: 2970
	//const int numStreams = nPreFixos / chunk + (nPreFixos % chunk == 0 ? 0 : 1); 
	
  fillFixedPaths(nivelPreFixos); 
  
  myThread[] threadPool = new myThread[numThreads];
  
  for (int i=0; i<numThreads; i++){
      threadPool[i] = new myThread(i,chunk); 
      threadPool[i].start();
  }
  
  for (int i=0; i<numThreads; i++){
    try{
      threadPool[i].join();
    }catch (InterruptedException e){}
  }
	
//   System.out.println("\n\n\n\t niveis preenchidos: "+nivelPreFixos);
// 
//   System.out.println("\t Numero de streams: "+numThreads);
//   System.out.println("\t Tamanho do stream: "+chunk);
//   System.out.println("\nQuantidade de solucoes encontradas: "+ qtd);
  System.out.println("\n\tOtimo global: "+ upper_bound);

}

  public static void main(String args[]) {
    int niveis = 5;
    CompleteEnumerationThread obj = new CompleteEnumerationThread(niveis);
    obj.read();    
    System.out.println("\n\nEnumeracao com Threads:\n\n");
    obj.callCompleteEnumThreads(niveis);
  }

  synchronized void atualizaUB(int ub){
    if (upper_bound>ub) upper_bound = ub;
    notifyAll();
  }

  synchronized void atualizaQTDSol(int qt){
    qtd +=  qt;
    notifyAll();
  }

  public class myThread extends Thread{
  //__global__ void dfs_cuda_UB_stream(int N,int stream_size, int *mat_d, short *preFixos_d, int nivelPrefixo, int upper_bound, int *sols_d, int *melhorSol_d)
    
    
      //register int idx = blockIdx.x * blockDim.x + threadIdx.x;
    int[] flag;
    int[] vertice; 

    int i, nivel, index;
    int custo;
    int qtd_solucoes_thread = 0;
    int UB_local;
    
    int stream_size_l;
    myThread(int index, int stream_size)
    {
      this.index = index;
      flag = new int [16];
      vertice = new int [16];
      stream_size_l = stream_size;
      UB_local = 999999;
    }
    public void run(){
      
      for (int raiz = 0; raiz< stream_size_l; raiz++){
	
	int idx = this.index*stream_size_l+raiz;
	
// 	if (idx < stream_size_l) {
// 	  System.out.println("idx "+idx+" thr: "+this.index);
	  for (i = 0; i < N; ++i) {
	    vertice[i] = _VAZIO_;
	    flag[i] = _NAO_VISITADO_;
	  }

	  vertice[0] = 0;
	  flag[0] = _VISITADO_;
	  custo= ZERO;

	  for (i = 1; i < nivelPrefixo; ++i) {
	    vertice[i] = path[idx * nivelPrefixo + i];
	    flag[vertice[i]] = _VISITADO_;
	    custo += mat(vertice[i-1],vertice[i]);
	  }

	  nivel=nivelPrefixo;

	  while (nivel >= nivelPrefixo ) {
	    if (vertice[nivel] != _VAZIO_) {
	      flag[vertice[nivel]] = _NAO_VISITADO_;
	      custo -= mat(vertice[anterior(nivel)],vertice[nivel]);
	    }

	    do {
	      vertice[nivel]++;
	    } while (vertice[nivel] < N && flag(flag[vertice[nivel]])); 
	    
	    if (vertice[nivel] < N) {
	      custo += mat(vertice[anterior(nivel)],vertice[nivel]);
	      flag[vertice[nivel]] = _VISITADO_;
	      nivel++;

	      if (nivel == N) {
		++qtd_solucoes_thread;
		if (custo + mat(vertice[anterior(nivel)],0) < UB_local) {
		  UB_local = custo + mat(vertice[anterior(nivel)],0);
		}
		nivel--;
	      }
	    }
	    else {
	      vertice[nivel] = _VAZIO_;
	      nivel--;
	    }
	  }
// 	}
      }
      //System.out.println("Thread: "+this.index + "Otimo_local: " +UB_local+" qtdSolucoes: "+qtd_solucoes_thread);
      atualizaUB(UB_local);
      atualizaQTDSol(qtd_solucoes_thread);
    }
  }
}
