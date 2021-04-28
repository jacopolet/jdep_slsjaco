@isTest
public class ContentDocumentLinkTriggerHandler_Test {
    private static testMethod void taskwithaccount(){
        //insert custom settings
        TriggerSettings__c ts = new TriggerSettings__c();
        ts.ContentDocumentLinkTrigger__c = true;
        insert ts;
        
        Account acc = new Account();
        acc.Name = 'accName';
        acc.Second_Account_Name__c = 'sAccName';
        acc.Sales_Organization__c = 'SAP_0333';
        //acc.Sales_Office__c = 'SAP_F020';
        acc.Phone = '+31302979111';
        acc.Account_Tier__c = 'Platinum';
        insert acc;
        
        Id serviceRecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Inbound').getRecordTypeId();
        
        Task taskRec = new Task();
        taskRec.WhatId = acc.Id;
        taskRec.RecordTypeId = serviceRecordTypeId;
        taskRec.Touchpoint_Type__c = 'Inbound Call';
            
        insert taskRec;
        
        Blob beforeblob=Blob.valueOf('Unit Test Attachment Body');

        ContentVersion cv = new ContentVersion();
        cv.title = 'test content trigger';      
        cv.PathOnClient ='test';           
        cv.VersionData =beforeblob;          
        insert cv;         
        
        ContentVersion testContent = [SELECT id, ContentDocumentId FROM ContentVersion where Id = :cv.Id];
        
        ContentDocumentLink notes = new ContentDocumentLink();
        notes.ShareType = 'V';
        notes.Visibility = 'InternalUsers';
        notes.ContentDocumentId = testcontent.ContentDocumentId;
        notes.LinkedEntityId = taskRec.Id;
        insert notes;
        
        ContentDocumentLink newnote = [Select Id, LinkedEntityId from ContentDocumentLink where LinkedEntityId =: acc.Id];
        System.assertEquals(newnote.LinkedEntityId, acc.Id);
    }
    
    private static testMethod void contactwithaccount(){
        //insert custom settings
        TriggerSettings__c ts = new TriggerSettings__c();
        ts.ContentDocumentLinkTrigger__c = true;
        insert ts;
        
        Account acc = new Account();
        acc.Name = 'accName';
        acc.Second_Account_Name__c = 'sAccName';
        acc.Sales_Organization__c = 'SAP_0333';
        //acc.Sales_Office__c = 'SAP_F020';
        acc.Phone = '+31302979111';
        acc.Account_Tier__c = 'Platinum';
        insert acc;
        
        
        Contact conRec = new Contact();
        conRec.FirstName = 'Test';
        conRec.LastName = 'Test';
        conRec.AccountId = acc.id;
        conRec.Phone = '+31302979111';
        conRec.Main_Commercial_Person__c = True;
        conRec.MobilePhone = '+31302979122';
            
        insert conRec;
        
        Blob beforeblob=Blob.valueOf('Unit Test Attachment Body');

        ContentVersion cv = new ContentVersion();
        cv.title = 'test content trigger';      
        cv.PathOnClient ='test';           
        cv.VersionData =beforeblob;          
        insert cv;         
        
        ContentVersion testContent = [SELECT id, ContentDocumentId FROM ContentVersion where Id = :cv.Id];
        
        ContentDocumentLink notes = new ContentDocumentLink();
        notes.ShareType = 'V';
        notes.Visibility = 'InternalUsers';
        notes.ContentDocumentId = testcontent.ContentDocumentId;
        notes.LinkedEntityId = conRec.Id;
        insert notes;
        
        ContentDocumentLink newnote = [Select Id, LinkedEntityId from ContentDocumentLink where LinkedEntityId =: acc.Id];
        System.assertEquals(newnote.LinkedEntityId, acc.Id);
    }
    
