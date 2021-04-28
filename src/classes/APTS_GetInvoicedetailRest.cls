@RestResource(urlMapping='/invoicedetail/*')
global with sharing class APTS_GetInvoicedetailRest {
@HttpGet
global static GetInvoicedetailReturnObject doGet() 
    {
        RestRequest req = RestContext.request;
        return APTS_CERUtility.getinvoicedetail(req.requestURI.substring(req.requestURI.lastIndexOf('/')+1));
    }
 
global class GetInvoicedetailReturnObject
    {
        public Boolean success;
        public String errorMessage;
        public Boolean freightcharge;
        public Boolean invoicepayment;
        public Boolean freepaperinvoice;
    }
}