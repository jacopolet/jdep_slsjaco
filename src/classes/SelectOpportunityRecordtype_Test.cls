@isTest
private class SelectOpportunityRecordtype_Test {

	private static testMethod void positiveTest() {
        SelectOpportunityRecordtype.fetchRecordTypeValues();
        List<Schema.RecordTypeInfo> recordtypes = Opportunity.SObjectType.getDescribe().getRecordTypeInfos();
        SelectOpportunityRecordtype.getRecTypeId(recordtypes[0].getName());
        
        Account acc = new Account();
        acc.Name = 'accName';
        acc.Second_Account_Name__c = 'sAccName';
        acc.Sales_Organization__c = 'SAP_0333';
        //acc.Sales_Office__c = 'SAP_F020';
        acc.Phone = '+31302979111';
        insert acc;
        
        Campaign camp = new Campaign();
        camp.Name = '1234';
        camp.CurrencyIsoCode = 'EUR';
        insert camp;
        
        Lead ld = new Lead();
        ld.Status = 'Open';
        ld.LastName = 'TestLead';
        ld.FirstName = 'TestLead';
        ld.Title = 'TestLead';
        ld.Phone = '+1234567890';
        ld.LeadSource = 'Asset Ownership Change';
        ld.Company = 'TestCompany';
        insert ld;
        
        Id recordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Inbound').getRecordTypeId();
        Task tasks = new Task();
        tasks.Touchpoint_Type__c = 'INBOUND CALL';
        tasks.WhatId = acc.Id;
        tasks.RecordTypeId = recordTypeId;
        tasks.Campaign__c = camp.ID;
        insert tasks;
    
        Task tasks1 = new Task();
        tasks1.Touchpoint_Type__c = 'INBOUND CALL';
        tasks1.WhoId = ld.Id;
        tasks1.RecordTypeId = recordTypeId;
        insert tasks1;
        
        SelectOpportunityRecordtype.getAccountId(tasks.id);
        SelectOpportunityRecordtype.getTouchpointType(tasks.id);
        SelectOpportunityRecordtype.getCampaign(tasks.id);
        SelectOpportunityRecordtype.getNamefield(tasks1.id);
        
        Task tRec = [Select Id, WhatId, Touchpoint_Type__c FROM Task WHERE Id = :tasks.Id];
        
        System.assert(tRec.WhatId <> Null);
        System.assert(tRec.Touchpoint_Type__c == 'INBOUND CALL');
	}
	
	private static testMethod void negativeTest() {
	    try {
	        
            List<Schema.RecordTypeInfo> recordtypes = Account.SObjectType.getDescribe().getRecordTypeInfos();
            SelectOpportunityRecordtype.getRecTypeId(recordtypes[0].getName());
            
            Account acc = new Account();
            acc.Name = 'accName';
            acc.Second_Account_Name__c = 'sAccName';
            acc.Sales_Organization__c = 'SAP_0333';
            acc.Phone = '+31302979111';
            insert acc;
            
            Id recordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Inbound').getRecordTypeId();
            Task tasks = new Task();
            tasks.Touchpoint_Type__c = 'INBOUND CALL';
            tasks.WhatId = acc.Id;
            tasks.RecordTypeId = recordTypeId;
            
            insert tasks;
            
            SelectOpportunityRecordtype.getAccountId(acc.id);
            SelectOpportunityRecordtype.getTouchpointType(acc.id);
            
            Task tRec = [Select Id, WhatId, Touchpoint_Type__c FROM Task WHERE Id = :tasks.Id];
            
            System.assert(tRec.WhatId <> Null);
            System.assert(tRec.Touchpoint_Type__c == 'INBOUND CALL');
        
	    } catch (Exception e) {
	        
	    }
	}

}