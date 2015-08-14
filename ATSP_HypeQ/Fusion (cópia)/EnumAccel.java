public class EnumAccel {
  
  EnumAccel(){
    
  }

  static{
  System.loadLibrary("proxyEnumDFS");
}
  
  public native int setData(int[] mat, int nivelPreFixos,int nPreF, int N, short[] path, int numThreads);
  
  public native int getQTSol();
  
  public native int getSolO();
  
  public native void clearAll();
  
  public class Unit{
    int index;
    Unit(int index){
      this.index = index;
      createStream(this.index);
    }
    
    public native void createStream(int index);
    public native int callCompleteEnumUnits(int index);
  }
}