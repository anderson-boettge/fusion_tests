/*
 * main.c
 *
 *  Created on: 26/01/2011
 *      Author: einstein
 */
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <time.h>

#define mat(i,j) mat[i*N+j]
#define proximo(x) x+1
#define anterior(x) x-1
#define MAX 512
#define INFINITO 999999
#define ZERO 0

int qtd = 0;

int N;
int upper_bound = INFINITO;


int mat[MAX];

void read(){
	int i , j ;
	scanf("%d", &N);
	for( i = 0 ; i < (N*N) ; i++ ){
        scanf("%d", &mat[ i ] ) ;
    }

}



void print(int *v,int custo_ciclo, int custo) {
	int i;
	for (i = 0; i < N; i++){
	    if(i<N-1)
            custo+=mat(v[i],v[i+1]);
        else
            custo+=mat(v[i],0);
		printf("%d ", v[i]);
    }

    printf("   custo: %d\n", custo);
	printf("\n");
}

int dfs2() {

	register int  vFlag[MAX];
	register int  vertice[MAX]; //representa o ciclo

	register int custo = ZERO;
	register int i, nivel = 1; //para dizer que 0-1 ja foi visitado e a busca comeca de 1, bote 2
	
    /*Inicializacao*/
	for (i = 0; i < N; ++i) { //
		vFlag[i] = 0;
		vertice[i] = -1;
	}

    /*
        para dizer que 0-1 sao fixos
    */
    vertice[0] = 0;
    vFlag[0] = 1;



   	while (nivel >= 1) { // modificar aqui se quiser comecar a busca de determinado nivel

		if(vertice[nivel] !=-1 ) {vFlag[vertice[nivel]] = 0; custo-= mat(vertice[anterior(nivel)],vertice[nivel]);};

		do {
			vertice[nivel]++;
		} while (vertice[nivel] < N && vFlag[vertice[nivel]]); //


		if (vertice[nivel] < N) {

            custo+= mat(vertice[anterior(nivel)],vertice[nivel]);


			vFlag[vertice[nivel]] = 1;
			nivel++;

			if (nivel == N){ //se o vértice do nível for == N, entao formou o ciclo e vc soma peso + vertice anterior -> inicio
				++qtd;
				if(custo + mat(vertice[anterior(nivel)],0)<upper_bound)
                    upper_bound=custo + mat(vertice[anterior(nivel)],0);
				nivel--;
			}else{

			}
		} else {
			vertice[nivel] = -1;
			nivel--;

		}
	}

	return upper_bound;
}


int dfs_novo() {

	register int  vFlag[MAX];
	register int  vertice[MAX]; //representa o ciclo

	register int custo = ZERO;
	register int i, nivel = 1;  //---> nivel zero ja tem a raiz


    /*Inicializacao*/
	for (i = 0; i < N; ++i) { //
		vFlag[i] = 0;
		vertice[i] = -1;
	}

    /*
        para dizer que 0-1 sao fixos
    */
    vertice[0] = 0; //raiz
    vFlag[0] = 1;



   	while (nivel >= 1) { // modificar aqui se quiser comecar a busca de determinado nivel

		if(vertice[nivel] !=-1 ) {
			vFlag[vertice[nivel]] = 0; 
			custo-= mat(vertice[anterior(nivel)],vertice[nivel]);
		}

		for(vertice[nivel]++;vertice[nivel] < N && vFlag[vertice[nivel]]; vertice[nivel]++); //

		if (vertice[nivel] < N) {

            custo+= mat(vertice[anterior(nivel)],vertice[nivel]);


			vFlag[vertice[nivel]] = 1;
			nivel++;

			if (nivel == N){ //se o vértice do nível for == N, entao formou o ciclo e vc soma peso + vertice anterior -> inicio
				++qtd;
				if(custo + mat(vertice[anterior(nivel)],0)<upper_bound)
                    upper_bound=custo + mat(vertice[anterior(nivel)],0);
				nivel--;
			}else{

			}
		} else {
			vertice[nivel] = -1;
			nivel--;

		}
	}

	return upper_bound;
}

/*
void dfs_agoravai(){

	int i;

	int stack[ MAX ];
	int len_stack = -1;
	int vFLag[ MAX ];

	memset(vFlag, 0, sizeof(vFlag));

	//mat(0,0)
	stack[ 0 ] = 0; len_stack = 0;

	while(len_stack > -1){
		int node = stack[ len_stack-- ];

		if(vFlag[ node ] == 0){
				Processa o node
			vFlag[ node ] = 1;
			for(i = 0; i < N; i++){
				if(mat(node, i) != INFINITO){
					stack[ len_stack++ ] = i;
				}
			}
		}

	}

	


}




	
	Initialize Stack S with root node ROOT;  //if it is graph, it is any beginning node K;
	while S.isNotEmpty()
	{
		node v = S.pop();
		if   v.isVisitedBefore() == false{
		 	process(v);
			mark v as visited;
			for all children i of node v // if it is graph, all vertices i adjacent to v
				push i into Stack S;
		} 
	}





}*/







int main() {
	//	dfs();
	int i,j;
	time_t tempo_inicial, tempo_final;
	read();
	
	tempo_inicial= time(NULL);
	printf("#################################\nTODAS SOL - SERIAL E N RECURSIVO\n");
	printf("\nDimensao: %d",N);
	printf("\nOtimo dfs2(): %d", dfs_novo());
	tempo_final = time(NULL);
	printf("\nQTD de solucoes encontradas:%d.\n",qtd);
	printf("\n\tTEMPO(S): %f\n\n", (double)(tempo_final-tempo_inicial));
	



// 	qtd = 0;
// 	upper_bound = INFINITO;
// 
// 	tempo_inicial= time(NULL);
// 
// 	printf("#################################\nTODAS SOL - SERIAL E N RECURSIVO\n");
// 	printf("\nDimensao: %d",N);
// 	printf("\nOtimo dfs_tentavia(): %d", dfs2());
// 	tempo_final = time(NULL);
// 	printf("\nQTD de solucoes encontradas:%d.\n",qtd);
// 	printf("\n\tTEMPO(S): %f\n\n", (double)(tempo_final-tempo_inicial));
// 	

    /*for(i = 0; i<N; ++i){
        for(j = 0; j<N; ++j){
            printf("%d ", mat(i,j));
        }
        puts("\n");
    }*/

	return 0;
}
