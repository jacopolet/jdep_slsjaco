/*
 *Created by: Karen Hung 
 *Date: 26.09.2019 DOO-5045
 *Description: Apex Controller for TS_toastNotification lightning component 
 * 
*/
public with sharing class TS_ToastNotifController {
   
    /*get open duplicate S10 or S15*/
    @AuraEnabled
    public static List<Case> getServiceCases(String recordId, String subType, String physicalAsset){
        
        List<Case> caseRecs = new List<Case>();
        
        if(subtype == TS_Constants.CASE_SUBTYPE_CORRECTMAINTAPI || subtype == TS_Constants.CASE_SUBTYPE_1STLINECORRECTMAINTAPI){
            
            List<String> excludedStatus = new List<String>{TS_Constants.STATUS_CLOSED, TS_Constants.STATUS_COMPLETED, TS_Constants.STATUS_CANCELED, TS_Constants.WOLI_STATUS_REVIEW};
            
            caseRecs = [SELECT Id, CaseNumber 
                        FROM Case 
                        WHERE Id != :recordId 
                        AND Subtype__c IN  (:TS_Constants.CASE_SUBTYPE_CORRECTMAINTAPI, :TS_Constants.CASE_SUBTYPE_1STLINECORRECTMAINTAPI)
                        AND Status NOT IN :excludedStatus
                       	AND PhysicalAsset__c = :physicalAsset];           
            
        }
        
        return caseRecs;
    }
}