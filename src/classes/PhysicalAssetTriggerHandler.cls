/**
* @author        Abram Vixen Reyes
* @date          2.4.2018           
* @description   Class responsible for the trigger business logic of Physical Asset object.
* @revision(s)   02.05.2018 Paul Aguiling: [KTS-392] - Contract Triggered Cases (Preventive Maintenance)
*                                          Added getExtPhyAssetMap(), resetPhysicalAssetManualIndicator()
*                                          validateNextPrevAndWTSDates(), and getCountrySettings()
*                4 May 2018, Archi Delphinanto implemented Object Level (Access) Security, as part of Code Review actions.
*                06.29.2017 Paul Aguiling - [KTS-1775]: Added invocation of resendTaskIntegLog() 
*/
public with sharing class PhysicalAssetTriggerHandler implements ITriggerHandler {
    
    public static Boolean isTriggerDisabled = true;
    public static Boolean done = false;
    public static Boolean hasException = false;
    public static Boolean isNotBatchExecution = true;
    public static Boolean isBatchExecution = false;

    private static Map<Id, PhysicalAsset__c> newExtMap = null;
    public static Map<String, CountrySetting__c> countryMap = new Map<String, CountrySetting__c>();

    
    public class TS_PhysicalAssetTriggerHandlerException extends Exception {}
    
    public void BeforeInsert(List<SObject> newItems) {
        CustomLogging.push('BeforeInsert', 'PhysicalAssetTriggerHandler');
        try{
            populateContractTriggerSetting(newItems);
            if (Test.isRunningTest() && hasException) {
                    throw new TS_PhysicalAssetTriggerHandlerException('Force to throw an exception');
            }
        }catch(Exception ex) {
            CustomLogging.debugException(ex);
            CustomLogging.pop();
            System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());
        }
        CustomLogging.pop(); 

    }
    
    public void BeforeUpdate(List<SObject> newList, Map<Id, SObject> newMapItems, List<SObject> oldList, Map<Id, SObject> oldMapItems) {  
        CustomLogging.push('BeforeUpdate', 'PhysicalAssetTriggerHandler');
        
        try {
             populateContractTriggerSetting(newList);
             flushNextWTSDate(newList,oldMapItems);
            //=====================================//
            // Added as part of security best practice, CRUD check on the object 
            Boolean hasUpdateRightOnPhysicalAsset  = TS_UtilityClass.isSObjectUpdateable(new String[] {'PhysicalAsset__c'});    
            if(hasUpdateRightOnPhysicalAsset) resetPhysicalAssetManualIndicator(newList, oldMapItems);
            //=====================================//

            if ((newExtMap == null && newMapItems != null) || !newExtMap.keySet().containsAll(newMapItems.keySet())) {
                newExtMap = getExtAssetMap(newMapItems.keySet());
            }
            //updateName(newList, oldMapItems);

            physicalAssetUpdates(newList, oldList, newMapItems, oldMapItems); //Karen Hung 6/7/2020 DOO-4692
            
            //Exception for test class purposes
            if (Test.isRunningTest() && hasException) {
                throw new TS_PhysicalAssetTriggerHandlerException('Force to throw an exception');
            }
            
        } catch(Exception ex) {
            CustomLogging.debugException(ex);
            CustomLogging.pop();
            System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());
        }
        
        CustomLogging.pop(); 
    }
    
    public void BeforeDelete(List<SObject> oldList, Map<Id, SObject> oldItems){
        
    }
    
    public void AfterInsert(List<SObject> newList, Map<Id, SObject> newMapItems){
        CustomLogging.push('AfterInsert', 'PhysicalAssetTriggerHandler');

        try {  
            // Added as part of security best practice, CRUD check on the object 
            Boolean hasUpdateRightOnPhysicalAsset  = TS_UtilityClass.isSObjectUpdateable(new String[] {'PhysicalAsset__c'});    
            if(hasUpdateRightOnPhysicalAsset) {
                PhysicalAssetTriggerHandler.PhysicalAssetTriggerHandlerWithoutSharing pawo = new PhysicalAssetTriggerHandler.PhysicalAssetTriggerHandlerWithoutSharing();
                pawo.createHistoryRecord(newList, null, null, null);
            }

            //Exception for test class purposes
            if (Test.isRunningTest() && hasException) {
                throw new TS_PhysicalAssetTriggerHandlerException('Force to throw an exception');
            }
            
        } catch(Exception ex) {
            CustomLogging.debugException(ex);
            CustomLogging.pop();
            System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());
        }
        
        CustomLogging.pop();        
    }
    
    public void AfterUpdate(List<SObject> newList , Map<Id, SObject> newMapItems, List<SObject> oldList, Map<Id, SObject> oldMapItems){
        CustomLogging.push('AfterUpdate', 'PhysicalAssetTriggerHandler');

        try {     

            if(!done){
                // Added as part of security best practice, CRUD check on the object 
                Boolean hasUpdateRightOnPhysicalAsset  = TS_UtilityClass.isSObjectUpdateable(new String[] {'PhysicalAsset__c'});                
                if(hasUpdateRightOnPhysicalAsset) {
                    
                    updateOptionUniqueNumber(newList, oldMapItems);//Karen Hung DOO-4692 06.07.2020
                    PhysicalAssetTriggerHandler.PhysicalAssetTriggerHandlerWithoutSharing pawo = new PhysicalAssetTriggerHandler.PhysicalAssetTriggerHandlerWithoutSharing();
                    pawo.deleteRouteItem(newList, oldList, newMapItems, oldMapItems); //Karen Hung DOO-3921 02.25.2020
                    pawo.createHistoryRecord(newList, oldList, newMapItems, oldMapItems);
                }
            }
            
            //KTS-1775: responsible to Initiate updates from related objects added by Paul Aguiling 7.2.2018 
            /* System.debug('resendTaskIntegLog >>>>>>> ');
            System.debug('isNotBatchExecution >>>>>>> ' + isNotBatchExecution);
            if (isNotBatchExecution) {
                //TS_UtilityClass.resendTaskIntegLog('PhysicalAsset__c', 'PhysicalAsset__c', newList, oldMapItems); KTS-2055: Turn off functionality for now
            } */            
            
            //Exception for test class purposes
            if (Test.isRunningTest() && hasException) {
                throw new TS_PhysicalAssetTriggerHandlerException('Force to throw an exception');
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
    * @date          2.05.2018           
    * @description   Method responsible in disabling the function of the trigger if user settings is false
    * @revision(s)   Nov. 12, 2018 isBatchExecution - to disable trigger when selected batches are running
    */
    public Boolean IsDisabled() {
        System.debug('isBatchExecution >>>>>>> ' + isBatchExecution);
        if (TriggerSettings__c.getInstance().PhysicalAssetTrigger__c == true && !isBatchExecution) { 
            return false;
        } else {
            return isTriggerDisabled;
        }
    }
    
    
    /**
    * @author        Abram Vixen Reyes
    * @date          2.05.2018           
    * @description   Method responsible for checking if there are any changes in the field in the physical asset field set.
    * @revision(s)
    */
    @TestVisible
    public Boolean validateIfHasChange(PhysicalAsset__c newPa, PhysicalAsset__c oldPA) {
        Boolean result = false;
        for(Schema.FieldSetMember fields :Schema.SObjectType.PhysicalAsset__c.fieldSets.getMap().get('HistoryFieldSet').getFields()) {

            if(newPa.get(fields.getFieldPath()) != oldPA.get(fields.getFieldPath())) {
                result = true;
                break;
            }                
        }        
        return result;
    }

    /**
    * @author        Paul Jarred Aguiling
    * @date          02.05.2018          
    * @description   [KTS-392]: Contract Triggered Cases (Preventive Maintenance)
    *                Method to update Preventive Maintenance Planned and Preventive Maintenance Manual Update to false
    * @revision(s)
    */
    private void resetPhysicalAssetManualIndicator(List<SObject> newList, Map<Id, SObject> oldMapItems) {
        CustomLogging.push('resetPhysicalAssetManualIndicator', 'PhysicalAssetTriggerHandler');

        //Iterate and compare old and new values of LastPreventiveMaintenanceDate__c
        for (PhysicalAsset__c physicalAsset: (List<PhysicalAsset__c>) newList) {
            PhysicalAsset__c oldPhysicalAsset = (PhysicalAsset__c) oldMapItems.get(physicalAsset.Id);

            //Set Preventive Maintenance Planned and Preventive Maintenance Manual Update to false
            if (physicalAsset.LastPreventiveMaintenanceDate__c != oldPhysicalAsset.LastPreventiveMaintenanceDate__c) {
                physicalAsset.PreventiveMaintenancePlanned__c = false;
                physicalAsset.PreventiveMaintenanceManualUpdate__c = false;
                physicalAsset.NextPreventiveMaintenanceDate__c = null;
            } 
            
            //Set WTS Manual Update and WTS Planned to false 
            //[KTS-1095]: Contract Triggered Cases (Waterfilter Changes) 
            if (physicalAsset.LastWTSDate__c != oldPhysicalAsset.LastWTSDate__c) { 
                physicalAsset.WTSPlanned__c = false;
                physicalAsset.WTSManualUpdate__c = false;
                physicalAsset.NextWTSDate__c = null;
            }
        }

        CustomLogging.pop(); 
    } 

    /**
    * @author        Karen Mae Hung
    * @date          11/29/2018           
    * @description   Method responsible for populating contracttrigger setting field
    * @revision(s)
    */
    private void populateContractTriggerSetting(List<SObject> newList){
        CustomLogging.push('populateContractTriggerSetting', 'PhysicalAssetTriggerHandler');

        if(countryMap.isEmpty()){
            for(CountrySetting__c country : [SELECT ID, Country__c FROM CountrySetting__c WHERE Recordtype.Name ='Contract Trigger Setting' AND Active__c = true]){
                countryMap.put(country.Country__c, country);
            }
        }
        
        for (PhysicalAsset__c physicalAsset: (List<PhysicalAsset__c>) newList) {
            if(physicalAsset.IncludesPreventiveMaintenanceCoverage__c || physicalAsset.IncludesWTSCoverage__c){
                if(countryMap.containsKey(physicalAsset.SalesOrganization__c)){
                    physicalAsset.ContractTriggerSettings__c = countryMap.get(physicalAsset.SalesOrganization__c).Id;   
                } else{
                    physicalAsset.ContractTriggerSettings__c = null;   
                }
            }
        }
              
        CustomLogging.pop(); 
    }

    /**
    * @author        Francis Alindogan
    * @date          02/17/2020
    * @description   Method responsible for flushing the next WTS Date
    * @revision(s)
    */
    public void flushNextWTSDate(List<SObject> newList, Map<Id, SObject> oldMapItems){
        CustomLogging.push('flushNextWTSDate', 'PhysicalAssetTriggerHandler');
        List<WorkOrderLineItem> woliList = new List<WorkOrderLineItem>();
        Map<Id, WorkOrderLineItem> paWoliMap = new Map<Id, WorkOrderLineItem>();

        for (PhysicalAsset__c physicalAsset: (List<PhysicalAsset__c>) newList) {
            PhysicalAsset__c oldPhysicalAsset = (PhysicalAsset__c) oldMapItems.get(physicalAsset.Id);

            if((physicalAsset.WTSInterval__c != null && physicalAsset.WTSInterval__c != oldPhysicalAsset.WTSInterval__c) &&  //Check if Waterfilter Interval has been updated
                physicalAsset.NextWTSDate__c != null && //Check if next WTS Change Date is not null
                physicalAsset.WTSPlanned__c == false //Check if next WTS has not been planned
                ) {
                    physicalAsset.NextWTSDate__c = null;
            }
        } 
        
        CustomLogging.pop(); 
    }

    public without sharing class PhysicalAssetTriggerHandlerWithoutSharing {
        /**
        * @author        Abram Vixen Reyes
        * @date          2.05.2018           
        * @description   Method responsible in cloning the physical asset record as physical asset history.
        * @revision(s)
        */
        public void createHistoryRecord(List<SObject> newList, List<SObject> oldList, Map<Id, SObject> newMapItems, Map<Id, SObject> oldMapItems) {
            
            Map<String, Schema.SObjectField> schemaPhysicalAssetHistoryMap = Schema.SObjectType.PhysicalAssetHistory__c.fields.getMap();
            Map<String, Schema.SObjectField> schemaPhysicalAssetMap = Schema.SObjectType.PhysicalAsset__c.fields.getMap();
            Set<Schema.SObjectField> schemaPhysicalAssetHistoryFieldsSet = new Set<Schema.SObjectField>();
            Set<Schema.SObjectField> schemaPhysicalAssetFieldsSet = new Set<Schema.SObjectField>();
            Set<String> schemaPhysicalAssetHistoryFieldsSetString = new Set<String>();
            Set<String> schemaPhysicalAssetFieldsSetString = new Set<String>();
            List<SObject> sourceList = new List<SObject>();
            List<PhysicalAsset__c> updatedAssetsList = new List<PhysicalAsset__c>();
            List<PhysicalAssetHistory__c> assetHistoryToInsertList = new List<PhysicalAssetHistory__c>();
            List<PhysicalAssetHistory__c> assetHistoryToUpdateList = new List<PhysicalAssetHistory__c>();
            
            //GET ALL FIELD NAMES OF PHYSICALL ASSET HISTORY OBJECT
            for(Schema.SObjectField schm : schemaPhysicalAssetHistoryMap.values()){
                schemaPhysicalAssetHistoryFieldsSet.add(schm);
                schemaPhysicalAssetHistoryFieldsSetString.add(String.valueOf(schm));
            }
            
            //GET ALL FIELD NAMES OF PHYSICAL ASSET OBJECT
            for(Schema.SObjectField schm : schemaPhysicalAssetMap.values()){
                schemaPhysicalAssetFieldsSet.add(schm);
                schemaPhysicalAssetFieldsSetString.add(String.valueOf(schm));
            }

            //CHECK IF INSERT OR UPDATE
            if(oldList != null && oldMapItems != null){
                
                //GET ALL UPDATED ASSETS
                for(PhysicalAsset__c ps : (List<PhysicalAsset__c>) newList){
                    PhysicalAssetTriggerHandler pa = new PhysicalAssetTriggerHandler();
                    if(pa.validateIfHasChange(ps, (PhysicalAsset__c)oldMapItems.get(ps.Id))){
                        updatedAssetsList.add(ps);
                    }
                }
                
                
                System.debug('updatedAssetsList');
                System.debug(updatedAssetsList);

                //UPDATE LATEST PHYSICAL HISTORY RECORD
                if(!updatedAssetsList.isEmpty()){
                    List<PhysicalAssetHistory__c> historyToUpdateList = [SELECT Id, ValidTo__c, PhysicalAsset__c FROM PhysicalAssetHistory__c 
                                                                        WHERE (PhysicalAsset__c IN:updatedAssetsList AND ValidTo__c = null)];
                    if(!historyToUpdateList.isEmpty()){
                        for(PhysicalAssetHistory__c his : historyToUpdateList){
                            his.ValidTo__c = DateTime.now();
                            assetHistoryToInsertList.add(his);
                        }
                    }
                    
                    //CREATE NEW PHYSICAL HISTORY RECORD
                    //for(PhysicalAsset__c ps : (List<PhysicalAsset__c>) oldList){
                    for(PhysicalAsset__c ps : (List<PhysicalAsset__c>) newList){
                        PhysicalAssetHistory__c history = new PhysicalAssetHistory__c();
                        
                        //ITERATE ON  PHYSICAL HISTORY OBJECT FIELDS
                        for(Schema.SObjectField field : schemaPhysicalAssetHistoryFieldsSet){
                            Schema.DescribeFieldResult dfr = field.getDescribe();
                            if(dfr.isUpdateable() && schemaPhysicalAssetFieldsSetString.contains(String.valueOf(field))){
                                history.put(String.valueOf(field), ps.get(String.valueOf(field)));
                                System.debug(String.valueOf(field) + ' ' + ps.get(String.valueOf(field)));
                            }
                        }
                        
                        history.PhysicalAsset__c = ps.Id;
                        assetHistoryToInsertList.add(history);
                    }
                    
                    System.debug('Xen 12/7 assetHistoryToInsertList: ' + assetHistoryToInsertList);
                    
                    /*if(!assetHistoryToInsertList.isEmpty() && (Schema.sObjectType.PhysicalAssetHistory__c.isCreateable()
                        || Schema.sObjectType.PhysicalAssetHistory__c.isUpdateable())) { */ 
                    if(!assetHistoryToInsertList.isEmpty()){
                        try {
                            //Exception for test class purposes
                            if (Test.isRunningTest() && hasException) {
                                throw new TS_PhysicalAssetTriggerHandlerException('Force to throw an exception');
                            }

                            upsert assetHistoryToInsertList;

                            //XEN REYES Feb 1, 2019
                            //DOO-4710 Xen Reyes July 7, 2020 - Commented
                            //done = true;
                            
                        } catch(Exception ex) {
                            CustomLogging.debugException(ex);
                            CustomLogging.pop();
                        }
                        //upsert assetHistoryToInsertList;
                    }
                }
            } else {
                
                //CREATE NEW PHYSICAL HISTORY RECORD ON CREATE/INSERT
                for(PhysicalAsset__c ps : (List<PhysicalAsset__c>) newList){
                    PhysicalAssetHistory__c history = new PhysicalAssetHistory__c();
                    
                    //ITERATE ON  PHYSICAL HISTORY OBJECT FIELDS
                    for(Schema.SObjectField field : schemaPhysicalAssetHistoryFieldsSet){
                        Schema.DescribeFieldResult dfr = field.getDescribe();
                        if(dfr.isUpdateable() && schemaPhysicalAssetFieldsSetString.contains(String.valueOf(field))){
                            history.put(String.valueOf(field), ps.get(String.valueOf(field)));
                        }
                    }
                    
                    history.PhysicalAsset__c = ps.Id;
                    assetHistoryToInsertList.add(history);
                }
                
                if(!assetHistoryToInsertList.isEmpty() && Schema.sObjectType.PhysicalAssetHistory__c.isCreateable()){
                    insert assetHistoryToInsertList;
                } 
            }                
            //done = true;     
        }

        
        /**
        * @author        Karen Hung
        * @date          Feb 25,2020           
        * @description   Method responsible in deleting route line item DOO-3921
        * @revision(s)
        */
        public void deleteRouteItem(List<SObject> newList, List<SObject> oldList, Map<Id, SObject> newMapItems, Map<Id, SObject> oldMapItems) {
            CustomLogging.push('deleteRouteItem', 'PhysicalAssetTriggerHandler');

            //WHERE PhysicalAssetId__r.AssetStatus__c IN  (\'Activated\',\'Pending Cancellation\') 
            Set<String> assets = new Set<String>();
            Map<Id, PhysicalAsset__c> oldItemMap = (Map<Id, PhysicalAsset__c>) oldMapItems;
            Map<Id, PhysicalAsset__c> newItemMap = (Map<Id, PhysicalAsset__c>) newMapItems;
            
            try{
                
                //get assets updated to cancelled
                for(PhysicalAsset__c updatedAsset : (List<PhysicalAsset__c>) newList){
                    if(
                        ((oldItemMap.get(updatedAsset.Id).AssetStatus__c != updatedAsset.AssetStatus__c) && updatedAsset.AssetStatus__c == 'Cancelled')
                        //XEN REYES DOO-4336 April 8, 2020
                        || (oldItemMap.get(updatedAsset.Id).AccountLocation__c != updatedAsset.AccountLocation__c)
                        ){
                        assets.add(updatedAsset.Id);
                    }
                }

                //Delete Route Line Items
                if(!assets.isEmpty()){

                    //GET IF THERE IS A ROUTE LINE ITEM
                    List<Route_Line_Item__c> rl_list = [SELECT Id FROM Route_Line_Item__c WHERE PhysicalAssetId__c IN :assets];
                    if(!rl_list.isEmpty()){
                        delete rl_list;
                    }
                }
                
                if (Test.isRunningTest() && hasException) {
                    throw new TS_PhysicalAssetTriggerHandlerException('Force to throw an exception');
                
                }

            }catch(Exception ex){
                CustomLogging.debugException(ex);
                CustomLogging.pop();
                System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());
            }

            CustomLogging.pop();  
        }
    }

    /**
    * @author        Karen Hung
    * @date          Jul 2,2020           
    * @description   Method to execute logic from TS_PhysicalAssetUpdates and to implement update for DOO-4692
    * @revision(s)
    */
    public void physicalAssetUpdates(List<SObject> newList, List<SObject> oldList, Map<Id, SObject> newMapItems, Map<Id, SObject> oldMapItems) {
        CustomLogging.push('physicalAssetUpdates', 'PhysicalAssetTriggerHandler');

        Map<Id, PhysicalAsset__c> oldItemMap = (Map<Id, PhysicalAsset__c>) oldMapItems;

        //Map<Id, PhysicalAsset__c> newExtMap = getExtAssetMap(newMapItems.keyset());

        Id machineRecType = TS_UtilityClass.getRecordTypeIdByName(TS_Constants.OBJ_PHYSICALASSET,TS_Constants.PA_RECTYPE_MACHINE);
        Id optionRecType = TS_UtilityClass.getRecordTypeIdByName(TS_Constants.OBJ_PHYSICALASSET,TS_Constants.PA_RECTYPE_OPTION);

        try{

            for(PhysicalAsset__c updatedAsset : (List<PhysicalAsset__c>) newList){
                
                //Exclude if PreventiveMaintenancePlanned__c or WTSPlanned__c is updated
                if(!(updatedAsset.PreventiveMaintenancePlanned__c != oldItemMap.get(updatedAsset.Id).PreventiveMaintenancePlanned__c || updatedAsset.WTSPlanned__c != oldItemMap.get(updatedAsset.Id).WTSPlanned__c)){
                    
                    if((updatedAsset.UniqueNumber__c == null || updatedAsset.SerialNumber__c != oldItemMap.get(updatedAsset.Id).SerialNumber__c || updatedAsset.Product__c != oldItemMap.get(updatedAsset.Id).Product__c) && updatedAsset.Product__c != null){
                        
                        //update machine unique number
                        if(updatedAsset.RecordtypeId == machineRecType && updatedAsset.SerialNumber__c != null){
                            //CURRENT PB VALUE: TEXT([PhysicalAsset__c].Product__c.APTS_Vendor_Code__c ) + [PhysicalAsset__c].SerialNumber__c 
                            updatedAsset.UniqueNumber__c = newExtMap.get(updatedAsset.Id).Product__r.APTS_Vendor_Code__c + updatedAsset.SerialNumber__c;
                        }

                        //update option unique number
                        if(updatedAsset.RecordtypeId == optionRecType && updatedAsset.ParentPhysicalAsset__c != null){
                            //CURRENT PB VALUE: //IF(NOT(ISBLANK([PhysicalAsset__c].SerialNumber__c)), [PhysicalAsset__c].ProductCode__c + "_" + [PhysicalAsset__c].ParentPhysicalAsset__c.UniqueNumber__c + "_" + [PhysicalAsset__c].SerialNumber__c  ,  [PhysicalAsset__c].ProductCode__c + "_" + [PhysicalAsset__c].ParentPhysicalAsset__c.UniqueNumber__c)
                            updatedAsset.UniqueNumber__c = updatedAsset.SerialNumber__c != null ? (updatedAsset.ProductCode__c + '_' +  newExtMap.get(updatedAsset.Id).ParentPhysicalAsset__r.UniqueNumber__c + '_' + updatedAsset.SerialNumber__c) : (updatedAsset.ProductCode__c + '_' + newExtMap.get(updatedAsset.id).ParentPhysicalAsset__r.UniqueNumber__c);   
                        }

                    }

                    //update name of machine
                    if(updatedAsset.UniqueNumber__c != null && updatedAsset.Name != updatedAsset.UniqueNumber__c.left(80)  && updatedAsset.RecordtypeId == machineRecType){
                        //CURRENT PB VALUE: LEFT([PhysicalAsset__c].UniqueNumber__c, 80)
                        updatedAsset.Name = updatedAsset.UniqueNumber__c.left(80);
                    }

                    //update name of option
                    if(updatedAsset.RecordtypeId == optionRecType && updatedAsset.Product__c != null && updatedAsset.ProductDescription__c != null && updatedAsset.Name != updatedAsset.ProductDescription__c.left(80)){
                        // CURRENTPB VALUE: LEFT([PhysicalAsset__c].ProductDescription__c, 80)
                        updatedAsset.Name = updatedAsset.ProductDescription__c.left(80);
                    }

                }
            }

            if (Test.isRunningTest() && hasException) {
                throw new TS_PhysicalAssetTriggerHandlerException('Force to throw an exception');
            }                

        }catch(Exception ex){
            CustomLogging.debugException(ex);
            CustomLogging.pop();
            System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());
        }
        CustomLogging.pop(); 
    }

    /**
    * @author        Karen Hung
    * @date          Jul 6,2020           
    * @description   Method to execute update of option unique number for DOO-4692
    * @revision(s)
    */
    public void updateOptionUniqueNumber(List<SObject> newList, Map<Id, SObject> oldMapItems) {
        CustomLogging.push('updateOptionUniqueNumber', 'PhysicalAssetTriggerHandler');
        Map<Id, PhysicalAsset__c> oldItemMap = (Map<Id, PhysicalAsset__c>) oldMapItems;

        Map<Id, PhysicalAsset__c> optionsForUpdate = new Map<Id, PhysicalAsset__c>();
        
        Id machineRecType = TS_UtilityClass.getRecordTypeIdByName(TS_Constants.OBJ_PHYSICALASSET,TS_Constants.PA_RECTYPE_MACHINE);
        Id optionRecType = TS_UtilityClass.getRecordTypeIdByName(TS_Constants.OBJ_PHYSICALASSET,TS_Constants.PA_RECTYPE_OPTION);

        try{
            Set<Id> parentIds = new Set<Id>();

            for(PhysicalAsset__c asset : (List<PhysicalAsset__c>) newList){
                //if has change in uniquenumber of machine record
                if(asset.RecordtypeId == machineRecType && oldItemMap.get(asset.Id).SerialNumber__c != asset.SerialNumber__c){
                    parentIds.add(asset.Id);
                }
            }

            if(parentIds != null && !parentIds.isEmpty()){
                List<PhysicalAsset__c> options = [SELECT Id, UniqueNumber__c, ProductCode__c, SerialNumber__c,ParentPhysicalAsset__r.UniqueNumber__c,Product__c 
                                                  FROM PhysicalAsset__c 
                                                  WHERE RecordtypeId = :optionRecType AND ParentPhysicalAsset__c IN :parentIds];
                
                if(options != null && !options.isEmpty()){
                    for(PhysicalAsset__c option : options){
                        option.UniqueNumber__c = option.SerialNumber__c != null ? (option.ProductCode__c + '_' +  option.ParentPhysicalAsset__r.UniqueNumber__c + '_' + option.SerialNumber__c) : (option.ProductCode__c + '_' + option.ParentPhysicalAsset__r.UniqueNumber__c);   
                        optionsForUpdate.put(option.Id, option);   
                    }

                    if(optionsForUpdate != null && !optionsForUpdate.values().isEmpty()){
                        update(optionsForUpdate.values());
                    }
                }
            }

            if (Test.isRunningTest() && hasException) {
                throw new TS_PhysicalAssetTriggerHandlerException('Force to throw an exception');
            } 

        }catch(Exception ex){
            CustomLogging.debugException(ex);
            CustomLogging.pop();
            System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());
        }

        CustomLogging.pop(); 
    }


    /**
    * @author        Karen Hung
    * @date          Jul 6,2020           
    * @description   Method to query extended fields from lookups
    * @revision(s)
    */
    public Map<Id, PhysicalAsset__c> getExtAssetMap(Set<Id> assetIds){
        CustomLogging.push('getExtAssetMap', 'PhysicalAssetTriggerHandler');
        Map<Id, PhysicalAsset__c> extMap = new Map<Id, PhysicalAsset__c>();
        if(assetIds != null && !assetIds.isEmpty()){
            extMap = new Map<Id, PhysicalAsset__c>(
                     [SELECT Id, Product__c, Product__r.APTS_Vendor_Code__c, ParentPhysicalAsset__r.UniqueNumber__c 
                      FROM PhysicalAsset__c WHERE Id IN: assetIds]);
        }
        CustomLogging.pop(); 
        return extMap;
    }   
}