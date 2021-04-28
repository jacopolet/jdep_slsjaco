@isTest
private class EmailMessageTriggerHandlerTest {
   
     @testSetup
    static void dataSetup() {
        //Custom settings is being shared by all test class, if another test class has already inserted the record 
        //this test class will throw "UNABLE_TO_LOCK_ROW, unable to obtain exclusive access to this record"
        try {
            TriggerSettings__c trg = TriggerSettings__c.getOrgDefaults();
            trg.WorkOrderTrigger__c = true;
            trg.WorkOrderLineItemTrigger__c = true;
            upsert trg;      
            system.debug('trg is:'+trg);
        } catch(Exception ex) {
            system.debug(ex);
        }

         try {
            IntegrationTriggerSettings__c trg1 = IntegrationTriggerSettings__c.getOrgDefaults();
            trg1.IntegrationLogTrigger__c = true;
            upsert trg1; 
        } catch(Exception ex) {
            system.debug(ex);
        }
        
        ProcessBuilderSettings__c pb = new ProcessBuilderSettings__c();
        pb.WorkOrderPBFlows__c = true;
        pb.CasePBFlows__c = true;
        insert pb;

        CountrySetting__c CS_EMAIL = new CountrySetting__c();
        CS_EMAIL.recordTypeId = Schema.SObjectType.CountrySetting__c.getRecordTypeInfosByName().get('Country Email Rules').getRecordTypeId();
        CS_EMAIL.email__c = 'test@abc.com';
        CS_EMAIL.Inbound_email__c = 'test@abc.com';
        CS_EMAIL.Active__c = true;
        CS_EMAIL.CaseType__c = 'Qualify Case';
        CS_EMAIL.Country__c = 'SAP_0333';
        insert CS_EMAIL;

    }
   
    private static testmethod void test(){
        
        Id CSrecordTypeId=Schema.SObjectType.CountrySetting__c.getRecordTypeInfosByName().get('Country Email Rules').getRecordTypeId();
        
        CountrySetting__c countrySetting = new CountrySetting__c(Name='Test CS', Country__c = 'SAP_0333',recordTypeId=CSrecordTypeId, email__c='test@abc.com', CaseType__c = 'Qualify Case', Active__c = true);
        insert countrySetting;   
        
        Case case1=TS_TestDataFactory.createFieldServiceCase();
        insert case1;
        test.startTest();
        EmailMessage em=new EmailMessage();
        em.toaddress='test@abc.com';
        em.fromAddress='from@test.com';
        em.incoming=true;
        em.TextBody='test test';
        em.subject='test subject';
        em.parentId=case1.id;
        insert em;
        Case updatedCase=[select id, salesorganization__c from case where id=:case1.id];
        //system.assertEquals(CountrySetting.Country__c, updatedCase.salesorganization__c);
        
        EmailMessage em1=new EmailMessage(id=em.id);
        em1.TextBody='test test test';
        update em1;
        
        delete em1;
        test.stopTest();
        
    }
    
    private static testmethod void testException(){
        EmailMessageTriggerHandler.hasException = true;
        
        Id CSrecordTypeId=Schema.SObjectType.CountrySetting__c.getRecordTypeInfosByName().get('Country Email Rules').getRecordTypeId();
        
        CountrySetting__c countrySetting = new CountrySetting__c(Name='Test CS', Country__c = 'SAP_0333',recordTypeId=CSrecordTypeId, email__c='test@abc.com', CaseType__c = 'Qualify Case', Active__c = true);
        insert countrySetting;   
        
        Case case1=TS_TestDataFactory.createFieldServiceCase();
        insert case1;
        test.startTest();
        EmailMessage em=new EmailMessage();
        em.toaddress='test@abc.com';
        em.ccaddress='test@abc.com';
        em.fromAddress='from@test.com';
        em.incoming=true;
        em.TextBody='test test';
        em.subject='test subject';
        em.parentId=case1.id;
        insert em;
        test.stopTest();
        
        //System.assert(EmailMessageTriggerHandler.hasException);
    }
   
   //Karen Hung 27.9.2018 additional for email blocking custom setting
    /*private static testMethod void emailTest(){

        test.startTest();
        TS_Email_Blocking__c  blocking = TS_Email_Blocking__c.getInstance();
        blocking.Name = 'Test';
        blocking.Active__c = true;
        blocking.Allowed_Domains__c = 'yahoo.com,gmail.com';
        blocking.Suffix__c = '.test';
        upsert blocking;
        
        Contact con1 = TS_TestDataFactory.createContact();
        con1.Email = 'test@jde.com';
        insert con1;
        
        Contact con2 = TS_TestDataFactory.createContact();
        con2.Phone = '+31302979119';
        con2.Email = 'test2@jde.com';
        insert con2;
        
        Case case1=TS_TestDataFactory.createFieldServiceCase();
        case1.ContactId = con1.id;
        case1.SecondaryContact__c = con2.id;
        case1.RequestorEmail__c = 'requestor@jde.com';
        insert case1;

        EmailMessage em = new EmailMessage();
        em.toaddress = 'test@abc.com,test@yahoo.com';
        em.CcAddress = 'test@gmail.com,test@jde.com';
        em.BccAddress = 'em@test.com, mail@gmail.com';
        em.fromAddress = 'from@test.com';
        em.incoming = false;
        em.TextBody = 'test test';
        em.subject = 'test subject';
        em.parentId = case1.id;
        database.insert(em);
        database.delete(em);
        database.undelete(em);
        test.stopTest();
        System.assertEquals(em.incoming,false);
    }*/
    //Karen Hung 03.10.18 for those valid email domain with suffix appended
    /*private static testMethod void emailTest2(){
        test.startTest();
        TS_Email_Blocking__c  blocking = TS_Email_Blocking__c.getInstance();
        blocking.Name = 'Test';
        blocking.Active__c = true;
        blocking.Allowed_Domains__c = 'yahoo.com,gmail.com';
        blocking.Suffix__c = '.test';
        upsert blocking;
        
        Contact con1 = TS_TestDataFactory.createContact();
        con1.Email = 'test@gmail.com.test';
        insert con1;
        
        Contact con2 = TS_TestDataFactory.createContact();
        con2.Phone = '+31302979119';
        con2.Email = 'test2@yahoo.com.test';
        insert con2;
        
        Case case1=TS_TestDataFactory.createFieldServiceCase();
        case1.ContactId = con1.id;
        case1.SecondaryContact__c = con2.id;
        case1.RequestorEmail__c = 'requestor@gmail.com.test';
        insert case1;

        EmailMessage em = new EmailMessage();
        em.toaddress = 'test@abc.com,test@yahoo.com';
        em.CcAddress = 'test@gmail.com,test@jde.com';
        em.BccAddress = 'em@test.com, mail@gmail.com';
        em.fromAddress = 'from@test.com';
        em.incoming = false;
        em.TextBody = 'test test';
        em.subject = 'test subject';
        em.parentId = case1.id;
        database.insert(em);
        database.delete(em);
        database.undelete(em);
        test.stopTest();
        System.assertEquals(em.incoming,false);   
    }*/
}