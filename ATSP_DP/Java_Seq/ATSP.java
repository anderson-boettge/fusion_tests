import java.util.Scanner;
public class ATSP{

  int MAX =8192;
  int INFINITO =999999;
  int ZERO =0;
  int ONE =1;

  int _VAZIO_      =-1;
  int _VISITADO_   = 1;
  int _NAO_VISITADO_ =0;


  int qtd = 0;
  int custo = 0;
  int N;
  int melhor = INFINITO;
  int upper_bound;

  int mat_h[] = new int [MAX];

  int nivelPreFixos;
  int nivelDesejado;
  int otimo_global = INFINITO;
  int qtd_sols_global = ZERO;
  
  ATSP(int nivelPre, int nivelDes){
      read();
      nivelPreFixos = nivelPre;
      nivelDesejado = nivelDes;

      int nPreFixos = calculaNPrefixos();
      
      int [] path_h = new int [nPreFixos * nivelPreFixos];
	
      fillFixedPaths(path_h);
	System.out.println("Nivel inicial: "+ nivelPreFixos);
	System.out.println("Quantidade de prefixos no nivel inicial: "+ nPreFixos);

	// for(int i = 0; i<nPreFixos;++i){
	// 	for(int j = 0; j<nivelPreFixos;++j )
	// 		printf(" %d ", path_h[i*nivelPreFixos+j]);
	// 	printf("\n");
	// }


	System.out.println("Nivel desejado: "+ nivelDesejado);
	System.out.println("Prefixos individuais por pai no nivel desejado: "+ calculaNPrefixosNivelDesejado());
	System.out.println("Prefixos totais no nivel desejado:"+ calculaNPrefixosNivelDesejado()*nPreFixos);
      
	//para nprefixos nivel inicial, imprimir as raizes de dfs descendentes criados
	for(int vertex = 0; vertex < nPreFixos; ++vertex){
		qtd_sols_global += dfs2(path_h, vertex) ;
	}

	
      
  }
  
  public int getSolsGlobal(){
    return qtd_sols_global;
  }
  
  public int getOtimoGlobal(){
    return otimo_global;
  }
  
  int proximo (int x){
    return x+1;
  }

  int anterior (int x){
    return x-1;
  }

  int mat_h (int i, int j){
    return mat_h[i*N+j];
  }
  
  private void read() {
    int i;
    //scanf("%d", &upper_bound);
    Scanner entrada = new Scanner(System.in);
    N = entrada.nextInt();;
    for (i = 0; i < (N * N); i++) {
      mat_h[i]=entrada.nextInt();
    }
  }	

  private int fatorBranchingNivelDesejado(int nivel){
     return N-nivel+1;
  }

