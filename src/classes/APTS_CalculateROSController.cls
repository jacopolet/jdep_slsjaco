public with sharing class APTS_CalculateROSController{
    
    public Id agreementId {get;set;}
    public Apttus__APTS_Agreement__c oAgreement {get;set;}
    
    public APTS_CalculateROSController(ApexPages.StandardController stdController){
        agreementId = ApexPages.currentPage().getParameters().get('id');
        oAgreement = [SELECT ID, APTS_NetSalesValue__c, APTS_Adj_EBIT__c, APTS_ROS__c FROM Apttus__APTS_Agreement__c WHERE ID=:agreementId];
    }
    
    public PageReference calculateROS(){
        PageReference pg = new PageReference('/' + agreementId);
        try{
            if(oAgreement.APTS_Adj_EBIT__c !=0 && oAgreement.APTS_NetSalesValue__c !=0 && oAgreement.APTS_Adj_EBIT__c !=NULL && oAgreement.APTS_NetSalesValue__c !=NULL && oAgreement.APTS_Adj_EBIT__c > 0 && oAgreement.APTS_NetSalesValue__c > 0){
                oAgreement.APTS_ROS__c = (oAgreement.APTS_Adj_EBIT__c / oAgreement.APTS_NetSalesValue__c)*100;
                update oAgreement;
                return pg;
            }
            else{
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,Label.APTS_ROSCalculationError));
                return null;
            }
        }catch(exception e){APTS_CustomLogging.createErrorLog(e.getTypeName(), 'Apex', e.getStackTraceString() ,'Agreement', ApexPages.currentPage().getParameters().get('businessObjectId'),'CPQ',false,true,'cpqerror@accenture.com',true); return pg;
        }
    }
    
    public PageReference doCancel(){
         PageReference pg = new PageReference('/' + agreementId);
         return pg;
    }
    
}