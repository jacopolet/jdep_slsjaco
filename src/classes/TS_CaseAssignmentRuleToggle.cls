/**
* @author        Abram Vixen Reyes
* @date          06.3.2018    
* @description   Class to initiate case assignment rule on create cases via Apex
* @revision(s)
*/
public without sharing class TS_CaseAssignmentRuleToggle {
    
    public static List<Case> fireAssignmentRuleBulk(List<Case> csList){
        CustomLogging.push('fireAssignmentRuleBulk', 'TS_CaseAssignmentRuleToggle');
        
        //GET ASSIGNMENT RULE FOR CASE
        AssignmentRule AR = [SELECT Id FROM AssignmentRule WHERE SobjectType = 'Case' AND Active = True LIMIT 1];

        //CREATE the DMLOptions for "Assign using active assignment rules" checkbox
        Database.DMLOptions dmlOpts = new Database.DMLOptions();
        dmlOpts.assignmentRuleHeader.assignmentRuleId= AR.id;
        
        try {
            if (Schema.sObjectType.Case.isCreateable()) {
                Database.insert(csList, dmlOpts);
            }
        } catch (Exception ex) {
            CustomLogging.debugException(ex);
            CustomLogging.pop();
            System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());
        }

        CustomLogging.pop();
        return csList;
    }
    
     public static Id fireAssignmentRuleSingle(Case cs){
        CustomLogging.push('fireAssignmentRuleSingle', 'TS_CaseAssignmentRuleToggle');
        
        //GET ASSIGNMENT RULE FOR CASE
        AssignmentRule AR = [SELECT Id FROM AssignmentRule WHERE SobjectType = 'Case' AND Active = True LIMIT 1];

        //CREATE the DMLOptions for "Assign using active assignment rules" checkbox
        Database.DMLOptions dmlOpts = new Database.DMLOptions();
        dmlOpts.assignmentRuleHeader.assignmentRuleId= AR.id;
        
        if(cs.AssignToQueue__c){
            cs.setOptions(dmlOpts);
        }

        try {
            if (Schema.sObjectType.Case.isUpdateable()) {
                update cs;
            }
        } catch (Exception ex) {
            CustomLogging.debugException(ex);
            CustomLogging.pop();
            System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());
        }

        CustomLogging.pop();
        return cs.Id;
    }

    public static void fireAssignmentRuleBulkUpdate(List<sObject> recList, Boolean isUpdate, Map<Id, SObject> recOldList){
        CustomLogging.push('fireAssignmentRuleBulkUpdate', 'TS_CaseAssignmentRuleToggle');
        List<Case> csList = new List<Case>();
        System.debug('fireAssignmentRuleBulkUpdate ' + recList);

        //CREATE the DMLOptions for "Assign using active assignment rules" checkbox
        Database.DMLOptions dmlOpts = new Database.DMLOptions();
        dmlOpts.assignmentRuleHeader.useDefaultRule = true;

        for(Case c : (List<Case>) recList) {
            if(!isUpdate){
                if(c.AssignToQueue__c){
                    Case newCS = new Case(Id = c.Id);
                    csList.add(newCS);
                } 
            } else {
                Case oldCase = (Case) recOldList.get(c.Id);
                if( //c.AssignToQueue__c && KTS-1874 XR 05.7.2018
                    ((c.CaseQualificationDate__c != null && c.CaseQualificationDate__c != oldCase.CaseQualificationDate__c) ||
                    (c.CreatedOrderedManually__c && c.CreatedOrderedManually__c != oldCase.CreatedOrderedManually__c) ||
                    (c.IsEscalated && c.IsEscalated != oldCase.IsEscalated))){  //4.27.2018 Adrian R: Added condition to rout escalated cases to escalation queue
                    Case newCS = new Case(Id = c.Id);
                    csList.add(newCS);
                }
            }                       
        }
        
        try {
            if(!csList.isEmpty() && Schema.sObjectType.Case.isUpdateable()){
                Database.update(csList, dmlOpts);
            }
        } catch (Exception ex) {
            CustomLogging.debugException(ex);
            CustomLogging.pop();
            System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());
        }
        
        CustomLogging.pop();
    }
}