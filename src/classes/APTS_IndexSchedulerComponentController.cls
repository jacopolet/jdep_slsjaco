/**
 * @description       : APTS_IndexSchedulerComponentController
 * @author            : Karan Khatri
 * @group             : 
 * @last modified on  : 10-03-2021
 * @last modified by  : Karan Khatri
 * Modifications Log 
 * Ver   Date         Author         Modification
 * 1.0   03-02-2021   Karan Khatri   Initial Version
**/
public without sharing class APTS_IndexSchedulerComponentController{
    
    @AuraEnabled
    public static List<String> getPicklistvalues(sObject objectName, String fieldName){
        List<String> optionlist = new List<String>();
        Map<String, Schema.SObjectField> fieldMap = objectName.getSObjectType().getDescribe().fields.getMap();
        
        for(Schema.PicklistEntry pick : fieldMap.get(fieldName).getDescribe().getPickListValues()){
           optionlist.add(pick.getLabel());
        }
        return optionlist;
    }
    
    /*@AuraEnabled
    public static List<APTS_Indexation_Executing__c> getIndexExecuting(){
        Integer month = System.Today().Month();
        return [Select Id, APTS_Indexation_Contract__r.Apttus__Status_Category__c, APTS_Indexation_Contract__r.Apttus__Status__c, 
                APTS_Indexation_Contract__r.Apttus__Contract_Start_Date__c, 
                APTS_Indexation_Contract__r.Apttus__Contract_End_Date__c,
                APTS_Indexation_Contract__r.Apttus__FF_Agreement_Number__c 
                FROM APTS_Indexation_Executing__c 
                WHERE CALENDAR_MONTH(APTS_Execution_Date__c) =:month 
                AND Is_Indexation_Executed__c = false
                AND APTS_Indexation_Contract__r.Apttus__Status__c = 'Activated'];
    }*/
    
    @AuraEnabled
    public static String scheduleNonStandardBatch(String batchRunDate){
        try{
            /*Indexation_Applied__c ia = new Indexation_Applied__c();
            ia.Indexation_Type__c = 'Non Standard';
            insert ia;*/
      
            /*APTS_NonStandardIndexBatch batch = new APTS_NonStandardIndexBatch(Date.valueOf(batchRunDate));
            Database.executebatch(batch, 2);*/
            
            //Non Standard Indexation script
            Database.executeBatch(new APTS_IndexationBatch_Phase1(Date.valueOf(batchRunDate)),200);
            return 'success';
        }catch(Exception ex){APTS_CustomLogging.createErrorLog(ex.getTypeName(), 'Apex', String.valueOf(ex) ,'Index Scheduler', null, 'CLM', false, false, null, true);return ex.getMessage();}
    }
    
    @AuraEnabled
    public static String updateIndexContracts(String region, String techService, String machineCare){
        try{
            APTS_CreateStandardTransaction batch = new APTS_CreateStandardTransaction(region, techService, machineCare);
            Database.executeBatch(batch, 200);
            return 'success';
        }catch(Exception ex){APTS_CustomLogging.createErrorLog(ex.getTypeName(), 'Apex', String.valueOf(ex) ,'Index Scheduler', null, 'CLM', false, false, null, true);return ex.getMessage();}
    }
    
    @AuraEnabled
    public static String scheduleStandardBatch(String region){
        try{
            
            /*Indexation_Applied__c ia = new Indexation_Applied__c();
            ia.Indexation_Type__c = 'Standard';
            ia.Region__c = region;
            insert ia;*/
            
            /*APTS_StandardIndexBatch batch = new APTS_StandardIndexBatch(region);
            Database.executeBatch(batch, 2);*/
            
            //Non Standard Indexation script
            Database.executeBatch(new APTS_IndexationBatch_Phase1(region),200);
            
            return 'success';
        }catch(Exception ex){APTS_CustomLogging.createErrorLog(ex.getTypeName(), 'Apex', String.valueOf(ex) ,'Index Scheduler', null, 'CLM', false, false, null, true);return ex.getMessage();}
    }
    
    @AuraEnabled
    public static String getStandardReportId(){
        try{
            String returnValue = null;
            List<Report> Lsreport = [select Id from Report where name = 'Standard Index Contracts'];
            if(Lsreport.size()>0){
                Id reportId = Lsreport[0].Id;
                returnValue = String.valueOf(reportId);
            }
            return returnValue;            
        }catch(Exception ex){APTS_CustomLogging.createErrorLog(ex.getTypeName(), 'Apex', String.valueOf(ex) ,'Index Scheduler', null, 'CLM', false, false, null, true);return ex.getMessage();}
    }

    @AuraEnabled
    public static String displayReportIndexTransactions(){
        try{
            String returnValue = null;
            List<Report> Lsreport = [select Id from Report where name = 'Indexation Transactions'];
            if(Lsreport.size()>0){
                Id reportId = Lsreport[0].Id;
                returnValue = String.valueOf(reportId);
            }
            return returnValue;            
        }catch(Exception ex){APTS_CustomLogging.createErrorLog(ex.getTypeName(), 'Apex', String.valueOf(ex) ,'Index Scheduler', null, 'CLM', false, false, null, true);return ex.getMessage();}
    }

    @AuraEnabled
    public static String getNonStandardReportId(){
        try{
            String returnValue = null;
            List<Report> Lsreport = [select Id from Report where name = 'Non Standard Index Contracts'];
            if(Lsreport.size()>0){
                Id reportId = Lsreport[0].Id;
                returnValue = String.valueOf(reportId);
            }
            return returnValue;            
        }catch(Exception ex){APTS_CustomLogging.createErrorLog(ex.getTypeName(), 'Apex', String.valueOf(ex) ,'Index Scheduler', null, 'CLM', false, false, null, true);return ex.getMessage();}
    }
    
    /*@AuraEnabled
    public static String startTransactionBatch(){
        try{
            //APTS_IndexationUtils.invokeTransactionBatch();
          return 'success';
        }catch(Exception ex){APTS_CustomLogging.createErrorLog(ex.getTypeName(), 'Apex', String.valueOf(ex) ,'Index Scheduler', null, 'CLM', false, false, null, true);return ex.getMessage();}
    }*/
    
    @AuraEnabled
    public static String deleteTransactionBatch(){
        try{
            
            Set<String> status = new Set<String>();
            status.add('Completed');
            status.add('Failed');
            
            
            Set<String> classNames = new Set<String>();
            status.add('APTS_IndexationBatch_Phase1');
            status.add('APTS_IndexationBatch_Phase2');
            status.add('APTS_IndexationBatch_Phase3');
            
            for(AsyncApexJob hasJobs : [Select id, apexclass.name, JobType, Status from AsyncApexJob where apexclass.name IN: classNames and Status Not IN: status]){
                
                System.abortJob(hasJobs.Id);
            
            }
            Database.executeBatch(new APTS_IndexationRollbackBatch(),Integer.valueOf(System.Label.APTS_AutoAssetRenewalBatchSize));
           /*APTS_IndexDeleteOrder batch = new APTS_IndexDeleteOrder();
            Database.executeBatch(batch, 2);
            
            APTS_IndexDeleteTransaction batch2 = new APTS_IndexDeleteTransaction();
            Database.executeBatch(batch2, 200);
            
            APTS_IndexUpdateAssetLine batch3 = new APTS_IndexUpdateAssetLine();
            Database.executeBatch(batch3, 200);*/

          return 'success';
        }catch(Exception ex){APTS_CustomLogging.createErrorLog(ex.getTypeName(), 'Apex', String.valueOf(ex) ,'Index Scheduler', null, 'CLM', false, false, null, true);return ex.getMessage();}
    }
}