public with sharing class SM_ActivateMastDataRequestApex {
	@AuraEnabled
    public static String returnResult(String recID){
        CustomLogging.push('returnResult', 'SM_ActivateMastDataRequestApex');
        try {
            String finalresult;
            Task gettask = new Task();
           	gettask = [Select Id, Requested_Operation__c, Touchpoint_Type__c, Requested_Account_Location_Name__c, Description,
                           Requested_Account_Name__c, Requested_AddressValidationTimestamp__c, Requested_Commercial_Register_Number__c,
                           Requested_CountryISO__c, Requested_Fourth_Name__c, Requested_Main_City__c, Requested_Main_Country__c, 
                           Requested_Main_Country_ISO__c, Requested_Main_House_Number__c, Requested_Main_House_Number_Supplement__c, 
                           Requested_Main_Postal_Box__c, Requested_Main_Postal_Box_City__c, WhatID,
                           Requested_Main_Postal_Code__c, Requested_Main_State__c,  Requested_Main_Street__c, Requested_Main_Street_Only__c, Requested_Second_Name__c,
                           Requested_Shipping_City__c,Requested_Shipping_Country__c, Requested_Shipping_House_No_Supplement__c, Requested_Shipping_House_number__c,
                           Requested_Shipping_Postal_Code__c, Requested_Shipping_Street__c, Requested_State__c, Requested_Street__c, Requested_Third_Name__c,
                           Requested_VAT_Number__c 
                       FROM Task 
                       WHERE ID = :recID];
                       
            if (getTask.Requested_Operation__c == 'Update Account' && getTask.Touchpoint_Type__c == 'ONLINE MASTER DATA CHANGE REQ' && String.valueOf(getTask.WhatId).left(3)  == SM_Constants.accountPrefix){
                List<Account> acclist = new List<Account>();
                List<Account> acclistupdate = new List<Account>();
                acclist = [Select Id, Main_Address_Validation_Timestamp__c, Main_Street_Only__c, Main_Street__c, Main_State__c, Main_Postal_Code__c,
                                   Main_Postal_Box_City__c, Main_Postal_Box__c, House_Number_Supplement__c, Main_House_Number__c, Main_Country_ISO__c, 
                                   Main_Country__c, Main_City__c, VAT_Registration_Number__c, Commercial_Register_Number__c, Billing_Header_Text__c, 
                               Name, Second_Account_Name__c, Third_Account_Name__c, Fourth_Account_Name__c 
                               FROM Account 
                               WHERE ID = :getTask.WhatId];
                
                     for ( Account acc : acclist ){
                         acc.Id = getTask.WhatId;
                         if (getTask.Requested_Account_Name__c == 'Null' || getTask.Requested_Account_Name__c == 'null') {
                     	    acc.Name = null;
                         }
                         else if (getTask.Requested_Account_Name__c != null){
                             acc.Name = getTask.Requested_Account_Name__c;
                         }
                     	 if (getTask.Requested_Second_Name__c == 'Null' || getTask.Requested_Second_Name__c == 'null') {
                     	    acc.Second_Account_Name__c = null;
                     	 }
                     	 else if (getTask.Requested_Second_Name__c != null){
                             acc.Second_Account_Name__c = getTask.Requested_Second_Name__c;
                         }
                         if (getTask.Requested_Third_Name__c == 'Null' || getTask.Requested_Third_Name__c  == 'null') {
                            acc.Third_Account_Name__c = null;
                         }
                         else if (getTask.Requested_Third_Name__c != null){
                             acc.Third_Account_Name__c = getTask.Requested_Third_Name__c;
                         }
                         if (getTask.Requested_Fourth_Name__c == 'Null' || getTask.Requested_Fourth_Name__c  == 'null') {
                            acc.Fourth_Account_Name__c = null;
                         }
                         else if (getTask.Requested_Fourth_Name__c != null){
                             acc.Fourth_Account_Name__c = getTask.Requested_Fourth_Name__c;
                         }
                         if (getTask.Requested_AddressValidationTimestamp__c != null) {
                            acc.Main_Address_Validation_Timestamp__c = getTask.Requested_AddressValidationTimestamp__c;
                         }
                         if (getTask.Requested_Main_Street_Only__c == 'Null' || getTask.Requested_Main_Street_Only__c  == 'null') {
                            acc.Main_Street_Only__c = null;
                         }
                         else if (getTask.Requested_Main_Street_Only__c != null){
                             acc.Main_Street_Only__c = getTask.Requested_Main_Street_Only__c;
                         }
                         if (getTask.Requested_Main_Street__c == 'Null' || getTask.Requested_Main_Street__c  == 'null') {
                            acc.Main_Street__c = null;
                         }
                         else if (getTask.Requested_Main_Street__c != null){
                             acc.Main_Street__c = getTask.Requested_Main_Street__c;
                         }
                         if (getTask.Requested_Main_State__c == 'Null' || getTask.Requested_Main_State__c  == 'null') {
                            acc.Main_State__c = null;
                         }
                         else if (getTask.Requested_Main_State__c != null){
                             acc.Main_State__c = getTask.Requested_Main_State__c;
                         }
                         if (getTask.Requested_Main_Postal_Code__c == 'Null' || getTask.Requested_Main_Postal_Code__c  == 'null') {
                            acc.Main_Postal_Code__c = null;
                         }
                         else if (getTask.Requested_Main_Postal_Code__c != null){
                             acc.Main_Postal_Code__c = getTask.Requested_Main_Postal_Code__c;
                         }
                         if (getTask.Requested_Main_Postal_Box_City__c == 'Null' || getTask.Requested_Main_Postal_Box_City__c  == 'null') {
                            acc.Main_Postal_Box_City__c = null;
                         }
                         else if (getTask.Requested_Main_Postal_Box_City__c != null){
                             acc.Main_Postal_Box_City__c = getTask.Requested_Main_Postal_Box_City__c;
                         }
                         if (getTask.Requested_Main_Postal_Box__c == 'Null' || getTask.Requested_Main_Postal_Box__c  == 'null') {
                            acc.Main_Postal_Box__c = null;
                         }
                         else if (getTask.Requested_Main_Postal_Box__c != null){
                             acc.Main_Postal_Box__c = getTask.Requested_Main_Postal_Box__c;
                         }
                         if (getTask.Requested_Main_House_Number_Supplement__c == 'Null' || getTask.Requested_Main_House_Number_Supplement__c  == 'null') {
                            acc.House_Number_Supplement__c = null;
                         }
                         else if (getTask.Requested_Main_House_Number_Supplement__c != null){
                             acc.House_Number_Supplement__c = getTask.Requested_Main_House_Number_Supplement__c;
                         }
                         if (getTask.Requested_Main_House_Number__c == 'Null' || getTask.Requested_Main_House_Number__c  == 'null') {
                            acc.Main_House_Number__c = null;
                         }
                         else if (getTask.Requested_Main_House_Number__c != null){
                             acc.Main_House_Number__c = getTask.Requested_Main_House_Number__c;
                         }
                         if (getTask.Requested_Main_Country_ISO__c == 'Null' || getTask.Requested_Main_Country_ISO__c  == 'null') {
                            acc.Main_Country_ISO__c = null;
                         }
                         else if (getTask.Requested_Main_Country_ISO__c != null){
                             acc.Main_Country_ISO__c = getTask.Requested_Main_Country_ISO__c;
                         }
                         if (getTask.Requested_Main_Country__c == 'Null' || getTask.Requested_Main_Country__c  == 'null') {
                            acc.Main_Country__c = null;
                         }
                         else if (getTask.Requested_Main_Country__c != null){
                             acc.Main_Country__c = getTask.Requested_Main_Country__c;
                         }
                         if (getTask.Requested_Main_City__c == 'Null' || getTask.Requested_Main_City__c  == 'null') {
                            acc.Main_City__c = null;
                         }
                         else if (getTask.Requested_Main_City__c != null){
                             acc.Main_City__c = getTask.Requested_Main_City__c;
                         }
                         if (getTask.Requested_VAT_Number__c == 'Null' || getTask.Requested_VAT_Number__c  == 'null') {
                            acc.VAT_Registration_Number__c = null;
                         }
                         else if (getTask.Requested_VAT_Number__c != null){
                             acc.VAT_Registration_Number__c = getTask.Requested_VAT_Number__c;
                         }
                         if (getTask.Requested_Commercial_Register_Number__c == 'Null' || getTask.Requested_Commercial_Register_Number__c  == 'null') {
                            acc.Commercial_Register_Number__c = null;
                         }
                         else if (getTask.Requested_Commercial_Register_Number__c != null){
                             acc.Commercial_Register_Number__c = getTask.Requested_Commercial_Register_Number__c;
                         }
                         if (getTask.Description == 'Null' || getTask.Description  == 'null') {
                            acc.Billing_Header_Text__c = getTask.Description;
                         }
                         else if (getTask.Description != null){
                             acc.Billing_Header_Text__c = getTask.Description;
                         }
                         acclistupdate.add(acc);
                	 }
                if (acclistupdate.size() > 0){
                    update acclistupdate;
                    finalresult = getTask.WhatId;
                }
                
            } else if(getTask.Requested_Operation__c == 'Create Account Location' && getTask.Touchpoint_Type__c == 'ONLINE MASTER DATA CHANGE REQ' && String.valueOf(getTask.WhatId).left(3)  == SM_Constants.accountPrefix){
                List<Account> acclist = new List<Account>();
                acclist = [Select Id, Language__c 
                            FROM Account 
                            WHERE ID = :getTask.WhatId];
                Apttus_Config2__AccountLocation__c acclocate = new Apttus_Config2__AccountLocation__c();
                Id recTypeIdAccountLocationValid = Schema.SObjectType.Apttus_Config2__AccountLocation__c.getRecordTypeInfosByName().get('Account Location Valid').getRecordTypeId();
                for (Account acc : acclist) {
                    if (getTask.Requested_Account_Location_Name__c == 'Null' || getTask.Requested_Account_Location_Name__c  == 'null') {
                        acclocate.Name = null;
                    }
                    else if (getTask.Requested_Account_Location_Name__c != null){
                        acclocate.Name = getTask.Requested_Account_Location_Name__c;
                    }
                    if (getTask.Requested_Second_Name__c == 'Null' || getTask.Requested_Second_Name__c == 'null') {
                        acclocate.Second_Account_Name__c = null;
                    }
                    else if (getTask.Requested_Second_Name__c != null){
                        acclocate.Second_Account_Name__c = getTask.Requested_Second_Name__c;
                    }
                    if (getTask.Requested_Third_Name__c == 'Null' || getTask.Requested_Third_Name__c  == 'null') {
                        acclocate.Third_Account_Name__c = null;
                    }
                    else if (getTask.Requested_Third_Name__c != null){
                        acclocate.Third_Account_Name__c = getTask.Requested_Third_Name__c;
                    }
                    if (getTask.Requested_Fourth_Name__c == 'Null' || getTask.Requested_Fourth_Name__c  == 'null') {
                        acclocate.Fourth_Account_Name__c = null;
                    }
                    else if (getTask.Requested_Fourth_Name__c != null){
                        acclocate.Fourth_Account_Name__c = getTask.Requested_Fourth_Name__c;
                    }
                    if (getTask.Requested_Street__c == 'Null' || getTask.Requested_Street__c  == 'null') {
                        acclocate.Apttus_Config2__Street__c = null;
                    }
                    else if (getTask.Requested_Street__c != null){
                        acclocate.Apttus_Config2__Street__c = getTask.Requested_Street__c;
                    }
                    if (getTask.Requested_Shipping_House_number__c == 'Null' || getTask.Requested_Shipping_House_number__c  == 'null') {
        			    acclocate.Shipping_House_Number__c = null;
                    }
                    else if (getTask.Requested_Shipping_House_number__c != null){
                        acclocate.Shipping_House_Number__c = getTask.Requested_Shipping_House_number__c;
                    }
                    if (getTask.Requested_Shipping_House_No_Supplement__c == 'Null' || getTask.Requested_Shipping_House_No_Supplement__c  == 'null') {
                        acclocate.House_Number_Supplement__c = null;
                    }
                    else if (getTask.Requested_Shipping_House_No_Supplement__c != null){
                        acclocate.House_Number_Supplement__c = getTask.Requested_Shipping_House_No_Supplement__c;
                    }
                    if (getTask.Requested_Shipping_Street__c == 'Null' || getTask.Requested_Shipping_Street__c  == 'null') {
                        acclocate.Shipping_Street_Only__c = null;
                    }
                    else if (getTask.Requested_Shipping_Street__c != null){
                        acclocate.Shipping_Street_Only__c = getTask.Requested_Shipping_Street__c;
                    }
                    if (getTask.Requested_Shipping_City__c == 'Null' || getTask.Requested_Shipping_City__c  == 'null') {
                        acclocate.Apttus_Config2__City__c = null;
                    }
                    else if (getTask.Requested_Shipping_City__c != null){
                        acclocate.Apttus_Config2__City__c = getTask.Requested_Shipping_City__c;
                    }
                    if (getTask.Requested_State__c == 'Null' || getTask.Requested_State__c  == 'null') {
                        acclocate.Apttus_Config2__State__c = null;
                    }
                    else if (getTask.Requested_State__c != null){
                        acclocate.Apttus_Config2__State__c = getTask.Requested_State__c;
                    }
                    if (getTask.Requested_Shipping_Postal_Code__c == 'Null' || getTask.Requested_Shipping_Postal_Code__c  == 'null') {
                        acclocate.Apttus_Config2__PostalCode__c = null;
                    }
                    else if (getTask.Requested_Shipping_Postal_Code__c != null){
                        acclocate.Apttus_Config2__PostalCode__c = getTask.Requested_Shipping_Postal_Code__c;
                    }
                    if (getTask.Requested_Shipping_Country__c == 'Null' || getTask.Requested_Shipping_Country__c  == 'null') {
                        acclocate.Apttus_Config2__Country__c = null;
                    }
                    else if (getTask.Requested_Shipping_Country__c != null){
                        acclocate.Apttus_Config2__Country__c = getTask.Requested_Shipping_Country__c;
                    }
                    if (getTask.Requested_CountryISO__c == 'Null' || getTask.Requested_CountryISO__c  == 'null') {
                        acclocate.Shipping_Country_ISO__c = null;
                    }
                    else if (getTask.Requested_CountryISO__c != null){
                        acclocate.Shipping_Country_ISO__c = getTask.Requested_CountryISO__c;
                    }
                    if (getTask.Requested_AddressValidationTimestamp__c != Null) {
                        acclocate.Shipping_Address_Validation_Timestamp__c = getTask.Requested_AddressValidationTimestamp__c;
                    }
                    if (getTask.Description == 'Null' || getTask.Description  == 'null') {
                        acclocate.Billing_header_text__c = null;
                    }
                    else if (getTask.Description != null){
                        acclocate.Billing_header_text__c = getTask.Description;
                    }
                    if (acc.Language__c != 'null' || acc.Language__c  == '') {
                        acclocate.Mini_Language__c = acc.Language__c;
                    }
                    if (getTask.WhatId != Null) {
                        acclocate.Apttus_Config2__AccountId__c = getTask.WhatId;
                    }
                    acclocate.RecordTypeId = recTypeIdAccountLocationValid;
                    acclocate.Shipping_Address_Validation_Timestamp__c = DateTime.now();
                    acclocate.Shipping_Address_Validation_Code__c = String.valueOfGmt(DateTime.now());
                    acclocate.Address_Validation__c = 'Valid';
                    acclocate.Account_Location_Status__c = 'Valid';
                }
                
                insert acclocate;
                getTask.WhatId = acclocate.Id;
                update getTask;
                finalresult = getTask.WhatId;
                
            } else if(getTask.Requested_Operation__c == 'Update Account Location' && getTask.Touchpoint_Type__c == 'ONLINE MASTER DATA CHANGE REQ' && String.valueOf(getTask.WhatId).left(3)  == System.Label.Account_Location_Prefix){
                List<Apttus_Config2__AccountLocation__c> acclocatelist = new List<Apttus_Config2__AccountLocation__c>();
                List<Apttus_Config2__AccountLocation__c> acclocateupdate = new List<Apttus_Config2__AccountLocation__c>();
                acclocatelist = [Select Id, Name, Second_Account_Name__c, Third_Account_Name__c, Fourth_Account_Name__c, Apttus_Config2__Street__c, 
                                     Shipping_House_Number__c, House_Number_Supplement__c, Shipping_Street_Only__c, Apttus_Config2__City__c,
                                     Apttus_Config2__State__c, Apttus_Config2__PostalCode__c, Apttus_Config2__Country__c, Shipping_Country_ISO__c,
                                     Shipping_Address_Validation_Timestamp__c, Billing_header_text__c, Mini_Language__c, Apttus_Config2__AccountId__r.Language__c
                                 FROM Apttus_Config2__AccountLocation__c
                                 WHERE ID = :getTask.WhatId];
                
                for ( Apttus_Config2__AccountLocation__c accloc : acclocatelist ){
                    if (getTask.WhatId != Null) {
                        accloc.Id = getTask.WhatId;
                    }
                    if (getTask.Requested_Account_Location_Name__c == 'Null' || getTask.Requested_Account_Location_Name__c  == 'null') {
                        accloc.Name = null;
                    }
                    else if (getTask.Requested_Account_Location_Name__c != null){
                        accloc.Name = getTask.Requested_Account_Location_Name__c;
                    }
                    if (getTask.Requested_Second_Name__c == 'Null' || getTask.Requested_Second_Name__c == 'null') {
                        accloc.Second_Account_Name__c = null;
                    }
                    else if (getTask.Requested_Second_Name__c != null){
                        accloc.Second_Account_Name__c = getTask.Requested_Second_Name__c;
                    }
                    if (getTask.Requested_Third_Name__c == 'Null' || getTask.Requested_Third_Name__c  == 'null') {
                        accloc.Third_Account_Name__c = null;
                    }
                    else if (getTask.Requested_Third_Name__c != null){
                        accloc.Third_Account_Name__c = getTask.Requested_Third_Name__c;
                    }
                    if (getTask.Requested_Fourth_Name__c == 'Null' || getTask.Requested_Fourth_Name__c  == 'null') {
                        accloc.Fourth_Account_Name__c = null;
                    }
                    else if (getTask.Requested_Fourth_Name__c != null){
                        accloc.Fourth_Account_Name__c = getTask.Requested_Fourth_Name__c;
                    }
                    if (getTask.Requested_Street__c == 'Null' || getTask.Requested_Street__c  == 'null') {
                        accloc.Apttus_Config2__Street__c = null;
                    }
                    else if (getTask.Requested_Street__c != null){
                        accloc.Apttus_Config2__Street__c = getTask.Requested_Street__c;
                    }
                    if (getTask.Requested_Shipping_House_number__c == 'Null' || getTask.Requested_Shipping_House_number__c  == 'null') {
        			    accloc.Shipping_House_Number__c = null;
                    }
                    else if (getTask.Requested_Shipping_House_number__c != null){
                        accloc.Shipping_House_Number__c = getTask.Requested_Shipping_House_number__c;
                    }
                    if (getTask.Requested_Shipping_House_No_Supplement__c == 'Null' || getTask.Requested_Shipping_House_No_Supplement__c  == 'null') {
                        accloc.House_Number_Supplement__c = null;
                    }
                    else if (getTask.Requested_Shipping_House_No_Supplement__c != null){
                        accloc.House_Number_Supplement__c = getTask.Requested_Shipping_House_No_Supplement__c;
                    }
                    if (getTask.Requested_Shipping_Street__c == 'Null' || getTask.Requested_Shipping_Street__c  == 'null') {
                        accloc.Shipping_Street_Only__c = null;
                    }
                    else if (getTask.Requested_Shipping_Street__c != null){
                        accloc.Shipping_Street_Only__c = getTask.Requested_Shipping_Street__c;
                    }
                    if (getTask.Requested_Shipping_City__c == 'Null' || getTask.Requested_Shipping_City__c  == 'null') {
                        accloc.Apttus_Config2__City__c = null;
                    }
                    else if (getTask.Requested_Shipping_City__c != null){
                        accloc.Apttus_Config2__City__c = getTask.Requested_Shipping_City__c;
                    }
                    if (getTask.Requested_State__c == 'Null' || getTask.Requested_State__c  == 'null') {
                        accloc.Apttus_Config2__State__c = null;
                    }
                    else if (getTask.Requested_State__c != null){
                        accloc.Apttus_Config2__State__c = getTask.Requested_State__c;
                    }
                    if (getTask.Requested_Shipping_Postal_Code__c == 'Null' || getTask.Requested_Shipping_Postal_Code__c  == 'null') {
                        accloc.Apttus_Config2__PostalCode__c = null;
                    }
                    else if (getTask.Requested_Shipping_Postal_Code__c != null){
                        accloc.Apttus_Config2__PostalCode__c = getTask.Requested_Shipping_Postal_Code__c;
                    }
                    if (getTask.Requested_Shipping_Country__c == 'Null' || getTask.Requested_Shipping_Country__c  == 'null') {
                        accloc.Apttus_Config2__Country__c = null;
                    }
                    else if (getTask.Requested_Shipping_Country__c != null){
                        accloc.Apttus_Config2__Country__c = getTask.Requested_Shipping_Country__c;
                    }
                    if (getTask.Requested_CountryISO__c == 'Null' || getTask.Requested_CountryISO__c  == 'null') {
                        accloc.Shipping_Country_ISO__c = null;
                    }
                    else if (getTask.Requested_CountryISO__c != null){
                        accloc.Shipping_Country_ISO__c = getTask.Requested_CountryISO__c;
                    }
                    if (getTask.Requested_AddressValidationTimestamp__c != Null) {
                        accloc.Shipping_Address_Validation_Timestamp__c = getTask.Requested_AddressValidationTimestamp__c;
                    }
                    if (getTask.Description == 'Null' || getTask.Description  == 'null') {
                        accloc.Billing_header_text__c = null;
                    }
                    else if (getTask.Description != null){
                        accloc.Billing_header_text__c = getTask.Description;
                    }
                    if (accloc.Apttus_Config2__AccountId__r.Language__c != Null || accloc.Apttus_Config2__AccountId__r.Language__c != '') {
                        accloc.Mini_Language__c = accloc.Apttus_Config2__AccountId__r.Language__c;
                    }
                    acclocateupdate.add(accloc);
                }
                if (acclocateupdate.size() > 0){
                    update acclocateupdate;
                    finalresult = getTask.WhatId;
                }
            }
    		return finalresult;
        } catch (Exception e) {
            CustomLogging.debugException(e);
            CustomLogging.pop();      
            System.debug(e.getMessage() + '\n' + e.getStackTraceString());
            return e.getMessage() + '\n' + e.getStackTraceString();
        }
    }
}