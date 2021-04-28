public without sharing class SM_DataAccessObjectLWC {

    public class AgreementWrapper{
        @AuraEnabled public Integer rowNumber {get;set;}
        @AuraEnabled public String agreementLink {get;set;}
        @AuraEnabled public String amendLink {get;set;}
        @AuraEnabled public String agreementName {get;set;}
        @AuraEnabled public String agreementNumber {get;set;}
        @AuraEnabled public String status {get;set;}
        @AuraEnabled public String statusCategory {get;set;}
        @AuraEnabled public Date agreementEndDate {get;set;}
        @AuraEnabled public Datetime agreementCreatedDate {get;set;}
    }

    @AuraEnabled(cacheable=true)
    public static List<AgreementWrapper> getAgreementList(Id oppId) {
        //  Opportunity opp = [Select Id, AccountId FROM Opportunity WHERE Id = :oppId];
        // return [SELECT Id,Apttus__FF_Amend__c, Name, Apttus__Agreement_Number__c, Apttus__Status__c, Apttus__Status_Category__c, Apttus__Contract_End_Date__c, CreatedDate FROM Apttus__APTS_Agreement__c WHERE APTS_Sold_To__c = :opp.AccountId];
        Integer i=0;
        List<AgreementWrapper> agreementWrapperList = new  List<AgreementWrapper>();
        for(Apttus__APTS_Agreement__c agr : [SELECT Id, Name, Apttus__Agreement_Number__c, Apttus__Status__c, Apttus__Status_Category__c, Apttus__Contract_End_Date__c, CreatedDate,Apttus__FF_Amend__c FROM Apttus__APTS_Agreement__c 
                                            WHERE Apttus__Status__c='Activated' and Apttus__Status_Category__c='In Effect' and APTS_Sold_To__c IN (Select AccountId FROM Opportunity WHERE Id = :oppId)]){
            AgreementWrapper agrWrap = new AgreementWrapper();
            agrWrap.rowNumber = i+1;
            agrWrap.agreementLink = '/'+agr.id;
            agrWrap.agreementName=agr.Name;
            agrWrap.agreementNumber=agr.Apttus__Agreement_Number__c;
            agrWrap.status=agr.Apttus__Status__c;
            agrWrap.statusCategory=agr.Apttus__Status_Category__c;
            agrWrap.agreementEndDate=agr.Apttus__Contract_End_Date__c;
            agrWrap.agreementCreatedDate=agr.CreatedDate;
            if(agr.Apttus__Status__c=='Activated'){
                agrWrap.amendLink = '/apex/Apttus__AgreementAmend?id='+agr.Id;
            }
            agreementWrapperList.add(agrWrap);
            i++;
        }
        return agreementWrapperList;  
    }

    @AuraEnabled(cacheable=true)
    public static Account fetchAccount(Id accId) {
        return [Select Id, GTM_Ingredients__c, GTM_Ingredients__r.Name FROM Account WHERE Id = :accId];
    }

}