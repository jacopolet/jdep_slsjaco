//-------------------------------------------------------------------------------------------//
// Author       :   Catherine Aragon - Accenture
// Created Date :   March 23, 2017
// Usage        :   Update Account Location Record which is related to an Account record
//-------------------------------------------------------------------------------------------//
public without sharing class AccountLocation{
    
    //Author: Catherine Aragon - Accenture
    //Usage: This method use to update the account location record which is related to an account record.
    @InvocableMethod
    public static void updateAccountLocation(List<Id> ListID){
        CustomLogging.push('updateAccountLocation', 'AccountLocation');
        try {
            List<Apttus_Config2__AccountLocation__c> updateAcctLoc = new List<Apttus_Config2__AccountLocation__c>();
            Set<Id> acctlocId = new Set<Id>();
            List<Account> acctList = new List<Account>();
            List<Apttus_Config2__AccountLocation__c> acctLocList = new List<Apttus_Config2__AccountLocation__c>();
            String userProfileId = UserInfo.getProfileId();
            Profile profileinfo;
            
            if (userProfileId <> null){
            	profileinfo = [Select Id, Name from Profile where ID = :userProfileId]; 
            }
            
            acctList = [Select Id, Name, SAP_Customer_ID__c, BillingStreet, BillingCity, BillingState, Main_House_Number__c, Main_State__c,
                        Main_Postal_Code__c, Main_City__c, Main_Country__c, Main_Street__c,
                        Main_Street_Only__c, BillingCountry, BillingPostalCode, Main_Country_ISO__c, Main_Address_Validation_Timestamp__c,
                        Main_Address_Validation_Pending__c, Main_Address_Validation_Code__c, Main_Address_Validation_Error__c, 
                        First_Account_Location_created__c, Sales_Organization__c, Language__c,  Mini_Company_Code__c,
                        Distribution_Channel__c, Division__c, Mini_Shipping_Conditions__c, Mini_Incoterms_Part_1__c, Transportation_zone__c,
                        Mini_Incoterms_Part_2__c, Mini_Delivery_Control__c, Mini_Max_part_deliveries__c, Archiving_Flag__c, Region__c,
                        Mini_Delivery_Priority__c, Account_Status__c, Duplicate_Validation__c, Duplicate_Reason__c, Delivery_Block_Reason__c,
                        House_Number_Supplement__c
                        FROM Account 
                        WHERE Id IN :ListID];
             
                                                
            acctLocList = [Select Apttus_Config2__AccountId__c, SAP_Customer_ID__c,  
                           Shipping_House_Number__c, Shipping_Street_Only__c, Shipping_Country_ISO__c,
                           //Shipping_Street__c, Shipping_City__c, Shipping_State__c, Shipping_PostalCode__c, Shipping_Country__c, 
                           Shipping_Address_Validation_Pending__c, Shipping_Address_Validation_Code__c, 
                           Shipping_Address_Validation_Error__c, Shipping_Address_Validation_Timestamp__c, Mini_Sales_Organization__c,
                           Mini_Language__c,  Mini_Company_Code__c, Mini_Distribution_Channel__c,
                           Mini_Division__c,    Mini_Shipping_Conditions__c, Mini_Incoterms_Part_1__c, Mini_Transportation_zone__c,
                           Mini_Incoterms_Part_2__c, Mini_Delivery_Control__c, Mini_Max_part_deliveries__c, Archiving_Flag__c, Copy_of_Parent_Account__c,
                           Apttus_Config2__Street__c, Apttus_Config2__City__c, Apttus_Config2__State__c, Apttus_Config2__PostalCode__c, Apttus_Config2__Country__c, Region__c,
                           Mini_Delivery_Priority__c, Account_Location_Status__c, Duplicate_Reason__c, Duplicate_Validation__c, Delivery_Block_Reason__c,
                           House_Number_Supplement__c
                           FROM Apttus_Config2__AccountLocation__c 
                           WHERE Apttus_Config2__AccountId__c IN :ListID];
                                                    
           if (!acctList.isEmpty()){
                for(Account acct: acctList){
                    if(!acctLocList.isEmpty()){
                        for (Apttus_Config2__AccountLocation__c acctLoc : acctLocList ){
                            if (acctLoc.Apttus_Config2__AccountId__c == acct.Id){
                                if (profileinfo.Name != 'JDE-Integration-Digital') {
                                    if (acctLoc.Copy_of_Parent_Account__c) {
                                        acctLoc.Apttus_Config2__Street__c = acct.Main_Street__c;
                                        acctLoc.Shipping_House_Number__c = acct.Main_House_Number__c;
                                        acctLoc.House_Number_Supplement__c = acct.House_Number_Supplement__c;
                                        acctLoc.Shipping_Street_Only__c = acct.Main_Street_Only__c;
                                        acctLoc.Apttus_Config2__City__c = acct.Main_City__c;
                                        acctLoc.Apttus_Config2__State__c = acct.Main_State__c;
                                        acctLoc.Apttus_Config2__PostalCode__c = acct.Main_Postal_Code__c;
                                        acctLoc.Apttus_Config2__Country__c = acct.Main_Country__c;
                                        acctLoc.Shipping_Country_ISO__c = acct.Main_Country_ISO__c;
                                        acctLoc.Shipping_Address_Validation_Timestamp__c = acct.Main_Address_Validation_Timestamp__c;
                                        acctLoc.Shipping_Address_Validation_Pending__c = acct.Main_Address_Validation_Pending__c;
                                        acctLoc.Shipping_Address_Validation_Code__c = acct.Main_Address_Validation_Code__c;
                                        acctLoc.Shipping_Address_Validation_Error__c = acct.Main_Address_Validation_Error__c;
                                        acctLoc.Mini_Sales_Organization__c = acct.Sales_Organization__c;
                                        acctLoc.Mini_Language__c = acct.Language__c;
                                        acctLoc.Mini_Transportation_zone__c = acct.Transportation_zone__c;
                                        acctLoc.Mini_Company_Code__c = acct.Mini_Company_Code__c;
                                        acctLoc.Mini_Distribution_Channel__c = acct.Distribution_Channel__c;
                                        acctLoc.Mini_Division__c = acct.Division__c;
                                        acctLoc.Mini_Delivery_Priority__c = acct.Mini_Delivery_Priority__c;
                                        acctLoc.Mini_Shipping_Conditions__c = acct.Mini_Shipping_Conditions__c;
                                        acctLoc.Mini_Incoterms_Part_1__c = acct.Mini_Incoterms_Part_1__c;
                                        acctLoc.Mini_Incoterms_Part_2__c = acct.Mini_Incoterms_Part_2__c;
                                        acctloc.Mini_Delivery_Control__c = acct.Mini_Delivery_Control__c;
                                        acctLoc.Mini_Max_part_deliveries__c = acct.Mini_Max_part_deliveries__c; 
                                        acctLoc.SAP_Customer_ID__c = acct.SAP_Customer_ID__c;
                                        acctLoc.Archiving_Flag__c = acct.Archiving_Flag__c;
                                        acctLoc.Region__c = acct.Region__c;
                                        acctLoc.Account_Location_Status__c = acct.Account_Status__c;
                                        acctLoc.Apttus_Config2__Street__c = acct.Main_Street__c;
                                        acctLoc.Duplicate_Reason__c = acct.Duplicate_Reason__c;
                                        acctLoc.Duplicate_Validation__c = acct.Duplicate_Validation__c;
                                        acctLoc.Delivery_Block_Reason__c = acct.Delivery_Block_Reason__c;
                                    } else if(!acctLoc.Copy_of_Parent_Account__c){
                                        acctLoc.Archiving_Flag__c = acct.Archiving_Flag__c;
                                    }
                                } else {
                                    acctLoc.Mini_Company_Code__c = acct.Mini_Company_Code__c;
                                    acctloc.Mini_Delivery_Control__c = acct.Mini_Delivery_Control__c;
                                    acctLoc.Mini_Delivery_Priority__c = acct.Mini_Delivery_Priority__c;
                                    acctLoc.Mini_Distribution_Channel__c = acct.Distribution_Channel__c;
                                    acctLoc.Mini_Division__c = acct.Division__c;
                                    acctLoc.Mini_Language__c = acct.Language__c;
                                    acctLoc.Mini_Max_part_deliveries__c = acct.Mini_Max_part_deliveries__c;
                                    acctLoc.Mini_Shipping_Conditions__c = acct.Mini_Shipping_Conditions__c;
                                    acctLoc.Mini_Transportation_zone__c = acct.Transportation_zone__c;
                                    acctLoc.Region__c = acct.Region__c;
                                    acctLoc.Account_Location_Status__c = acct.Account_Status__c;
                                    acctLoc.Duplicate_Reason__c = acct.Duplicate_Reason__c;
                                    acctLoc.Duplicate_Validation__c = acct.Duplicate_Validation__c;
                                    acctLoc.Delivery_Block_Reason__c = acct.Delivery_Block_Reason__c;
                                    acctLoc.SAP_Customer_ID__c = acct.SAP_Customer_ID__c;
                                }
                                if (!acctlocId.contains(acctLoc.Id)){
                                    updateAcctLoc.add(acctLoc);
                                    acctlocId.add(acctLoc.Id);
                                }
                            }
                            
                        }
                        
                    }
                }
                    
             }
            
            //updated by jed to remove DML from the loop
            if (!updateAcctLoc.isEmpty()){
            	update updateAcctLoc;
            }      
        } catch (Exception e) {
            CustomLogging.debugException(e);
            CustomLogging.pop();      
            System.debug(e.getMessage() + '\n' + e.getStackTraceString());
        }
    }
}