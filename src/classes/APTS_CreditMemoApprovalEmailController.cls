public with sharing class APTS_CreditMemoApprovalEmailController {
    
    public Id creditMemoId {get; set;}
    
    public Apttus_Billing__CreditMemo__c getCreditMemo(){
        Apttus_Billing__CreditMemo__c oCreditMemo = [SELECT Id, Name, Owner.Name FROM Apttus_Billing__CreditMemo__c WHERE Id =: creditMemoId];
        return oCreditMemo;
    }
    public List<Apttus_Billing__CreditMemoLineItem__c> getCreditMemoLineItems(){
        List<Apttus_Billing__CreditMemoLineItem__c> oCreditMemoLIList = [SELECT Id, Name, Apttus_Billing__Amount__c FROM Apttus_Billing__CreditMemoLineItem__c WHERE Apttus_Billing__CreditMemoId__c =: creditMemoId];
        return oCreditMemoLIList;
    }

}