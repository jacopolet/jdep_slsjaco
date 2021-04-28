/**
* @author        Abram Vixen Reyes
* @date          25.4.2018           
* @description   Class responsible for the trigger business logic of Meter Reading Data Object object.
* @revision(s)   
*/
public with sharing class APTS_MeterReadingDataTriggerHandler implements ITriggerHandler {

	public static Boolean isTriggerDisabled = true;
    public static Boolean hasException = false;
    public static Boolean generateFUPdone = false;
    public static Boolean doNotProceed = false;

    public static List<APTS_Meter_Reading_Data__c> forFilteringMeterReadingList = new List<APTS_Meter_Reading_Data__c>();
    public static Set<Id> physicalAssetIdSet = new Set<Id>();
    public static String reasonCodeSFDC = '';
    

    public class APTS_MeterReadingDataTriggerHandlerException extends Exception {}
    
    public void BeforeInsert(List<SObject> newItems) {
        
    }
    
    public void BeforeUpdate(List<SObject> newList, Map<Id, SObject> newMapItems, List<SObject> oldList, Map<Id, SObject> oldMapItems) {
        CustomLogging.push('BeforeUpdate', 'APTS_MeterReadingDataTriggerHandler');

        getAssetIds(newList, oldMapItems);

        CustomLogging.pop();
    }   
    
    public void BeforeDelete(List<SObject> oldList, Map<Id, SObject> oldItems){
        
    }
    
    public void AfterInsert(List<SObject> newList, Map<Id, SObject> newMapItems){
             
    }
    
    public void AfterUpdate(List<SObject> newList , Map<Id, SObject> newMapItems, List<SObject> oldList, Map<Id, SObject> oldMapItems){
        CustomLogging.push('AfterUpdate', 'APTS_MeterReadingDataTriggerHandler');

        try {       
            
            if(!generateFUPdone){
                generateFUP(newList, oldMapItems, newMapItems);
            }

        } catch(Exception ex) {
            CustomLogging.debugException(ex);
            CustomLogging.pop();
            System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());
        }
        
        CustomLogging.pop();
    }
    
    public void AfterDelete(List<SObject> oldList, Map<Id, SObject> oldMapItems){

    }
    
    public void AfterUndelete(List<SObject> newList, Map<Id, SObject> newMapItems){
        
    }
    
    /**
    * @author        Abram Vixen Reyes
    * @date          25.4.2018           
    * @description   Method responsible in disabling the function of the trigger if user settings is false
    * @revision(s)
    */
    public Boolean IsDisabled() {
        if (TriggerSettings__c.getInstance().APTS_MeterReadingDataTrigger__c) {
            return false;
        } else {
            return isTriggerDisabled;
        }
    }

    /*
    * @author        Abram Vixen Reyes
    * @date          Nov. 6, 2018
    * @description   Method that will collect unique physical asset and generate Counter Reading FUPs.
    * @revision(s)   Nov. 7, 2018 - KTS-2296
    */
    public void generateFUP(List<SObject> newList, Map<Id, SObject> oldMapItems, Map<Id, SObject> newMapItems) {
        
        CustomLogging.push('generateFUP', 'APTS_MeterReadingDataTriggerHandler');

        Set<Id> meterReadingIds = new Set<Id>();
        Set<Id> physicalAssetIdSetWithActiveFUP = new Set<Id>();
        List<Id> physicalAssetIdSetFiltered = new List<Id>();
        List<PhysicalAsset__c> physicalAssetList = new List<PhysicalAsset__c>();
        List<APTS_Meter_Reading_Data__c> meterReadingForUpdate = new List<APTS_Meter_Reading_Data__c>();

        if(!physicalAssetIdSet.isEmpty() && !doNotProceed){

            //UPDATE OTHER METER READING DATA NOT INCLUDED IN THE TRIGGER CONTEXT/NOT TICKED IN LIST VIEW BUT HAS A PHYSICAL ASSET TO BE PROCESSED
            for(APTS_Meter_Reading_Data__c mtrUpdate : [SELECT Id FROM APTS_Meter_Reading_Data__c WHERE PhysicalAsset__c IN: physicalAssetIdSet AND APTS_Status__c !=: TS_Constants.STATUS_COMPLETED]){

                if(!meterReadingIds.contains(mtrUpdate.Id)){
                    mtrUpdate.APTS_Corrective_Action__c = TS_Constants.METERREADING_WORKORDERCREATED;
                    mtrUpdate.APTS_Status__c = TS_Constants.STATUS_COMPLETED;
                    mtrUpdate.APTS_Reason_code_SFDC__c = reasonCodeSFDC;
                    meterReadingForUpdate.add(mtrUpdate);
                }
            }

            /* if(!meterReadingForUpdate.isEmpty()){
                Database.update(meterReadingForUpdate);
            } */
                    
            //CHECK IF THERE IS AN OUTSTANDING FUP ON EACH ASSET
            Id counterReadingFUP = Schema.SObjectType.WorkOrder.getRecordTypeInfosByName().get(TS_Constants.TS_WO_RECORDTYPE_COUNTERREADING).getRecordTypeId();
            List<WorkOrder> woliFUPList = [SELECT Id, OP_Physical_Asset__c FROM WorkOrder WHERE RecordTypeId =: counterReadingFUP AND WorkOrderType__c =: TS_Constants.WO_TYPE_S22_COUNTERREADINGFUP AND OP_Physical_Asset__c IN: physicalAssetIdSet AND Status !=: TS_Constants.STATUS_COMPLETED AND Status !=: TS_Constants.STATUS_CANCELED];

            if(!woliFUPList.isEmpty()){
                for(WorkOrder wo: woliFUPList){
                    physicalAssetIdSetWithActiveFUP.add(wo.OP_Physical_Asset__c);
                }
                physicalAssetIdSet.removeAll(physicalAssetIdSetWithActiveFUP);
            }

            //GET ALL FINAL COUNTER READING DATA RECORDS TO EXCLUDE IN THE UPDATE TO AVOID ERROR
            for(APTS_Meter_Reading_Data__c mtr : forFilteringMeterReadingList){
                if(physicalAssetIdSet.contains(mtr.PhysicalAsset__c)){
                    meterReadingIds.add(mtr.Id);
                }
            }

            if(!physicalAssetIdSet.isEmpty()){

                generateFUPdone = true;
                physicalAssetList = [SELECT Id, Connected__c, CounterReading__c, SalesOrganization__c, AccountLocation__c  FROM PhysicalAsset__c WHERE Id IN: physicalAssetIdSet AND CounterReading__c =: TS_Constants.METERREADING_YES];
                
                //Francis Allen Alindogan 04/14/2020 DOO-4300
                if(!physicalAssetList.isEmpty()){
                    createCounterReadingFUP(physicalAssetList, meterReadingForUpdate, (Map<Id, APTS_Meter_Reading_Data__c>) oldMapItems, (Map<Id, APTS_Meter_Reading_Data__c>) newMapItems);
                }
            }
            
            System.debug('XEN 11/16');
            System.debug('XEN 11/16 newList: '+ newList);
            System.debug('XEN 11/16 woliFUPList: '+ woliFUPList);
            System.debug('XEN 11/16 physicalAssetIdSet: '+ physicalAssetIdSet);
            System.debug('XEN 11/16 physicalAssetIdSetWithActiveFUP '+ physicalAssetIdSetWithActiveFUP);
            System.debug('XEN 11/16 physicalAssetIdSetFiltered: '+ physicalAssetIdSetFiltered);
            System.debug('XEN 11/16 physicalAssetList: '+ physicalAssetList);
        }

        CustomLogging.pop();     
    }

    /*
    * @author        Abram Vixen Reyes
    * @date          Nov. 7, 2018
    * @description   Method that will collect the physical asset Ids and throw an error if the number of distinct physical assets to be processed is greater than the threshold
    * @revision(s)   
    */
    public void getAssetIds (List<SObject> newList, Map<Id, SObject> oldMapItems) {
        Integer assetThreshold = Integer.valueOf(Label.TS_AssetThreshold); //Francis Allen Alindogan 04/14/2020 DOO-4300
        
        CustomLogging.push('generateFUP', 'APTS_MeterReadingDataTriggerHandler');

        for(APTS_Meter_Reading_Data__c mtr : (List<APTS_Meter_Reading_Data__c>) newList){
            APTS_Meter_Reading_Data__c oldRec = (APTS_Meter_Reading_Data__c) oldMapItems.get(mtr.Id);
            System.debug(oldRec);
            
            //APTS_Reason_code_SFDC__c Nov. 6, 2018
            if(mtr.APTS_Corrective_Action__c != oldRec.APTS_Corrective_Action__c && mtr.APTS_Corrective_Action__c == TS_Constants.METERREADING_WORKORDERCREATED){
                physicalAssetIdSet.add(mtr.PhysicalAsset__c);
                forFilteringMeterReadingList.add(mtr);
            }

            reasonCodeSFDC = mtr.APTS_Reason_code_SFDC__c;

            //ADD ERROR MESSAGE IN PROCESSING MORE THAN SUGGESTED ASSETS
            if(physicalAssetIdSet.size() > assetThreshold){
                mtr.addError(TS_Constants.METERREADING_ASSETTHRESHOLD_ERROR);
                doNotProceed = true;
            }
        }

        CustomLogging.pop();     
    }

    /*
    * @author        Francis Allen Alindogan
    * @date          April. 8, 2020
    * @description   Method to create Counter Reading FUP Work Orders
    * @revision(s)   
    */
    private void createCounterReadingFUP(List<PhysicalAsset__c> physicalAssetList, List<APTS_Meter_Reading_Data__c> meterToUpdateList, Map<Id, APTS_Meter_Reading_Data__c> meterMapOld, Map<Id, APTS_Meter_Reading_Data__c> newMapItems){
        CustomLogging.push('createCounterReadingFUP', 'APTS_MeterReadingDataTriggerHandler');
        List<WorkOrder> woListUpdate = new List<WorkOrder>();

        if(!physicalAssetList.isEmpty()){
            for(PhysicalAsset__c pa : physicalAssetList){
                WorkOrder wo = new WorkOrder();
                wo.OP_Physical_Asset__c = pa.Id;
                wo.SalesOrganization__c = pa.SalesOrganization__c;
                wo.Account_Location__c = pa.AccountLocation__c;
                wo.WorkOrderType__c = TS_Constants.WO_TYPE_S22_COUNTERREADINGFUP;
                wo.Task_Activity_Type__c = 'Counter';
                woListUpdate.add(wo);
            }
        }

        try {       
            if(!woListUpdate.isEmpty()){
                insert woListUpdate;
                update meterToUpdateList;
            }
        } 
        catch(Exception ex) {
            CustomLogging.debugException(ex);
            CustomLogging.pop();
            System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());

            //THROW AND ERROR ON OTHER METER READING DATA
            for(APTS_Meter_Reading_Data__c mtr: meterToUpdateList){
                mtr.addError('An error occured.');
            }
        
        }
    }
}