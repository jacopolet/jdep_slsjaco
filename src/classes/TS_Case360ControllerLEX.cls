/*
* @author        Xen Reyes
* @date          9.01.2017          
* @description   Controller class for Case 360 Lightning Component
* @revision(s)
*/
public with sharing class TS_Case360ControllerLEX {

    public static Boolean hasException = false;
    public class TS_Case360ControllerLEXException extends Exception {  }

    @AuraEnabled
    public static List<PhysicalAsset__c> getOptions (String physicalAssetId){
        
        List<PhysicalAsset__c> options = new List<PhysicalAsset__c>();
        Id optionId = Schema.SObjectType.PhysicalAsset__c.getRecordTypeInfosByName().get('Option').getRecordTypeId();

        if(physicalAssetId != null) {

            try{
                options = [SELECT Id, Name, AssetStatus__c, ProductDescription__c FROM PhysicalAsset__c WHERE RecordTypeId =:optionId AND ParentPhysicalAsset__c =:physicalAssetId];

                //Exception for test class purposes
                if (Test.isRunningTest() && hasException) {
                    throw new TS_Case360ControllerLEXException('Force to throw an exception');
                }

            } catch(Exception ex){
                System.debug(ex);
                CustomLogging.debugException(ex);
                CustomLogging.pop();
            }
        }
        
        return options;
    
    }

    @AuraEnabled
    public static Case getDetails (String caseId){
        
        Case cs = new Case();

        if(caseId != null) {

            try{
                List<Case> csList = [SELECT Id, 
                            Type,
                            SubType__c,
                            AccountId,
                            Account.Name,
                            Account.Parent.Name,
                            Account.Ultimate_Parent_Account__c,
                            Account.Account_Lifecycle__c,
                            Account.Key_Account__c,
                            Account.Account_Type__c,
                            Account.Account_Status__c,
                            Account.OwnerId,
                            Account.Owner.Name,
                            Account.DMU__c,
                            Account.Phone,
                            toLabel(Account.Segment__c),
                            Account.Territory__r.Name,
                            Account.Customer_Relations_1__c,
                            Account.Customer_Relations_1__r.Name,
                            Account.Account_Value_Estimation__c,
                            Account.Account_Annual_Value__c,
                            Account.Delivery_Block_Reason__c,
                            Account.Account_Block__c,
                            Account.Main_Street_Only__c,
                            Account.Main_City__c,
                            Account.Main_Postal_Code__c,
                            Account.Main_House_Number__c,
                            Account.Last_Case_Date__c,
                            Account.Last_Invoice_Date__c,
                            Account.Last_Order_Date__c,
                            Account.Active_Machine__c,
                            Account.Active_Contract__c,
                            AccountLocation__c,
                            AccountLocation__r.Apttus_Config2__AccountId__r.Name,
                            AccountLocation__r.Name,
                            AccountLocation__r.Shipping_Street_Only__c,
                            AccountLocation__r.Shipping_House_Number__c,
                            AccountLocation__r.Apttus_Config2__PostalCode__c,
                            AccountLocation__r.Apttus_Config2__City__c,
                            AccountLocation__r.Apttus_Config2__State__c,
                            AccountLocation__r.Apttus_Config2__Country__c,
                            AccountLocation__r.Account_Location_Status__c,
                            AccountLocation__r.Delivery_Block_Reason__c,
                            AccountLocation__r.Special_Access_Protocols__c,
                            AccountLocation__r.PreferredEngineer__c,
                            AccountLocation__r.PreferredEngineer__r.Name,
                            AccountLocation__r.ExcludedEngineer__c,
                            AccountLocation__r.ExcludedEngineer__r.Name,
                            AccountLocation__r.ApprovalPreventiveMaintenanceWTS__c,
                            AccountLocation__r.StakeholderNotification__c,
                            AccountLocation__r.Screening_Required__c,
                            AccountLocation__r.Upfront_Call_Needed__c,
                            AccountLocation__r.Start_of_Business_Day__c,
                            AccountLocation__r.End_of_Business_Day__c,
                            AccountLocation__r.Monday_Exception__c,
                            AccountLocation__r.Custom_Service_Hours__c,
                            AccountLocation__r.Custom_Service_Hours_Description__c,
                            ContactId,
                            Contact.Name,
                            Contact.Account.Name,
                            Contact.Title,
                            Contact.Function__c,
                            toLabel(Contact.Preferred_Language__c),
                            Contact.Communication_Preference__c,
                            Contact.Phone,
                            Contact.MobilePhone,
                            Contact.Email,
                            Contact.CaseCreationNotification__c,
                            Contact.CaseDelayNotification__c,
                            Contact.CaseClosureNotification__c,
                            Contact.ETANotification__c,
                            Contact.ATANotification__c,
                            PhysicalAsset__c,
                            Fault_Configuration__c,
                            ApptusOrder__c,
                            ChildOrder__c FROM Case WHERE Id =: caseId LIMIT 1];

                if(!csList.isEmpty()){
                    cs = csList[0];
                }

                //Exception for test class purposes
                if (Test.isRunningTest() && hasException) {
                    throw new TS_Case360ControllerLEXException('Force to throw an exception');
                }

            } catch(Exception ex){
                System.debug(ex);
                CustomLogging.debugException(ex);
                CustomLogging.pop();
            }
        }
        
        return cs;
    
    }

    @AuraEnabled
    public static WorkOrder getWODetails (String woId){
        
        WorkOrder wo = new WorkOrder();

        if(woId != null) {

            try{
                List<WorkOrder> woList = [SELECT Id, OP_Physical_Asset__c, Account_Location__c FROM WorkOrder WHERE Id =: woId];

                if(!woList.isEmpty()){
                    wo = woList[0];
                }

                //Exception for test class purposes
                if (Test.isRunningTest() && hasException) {
                    throw new TS_Case360ControllerLEXException('Force to throw an exception');
                }

            } catch(Exception ex){
                System.debug(ex);
                CustomLogging.debugException(ex);
                CustomLogging.pop();
            }
        }
        
        return wo;

    }

    //DOO-4653 Francis Allen Alindogan 06.20.2020
    @AuraEnabled
    public static List<OperatingHourAssociation__c> getOHAList (String accLocId){
        List<OperatingHourAssociation__c> OHAList = new List<OperatingHourAssociation__c>();
        if(accLocId!= null){
            try {  
                OHAList = [SELECT Id, BusinessUnit__c, CustomServiceHours__c, Open__c, Close__c, CustomServiceHoursDescription__c, Name FROM OperatingHourAssociation__c WHERE Account_Location__c =: accLocId and Active__c = true ORDER BY BusinessUnit__c ASC];            
            } 
            catch(Exception ex){
                System.debug(ex);
                CustomLogging.debugException(ex);
                CustomLogging.pop();
            }
        }
        return OHAList;        
    }
}