    private static testMethod void opportunitywithaccount(){
        //insert custom settings
        TriggerSettings__c ts = new TriggerSettings__c();
        ts.ContentDocumentLinkTrigger__c = true;
        insert ts;
        
        Account acc = new Account();
        acc.Name = 'accName';
        acc.Second_Account_Name__c = 'sAccName';
        acc.Sales_Organization__c = 'SAP_0333';
        //acc.Sales_Office__c = 'SAP_F020';
        acc.Phone = '+31302979111';
        acc.Account_Tier__c = 'Platinum';
        insert acc;
        
        
        Opportunity opp = new Opportunity();
        opp.Name = 'oppName';
        opp.AccountId = acc.id;
        opp.CLoseDate = Date.Today();
        opp.StageName = 'Open';
        opp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get(SM_Constants.OppStandardRT).getRecordTypeId();
            
        insert opp;
        
        Blob beforeblob=Blob.valueOf('Unit Test Attachment Body');

        ContentVersion cv = new ContentVersion();
        cv.title = 'test content trigger';      
        cv.PathOnClient ='test';           
        cv.VersionData =beforeblob;          
        insert cv;         
        
        ContentVersion testContent = [SELECT id, ContentDocumentId FROM ContentVersion where Id = :cv.Id];
        
        ContentDocumentLink notes = new ContentDocumentLink();
        notes.ShareType = 'V';
        notes.Visibility = 'InternalUsers';
        notes.ContentDocumentId = testcontent.ContentDocumentId;
        notes.LinkedEntityId = opp.Id;
        insert notes;
        
        ContentDocumentLink newnote = [Select Id, LinkedEntityId from ContentDocumentLink where LinkedEntityId =: acc.Id];
        System.assertEquals(newnote.LinkedEntityId, acc.Id);
    }
     private static testMethod void eventwithaccount(){
        //insert custom settings
        TriggerSettings__c ts = new TriggerSettings__c();
        ts.ContentDocumentLinkTrigger__c = true;
        insert ts;
        
        Account acc = new Account();
        acc.Name = 'accName';
        acc.Second_Account_Name__c = 'sAccName';
        acc.Sales_Organization__c = 'SAP_0333';
        //acc.Sales_Office__c = 'SAP_F020';
        acc.Phone = '+31302979111';
        acc.Account_Tier__c = 'Platinum';
        insert acc;
        
        
        Event eventRec = new Event();
        eventRec.WhatId = acc.Id;
        eventRec.Touchpoint_Type__c = 'Inbound Call';
        eventRec.StartDateTime = System.Now();
        eventRec.EndDateTime = System.Now() + 1;
            
        insert eventRec;
        
        Blob beforeblob=Blob.valueOf('Unit Test Attachment Body');

        ContentVersion cv = new ContentVersion();
        cv.title = 'test content trigger';      
        cv.PathOnClient ='test';           
        cv.VersionData =beforeblob;          
        insert cv;         
        
        ContentVersion testContent = [SELECT id, ContentDocumentId FROM ContentVersion where Id = :cv.Id];
        
        ContentDocumentLink notes = new ContentDocumentLink();
        notes.ShareType = 'V';
        notes.Visibility = 'InternalUsers';
        notes.ContentDocumentId = testcontent.ContentDocumentId;
        notes.LinkedEntityId = eventRec.Id;
        insert notes;
        
        ContentDocumentLink newnote = [Select Id, LinkedEntityId from ContentDocumentLink where LinkedEntityId =: acc.Id];
        System.assertEquals(newnote.LinkedEntityId, acc.Id);
    }
    
