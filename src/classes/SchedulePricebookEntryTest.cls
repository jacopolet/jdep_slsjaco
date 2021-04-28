/**
* @author        Harold Marilag
* @date          5.30.2017           
* @description   Test class for SchedulePricebookEntry
* @revision(s)
*/
@isTest
private class SchedulePricebookEntryTest {
    
    static testMethod void testCreateIntegrationLog(){
        
        Product2 prod = new Product2(Name = 'Laptop X200', 
            Family = 'Hardware');
        insert prod;
        
        Id pricebookId = Test.getStandardPricebookId();
        
        PricebookEntry standardPrice = new PricebookEntry(
            Pricebook2Id = pricebookId, Product2Id = prod.Id,
            UnitPrice = 10000, IsActive = true);
        insert standardPrice;
        
        Pricebook2 customPB = new Pricebook2(Name='Custom Pricebook', isActive=true, Is_Country_Standard_Price__c = true);
        insert customPB;
        
        PricebookEntry customPrice = new PricebookEntry(
            Pricebook2Id = customPB.Id, Product2Id = prod.Id,
            UnitPrice = 12000, OldStandardPrice__c=100.0, IsActive = true);
        insert customPrice;
        
        customPrice.UnitPrice = 1212;
        update customPrice;
        
        //insert new IntegrationTriggerSettings__c (IntegrationLogTrigger__c = true);
        test.startTest();
        SchedulePricebookEntry newSchedulePricebookEntry = new SchedulePricebookEntry();
        newSchedulePricebookEntry.createIntegrationLog();
        test.stopTest();
        PricebookEntry pe = [Select Is_price_changed__c from PricebookEntry where id =: customPrice.id];
        System.assertequals(false, pe.Is_price_changed__c);
        
    }

    static testMethod void testFailCreateIntegrationLog(){
        IntegrationUserAndProfile__c integ = new IntegrationUserAndProfile__c();
        integ.Click_Session_Id_Duration__c = 30;
        integ.ClickPriceBookEntryScheduleDuration__c = 600;
        insert integ;

        IntegrationTriggerSettings__c integTrigger = new IntegrationTriggerSettings__c();
        integTrigger.IntegrationLogTrigger__c = true;
        insert integTrigger;

        Product2 prod = new Product2(Name = 'Laptop X200', 
            Family = 'Hardware');
        insert prod;
        
        Id pricebookId = Test.getStandardPricebookId();
        
        PricebookEntry standardPrice = new PricebookEntry(
            Pricebook2Id = pricebookId, Product2Id = prod.Id,
            UnitPrice = 10000, IsActive = true);
        insert standardPrice;
        
        Pricebook2 customPB = new Pricebook2(Name='Custom Pricebook', isActive=true, Is_Country_Standard_Price__c = true);
        insert customPB;
        
        PricebookEntry customPrice = new PricebookEntry(
            Pricebook2Id = customPB.Id, Product2Id = prod.Id,
            UnitPrice = 12000, OldStandardPrice__c=100.0, IsActive = true);
        insert customPrice;
        
        customPrice.UnitPrice = 1212;
        update customPrice;

        test.startTest();        
        SchedulePricebookEntry.hasException = true;
        System.schedule('testPrevMaintenanceConTriggerScheduler', '0 0 4 * * ?', new SchedulePricebookEntry());
        test.stopTest();
        PricebookEntry pe = [Select Is_price_changed__c from PricebookEntry where id =: customPrice.id];
        System.assertequals(true, pe.Is_price_changed__c);
    }

    static testMethod void testSchedulePricebookEntry(){
        IntegrationUserAndProfile__c integ = new IntegrationUserAndProfile__c();
        integ.Click_Session_Id_Duration__c = 30;
        integ.ClickPriceBookEntryScheduleDuration__c = 600;
        insert integ;

        Datetime dt = Datetime.now().addMinutes(1);
        String CRON_EXP = '0 '+ dt.minute() + ' * ' + dt.day() + ' ' + dt.month() + ' ? ' + dt.year();
        String jobId = system.schedule('Sample_Heading', CRON_EXP, new SchedulePricebookEntry () );
        List<CronTrigger> cronJob = [select Id, cronExpression, TimesTriggered, NextFireTime from CronTrigger where (Id = :jobId)];
        
        if(!cronJob.isEmpty()){
            CronTrigger schedJob = cronJob.get(0);
            system.assert(schedJob.CronExpression.equals(CRON_EXP ));
            system.assert(schedJob.TimesTriggered == 0);
        }
    }    
    
    
      
}