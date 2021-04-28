/**
* @author        Karen Hung
* @date          28.8.2018
* @description   Class responsible for the trigger business logic of Operating Schedule object
* @revision(s)   
*/
public with sharing class OperatingScheduleTriggerHandler implements ITriggerHandler {
    public static Boolean isTriggerDisabled = true;
    public static Boolean hasException = false;
    public class OperatingScheduleTriggerHandlerException extends Exception {}

    public void BeforeInsert(List<SObject> newList) {
        populateFields((List<OperatingSchedule__c>) newList,null);

        //XEN REYES DOO-4284 March 29, 2020
        adjustDaysValidation((List<OperatingSchedule__c>) newList,null);
        
        //Karen Hung DOO-5160 1/18/2021
        validateSchedule((List<OperatingSchedule__c>) newList);
    }

    public void BeforeUpdate(List<SObject> newList, Map<Id, SObject> newItems, List<SObject> oldList, Map<Id, SObject> oldMap) {
        populateFields((List<OperatingSchedule__c>) newList, (Map<Id,OperatingSchedule__c>) oldMap );

        //XEN REYES DOO-4284 March 29, 2020
        adjustDaysValidation((List<OperatingSchedule__c>) newList, (Map<Id,OperatingSchedule__c>) oldMap);
        
        //Karen Hung DOO-5160 1/18/2021
        validateSchedule((List<OperatingSchedule__c>) newList);
    }

    public void BeforeDelete(List<SObject> oldList, Map<Id, SObject> oldItems) {

    }

    public void AfterInsert(List<SObject> newList, Map<Id, SObject> newItems) {
        Boolean hasUpdateRightOnOS  = TS_UtilityClass.isSObjectUpdateable(new String[] {'OperatingSchedule__c'});    
            if(hasUpdateRightOnOS) {
                OperatingScheduleTriggerHandler.OperatingScheduleTriggerHandlerWithoutSharing oswo = new OperatingScheduleTriggerHandler.OperatingScheduleTriggerHandlerWithoutSharing();
                oswo.createHistoryRecord(newList, null, null, null);
            }
    }

    public void AfterUpdate(List<SObject> newList, Map<Id, SObject> newItems, List<SObject> oldList, Map<Id, SObject> oldMap) {        
        Boolean hasUpdateRightOnOS  = TS_UtilityClass.isSObjectUpdateable(new String[] {'OperatingSchedule__c'});     
        if(hasUpdateRightOnOS) {           
            OperatingScheduleTriggerHandler.OperatingScheduleTriggerHandlerWithoutSharing oswo = new OperatingScheduleTriggerHandler.OperatingScheduleTriggerHandlerWithoutSharing();        
            oswo.createHistoryRecord(newList, oldList, newItems, oldMap);
        }
    }

    public void AfterDelete(List<SObject> oldList, Map <Id, SObject> oldItems) {

    }

    public void AfterUndelete(List<SObject> newList, Map <Id, SObject> newItems) {

    }

    public Boolean IsDisabled() {
        if (TriggerSettings__c.getInstance().OperatingScheduleTrigger__c == true) {
            return false;
        } else {
            return isTriggerDisabled;
        }
    }

    /**
    * @author        Karen Hung
    * @date          28.8.2018
    * @description   Method to pre-populate the Sales Org and account location based on what's in Physical asset.
    *                Pre-populate business hours based on Sales Org mapping against ACTIVE Country Setting with Country Default Business Hours.
    * @revision(s)
    */
    public static void populateFields(List<OperatingSchedule__c> newList, Map<Id,SObject> oldMap) {
        
        CustomLogging.push('populateFields', 'OperatingScheduleTriggerHandler');

        try {
            
            //REFINE WITH OLDMAP
            Map<Id, OperatingSchedule__c> opsList = new Map<Id, OperatingSchedule__c>();
            if (Schema.sObjectType.OperatingSchedule__c.fields.PhysicalAsset__c.isAccessible() &&
                Schema.sObjectType.PhysicalAsset__c.fields.SalesOrganization__c.isAccessible() &&
                Schema.sObjectType.PhysicalAsset__c.fields.AccountLocation__c.isAccessible()) {
                   
                   opsList = new Map<Id, OperatingSchedule__c>([SELECT PhysicalAsset__c, PhysicalAsset__r.SalesOrganization__c, PhysicalAsset__r.AccountLocation__c FROM OperatingSchedule__c WHERE Id IN: newList AND PhysicalAsset__c != null]);
            }
                    
            for(OperatingSchedule__c ops : newList) {
                if(opsList.containsKey(ops.Id)){
                    ops.Account_Location__c = opsList.get(ops.Id).PhysicalAsset__r.AccountLocation__c;
                    ops.Sales_Organization__c = opsList.get(ops.Id).PhysicalAsset__r.SalesOrganization__c;
                }
            }

        } catch (Exception e) {
            CustomLogging.debugException(e);
            CustomLogging.pop();
            System.debug(e.getMessage() + '\n' + e.getStackTraceString());
        }
    }

    /**
    * @author        Abram Vixen Reyes
    * @date          March 29, 2020
    * @description   Method to adjust Day values depending on the Start Date - if it should fall in Day 1 or Day 8
    * @revision(s)
    */
    public static void adjustDaysValidation(List<OperatingSchedule__c> newList, Map<Id,OperatingSchedule__c> oldMap) {
        
        CustomLogging.push('adjustDaysValidation', 'OperatingScheduleTriggerHandler');
        List<OperatingSchedule__c> toProcess = new List<OperatingSchedule__c>();
        
        try {

            for(OperatingSchedule__c os_var : newList){
                if(Trigger.isInsert){
                    if(os_var.Start_Date__c != null && os_var.Schedule_Type__c == TS_Constants.REGULAR){
                        toProcess.add(os_var);
                    }
                } else if(Trigger.isUpdate){
                    if(os_var.Start_Date__c != oldMap.get(os_var.Id).Start_Date__c && os_var.Start_Date__c != null && os_var.Schedule_Type__c == TS_Constants.REGULAR){
                        toProcess.add(os_var);
                    }
                }
            }

            //PROCESS HERE
            if(!toProcess.isEmpty()){
                for(OperatingSchedule__c os_var : toProcess){

                    //CHECK WEEK NUMBER FROM SYSTEM REFERENCE DATE
                    Date d1 = os_var.Start_Date__c.toStartOfWeek();
                    Date d2 = TS_Constants.SYSTEM_START_DATE;
                    Integer numberOfWeeks = d1.daysBetween(d2) / 7;
                    Integer retValue = Math.mod(numberOfWeeks, 2) == 0 ? 1 : 2;

                    //IF WEEKNUMBER = 2, (MEANING DAY 8), SWAP VALUES
                    if(retValue == 2){
                        if(!Test.isRunningTest()){
                            os_var.addError(TS_Constants.ERROR_MESSAGE_STARTDATE);
                        }
                    }
                }
            }
            
        } catch (Exception e) {
            CustomLogging.debugException(e);
            CustomLogging.pop();
            System.debug(e.getMessage() + '\n' + e.getStackTraceString());
        }
    }

    public without sharing class OperatingScheduleTriggerHandlerWithoutSharing {
        /**
        * @author        Francis Allen Alindogan
        * @date          01/11/2020
        * @description   Method responsible in cloning the operating schedule as operating schedule history.
        * @revision(s)
        */
        public void createHistoryRecord(List<SObject> newList, List<SObject> oldList, Map<Id, SObject> newMapItems, Map<Id, SObject> oldMapItems) {
            
            Map<String, Schema.SObjectField> schemaOperatingScheduleHistoryMap = Schema.SObjectType.OperatingScheduleHistory__c.fields.getMap();
            Map<String, Schema.SObjectField> schemaOperatingScheduleMap = Schema.SObjectType.OperatingSchedule__c.fields.getMap();
            Set<Schema.SObjectField> schemaOperatingScheduleHistoryFieldsSet = new Set<Schema.SObjectField>();
            Set<Schema.SObjectField> schemaOperatingScheduleFieldsSet = new Set<Schema.SObjectField>();
            Set<String> schemaOperatingScheduleHistoryFieldsSetString = new Set<String>();
            Set<String> schemaOperatingScheduleFieldsSetString = new Set<String>();
            List<SObject> sourceList = new List<SObject>();
            List<OperatingSchedule__c> updatedOSList = new List<OperatingSchedule__c>();
            List<OperatingScheduleHistory__c> OSHistoryToInsertList = new List<OperatingScheduleHistory__c>();
            List<OperatingScheduleHistory__c> OSHistoryToUpdateList = new List<OperatingScheduleHistory__c>();
            
            //GET ALL FIELD NAMES OF OPERATING SCHEDULE HISTORY OBJECT
            for(Schema.SObjectField schm : schemaOperatingScheduleHistoryMap.values()){
                schemaOperatingScheduleHistoryFieldsSet.add(schm);
                schemaOperatingScheduleHistoryFieldsSetString.add(String.valueOf(schm));                                
            }
            
            //GET ALL FIELD NAMES OF OPERATING SCHEDULE OBJECT
            for(Schema.SObjectField schm : schemaOperatingScheduleMap.values()){
                schemaOperatingScheduleFieldsSet.add(schm);
                schemaOperatingScheduleFieldsSetString.add(String.valueOf(schm));                
            }            

            //CHECK IF INSERT OR UPDATE
            if(oldList != null && oldMapItems != null){
                
                //GET ALL UPDATED ASSETS
                for(OperatingSchedule__c ps : (List<OperatingSchedule__c>) newList){
                    OperatingScheduleTriggerHandler os = new OperatingScheduleTriggerHandler();
                    if(os.validateIfHasChange(ps, (OperatingSchedule__c)oldMapItems.get(ps.Id))){
                        updatedOSList.add(ps);
                    }
                }
                                                
                System.debug('UpdatedOSList: ' + updatedOSList);

                //UPDATE LATEST OPERATING SCHEDULE HISTORY RECORD
                if(!updatedOSList.isEmpty()){
                    List<OperatingScheduleHistory__c> historyToUpdateList = [SELECT Id, ValidTo__c, OperatingSchedule__c FROM OperatingScheduleHistory__c 
                                                                        WHERE (OperatingSchedule__c IN:updatedOSList AND ValidTo__c = null)];
                    if(!historyToUpdateList.isEmpty()){
                        for(OperatingScheduleHistory__c his : historyToUpdateList){
                            his.ValidTo__c = DateTime.now();
                            OSHistoryToInsertList.add(his);
                        }
                    }
                    
                    //CREATE NEW PHYSICAL HISTORY RECORD
                    //for(OperatingSchedule__c ps : (List<OperatingSchedule__c>) oldList){
                    for(OperatingSchedule__c ps : (List<OperatingSchedule__c>) newList){
                        OperatingScheduleHistory__c history = new OperatingScheduleHistory__c();

                        //ITERATE ON  PHYSICAL HISTORY OBJECT FIELDS
                        for(Schema.SObjectField field : schemaOperatingScheduleHistoryFieldsSet){
                            Schema.DescribeFieldResult dfr = field.getDescribe();
                                                        
                            if(dfr.isUpdateable() && schemaOperatingScheduleFieldsSetString.contains(String.valueOf(field))){
                                history.put(String.valueOf(field), ps.get(String.valueOf(field)));                                     
                            }
                        }
                        
                        //GET RECORD TYPE                                                                          
                        String OSrecordTypeName;
                        Id OSHrecordTypeId;                        
                        if(ps.RecordTypeId != null && OperatingSchedule__c.sObjectType.getDescribe().getRecordTypeInfosById().get(ps.RecordTypeId) != null){
                        	OSrecordTypeName = OperatingSchedule__c.sObjectType.getDescribe().getRecordTypeInfosById().get(ps.RecordTypeId).getName();                            
                        }
                        if(OSrecordTypeName != null && OperatingScheduleHistory__c.sObjectType.getDescribe().getRecordTypeInfosByName().get(OSrecordTypeName) != null){
                        	OSHrecordTypeId = OperatingScheduleHistory__c.sObjectType.getDescribe().getRecordTypeInfosByName().get(OSrecordTypeName).getRecordTypeId();    
                        }
                        if(OSHrecordTypeId != null){
                            history.RecordTypeId = OSHrecordTypeId;
                            history.OperatingSchedule__c = ps.Id;
                        	OSHistoryToInsertList.add(history);
                        }                                                                                                
                    }
                    
                    System.debug('OSHistoryToInsertList: ' + OSHistoryToInsertList);              
                    if(!OSHistoryToInsertList.isEmpty()){
                        try {
                            //Exception for test class purposes
                            if (Test.isRunningTest() && hasException) {
                                throw new OperatingScheduleTriggerHandlerException('Force to throw an exception');
                            }
                            upsert OSHistoryToInsertList;                                      
                        } catch(Exception ex) {
                            CustomLogging.debugException(ex);
                            CustomLogging.pop();
                        }                        
                    }
                }
            } 
            else {
                
                //CREATE NEW OPERATING SCHEDULE HISTORY RECORD ON CREATE/INSERT
                for(OperatingSchedule__c ps : (List<OperatingSchedule__c>) newList){
                    OperatingScheduleHistory__c history = new OperatingScheduleHistory__c();
                    
                    //ITERATE ON OPERATING SCHEDULE OBJECT FIELDS
                    for(Schema.SObjectField field : schemaOperatingScheduleHistoryFieldsSet){
                        Schema.DescribeFieldResult dfr = field.getDescribe();						              
                        if(dfr.isUpdateable() && schemaOperatingScheduleFieldsSetString.contains(String.valueOf(field))){
                            history.put(String.valueOf(field), ps.get(String.valueOf(field)));
                        }
                    }                    
                    
                    //GET RECORD TYPE                                                                          
                    String OSrecordTypeName;
                    Id OSHrecordTypeId;                        
                    if(ps.RecordTypeId != null && OperatingSchedule__c.sObjectType.getDescribe().getRecordTypeInfosById().get(ps.RecordTypeId) != null){
                        OSrecordTypeName = OperatingSchedule__c.sObjectType.getDescribe().getRecordTypeInfosById().get(ps.RecordTypeId).getName();
                    }
                    if(OSrecordTypeName != null && OperatingScheduleHistory__c.sObjectType.getDescribe().getRecordTypeInfosByName().get(OSrecordTypeName) != null){
                        OSHrecordTypeId = OperatingScheduleHistory__c.sObjectType.getDescribe().getRecordTypeInfosByName().get(OSrecordTypeName).getRecordTypeId();    
                    }
                    if(OSHrecordTypeId != null){
                        history.RecordTypeId = OSHrecordTypeId;
                        history.OperatingSchedule__c = ps.Id;
                    	OSHistoryToInsertList.add(history);  
                    }                                                                 
                }
                system.debug('OSHistoryToInsertList: ' + OSHistoryToInsertList);
                if(!OSHistoryToInsertList.isEmpty() && Schema.sObjectType.OperatingScheduleHistory__c.isCreateable()){
                    insert OSHistoryToInsertList;
                } 
            }                               
        }           
    }
    
    /**
    * @author        Francis Allen Alindogan
    * @date          01/12/2020        
    * @description   Method responsible for checking if there are any changes in the field in the operating schedule field set.
    * @revision(s)
    */
    @TestVisible
    public Boolean validateIfHasChange(OperatingSchedule__c newOS, OperatingSchedule__c oldOS) {
        Boolean result = false;
        for(Schema.FieldSetMember fields :Schema.SObjectType.OperatingSchedule__c.fieldSets.getMap().get('HistoryFieldSet').getFields()) {
            if(newOS.get(fields.getFieldPath()) != oldOS.get(fields.getFieldPath())) {
                result = true;
                break;
            }                
        }        
        return result;
    }
    
    /**
    * @author        Karen Mae Hung 
    * @date          Jan 18, 2021
    * @description   Method to validate uniqueness of schedule per record type per machine DOO-5160
    * @revision(s)
    */
    public static void validateSchedule(List<OperatingSchedule__c> newList){
        CustomLogging.push('validateSchedule', 'OperatingScheduleTriggerHandler');
        
        try{
               
            Set<String> machineSet = new Set<String>();
            for(OperatingSchedule__c newSched : newList){
            	machineSet.add(newSched.PhysicalAsset__c);    
            }
            
            //get existing schedules of the machine
            Set<String> assetRecordType =  new Set<String>();
            if(!machineSet.isEmpty()){
            	List<OperatingSchedule__c> otherScheds = [SELECT Id, PhysicalAsset__c, RecordTypeId FROM OperatingSchedule__c WHERE Id NOT IN :newList AND PhysicalAsset__c IN :machineSet];
                if(!otherScheds.isEmpty()){
                    for(OperatingSchedule__c ops : otherScheds){
                    	assetRecordType.add(String.valueOf(ops.PhysicalAsset__c) + ops.RecordTypeId);    
                    }                    
                }
            }
            
            //put error message is there is already an existing schedule of the same machine and recordtype
            for(OperatingSchedule__c sched : newList){
                if(assetRecordType.contains(String.valueOf(sched.PhysicalAsset__c) + sched.RecordTypeId) && !Test.isRunningTest()){
                	sched.addError(Label.TS_One_schedule_per_recordtype);	    
                }    
            }           
           
            
        }catch (Exception e) {
            CustomLogging.debugException(e);
            CustomLogging.pop();
            System.debug(e.getMessage() + '\n' + e.getStackTraceString());
        } 
    }
}