@isTest
private class SM_ActivateMastDataRequestApex_Test {

	private static testMethod void updateAccount() {
	    
	    //Create account record
	    Account acc = new Account();
        acc.Name = 'Test Account';
        acc.recordtypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get(SM_Constants.Customer).getRecordTypeId();
        acc.Main_Street_Only__c = 'Test Street';
        acc.Main_Postal_Code__c = null;
        acc.Industry_Code__c = null;
        acc.Phone = '+1234567890';
        acc.CurrencyIsoCode = 'EUR';
        acc.Language__c = 'SAP_EN';
        acc.Sales_Organization__c = 'SAP_0333';
        acc.Account_Type__c = 'Customer';
        acc.Segment__c = 'SAP_A';
        acc.of_Beds__c = 10;
        acc.of_drinks__c = 10;
        acc.of_Employees_FTE__c = 10;
        acc.Exclude_from_Territory_Assignment__c = false;
        acc.of_Seats__c = 10;
        acc.Account_Lifecycle__c = 'Active Customer';
        acc.SAP_PO_Updated__c = false;
        
        insert acc;
	   
        //Create new task with master data and account     
        Task taskRec = new Task();
        taskRec.Requested_Account_Name__c = 'Account Name';
        taskRec.Requested_Operation__c = 'Update Account';
        taskRec.Touchpoint_Type__c = 'ONLINE MASTER DATA CHANGE REQ';
        taskRec.WhatId = acc.Id;
        taskRec.Requested_Second_Name__c = 'Req Second Name';
        taskRec.Requested_Third_Name__c = 'Req Third Name';
        taskRec.Requested_Fourth_Name__c = 'Req Fourth Name';
        taskRec.Requested_AddressValidationTimestamp__c = date.today();
        taskRec.Requested_Main_Street_Only__c = 'Street Only';
        taskRec.Requested_Main_Street__c = 'Street';
        taskRec.Requested_Main_State__c = 'State';
        taskRec.Requested_Main_Postal_Code__c = 'PC 1234';
        taskRec.Requested_Main_Postal_Box_City__c = 'PB City';
        taskRec.Requested_Main_Postal_Box__c = 'PBox';
        taskRec.Requested_Main_House_Number_Supplement__c = '123';
        taskRec.Requested_Main_House_Number__c = '098';
        taskRec.Requested_Main_Country_ISO__c = 'ISO';
        taskRec.Requested_Main_Country__c = 'Country';
        taskRec.Requested_Main_City__c = 'City';
        taskRec.Requested_VAT_Number__c = 'ty67628';
        taskRec.Requested_Commercial_Register_Number__c = 'Com0909';
        taskRec.Description = 'Description';
        
        insert taskRec;
        
        Task taskRec1 = new Task();
        taskRec1.Requested_Account_Name__c = 'Null';
        taskRec1.Requested_Operation__c = 'Update Account';
        taskRec1.Touchpoint_Type__c = 'ONLINE MASTER DATA CHANGE REQ';
        taskRec1.WhatId = acc.Id;
        taskRec1.Requested_Second_Name__c = 'Null';
        taskRec1.Requested_Third_Name__c = 'Null';
        taskRec1.Requested_Fourth_Name__c = 'Null';
        taskRec1.Requested_AddressValidationTimestamp__c = date.today();
        taskRec1.Requested_Main_Street_Only__c = 'Null';
        taskRec1.Requested_Main_Street__c = 'Null';
        taskRec1.Requested_Main_State__c = 'Null';
        taskRec1.Requested_Main_Postal_Code__c = 'Null';
        taskRec1.Requested_Main_Postal_Box_City__c = 'Null';
        taskRec1.Requested_Main_Postal_Box__c = 'Null';
        taskRec1.Requested_Main_House_Number_Supplement__c = 'Null';
        taskRec1.Requested_Main_House_Number__c = 'Null';
        taskRec1.Requested_Main_Country_ISO__c = 'Null';
        taskRec1.Requested_Main_Country__c = 'Null';
        taskRec1.Requested_Main_City__c = 'Null';
        taskRec1.Requested_VAT_Number__c = 'Null';
        taskRec1.Requested_Commercial_Register_Number__c = 'Null';
        taskRec1.Description = 'Null';
        
        insert taskRec1;
        
        SM_ActivateMastDataRequestApex.returnResult(taskRec.Id);
        SM_ActivateMastDataRequestApex.returnResult(taskRec1.Id);
        
        Task taskData = [Select Id, Requested_Operation__c, Touchpoint_Type__c FROM Task WHERE Id = :taskRec.Id];

        //Assert the name field and saved expense
        System.assert(taskData.Requested_Operation__c == 'Update Account');
        System.assert(taskData.Touchpoint_Type__c == 'ONLINE MASTER DATA CHANGE REQ');
    }
    
