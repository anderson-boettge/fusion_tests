public class DFS_Solving {
	int _VAZIO_ = -1;
	int _VISITADO_ = 1;
	int _NAO_VISITADO_ = 0;
	
	int INFINITO = 999999;
	int ZERO = 0;
	int ONE = 1;
	
	int nivelPreFixos, nivelDesejado, N;
	DFS_intermediario dfs_intermediario;
	int[] mat_h;
	
	DFS_Solving(int N, int[] mat_h, int nivelPrefixos, int nivelDesejado){
		this.N=N;
		this.mat_h = mat_h;
		this.nivelPreFixos = nivelPrefixos;
		this.nivelDesejado = nivelDesejado;
	}
	
	static{
	  System.loadLibrary("dfs");
	}
	
	public int[] getQTSol(){
	   System.out.println("BUSCANDO SOLUÇÕES");
	   int [] r = new int[2];
	   r = dfs_intermediario.getQTSolutions();
	   return r;
	}
	
	class DFS_intermediario{
		
		int nPreFixos;
		int qtd_prefixos_segundo_dfs;
		int qtd_prefixos_locais;
		int[] path_second_dfs_d;
		
		int[] qtd_sols_d; 
		int[] melhor_sol_d;
		int[] path_d;
		int[] mat_d;
		
		int block_size;
		int n_blocks;
		
		DFS_intermediario(){
			
		}
		//Receive and set data for cuda operations
		public void setData(int[] path_h, int nPreFixos, int qtd_prefixos_segundo_dfs, 
				int qtd_prefixos_locais, int[] qtd_sols_h, int[] melhor_sol_h){
			block_size = 192;
			n_blocks = nPreFixos / block_size + (nPreFixos % block_size == 0 ? 0 : 1);
			setData_c(N, mat_h, nivelPreFixos, nivelDesejado, path_h, nPreFixos, qtd_prefixos_segundo_dfs, 
			  qtd_prefixos_locais, qtd_sols_h, melhor_sol_h);	
		}
		public native void setData_c(int N, int[] mat, int nivelPreFixos, int nivelDesejado, int[] path, 
		  int npreFixos, int qtd_prefixos_segundo_dfs, int qtd_prefixos_locais, int[] qtd_sols_h, int[] melhor_sol_h);
		  
		//Implements kernel dfs_intermediario
		public void solDFS_intermediario(){ k_dfs_intermediario(block_size,n_blocks);};
		public native void k_dfs_intermediario(int grid, int block);
		
		//Implements kernel dfs_final
		public native void dfs_final(int N, int[] mat_d, int[] preFixos_d, int nPrefixosNivelDesejado, 
				int nivelDesejado, int[] sols_d,  int[] melhorSol_d, int salto);
		
		//Get solution
		public native int[] getQTSolutions();
		
	}	
}
