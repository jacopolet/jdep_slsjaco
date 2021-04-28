/*************************************************************
@Name: APTS_AgreementHierarchyViewController
@Author: Pranjal Mittal
@CreateDate: 19-02-2018
@Description: Displays hierarchy pricing conditions applied on an account or agreement.
@UsedBy: APTS_AgreementHierarchyView
******************************************************************/

public with sharing class APTS_AgreementHierarchyViewController {

    //public List<APTS_Contract_Entitlement_Repository__c> lstCER {get; set;}
    //public Id aggrOrAccId {get; set;}
    public static final String ACCOUNT_API = 'Account';
    public static final String AGREEMENT_API = 'Apttus__APTS_Agreement__c';

    /*public APTS_AgreementHierarchyViewController() {
        //this.mysObject = (sObject)stdController.getRecord();
        aggrOrAccId = ApexPages.currentPage().getParameters().get('id');
        String sObjName = aggrOrAccId.getSObjectType().getDescribe().getName();

        if(sObjName.equalsIgnoreCase(ACCOUNT_API)){
            lstCER = APTS_ManageCER.getCERDataForAccount(aggrOrAccId);
            if(lstCER.isEmpty()){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'No Pricing Condition(s) associated to account.'));
            }
        }
        else if(sObjName.equalsIgnoreCase(AGREEMENT_API)){
            lstCER = APTS_ManageCER.getCERDataForAgreement(aggrOrAccId);
            if(lstCER.isEmpty()){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'No Pricing Condition(s) associated to agreement.'));
            }
        }
    }*/
    
    @AuraEnabled
    public static List<APTS_Contract_Entitlement_Repository__c> getCERData(String recordId){
        Id recId = recordId;
        String sObjName = recId.getSObjectType().getDescribe().getName();
        List<APTS_Contract_Entitlement_Repository__c> lstCER = new List<APTS_Contract_Entitlement_Repository__c>();
        if(sObjName.equalsIgnoreCase(ACCOUNT_API)){
            lstCER = APTS_ManageCER.getCERDataForAccount(recordId);
        }
        else if(sObjName.equalsIgnoreCase(AGREEMENT_API)){
            //lstCER = APTS_ManageCER.getCERDataForAgreement(recordId);
            //Changes as per defect#  16408
            Apttus__APTS_Agreement__c aggrObj = [SELECT Id, Apttus__Account__c FROM Apttus__APTS_Agreement__c WHERE Id =:recordId];
            if(aggrObj != null){
                lstCER = APTS_ManageCER.getCERDataForAccount(aggrObj.Apttus__Account__c);
            }
        }
        
        return lstCER;
    }

    /*public PageReference goBack(){
        PageReference returnPage = new PageReference('/' + aggrOrAccId);
        return returnPage;
    }*/
}