    private static testMethod void eventwithoppty(){
        //insert custom settings
        TriggerSettings__c ts = new TriggerSettings__c();
        ts.ContentDocumentLinkTrigger__c = true;
        insert ts;
        
        Account acc = new Account();
        acc.Name = 'accName';
        acc.Second_Account_Name__c = 'sAccName';
        acc.Sales_Organization__c = 'SAP_0333';
        //acc.Sales_Office__c = 'SAP_F020';
        acc.Phone = '+31302979111';
        acc.Account_Tier__c = 'Platinum';
        insert acc;
        
        Opportunity opp = new Opportunity();
        opp.Name = 'oppName';
        opp.AccountId = acc.id;
        opp.CLoseDate = Date.Today();
        opp.StageName = 'Open';
        opp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get(SM_Constants.OppStandardRT).getRecordTypeId();
        
        insert opp;
        
        Event eventRec = new Event();
        eventRec.WhatId = opp.Id;
        eventRec.Touchpoint_Type__c = 'Inbound Call';
        eventRec.StartDateTime = System.Now();
        eventRec.EndDateTime = System.Now() + 1;
            
        insert eventRec;
        
        Blob beforeblob=Blob.valueOf('Unit Test Attachment Body');

        ContentVersion cv = new ContentVersion();
        cv.title = 'test content trigger';      
        cv.PathOnClient ='test';           
        cv.VersionData =beforeblob;          
        insert cv;         
        
        ContentVersion testContent = [SELECT id, ContentDocumentId FROM ContentVersion where Id = :cv.Id];
        
        ContentDocumentLink notes = new ContentDocumentLink();
        notes.ShareType = 'V';
        notes.Visibility = 'InternalUsers';
        notes.ContentDocumentId = testcontent.ContentDocumentId;
        notes.LinkedEntityId = eventRec.Id;
        insert notes;
        
        // ContentDocumentLink newnote = [Select Id, LinkedEntityId from ContentDocumentLink where LinkedEntityId =: acc.Id];
        System.assertEquals(opp.AccountId, acc.Id);
        
        ContentDocumentLink notes1 = new ContentDocumentLink();
        notes1.ShareType = 'V';
        notes1.Visibility = 'InternalUsers';
        notes1.ContentDocumentId = testcontent.ContentDocumentId;
        notes1.LinkedEntityId = opp.Id;
        insert notes1;
    }
    
    private static testMethod void eventwithaccloc(){
        //insert custom settings
        TriggerSettings__c ts = new TriggerSettings__c();
        ts.ContentDocumentLinkTrigger__c = true;
        insert ts;
        
        Account acc = new Account();
        acc.Name = 'accName';
        acc.Second_Account_Name__c = 'sAccName';
        acc.Sales_Organization__c = 'SAP_0333';
        //acc.Sales_Office__c = 'SAP_F020';
        acc.Phone = '+31302979111';
        acc.Account_Tier__c = 'Platinum';
        insert acc;
        
        Apttus_Config2__AccountLocation__c accloc = new Apttus_Config2__AccountLocation__c();
        accloc.Apttus_Config2__AccountId__c = acc.Id;
        accloc.Name = 'accName';
        accloc.Mini_Language__c = 'SAP_EN';
        accloc.Apttus_Config2__Street__c = 'Prins Hendrikkade 123';
        accloc.Shipping_House_Number__c = '123';
        accloc.Apttus_Config2__PostalCode__c = '1011 AM';
        accloc.Apttus_Config2__City__c = 'AMSTERDAM';
        accloc.Apttus_Config2__Country__c = 'NETHERLANDS';
        insert accloc;
        
        Event eventRec = new Event();
        eventRec.WhatId = accloc.Id;
        eventRec.Touchpoint_Type__c = 'Inbound Call';
        eventRec.StartDateTime = System.Now();
        eventRec.EndDateTime = System.Now() + 1;
            
        insert eventRec;
        
        Blob beforeblob=Blob.valueOf('Unit Test Attachment Body');

        ContentVersion cv = new ContentVersion();
        cv.title = 'test content trigger';      
        cv.PathOnClient ='test';           
        cv.VersionData =beforeblob;          
        insert cv;         
        
        ContentVersion testContent = [SELECT id, ContentDocumentId FROM ContentVersion where Id = :cv.Id];
        
        ContentDocumentLink notes = new ContentDocumentLink();
        notes.ShareType = 'V';
        notes.Visibility = 'InternalUsers';
        notes.ContentDocumentId = testcontent.ContentDocumentId;
        notes.LinkedEntityId = eventRec.Id;
        insert notes;
        
        // ContentDocumentLink newnote = [Select Id, LinkedEntityId from ContentDocumentLink where LinkedEntityId =: acc.Id];
        System.assertEquals(accloc.Apttus_Config2__AccountId__c, acc.Id);
        
        ContentDocumentLink notes1 = new ContentDocumentLink();
        notes1.ShareType = 'V';
        notes1.Visibility = 'InternalUsers';
        notes1.ContentDocumentId = testcontent.ContentDocumentId;
        notes1.LinkedEntityId = accloc.Id;
        insert notes1;
    }
    
