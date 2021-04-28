@RestResource(urlMapping='/paymentdetail/*')
global with sharing class APTS_GetPaymentdetailRest {
@HttpGet
global static GetPaymentdetailReturnObject doGet() 
    {
        RestRequest req = RestContext.request;
        return APTS_CERUtility.getPaymentdetail(req.requestURI.substring(req.requestURI.lastIndexOf('/')+1));
    }
 
global class GetpaymentdetailReturnObject
    {
        public Boolean success;
        public String errorMessage;
        public String paymentterm;
        public String paymenttermid;
        public String paymenttermsapid;
        public String invoicedelivery;
    }

}