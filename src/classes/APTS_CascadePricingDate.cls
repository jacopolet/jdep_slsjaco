public with sharing class APTS_CascadePricingDate {
    
    @invocableMethod
    public static void updateAgreementLineItemPricingDate(List<Id> agreementIdList){
        try{
        
        List<Apttus__AgreementLineItem__c> oAgreementLIToUpdateList = new List<Apttus__AgreementLineItem__c> ();
        List<Apttus__AgreementLineItem__c> oAgreementLIList = [SELECT ID, APTS_PricingDate__c, Apttus__AgreementId__r.APTS_PricingDate__c FROM Apttus__AgreementLineItem__c WHERE Apttus__AgreementId__c =:agreementIdList];
        
        for(Apttus__AgreementLineItem__c oALI: oAgreementLIList){
            if(oALI.Apttus__AgreementId__r.APTS_PricingDate__c != null){
                oALI.APTS_PricingDate__c = oALI.Apttus__AgreementId__r.APTS_PricingDate__c;
                oAgreementLIToUpdateList.add(oALI);
            }
        }
        database.update(oAgreementLIToUpdateList);
        }catch(Exception e){APTS_CustomLogging.createErrorLog(e.getTypeName(), 'Apex', e.getStackTraceString() ,'APTS_CascadePricingDate', null,'CPQ',false,true,'cpqerror@accenture.com',true);}
    }

}