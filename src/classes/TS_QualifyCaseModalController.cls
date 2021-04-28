/**
* @author        Rey Austral
* @date          9.28.2017           
* @description   Controller for TS_QualifyCaseModal (Lightning Component)
* @revision(s)
*/
public with sharing class TS_QualifyCaseModalController {

    @AuraEnabled
    public static Map<String,TS_PicklistEntryWrapper> getDependentValue(String objectName, String controllingField, String dependentField) {
        CustomLogging.push('getDependentValue', 'TS_QualifyCaseModalController');
        CustomLogging.pop();
        return TS_PicklistFieldHelper.getDependentOptionsImpl(objectName, controllingField, dependentField);
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
        CustomLogging.push('getPLvalueOption2', 'TS_CloseTaskWOLIController');
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
    public static String getPLvalueOptionBulk(String fieldDependenciesList) {
        CustomLogging.push('getPLvalueOptionBulk', 'TS_CloseTaskWOLIController');
        
        String retVal;
        List<DependentPicklistResponse> depRespList = new List<DependentPicklistResponse>();
        List<TS_QualifyCaseModalController.dependentPicklistWrapper> dependentWrapper = (List<TS_QualifyCaseModalController.dependentPicklistWrapper>) System.JSON.deserialize(fieldDependenciesList, List<TS_QualifyCaseModalController.dependentPicklistWrapper>.class);

        System.debug(dependentWrapper);

        if(!dependentWrapper.isEmpty()){
            for(TS_QualifyCaseModalController.dependentPicklistWrapper var : dependentWrapper){

                Schema.SObjectType objType = Schema.getGlobalDescribe().get(var.objectName);
                Map<String, Schema.SObjectField> objFieldMap = objType.getDescribe().fields.getMap();
                
                Schema.DescribeFieldResult F = objFieldMap.get(var.controllingField).getDescribe();
                Schema.sObjectField T = F.getSObjectField();
                
                Schema.DescribeFieldResult F1 = objFieldMap.get(var.dependentField).getDescribe();
                Schema.sObjectField T1 = F1.getSObjectField();

                DependentPicklistResponse dep = new DependentPicklistResponse();
                dep.objectName = var.objectName;
                dep.controllingField = var.controllingField;
                dep.dependentField = var.dependentField;
                dep.mapPicklistValues = TS_HL_FieldDescribeUtil.getDependentOptionsImpl2(T1, T);
                depRespList.add(dep);
            }

            retVal = JSON.serialize(depRespList);
        }

        /* Schema.SObjectType objType = Schema.getGlobalDescribe().get(objectName);
        Map<String, Schema.SObjectField> objFieldMap = objType.getDescribe().fields.getMap();
        
        Schema.DescribeFieldResult F = objFieldMap.get(controllingField).getDescribe();
        Schema.sObjectField T = F.getSObjectField();
        
        Schema.DescribeFieldResult F1 = objFieldMap.get(dependentField).getDescribe();
        Schema.sObjectField T1 = F1.getSObjectField(); */

        CustomLogging.pop();

        return retVal;
        
    }

    @AuraEnabled
    public static String insertCase(Case csRec) {
        CustomLogging.push('insertCase', 'TS_QualifyCaseModalController');
        try{
            insert csRec;
        } catch (Exception e){
            return String.valueOf(e);
        }
        CustomLogging.pop();
        return 'SUCCESS';
    }

    @AuraEnabled
    public static String insertCaseDebug(Case csRec) {
        CustomLogging.push('insertCaseDebug', 'TS_QualifyCaseModalController');
        Id caseId;

        try{
            caseId = TS_CaseAssignmentRuleToggle.fireAssignmentRuleSingle(csRec);
        } catch (Exception e){
            return String.valueOf(e);
        }
        CustomLogging.pop();
        return String.valueOf(caseId);
    }

    @AuraEnabled
    public static String qualifyCase(String caseId, String contactId, String assetId, String accountLocationId, String caseType, String caseSubType, Boolean useRouting, String subj, String description, String reason1, String reason2, String product, 
                                     String orderId, String orderName, String customerCaseId, String lotCode, Date bestBeforeDate, String transactionId, Integer quantity, String quantityUnit, String poNumber, Boolean requiresCostEstimate, Boolean coffeeIsRunning, Boolean scheduleManually, Decimal costIndicationAsDiscussed, DateTime slaDate, Boolean sendTo3rdParty) {
                           
        LightningResponse lResponse = new LightningResponse();
            
        //Fetching the assignment rules on case
        AssignmentRule AR = new AssignmentRule();
        AR = [SELECT Id FROM AssignmentRule WHERE SobjectType = 'Case' AND Active = True LIMIT 1];

        //Creating the DMLOptions for "Assign using active assignment rules" checkbox
        Database.DMLOptions dmlOpts = new Database.DMLOptions();
        dmlOpts.assignmentRuleHeader.assignmentRuleId= AR.id;

        if(!String.isEmpty(caseId)){

            try{
                Case getCase = [SELECT Id, OwnerId FROM Case WHERE Id =: caseId LIMIT 1];

                //CHECK IF THE CURRENT USER IN THE DATABASE IS STILL THE OWNER //DOO-5274 XEN REYES - Jan. 26, 2020
                if(UserInfo.getUserId() != getCase.OwnerId){
                    lResponse.returnValue = 'ERROR';
                    lResponse.status = 'ERROR';
                    lResponse.message = 'Only the owner can qualify the case. Please take ownership and/or refresh the page.';
                    return JSON.serialize(lResponse);
                }

                getCase.ContactId = contactId;
                getCase.Status = 'Open';
                getCase.Type = caseType;
                getCase.SubType__c = caseSubType;
                getCase.AssignToQueue__c = useRouting;
                
                if(!String.isEmpty(product)){
                    getCase.ProductId = product;
                }
                //getCase.setOptions(dmlOpts);

                getCase.Subject = subj;
                getCase.Description = description;

                if(!String.isEmpty(assetId)){
                    getCase.PhysicalAsset__c = assetId; 
                }
                
                if(!String.isEmpty(accountLocationId)){
                    getCase.AccountLocation__c = accountLocationId;
                }

                if(caseType == TS_Constants.CASE_TYPE_COMPLAINT){
                    getCase.ReasonLevel1__c = reason1;
                    
                    if(reason2 != null){
                        getCase.ReasonLevel2__c = reason2;
                    }
                }
                
                //DOO-5104 12/10/2020 Francis Allen Alindogan
                if(caseType == TS_Constants.CASE_TYPE_COMPLAINT){
                    if(lotCode != null){
                        getCase.TS_Lot_Code__c = lotCode;
                    }
                    if(bestBeforeDate != null){
                        getCase.TS_Best_Before_Date__c = bestBeforeDate;
                    }
                    if(orderId != null){
                        getCase.ApptusOrder__c = orderId;
                    }
                    if(transactionId != null){
                        getCase.Transaction_ID__c = transactionId;
                    }
                    if(customerCaseId != null){
                        getCase.Customer_Case_ID__c = customerCaseId;
                    }
                    if(quantity != null){
                        getCase.Quantity__c = quantity;
                    }
                    if(quantityUnit != null){
                        getCase.QuantityUnit__c = quantityUnit;
                    }                                                         
                }
                else if(caseType == TS_Constants.CASE_TYPE_CUSTOMERCARE){
                    if(customerCaseId != null){
                        getCase.Customer_Case_ID__c = customerCaseId;
                    }                    
                }
                else if(caseType == TS_Constants.CASE_TYPE_FIELDSERVICE){
                    if(poNumber != null){
                        getCase.PO_Number__c = poNumber;
                    }
                    if(requiresCostEstimate != null){
						getCase.RequiresCostEstimate__c = requiresCostEstimate;                        
                    }
                    if(costIndicationAsDiscussed != null){
                        getCase.CostIndicationAsDiscussed__c = costIndicationAsDiscussed;
                    }
                    if(customerCaseId != null){
						getCase.Customer_Case_ID__c = customerCaseId;               
                    }       
                    if(coffeeIsRunning != null){
                        getCase.CoffeeIsRunning__c = coffeeIsRunning;
                    }
                    if(scheduleManually != null){
                        getCase.ScheduleManually__c = scheduleManually;
                    }                                        
                    if(slaDate != null){
                        getCase.SLADate__c = slaDate;
                    }                             
                    if(sendTo3rdParty != null && caseSubType == TS_Constants.WO_TYPE_S15_1STLINECM){
                    	getCase.SendTo3rdParty__c = sendTo3rdParty;    
                    }                                        
                }

                update getCase;
                lResponse.returnValue = 'SUCCESS';
                lResponse.status = 'SUCCESS';

            } catch (Exception e){
                String message = e.getMessage();

                lResponse.returnValue = 'ERROR';
                lResponse.status = 'ERROR';
                //lResponse.message = 'Error: ' + e.getMessage() + '\nSTACK TRACE: ' + e.getStackTraceString();

                if(message.contains('FIELD_CUSTOM_VALIDATION_EXCEPTION')){
                    lResponse.message = message.SubStringAfter('FIELD_CUSTOM_VALIDATION_EXCEPTION, ').SubStringBefore(': []');
                } else {
                    lResponse.message = e.getMessage();
                }
            }
        }

        
        return JSON.serialize(lResponse);
    }

    @AuraEnabled
    public static String getRecordTypeCR(){
        CustomLogging.push('getRecordTypeCR', 'TS_QualifyCaseModalController');
        CustomLogging.pop();
        return TS_UtilityClass.getRecordTypeIdByName(Label.TS_Obj_API_Name_Case, Label.TS_Case_RecordType_Registration);          
    }

    public class dependentPicklistWrapper{
        @AuraEnabled
        public  String objectName {get; set;} 
        @AuraEnabled
        public  String controllingField {get; set;} 
        @AuraEnabled
        public  String dependentField {get; set;} 
    }

    public class DependentPicklistResponse{
        @AuraEnabled
        public String objectName;
        @AuraEnabled
        public String controllingField;
        @AuraEnabled
        public String dependentField;
        @AuraEnabled
        public Map<String,TS_PicklistEntryWrapper> mapPicklistValues;

        public DependentPicklistResponse(){
            this.objectName = objectName;
            this.controllingField = controllingField;
            this.dependentField = dependentField;
            this.mapPicklistValues = mapPicklistValues;
        }
    }

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

    //check if application being used is Service Console Karen Hung 2/21/2019
    @AuraEnabled
    public static Boolean isServiceConsole(){
        CustomLogging.push('isServiceConsole', 'TS_QualifyCaseModalController');
        Boolean isServiceConsole = false;
        Set<String> ACTIVE_APP_SET = new Set<String>();

        UserAppInfo userAppInfo = [SELECT Id, AppDefinitionId FROM UserAppInfo WHERE UserId = :UserInfo.getUserId() LIMIT 1];
        List<AppDefinition> appDefinitionList = [SELECT DurableId, Label FROM AppDefinition Where DurableId = :userAppInfo.AppDefinitionId];
        
        if(!appDefinitionList.isEmpty()){
            for(AppDefinition APP_VAR : appDefinitionList){
                if(APP_VAR.Label.equals(Label.TS_ServiceConsoleAppName)){
                    isServiceConsole = true;
                    break;
                }
            }
        }

        //OVERRIDE VALUE - April 1, 2019 - Xen Reyes
        if(Boolean.valueOf(Label.TS_DoNotEnforceApplicationChecker)){
            isServiceConsole = true;
        }

        CustomLogging.pop();  
        return isServiceConsole;  
    }

    @AuraEnabled
    public static String getTimeSLAController(String country) {
        CustomLogging.push('getTimeSLAController', 'TS_RecordHeaderController');
        
        CountrySetting__c csRet = new CountrySetting__c();
        if(country != null && country != ''){
            Id recTypeBusinessHours = Schema.SObjectType.CountrySetting__c.getRecordTypeInfosByName().get('Country Default Business Hours').getRecordTypeId();
            CountrySetting__c[] csList = [SELECT Id, Business_Hours__r.MondayEndTime, Business_Hours__r.TuesdayEndTime, Business_Hours__r.WednesdayEndTime, Business_Hours__r.ThursdayEndTime, Business_Hours__r.FridayEndTime, Business_Hours__r.SaturdayEndTime, Business_Hours__r.SundayEndTime FROM CountrySetting__c WHERE Country__c =: country AND RecordTypeId =: recTypeBusinessHours AND Active__c = true];
            
            if(!csList.isEmpty()){
                csRet = csList[0];
            }
            
        }
        
        CustomLogging.pop();
        
        return JSON.serialize(csRet);
    }       
    
    @AuraEnabled
    public static Boolean isFeatureFlagEnabled(String apiName){
        CustomLogging.push('getTimeSLAController', 'TS_QualifyCaseModalController');
        Boolean returnFlag = false;
        try {
            if(apiName != null){
                TS_Feature_Flag__mdt featureFlag =  [SELECT Id, QualifiedApiName, Enable__c FROM TS_Feature_Flag__mdt WHERE QualifiedApiName =:apiName LIMIT 1];    
                system.debug('featureFlag');
                system.debug(featureFlag);
                if(featureFlag.Id != null){
                    returnFlag = featureFlag.Enable__c;
                }
            }
        }
        catch(Exception ex) {
            CustomLogging.debugException(ex);
            CustomLogging.pop();
            System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());
        }
        
        CustomLogging.pop();
        return returnFlag;
    }
}