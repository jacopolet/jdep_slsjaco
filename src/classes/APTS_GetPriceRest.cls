@RestResource(urlMapping='/price/*')
global with sharing class APTS_GetPriceRest {
@HttpGet
global static GetPriceReturnObject doGet() 
	{
        RestRequest req = RestContext.request;
		return APTS_CERUtility.getPrice(req.requestURI.substring(req.requestURI.lastIndexOf('/')+1));
    }
 
global class GetPriceReturnObject
	{
		public Boolean success;
		public String currencyCode;
		public String errorMessage;
		public List<GetPriceWrapper> response=new List<GetPriceWrapper>();
	}
global class GetPriceWrapper
    {
        //public Id  productId;
        public Decimal netPrice;
        //public Boolean isContracted;
        //public String paymentMethod;
        public String productCodeSAP;
        public String replacementProductCode;
       // public String sellingUom;
		public String priceUom;
        public String vatIndicator;
        public Decimal taxAmount;
	
    } 
}