    private static testMethod void taskwithoppty(){
        //insert custom settings
        TriggerSettings__c ts = new TriggerSettings__c();
        ts.ContentDocumentLinkTrigger__c = true;
        insert ts;
        
        Account acc = new Account();
        acc.Name = 'accName';
        acc.Second_Account_Name__c = 'sAccName';
        acc.Sales_Organization__c = 'SAP_0333';
        //acc.Sales_Office__c = 'SAP_F020';
        acc.Phone = '+31302979111';
        acc.Account_Tier__c = 'Platinum';
        insert acc;
        
        Opportunity opp = new Opportunity();
        opp.Name = 'oppName';
        opp.AccountId = acc.id;
        opp.CLoseDate = Date.Today();
        opp.StageName = 'Open';
        opp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get(SM_Constants.OppStandardRT).getRecordTypeId();
        
        insert opp;
        
        Id serviceRecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Inbound').getRecordTypeId();
        
        Task taskRec = new Task();
        taskRec.WhatId = opp.Id;
        taskRec.RecordTypeId = serviceRecordTypeId;
        taskRec.Touchpoint_Type__c = 'Inbound Call';
            
        insert taskRec;
        
        Blob beforeblob=Blob.valueOf('Unit Test Attachment Body');

        ContentVersion cv = new ContentVersion();
        cv.title = 'test content trigger';      
        cv.PathOnClient ='test';           
        cv.VersionData =beforeblob;          
        insert cv;         
        
        ContentVersion testContent = [SELECT id, ContentDocumentId FROM ContentVersion where Id = :cv.Id];
        
        ContentDocumentLink notes = new ContentDocumentLink();
        notes.ShareType = 'V';
        notes.Visibility = 'InternalUsers';
        notes.ContentDocumentId = testcontent.ContentDocumentId;
        notes.LinkedEntityId = taskRec.Id;
        insert notes;
        
        // ContentDocumentLink newnote = [Select Id, LinkedEntityId from ContentDocumentLink where LinkedEntityId =: acc.Id];
        System.assertEquals(opp.AccountId, acc.Id);
        
        ContentDocumentLink notes1 = new ContentDocumentLink();
        notes1.ShareType = 'V';
        notes1.Visibility = 'InternalUsers';
        notes1.ContentDocumentId = testcontent.ContentDocumentId;
        notes1.LinkedEntityId = opp.Id;
        insert notes1;
    }
    