    private static testMethod void createAccountLocation() {
	    
	    //Create account record
	    Account acc = new Account();
        acc.Name = 'Test Account';
        acc.recordtypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get(SM_Constants.Customer).getRecordTypeId();
        acc.Main_Street_Only__c = 'Test Street';
        acc.Main_Postal_Code__c = null;
        acc.Industry_Code__c = null;
        acc.Phone = '+1234567890';
        acc.CurrencyIsoCode = 'EUR';
        acc.Language__c = 'SAP_EN';
        acc.Sales_Organization__c = 'SAP_0333';
        acc.Account_Type__c = 'Customer';
        acc.Segment__c = 'SAP_A';
        acc.of_Beds__c = 10;
        acc.of_drinks__c = 10;
        acc.of_Employees_FTE__c = 10;
        acc.Exclude_from_Territory_Assignment__c = false;
        acc.of_Seats__c = 10;
        acc.Account_Lifecycle__c = 'Active Customer';
        acc.SAP_PO_Updated__c = false;
        
        insert acc;
	   
        //Create new task with master data and account     
        Task taskRec = new Task();
        taskRec.Requested_Account_Name__c = 'Account Name';
        taskRec.Requested_Operation__c = 'Create Account Location';
        taskRec.Touchpoint_Type__c = 'ONLINE MASTER DATA CHANGE REQ';
        taskRec.WhatId = acc.Id;
        taskRec.Requested_Second_Name__c = 'Req Second Name';
        taskRec.Requested_Third_Name__c = 'Req Third Name';
        taskRec.Requested_Fourth_Name__c = 'Req Fourth Name';
        taskRec.Requested_AddressValidationTimestamp__c = date.today();
        taskRec.Requested_Main_Street_Only__c = 'Street Only';
        taskRec.Requested_Main_Street__c = 'Street';
        taskRec.Requested_Main_State__c = 'State';
        taskRec.Requested_Main_Postal_Code__c = 'PC 1234';
        taskRec.Requested_Main_Postal_Box_City__c = 'PB City';
        taskRec.Requested_Main_Postal_Box__c = 'PBox';
        taskRec.Requested_Main_House_Number_Supplement__c = '123';
        taskRec.Requested_Main_House_Number__c = '098';
        taskRec.Requested_Main_Country_ISO__c = 'ISO';
        taskRec.Requested_Main_Country__c = 'Country';
        taskRec.Requested_Main_City__c = 'City';
        taskRec.Requested_VAT_Number__c = 'ty67628';
        taskRec.Requested_Commercial_Register_Number__c = 'Com0909';
        taskRec.Description = 'Description';
        taskRec.Requested_Account_Location_Name__c = 'Created AL';
        
        insert taskRec;
        
        Task taskRec1 = new Task();
        taskRec1.Requested_Account_Name__c = 'Null';
        taskRec1.Requested_Operation__c = 'Create Account Location';
        taskRec1.Touchpoint_Type__c = 'ONLINE MASTER DATA CHANGE REQ';
        taskRec1.WhatId = acc.Id;
        taskRec1.Requested_Second_Name__c = 'Null';
        taskRec1.Requested_Third_Name__c = 'Null';
        taskRec1.Requested_Fourth_Name__c = 'Null';
        taskRec1.Requested_AddressValidationTimestamp__c = date.today();
        taskRec1.Requested_Main_Street_Only__c = 'Null';
        taskRec1.Requested_Main_Street__c = 'Null';
        taskRec1.Requested_Main_State__c = 'Null';
        taskRec1.Requested_Main_Postal_Code__c = 'Null';
        taskRec1.Requested_Main_Postal_Box_City__c = 'Null';
        taskRec1.Requested_Main_Postal_Box__c = 'Null';
        taskRec1.Requested_Main_House_Number_Supplement__c = 'Null';
        taskRec1.Requested_Main_House_Number__c = 'Null';
        taskRec1.Requested_Main_Country_ISO__c = 'Null';
        taskRec1.Requested_Main_Country__c = 'Null';
        taskRec1.Requested_Main_City__c = 'Null';
        taskRec1.Requested_VAT_Number__c = 'Null';
        taskRec1.Requested_Commercial_Register_Number__c = 'Null';
        taskRec1.Description = 'Null';
        taskRec1.Requested_Account_Location_Name__c = 'Null';
        
        insert taskRec1;
        
        SM_ActivateMastDataRequestApex.returnResult(taskRec.Id);
        SM_ActivateMastDataRequestApex.returnResult(taskRec1.Id);
        
        Task taskData = [Select Id, Requested_Operation__c, Touchpoint_Type__c FROM Task WHERE Id = :taskRec.Id];

        //Assert the name field and saved expense
        System.assert(taskData.Requested_Operation__c == 'Create Account Location');
        System.assert(taskData.Touchpoint_Type__c == 'ONLINE MASTER DATA CHANGE REQ');
    }
    
