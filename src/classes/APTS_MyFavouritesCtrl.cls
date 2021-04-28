public class APTS_MyFavouritesCtrl
{
    private String flow;
    private String configRequestId;
    private String configId;
    public APTS_MyFavouritesCtrl()
    {
    
      configId = ApexPages.currentPage().getParameters().get('id');   
      flow = ApexPages.currentPage().getParameters().get('flow');
      configRequestId = ApexPages.currentPage().getParameters().get('configRequestId');
    
    }
    
    //Method used to redirect back to the cart 
    public PageReference redirectToFavoritePage(){  
         PageReference pg;
         pg = new PageReference('/apex/Apttus_Config2__Cart?id='+configId+'&flow='+flow+'&configRequestId='+configRequestId+'#!/favorites/');
         return pg; 
    }
}