/*
* @author        Xen Reyes
* @date          11.08.2017        
* @description   Controller class for TS_CloseTaskWOLI lightning component.
* @revision(s)
*/
public with sharing class TS_CloseTaskWOLIController {
    
    /* RESPONSE FORMAT */
    public class LightningResponse{
        @AuraEnabled
        public String returnValue;
        @AuraEnabled
        public String status;
        @AuraEnabled
        public String message;

        public LightningResponse(){
            this.returnValue = returnValue;
            this.status = status;
            this.message = message;
        }
    }

    @AuraEnabled
    public static List<String> fetchPicklistValues(String objectName, String fieldAPI) {
        CustomLogging.push('fetchPicklistValues', 'TS_CloseTaskWOLIController');
        List<String> labelValueList = new List<String>();
        Schema.DescribeSObjectResult sobjectType = Schema.getGlobalDescribe().get(objectName).getDescribe();
        Schema.DescribeFieldResult sObjectResult = sobjectType.fields.getMap().get(fieldAPI).getDescribe();
        List<Schema.PicklistEntry> pick_list_values = sObjectResult.getPickListValues();
        for (Schema.PicklistEntry a : pick_list_values) {
            labelValueList.add(a.getLabel());
        }
        CustomLogging.pop();
        return labelValueList;
    }

    @AuraEnabled
    public static String getCurrentUserType() {

        LightningResponse lResponse = new LightningResponse();
        Map<String, String> responseMap = new Map<String, String>();

        //Xen Reyes 9.03.2018 KTS-2140
        CustomLogging.push('getCurrentUserType', 'TS_CloseTaskWOLIController');

        responseMap.put('userType', Userinfo.getUserType());
        responseMap.put('isThirdPartyRLS', ([SELECT Id, RLS_Portal_User__c FROM Resource__c WHERE RelatedUser__c =: UserInfo.getUserId() AND RLS_Portal_User__c = true].size() != 0 ? 'true':'false'));

        lResponse.returnValue = JSON.serialize(responseMap);

        CustomLogging.pop();

        return JSON.serialize(lResponse);
    }

    @AuraEnabled
    public static Map<String, String> fetchPicklistValuesMap(String objectName, String fieldAPI) {
        CustomLogging.push('fetchPicklistValuesMap', 'TS_CloseTaskWOLIController');
        Map<String, String> labelValueMap = new Map<String, String>();
        Schema.DescribeSObjectResult sobjectType = Schema.getGlobalDescribe().get(objectName).getDescribe();
        Schema.DescribeFieldResult sObjectResult = sobjectType.fields.getMap().get(fieldAPI).getDescribe();
        List<Schema.PicklistEntry> pick_list_values = sObjectResult.getPickListValues();
        for (Schema.PicklistEntry a : pick_list_values) {
            labelValueMap.put(a.getLabel(), a.getValue());
        }
        CustomLogging.pop();
        return labelValueMap;
    }
    
    @AuraEnabled
    public static List<WorkOrderLineItem> queryChildWOLIs(String recordId) {
        CustomLogging.push('queryChildWOLIs', 'TS_CloseTaskWOLIController');
        List<WorkOrderLineItem> woliList = new List<WorkOrderLineItem>();
        
        try{
            woliList = [SELECT Id, RecordTypeId, RecordType.DeveloperName, toLabel(Warranty__c), PricebookEntry.Name, PricebookEntryId, Quantity,Part_used_from_own_storage_location__c, DirectToCustomer__c, IsLabour__c, MissingReason__c 
                        FROM WorkOrderLineItem WHERE (ParentWorkOrderLineItemId =: recordId AND PricebookEntryId != '') ];
            if(woliList.size() != 0){
                return woliList;
            }
        } catch (Exception e){
            System.debug(e);
        }
        CustomLogging.pop();
        return woliList;
    }
    
    @AuraEnabled
    public static Map<String, List<String>> getPLvalueOption2(String objectName, String controllingField, String dependentField) {
        CustomLogging.push('getPLvalueOption2', 'TS_CloseTaskWOLIController');
        Schema.SObjectType objType = Schema.getGlobalDescribe().get(objectName);
        Map<String, Schema.SObjectField> objFieldMap = objType.getDescribe().fields.getMap();
        
        Schema.DescribeFieldResult F = objFieldMap.get(controllingField).getDescribe();
        Schema.sObjectField T = F.getSObjectField();
        
        Schema.DescribeFieldResult F1 = objFieldMap.get(dependentField).getDescribe();
        Schema.sObjectField T1 = F1.getSObjectField();
        CustomLogging.pop();
        return TS_HL_FieldDescribeUtil.getDependentOptionsImpl(T1, T);
    }

    @AuraEnabled
    public static Map<String,TS_PicklistEntryWrapper> getPLvalueOption3(String objectName, String controllingField, String dependentField) {
        CustomLogging.push('getPLvalueOption3', 'TS_CloseTaskWOLIController');
        Schema.SObjectType objType = Schema.getGlobalDescribe().get(objectName);
        Map<String, Schema.SObjectField> objFieldMap = objType.getDescribe().fields.getMap();
        
        Schema.DescribeFieldResult F = objFieldMap.get(controllingField).getDescribe();
        Schema.sObjectField T = F.getSObjectField();
        
        Schema.DescribeFieldResult F1 = objFieldMap.get(dependentField).getDescribe();
        Schema.sObjectField T1 = F1.getSObjectField();
        CustomLogging.pop();
        return TS_HL_FieldDescribeUtil.getDependentOptionsImpl2(T1, T);
    }
    
    @AuraEnabled
    public static String insertParts(String woliList, String woliId, String caseId, String wOId, Boolean isMobile, WorkOrderLineItem wo, Boolean reviewNeeded, Boolean isFromReviewNeeded) {
        CustomLogging.push('insertParts', 'TS_CloseTaskWOLIController');
        
        //WorkOrderLineItemTriggerHandler.COMPLETED_THIRDPARTY_PORTAL = true;
        
        Savepoint sp = Database.setSavepoint();

        Id missingPartRecTypeId = Schema.SObjectType.WorkOrderLineItem.getRecordTypeInfosByName().get(Label.TS_WOLI_RecordType_RegMissPart).getRecordTypeId();
        Id usedPartRecTypeId = Schema.SObjectType.WorkOrderLineItem.getRecordTypeInfosByName().get(Label.TS_WOLI_RecordType_RegUsedPart).getRecordTypeId();
        Id serviceMaterialsRecTypeId = Schema.SObjectType.WorkOrderLineItem.getRecordTypeInfosByName().get(Label.TS_WOLI_RecordType_RegServMat).getRecordTypeId();

        WorkOrderLineItem dummyMat = new WorkOrderLineItem();
        
        System.debug('woliList');
        System.debug(woliList);
        
        List<TS_CloseTaskWOLIController.woliPartsWrapper> woliWrapper = (List<TS_CloseTaskWOLIController.woliPartsWrapper>) System.JSON.deserialize(woliList, List<TS_CloseTaskWOLIController.woliPartsWrapper>.class);
        System.debug(woliWrapper);
        System.debug(woliWrapper.size());
        
        /* if(isMobile && woliWrapper.size() != 0){
            woliWrapper.remove(woliWrapper.size() -1);
        } */
        
        System.debug('woliWrapper');
        System.debug(woliWrapper);
        System.debug(woliWrapper.size());
        
        
        List<WorkOrderLineItem> partsToInsertList = new List<WorkOrderLineItem>();
        List<WorkOrderLineItem> partsToUpdateList = new List<WorkOrderLineItem>();
        List<WorkOrderLineItem> partsToUpsertList = new List<WorkOrderLineItem>();
        String status = '';
        String operation = '';


        Map<String, String> warranty = new Map<String, String>();
        warranty.put('Under Warranty', 'K1');
        warranty.put('Covered By Contract', 'YR');
        warranty.put('Coulance (Goodwill)', 'Z1');
        warranty.put('To be paid by Customer', 'C1');
        
        try{
            
            for(TS_CloseTaskWOLIController.woliPartsWrapper ts : woliWrapper){
                
                if(ts.isExisting == true && !String.isEmpty(ts.recordId) && ts.recordId != null){
                    WorkOrderLineItem updatePart = new WorkOrderLineItem(Id = ts.recordId);
                    
                    if(ts.partType == 'UsedPart'){

                        //XR 7.13.2018
                        if(warranty.containsKey(ts.warranty)){
                            updatePart.Warranty__c = warranty.get(ts.warranty);
                        } else {
                            updatePart.Warranty__c = ts.warranty;
                        }

                        //Karen Hung DOO-4667 28.05.2020
                        updatePart.Part_used_from_own_storage_location__c = ts.fromOwnCar;
                        
                        updatePart.Status = 'Completed'; //XR 5.23
                    } else if(ts.partType == 'MissingPart'){

                        updatePart.DirectToCustomer__c = ts.directCus;
                        updatePart.MissingReason__c = ts.missingReason;

                        //Karen Hung 16.6.2020 DOO-4648
                        if(warranty.containsKey(ts.warranty)){
                            updatePart.Warranty__c = warranty.get(ts.warranty);
                        } else {
                            updatePart.Warranty__c = ts.warranty;
                        }

                    } else if(ts.partType == 'ServiceMaterial'){
                        
                        //XR 7.13.2018
                        if(warranty.containsKey(ts.warranty)){
                            updatePart.Warranty__c = warranty.get(ts.warranty);
                        } else {
                            updatePart.Warranty__c = ts.warranty;
                        }
                    }
                    
                    if(ts.quantity == 0 || ts.quantity == null){
                        updatePart.Quantity = 1;
                    } else {
                        updatePart.Quantity = ts.quantity;
                    }
                    
                    System.debug('updatePart');
                    System.debug(updatePart);
                    
                    partsToUpdateList.add(updatePart);
                    partsToUpsertList.add(updatePart);
                    
                } else if(ts.isExisting == false && ts.isExisting != null){
                    WorkOrderLineItem newPart = new WorkOrderLineItem();
                    
                    if(ts.productId != null){
                        newPart.PricebookEntryId = ts.productId;  
                    } else {
                        continue;
                    }
                    
                    if(ts.partType == 'UsedPart'){
                        newPart.RecordTypeId = usedPartRecTypeId;
                        newPart.WorkOrderLineItemType__c = 'UsedSpareParts';
                        newPart.Status = 'Completed'; //XR 5.23

                        //XR 7.13.2018
                        if(warranty.containsKey(ts.warranty)){
                            newPart.Warranty__c = warranty.get(ts.warranty);
                        } else {
                            newPart.Warranty__c = ts.warranty;
                        }

                        //Karen Hung 29.05.2020 DOO-4667
                        newPart.Part_used_from_own_storage_location__c = ts.fromOwnCar;

                    } else if(ts.partType == 'MissingPart'){

                        newPart.RecordTypeId = missingPartRecTypeId;
                        newPart.WorkOrderLineItemType__c = 'MissingSpareParts';
                        newPart.DirectToCustomer__c = ts.directCus;
                        newPart.MissingReason__c = ts.missingReason;
                        
                        //Karen Hung 16.6.2020 DOO-4648
                        if(warranty.containsKey(ts.warranty)){
                            newPart.Warranty__c = warranty.get(ts.warranty);
                        } else {
                            newPart.Warranty__c = ts.warranty;
                        }                       
                    } else if(ts.partType == 'ServiceMaterial'){
                        newPart.RecordTypeId = serviceMaterialsRecTypeId;
                        newPart.WorkOrderLineItemType__c = 'Service Materials';
                        
                        //XR 7.13.2018
                        if(warranty.containsKey(ts.warranty)){
                            newPart.Warranty__c = warranty.get(ts.warranty);
                        } else {
                            newPart.Warranty__c = ts.warranty;
                        }
                    }
                    
                    newPart.Case__c = caseId;
                    newPart.WorkOrderId = wOId;
                    newPart.ParentWorkOrderLineItemId = woliId;
                    
                    if(ts.quantity == 0 || ts.quantity == null){
                        newPart.Quantity = 1;
                    } else {
                        newPart.Quantity = ts.quantity;
                    }
                    
                    System.debug('newPart');
                    System.debug(newPart);
                    
                    partsToInsertList.add(newPart);
                    partsToUpsertList.add(newPart);
                
                }
            }
            
            List<WorkOrderLineItem> woliUpsert_list = new List<WorkOrderLineItem>();

            if (partsToInsertList.size() != 0 && partsToUpdateList.size() != 0){
                System.debug('upsert');
                operation = 'upsert';
                
                //upsert partsToUpsertList;
                woliUpsert_list.addAll(partsToUpsertList);

            } else if (partsToInsertList.size() != 0 && partsToUpdateList.size() == 0){
                System.debug('insert');
                operation = 'insert';
                
                //insert partsToInsertList;
                woliUpsert_list.addAll(partsToInsertList);
            } else if (partsToInsertList.size() == 0 && partsToUpdateList.size() != 0){
                System.debug('update');
                operation = 'update';
                
                //update partsToUpdateList;
                woliUpsert_list.addAll(partsToUpdateList);
            }

            //UPDATE WORKORDERLINEITEM 11/29 Xen Reyes
            //update wo;
            woliUpsert_list.add(wo);

            //INSERT DUMMY MATERIAL - Xen Reyes Jan. 8, 2019
            System.debug('XEN Jan .8 reviewNeeded: ' + reviewNeeded);
            if(reviewNeeded != true && reviewNeeded != null){
                dummyMat = insertDummyServiceMaterialMethod2(wo.WorkOrderId, wo.Case__c, wo.Id, isFromReviewNeeded);
                
                //insert dummyMat;
                woliUpsert_list.add(dummyMat);
            }
            
            //DOO-3911 Francis Alindogan Feb. 26, 2020
            upsert woliUpsert_list;

            System.debug('SUCCESS ' + operation);
            status = 'SUCCESS';
            CustomLogging.pop();

        } catch (Exception e){
            //status =  e.getMessage();

            status =  e.getMessage();
            System.debug(status);
            if(status.contains('FIELD_CUSTOM_VALIDATION_EXCEPTION')){
                status = status.substringBetween('FIELD_CUSTOM_VALIDATION_EXCEPTION, ', ': ');
            }
            System.debug(status);

            Database.rollback(sp);
        }

        return status;
    }
    
    public class woliPartsWrapper{
        @AuraEnabled
        public  String partType {get; set;} 
        @AuraEnabled
        public  Id productId {get; set;} 
        @AuraEnabled
        public  Boolean directCus {get; set;} 
        @AuraEnabled
        public  Boolean isExisting {get; set;}
        @AuraEnabled
        public  String recordId {get; set;} 
        @AuraEnabled
        public  Integer quantity {get; set;}
        @AuraEnabled
        public  Boolean fromOwnCar {get; set;} //Karen Hung DOO-4667 28.05.2020
        @AuraEnabled
        public  String warranty {get; set;} 
         @AuraEnabled
        public  String missingReason {get; set;} 
    }
    
    @AuraEnabled
    public static Long getDifference (DateTime startTime, DateTime endTime) {
        CustomLogging.push('getDifference', 'TS_CloseTaskWOLIController');
        Long diff = 0;
        System.debug('startTime ' + startTime);
        System.debug('endTime ' + endTime);
        
        
        if (startTime != null && endTime != null) {
            Decimal actualTravelHours = (Decimal.valueOf(endTime.getTime() - startTime.getTime()) / (1000 * 60 * 60)) * 4;
            diff = actualTravelHours.round(System.RoundingMode.UP);
        }
        
        System.debug('diff ' + diff);
        CustomLogging.pop();
        return diff;
    }
    
    @AuraEnabled
    public static string insertDummyServiceMaterial (String woId, String caseId, String parentWOLI, Boolean hasReviewNeeded) {
        CustomLogging.push('insertDummyServiceMaterial', 'TS_CloseTaskWOLIController');
        Id serviceMaterialsRecTypeId = Schema.SObjectType.WorkOrderLineItem.getRecordTypeInfosByName().get(Label.TS_WOLI_RecordType_RegServMat).getRecordTypeId();
        String status = 'SUCCESS';
        List<WorkOrderLineItem> woliQuotingSignatureList = new  List<WorkOrderLineItem>();
        List<WorkOrderLineItem> parentWOLIList = new List<WorkOrderLineItem>();
        
        //Savepoint sp = Database.setSavepoint();

        try{

            //update wo;

            parentWOLIList = [SELECT Id, QuotingSignature__c, Status, ReviewNeeded__c FROM WorkOrderLineItem where Id =: parentWOLI LIMIT 1];
            System.debug('xEN 10/2 parentWOLIList: ' + parentWOLIList);

            //if(Userinfo.getUserType() == 'Standard'){
            WorkOrderLineItem dummy = new WorkOrderLineItem();
            dummy.recordTypeId = serviceMaterialsRecTypeId;
            dummy.IsReadyToSummarize__c = true;
            dummy.WorkOrderLineItemType__c = 'Service Materials';
            dummy.WorkOrderId = woId;
            
            dummy.ParentWorkOrderLineItemId = parentWOLI;
            dummy.Warranty__c = 'K1';
            dummy.Status = 'Completed';

            //KTS-1849  BY Ritesh Kuamr 05.09.2018
            if(hasReviewNeeded){
                woliQuotingSignatureList = [SELECT Id, QuotingSignature__c, Status, ReviewNeeded__c FROM WorkOrderLineItem where Id =: parentWOLI LIMIT 1];
                
                if(!woliQuotingSignatureList.isEmpty()){
                
                    if(woliQuotingSignatureList[0].QuotingSignature__c != null){
                        dummy.QuotingSignature__c =  woliQuotingSignatureList[0].QuotingSignature__c;
                    }
                }
            }
            
            insert dummy;
            //}

        } catch (Exception e){

            //Database.rollback(sp);

            status =  e.getMessage();
            System.debug(status);
            if(status.contains('FIELD_CUSTOM_VALIDATION_EXCEPTION')){
                status = status.substringBetween('FIELD_CUSTOM_VALIDATION_EXCEPTION, ', ': ');
            }
            System.debug(status);

        }

        CustomLogging.pop();
        return status;
    }
    
    @AuraEnabled
    public static WorkOrderLineItem getRecordWOLI (String recId) {
        CustomLogging.push('getRecordWOLI', 'TS_CloseTaskWOLIController');
        WorkOrderLineItem rec = new WorkOrderLineItem();
        try{
            rec = [SELECT Id, ActionType__c, SamId__c,ExecutingEngineer__c, ExecutingEngineer__r.Name, CompletionCode__c, FaultLocationCategory__c, FaultCode__c, DefectCode__c, Warranty__c, InternalCompletionNote__c, ExternalCompletionNote__c, WorkQuarters__c, CoffeeRunsAfterVisit__c, CoffeeRunsUponArrival__c, ReturnNeeded__c,Return_Needed_Comment__c, Return_Needed_S10__c, StartDate__c, EndDate__c, Travel_Start_Time__c, Travel_Stop_Time__c, PhysicalAsset__c, PhysicalAsset__r.Name, ConnectivityModuleSerialNumber__c, PaymentModuleSerialNumber__c, MissingReason__c, InternalOrderSAP__c FROM WorkOrderLineItem WHERE Id =: recId LIMIT 1];
        } catch (Exception e){
            System.debug(e.getMessage());
        }
        CustomLogging.pop();
        return rec;
    }
    
    @AuraEnabled
    public static void deleteParts (List<String> partsId) {
        CustomLogging.push('deleteParts', 'TS_CloseTaskWOLIController');
        delete [SELECT Id FROM WorkOrderLineItem WHERE Id IN: partsId];
        CustomLogging.pop();
    }

    public static WorkOrderLineItem insertDummyServiceMaterialMethod2 (String woId, String caseId, String parentWOLI, Boolean hasReviewNeeded) {
        CustomLogging.push('insertDummyServiceMaterialMethod2', 'TS_CloseTaskWOLIController');
        Id serviceMaterialsRecTypeId = Schema.SObjectType.WorkOrderLineItem.getRecordTypeInfosByName().get(Label.TS_WOLI_RecordType_RegServMat).getRecordTypeId();
        String status = 'SUCCESS';
        List<WorkOrderLineItem> woliQuotingSignatureList = new  List<WorkOrderLineItem>();
        List<WorkOrderLineItem> parentWOLIList = new List<WorkOrderLineItem>();
        WorkOrderLineItem dummy = new WorkOrderLineItem();
        
        try{

            parentWOLIList = [SELECT Id, QuotingSignature__c, Status, ReviewNeeded__c FROM WorkOrderLineItem where Id =: parentWOLI LIMIT 1];
            System.debug('XEN 10/2 parentWOLIList: ' + parentWOLIList);

            //if(Userinfo.getUserType() == 'Standard'){
            dummy.recordTypeId = serviceMaterialsRecTypeId;
            dummy.IsReadyToSummarize__c = true;
            dummy.WorkOrderLineItemType__c = 'Service Materials';
            dummy.WorkOrderId = woId;
            dummy.Case__c = caseId;
            dummy.ParentWorkOrderLineItemId = parentWOLI;
            dummy.Warranty__c = 'K1';
            dummy.Status = 'Completed';

            //KTS-1849  BY Ritesh Kuamr 05.09.2018
            if(hasReviewNeeded){
                woliQuotingSignatureList = [SELECT Id, QuotingSignature__c, Status, ReviewNeeded__c FROM WorkOrderLineItem where Id =: parentWOLI LIMIT 1];
                
                if(!woliQuotingSignatureList.isEmpty()){
                
                    if(woliQuotingSignatureList[0].QuotingSignature__c != null){
                        dummy.QuotingSignature__c =  woliQuotingSignatureList[0].QuotingSignature__c;
                    }
                }
            }

        } catch (Exception e){

            status =  e.getMessage();
            System.debug(status);
            if(status.contains('FIELD_CUSTOM_VALIDATION_EXCEPTION')){
                status = status.substringBetween('FIELD_CUSTOM_VALIDATION_EXCEPTION, ', ': ');
            }
            System.debug(status);

        }

        CustomLogging.pop();
        return dummy;
    }

    //Francis Alindogan 01.21.2019 DOO-3522
    @AuraEnabled
    public static Decimal getWTSInterval (String recId) {
        CustomLogging.push('getWTSInterval', 'TS_CloseTaskWOLIController');
        Map<String, CountrySetting__c> map_thresholdByCountry = new Map<String, CountrySetting__c>();
        WorkOrderLineItem woli = new WorkOrderLineItem();
        Decimal wtsInterval;

        try{
            woli = [SELECT Id, PhysicalAsset__r.WTSInterval__c, PhysicalAsset__r.SalesOrganization__c  FROM WorkOrderLineItem WHERE Id =: recId LIMIT 1];

             List<CountrySetting__c> countrySetList = [SELECT Name, Country__c, Business_Hours__c, 
                                                         Business_Hours__r.MondayEndTime,
                                                         Business_Hours__r.TuesdayEndTime,
                                                         Business_Hours__r.WednesdayEndTime,
                                                         Business_Hours__r.ThursdayEndTime,
                                                         Business_Hours__r.FridayEndTime,
                                                         Business_Hours__r.SaturdayEndTime,
                                                         Business_Hours__r.SundayEndTime,
                                                         RecordType.DeveloperName,
                                                         PreventiveMainTriggerThreshold__c, 
                                                         WTSTriggerThreshold__c,
                                                         Default_WTS_Interval__c, 
                                                         Merge_WTS__c
                                                  FROM CountrySetting__c 
                                                  WHERE (RecordType.DeveloperName = :TS_Constants.TS_CountrySettingRecType_CountryDefBusHrs
                                                  OR RecordType.DeveloperName = :TS_Constants.TS_CountrySettingRecType_ConTriggerSet
                                                  OR RecordType.DeveloperName = :TS_Constants.TS_RECORDTYPENAME_COUNTRYSETTING_MERGEWTS)
                                                  AND Active__c = true];

                for (CountrySetting__c countrySet: countrySetList) {
                    //Retrieve and iterate country settings with record type 'ContractTriggerSetting' 
                    //Check if country in the map already exist. If not, populate map with country and CountrySetting__c
                    if (TS_Constants.TS_CountrySettingRecType_ConTriggerSet.equals(countrySet.RecordType.DeveloperName) && !map_thresholdByCountry.containsKey(countrySet.Country__c)) {
                        map_thresholdByCountry.put(countrySet.Country__c, countrySet);
                    }
                }
            
                if(woli.PhysicalAsset__r.WTSInterval__c != null){
                    wtsInterval = woli.PhysicalAsset__r.WTSInterval__c;
                }
                else {
                    wtsInterval = map_thresholdByCountry.get(woli.PhysicalAsset__r.SalesOrganization__c).Default_WTS_Interval__c;
                }
        } 
        catch (Exception e){
            System.debug(e.getMessage());
        }
        CustomLogging.pop();
        return wtsInterval;
    }

}