    private static testMethod void updateAccountLocation() {
        
        //Create account record
	    Account acc = new Account();
        acc.Name = 'Test Account';
        acc.recordtypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get(SM_Constants.Customer).getRecordTypeId();
        acc.Main_Street_Only__c = 'Test Street';
        acc.Main_Postal_Code__c = null;
        acc.Industry_Code__c = null;
        acc.Phone = '+1234567890';
        acc.CurrencyIsoCode = 'EUR';
        acc.Language__c = 'SAP_EN';
        acc.Sales_Organization__c = 'SAP_0333';
        acc.Account_Type__c = 'Customer';
        acc.Segment__c = 'SAP_A';
        acc.of_Beds__c = 10;
        acc.of_drinks__c = 10;
        acc.of_Employees_FTE__c = 10;
        acc.Exclude_from_Territory_Assignment__c = false;
        acc.of_Seats__c = 10;
        acc.Account_Lifecycle__c = 'Active Customer';
        acc.SAP_PO_Updated__c = false;
        
        insert acc;
	    
	    //Create account location
	    Apttus_Config2__AccountLocation__c acctLoc = new Apttus_Config2__AccountLocation__c();
        acctLoc.Copy_of_Parent_Account__c = true;
        acctLoc.Apttus_Config2__AccountId__c = acc.Id;
        acctLoc.Name = 'SAMP';
        acctLoc.Mini_Language__c = 'SAP_FR';
        acctLoc.Pallet_type__c = 'SAP_007';
        acctLoc.Saturday_Afternoon_From_Receiving__c = '14:30';
        acctLoc.Saturday_Afternoon_To_Receiving__c = '15:00';
        acctLoc.Saturday_Morning_From_Receiving__c = '02:45';
        acctLoc.Saturday_Morning_To_Receiving__c = '02:15';
        acctLoc.Sunday_Afternoon_From_Receiving__c = '15:15';
        acctLoc.Sunday_Afternoon_To_Receiving__c = '15:30';
        acctLoc.Sunday_Morning_From_Receiving__c = '03:30';
        acctLoc.Sunday_Morning_To_Receiving__c = '   01:00';
        
        insert acctLoc;
	   
        //Create new task with master data and account     
        Task taskRec = new Task();
        taskRec.Requested_Account_Name__c = 'Account Name';
        taskRec.Requested_Operation__c = 'Update Account Location';
        taskRec.Touchpoint_Type__c = 'ONLINE MASTER DATA CHANGE REQ';
        taskRec.WhatId = acctLoc.Id;
        taskRec.Requested_Second_Name__c = 'Req Second Name';
        taskRec.Requested_Third_Name__c = 'Req Third Name';
        taskRec.Requested_Fourth_Name__c = 'Req Fourth Name';
        taskRec.Requested_AddressValidationTimestamp__c = date.today();
        taskRec.Requested_Main_Street_Only__c = 'Street Only';
        taskRec.Requested_Main_Street__c = 'Street';
        taskRec.Requested_Main_State__c = 'State';
        taskRec.Requested_Main_Postal_Code__c = 'PC 1234';
        taskRec.Requested_Main_Postal_Box_City__c = 'PB City';
        taskRec.Requested_Main_Postal_Box__c = 'PBox';
        taskRec.Requested_Main_House_Number_Supplement__c = '123';
        taskRec.Requested_Main_House_Number__c = '098';
        taskRec.Requested_Main_Country_ISO__c = 'ISO';
        taskRec.Requested_Main_Country__c = 'Country';
        taskRec.Requested_Main_City__c = 'City';
        taskRec.Requested_VAT_Number__c = 'ty67628';
        taskRec.Requested_Commercial_Register_Number__c = 'Com0909';
        taskRec.Description = 'Description';
        taskRec.Requested_Account_Location_Name__c = 'Update AL';
        
        insert taskRec;
        
        Task taskRec1 = new Task();
        taskRec1.Requested_Account_Name__c = 'Null';
        taskRec1.Requested_Operation__c = 'Update Account Location';
        taskRec1.Touchpoint_Type__c = 'ONLINE MASTER DATA CHANGE REQ';
        taskRec1.WhatId = acctLoc.Id;
        taskRec1.Requested_Second_Name__c = 'Null';
        taskRec1.Requested_Third_Name__c = 'Null';
        taskRec1.Requested_Fourth_Name__c = 'Null';
        taskRec1.Requested_AddressValidationTimestamp__c = date.today();
        taskRec1.Requested_Main_Street_Only__c = 'Null';
        taskRec1.Requested_Main_Street__c = 'Null';
        taskRec1.Requested_Main_State__c = 'Null';
        taskRec1.Requested_Main_Postal_Code__c = 'Null';
        taskRec1.Requested_Main_Postal_Box_City__c = 'Null';
        taskRec1.Requested_Main_Postal_Box__c = 'Null';
        taskRec1.Requested_Main_House_Number_Supplement__c = 'Null';
        taskRec1.Requested_Main_House_Number__c = 'Null';
        taskRec1.Requested_Main_Country_ISO__c = 'Null';
        taskRec1.Requested_Main_Country__c = 'Null';
        taskRec1.Requested_Main_City__c = 'Null';
        taskRec1.Requested_VAT_Number__c = 'Null';
        taskRec1.Requested_Commercial_Register_Number__c = 'Null';
        taskRec1.Description = 'Null';
        taskRec1.Requested_Account_Location_Name__c = 'Null';
        
        insert taskRec1;
        
        SM_ActivateMastDataRequestApex.returnResult(taskRec.Id);
        SM_ActivateMastDataRequestApex.returnResult(taskRec1.Id);
        
        Task taskData = [Select Id, Requested_Operation__c, Touchpoint_Type__c FROM Task WHERE Id = :taskRec.Id];

        //Assert the name field and saved expense
        System.assert(taskData.Requested_Operation__c == 'Update Account Location');
        System.assert(taskData.Touchpoint_Type__c == 'ONLINE MASTER DATA CHANGE REQ');
    }

}