  private int calculaNPrefixos() {
	int x = N - 1;
	int i;
	for (i = 1; i < nivelPreFixos-1; ++i) {
		x *= N - i-1;
	}
	return x;
  }

private int calculaNPrefixosNivelDesejado() {
	int nivelBusca = nivelPreFixos+1;
	int i;
	int nprefixos = 1;
	for (i = nivelBusca; i <=nivelDesejado; ++i) {
		nprefixos *= fatorBranchingNivelDesejado(i);
	}
	return nprefixos;
}

boolean flag(int i){
  if(i==0) return false;
  return true;
} 

private void fillFixedPaths(int[] preFixo) {
	int vflag[]= new int[16];
	int vertice[] = new int [16]; //representa o ciclo
	int cont = 0;
	int i, nivel; //para dizer que 0-1 ja foi visitado e a busca comeca de 1, bote 2

	for (i = 0; i < N; ++i) {
		vflag[i] = 0;
		vertice[i] = -1;
	}

	vertice[0] = 0; //aqui!!!! vertice[nivel] = idx vflag[idx] = 1
	vflag[0] = 1;
	nivel = 1;
	while (nivel >= 1) { // modificar aqui se quiser comecar a busca de determinado nivel
		if (vertice[nivel] != -1) {
			vflag[vertice[nivel]] = 0;
		}
		do {
			vertice[nivel]++;
		} while (vertice[nivel] < N && flag(vflag[vertice[nivel]])); //

		if (vertice[nivel] < N) { //vertice[x] vertice no nivel x
			vflag[vertice[nivel]] = 1;
			nivel++;
			if (nivel == nivelPreFixos) {
				for (i = 0; i < nivelPreFixos; ++i) {
					preFixo[cont * nivelPreFixos + i] = vertice[i];
//					printf("%d ", vertice[i]);
				}
//				printf("\n");
				cont++;
				nivel--;
			}
		} else {
			vertice[nivel] = -1;
			nivel--;
		}//else
	}//while
}

private int finalDFS(int preFixos[],  int idx, int [] melhor_sol,  int nPreFixos){
	
	int vflag[] = new int[16];
	int vertice[] = new int [16]; //representa o ciclo
	
	int i, nivel; //para dizer que 0-1 ja foi visitado e a busca comeca de 1, bote 2
	int custo=0; 
	int qtd_solucoes_thread = 0;
	int UB_local = INFINITO;
	int nivelGlobal = nivelDesejado;

	if (idx < nPreFixos) { //(@)botar algo com vflag aqui, pois do jeito que esta algumas threads tentarao descer.
		for (i = 0; i < N; ++i) {
			vertice[i] = _VAZIO_;
			vflag[i] = _NAO_VISITADO_;
		}
		
		vertice[0] = 0;
		vflag[0] = _VISITADO_;
		custo= ZERO;
		
		for (i = 1; i < nivelGlobal; ++i) {
			vertice[i] = preFixos[idx * nivelGlobal + i];
			vflag[vertice[i]] = _VISITADO_;
			custo += mat_h(vertice[i-1],vertice[i]);
		}
		
		nivel=nivelDesejado;

		while (nivel >= nivelGlobal ) { // modificar aqui se quiser comecar a busca de determinado nivel

			if (vertice[nivel] != _VAZIO_) {
				vflag[vertice[nivel]] = _NAO_VISITADO_;
				custo -= mat_h(vertice[anterior(nivel)],vertice[nivel]);
			}
			do {
				vertice[nivel]++;
			} while (vertice[nivel] < N && flag(vflag[vertice[nivel]])); //

			if (vertice[nivel] < N) { //vertice[x] vertice no nivel x
				custo += mat_h(vertice[anterior(nivel)],vertice[nivel]);
				vflag[vertice[nivel]] = _VISITADO_;
				nivel++;
				if (nivel == N) { //se o vértice do nível for == N, entao formou o ciclo e vc soma peso + vertice anterior -> inicio
					++qtd_solucoes_thread;
					if (custo + mat_h(vertice[anterior(nivel)],0) < UB_local) {
						UB_local = custo + mat_h(vertice[anterior(nivel)],0);
					}
					nivel--;
				}
				//else {
					//if (custo > custoMin_d[0])
						//nivel--; //poda, LB maior que UB
				//}
			}
			else {
				vertice[nivel] = _VAZIO_;
				nivel--;
			}//else
		}//while
	}//dfs

	if(UB_local < (melhor_sol[0])){
		melhor_sol[0] = UB_local;
	}
	return qtd_solucoes_thread;
}

int dfs2( int preFixos[],  int idx) {

	//pode tirar o idx

	int vflag[]= new int[16];
	int vertice[] = new int [16]; //representa o ciclo
	int i, nivel; //para dizer que 0-1 ja foi visitado e a busca comeca de 1, bote 2
	
	int qtd_solucoes_local = 0;
	int qtd_solucoes_filho = 0;

	int cont = 0;

	int qtd_prefixos_locais =  calculaNPrefixosNivelDesejado();

	int melhor_sol[] = new int[1];
	melhor_sol[0] = INFINITO;

	int []path_local;

	path_local = new int [ nivelDesejado *  qtd_prefixos_locais]; 
		

		for (i = 0; i < N; ++i) {
			vertice[i] = _VAZIO_;
			vflag[i] = _NAO_VISITADO_;
		}
		
		vertice[0] = 0;
		vflag[0] = _VISITADO_;
		custo= ZERO;
		
		for (i = 1; i < nivelPreFixos; ++i) {
			vertice[i] = preFixos[idx * nivelPreFixos + i];
			vflag[vertice[i]] = _VISITADO_;
		}
		
		nivel=nivelPreFixos;

		while (nivel >= nivelPreFixos ) { // modificar aqui se quiser comecar a busca de determinado nivel

			if (vertice[nivel] != _VAZIO_) {
				vflag[vertice[nivel]] = _NAO_VISITADO_;
			}

			do {
				vertice[nivel]++;
			} while (vertice[nivel] < N && flag(vflag[vertice[nivel]])); //


			if (vertice[nivel] < N) { //vertice[x] vertice no nivel x
			
				vflag[vertice[nivel]] = _VISITADO_;
				nivel++;

				if (nivel == nivelDesejado) { //se o vértice do nível for == N, entao formou o ciclo e vc soma peso + vertice anterior -> inicio
						
					for (i = 0; i < nivelDesejado; ++i) {
						path_local[cont * nivelDesejado + i] = vertice[i];
					}
					++cont;
					nivel--;
				}
		
			}
			else {
				vertice[nivel] = _VAZIO_;
				nivel--;
			}//else
		}//while

	
	// for(int pref = 0; pref < qtd_prefixos_locais; ++pref){
	// 	for(int j = 0; j<nivelDesejado;++j){

	// 		printf(" %d ", path_local[pref*nivelDesejado + j]);
	// 	}
	// 	printf("\n");
	// }

	for(int pref = 0; pref < qtd_prefixos_locais; ++pref){
		qtd_solucoes_filho = finalDFS(path_local,pref, melhor_sol, qtd_prefixos_locais);
		qtd_solucoes_local+=qtd_solucoes_filho;
	}

	if(melhor_sol[0] < (otimo_global)){
		otimo_global = melhor_sol[0];
	}

	return qtd_solucoes_local;
}//dfs2




public static void main(String args[]) {
	ATSP atsp = new ATSP(5,8);
	System.out.println("Quantidade de solucoes Global: "+ atsp.getSolsGlobal());
	System.out.println("Otimo global: "+ atsp.getOtimoGlobal());
}
}