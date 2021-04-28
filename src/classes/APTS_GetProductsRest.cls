@RestResource(urlMapping='/product/*')
global with sharing class APTS_GetProductsRest {
@HttpGet
global static GetProductReturnObject doGet() 
    {
        RestRequest req = RestContext.request;
        return APTS_CERUtility.getProduct(req.requestURI.substring(req.requestURI.lastIndexOf('/')+1));
    }
 
global class GetProductReturnObject
    {
        public Boolean success;
		public String currencyCode;
        public String errorMessage;
        public List<GetProductsWrapper> response=new List<GetProductsWrapper>();
    }
global class GetProductsWrapper
    {
        public Decimal netPrice;
        public String productCodeSAP;
		public String replacementProductCode;
        public String sellingUom;
		public String priceUom;
        public String vatIndicator;
        public Decimal taxAmount;
    } 
}