     private static testMethod void taskwithaccloc(){
        //insert custom settings
        TriggerSettings__c ts = new TriggerSettings__c();
        ts.ContentDocumentLinkTrigger__c = true;
        insert ts;
        
        Account acc = new Account();
        acc.Name = 'accName';
        acc.Second_Account_Name__c = 'sAccName';
        acc.Sales_Organization__c = 'SAP_0333';
        //acc.Sales_Office__c = 'SAP_F020';
        acc.Phone = '+31302979111';
        acc.Account_Tier__c = 'Platinum';
        insert acc;
        
        Apttus_Config2__AccountLocation__c accloc = new Apttus_Config2__AccountLocation__c();
        accloc.Apttus_Config2__AccountId__c = acc.Id;
        accloc.Name = 'accName';
        accloc.Mini_Language__c = 'SAP_EN';
        accloc.Apttus_Config2__Street__c = 'Prins Hendrikkade 123';
        accloc.Shipping_House_Number__c = '123';
        accloc.Apttus_Config2__PostalCode__c = '1011 AM';
        accloc.Apttus_Config2__City__c = 'AMSTERDAM';
        accloc.Apttus_Config2__Country__c = 'NETHERLANDS';
        insert accloc;
        
        Id serviceRecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Inbound').getRecordTypeId();
        
        Task taskRec = new Task();
        taskRec.WhatId = accloc.Id;
        taskRec.RecordTypeId = serviceRecordTypeId;
        taskRec.Touchpoint_Type__c = 'Inbound Call';
            
        insert taskRec;
        
        Blob beforeblob=Blob.valueOf('Unit Test Attachment Body');

        ContentVersion cv = new ContentVersion();
        cv.title = 'test content trigger';      
        cv.PathOnClient ='test';           
        cv.VersionData =beforeblob;          
        insert cv;         
        
        ContentVersion testContent = [SELECT id, ContentDocumentId FROM ContentVersion where Id = :cv.Id];
        
        ContentDocumentLink notes1 = new ContentDocumentLink();
        notes1.ShareType = 'V';
        notes1.Visibility = 'InternalUsers';
        notes1.ContentDocumentId = testcontent.ContentDocumentId;
        notes1.LinkedEntityId = accloc.Id;
        insert notes1;
        
        // ContentDocumentLink newnote = [Select Id, LinkedEntityId from ContentDocumentLink where LinkedEntityId =: acc.Id];
        System.assertEquals(accloc.Apttus_Config2__AccountId__c, acc.Id);
        
        ContentDocumentLink notes = new ContentDocumentLink();
        notes.ShareType = 'V';
        notes.Visibility = 'InternalUsers';
        notes.ContentDocumentId = testcontent.ContentDocumentId;
        notes.LinkedEntityId = taskRec.Id;
        insert notes;
    }
    
    private static testMethod void attachmentOnAgreement(){
        //insert custom settings
        TriggerSettings__c ts = new TriggerSettings__c();
        ts.ContentDocumentLinkTrigger__c = true;
        insert ts;
        
        Contact contact = APTS_TestUtils.createContact();
        Database.insert(contact, false);

        Apttus_Config2__PriceList__c priceList = APTS_TestUtils.createPriceList();
        Database.insert(priceList, false);
        
        List<Account> childAccountList = new List<Account>();

        Account account = APTS_TestUtils.createaccount();
        insert account;

        Account childAccount = APTS_TestUtils.createChildAccount(account);
        insert childAccount;

        childAccountList.add(childAccount);

        Apttus__APTS_Agreement__c agreement = APTS_TestUtils.createAgreement(contact.Id, null, priceList.Id, account.Id);
        agreement.Apttus__Status__c = Label.Apttus.Activated;
        agreement.Apttus__Status_Category__c = Label.APTS_In_Effect;
        agreement.Apttus__Auto_Renewal__c = false;
        agreement.Apttus__Contract_End_Date__c = System.Today() - 1;
        agreement.APTS_Order_Non_Contracted_Products__c = true;
        Database.insert(agreement, false);
        
        Blob beforeblob=Blob.valueOf('Unit Test Attachment Body');

        ContentVersion cv = new ContentVersion();
        cv.title = 'test content trigger';      
        cv.PathOnClient ='test';           
        cv.VersionData =beforeblob;
        insert cv;         
        
        ContentVersion testContent = [SELECT id, ContentDocumentId FROM ContentVersion where Id = :cv.Id];
        
        ContentDocumentLink notes = new ContentDocumentLink();
        notes.ShareType = 'V';
        notes.Visibility = 'InternalUsers';
        notes.ContentDocumentId = testcontent.ContentDocumentId;
        notes.LinkedEntityId = agreement.Id;
        insert notes;
        
        ContentDocumentLink newnote = [Select Id, LinkedEntityId from ContentDocumentLink where LinkedEntityId =: agreement.Id];
        System.assertEquals(newnote.LinkedEntityId, agreement.Id);
    }
}