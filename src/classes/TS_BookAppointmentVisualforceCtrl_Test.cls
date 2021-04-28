/**
* @author        Adrian Reyes
* @date          04.16.2018           
* @description   Test class for TS_BookAppointmentVisualforceController
* @revision(s)   
*/
@isTest
private class TS_BookAppointmentVisualforceCtrl_Test {
    static Case c;
    static WorkOrder wo;
    static WorkOrderLineItem woli;
    
    /**
    * @author        Adrian Reyes
    * @date          04.16.2018           
    * @description   Method responsible for creating test data
    * @revision(s)
    */
    static void setupTestData() {
        Account acct = new Account(Name='Account', Phone='+31302979111');
        insert acct;
        
        Contact con = TS_TestDataFactory.createContact();  
        con.Preferred_Language__c = 'SAP_EN';
        insert con;
        
        Apttus_Config2__AccountLocation__c acctLoc = new Apttus_Config2__AccountLocation__c(Name='AL Test Account', Apttus_Config2__AccountId__c = acct.Id, Customer_calendar_key__c = 'SAP_BE', Apttus_Config2__PostalCode__c = '1234', Apttus_Config2__City__c = 'Test City', Shipping_Street_Only__c = 'Test Street', Shipping_Country_ISO__c = 'NL');
        insert acctLoc;
        
        Product2 prod = TS_TestDataFactory.createProduct('Test Product I', 'MA');
        prod.ProductCode = '123';
        insert prod;
        
         //Create sales org pricebook
        Pricebook2 orgPB = new Pricebook2();
        orgPB.name = 'NL Price Book';
        orgPB.IsActive = true;
        orgPB.Sales_Organization__c = 'SAP_0111';
        insert orgPB;
        
        //Create Pricebookentry with standard and sales org pricebook
        PricebookEntry pbe = new PricebookEntry();
        pbe.product2id = prod.id;
        pbe.pricebook2id = Test.getStandardPricebookId();
        pbe.UnitPrice = 1;
        pbe.IsActive = true;
        pbe.TS_Load_Id__c = String.valueOf(prod.id) + String.valueOf(Test.getStandardPricebookId());
        insert pbe;
        
        pbe = new pricebookentry();
        pbe.product2id = prod.id;
        pbe.pricebook2id = orgPB.id;
        pbe.UnitPrice = 11;
        pbe.IsActive = true;
        pbe.TS_Load_Id__c = String.valueOf(prod.id) + String.valueOf(orgPB.id);
        insert pbe;
        
        PhysicalAsset__c pa = new PhysicalAsset__c(Name='Test', UniqueNumber__c='1234567-TestMachine', RecordTypeId = Schema.SObjectType.PhysicalAsset__c.getRecordTypeInfosByName().get('Machine').getRecordTypeId(), Product__c = prod.Id);
        insert pa;
        
        Resource__c resource1 = TS_TestDataFactory.createResourceSingle('Test Resource 1');
        insert resource1;
        
        Resource__c resource2 = TS_TestDataFactory.createResourceSingle('Test Resource 2');
        insert resource2;
        
        c = TS_TestDataFactory.createFieldServiceCase();
        c.ContactId = con.Id;
        insert c;
        
        wo = TS_TestDataFactory.createWorkOrder();
        wo.CaseId = c.Id;
        wo.WorkOrderType__c = Label.TS_Case_SubType_CorrectMaint;
        wo.ContactId = con.Id;
        wo.Pricebook2Id = orgPB.Id;
        insert wo;
        
        woli = TS_TestDataFactory.createWorkOrderLineItem(wo.Id);         
        woli.Case__c = c.Id;
        woli.WorkOrderLineItemType__c = Label.TS_Type_Task;
        woli.AccountLocation__c = acctLoc.Id;
        woli.JDELineItemNumber__c = '12345';
        woli.PhysicalAsset__c = pa.Id;
        woli.ExcludedEngineer__c = resource1.Id;
        woli.RequiredEngineer__c = resource2.Id;
        insert woli;
    }
    
    static testMethod void testSearchSlots(){
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        
        System.runAs(u) {
            setupTestData();
            
            Test.startTest();

            String message = '{"recordId":"' + woli.Id + '","start":"2018-04-01T00:00:00.000Z","finish":"2018-04-30T00:00:00.000Z","isRequest":true,"isSelect":false}';
            ApexPages.currentPage().getParameters().put('message', message);
            TS_BookAppointmentVisualforceController controller = new TS_BookAppointmentVisualforceController();
            Continuation cont = controller.startRequest();
            
            HttpResponse response = new HttpResponse();
            response.setBody('   <s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/">  '  + 
                             '      <s:Body>  '  + 
                             '         <SXPExtendedTaskGetAppointmentsEx2Response>  '  + 
                             '            <OptionalAppointments>  '  + 
                             '               <TimeInterval>  '  + 
                             '                  <Start>2018-04-18T08:00:00</Start>  '  + 
                             '                  <Finish>2018-04-18T12:00:00</Finish>  '  + 
                             '                  <Grade>6980</Grade>  '  + 
                             '               </TimeInterval>  '  + 
                             '               <TimeInterval>  '  + 
                             '                  <Start>2018-04-18T12:00:00</Start>  '  + 
                             '                  <Finish>2018-04-18T16:00:00</Finish>  '  + 
                             '                  <Grade>6979</Grade>  '  + 
                             '               </TimeInterval>  '  + 
                             '               <TimeInterval>  '  + 
                             '                  <Start>2018-04-19T08:00:00</Start>  '  + 
                             '                  <Finish>2018-04-19T12:00:00</Finish>  '  + 
                             '                  <Grade>6662</Grade>  '  + 
                             '               </TimeInterval>  '  + 
                             '               <TimeInterval>  '  + 
                             '                  <Start>2018-04-19T12:00:00</Start>  '  + 
                             '                  <Finish>2018-04-19T16:00:00</Finish>  '  + 
                             '                  <Grade>6658</Grade>  '  + 
                             '               </TimeInterval>  '  + 
                             '               <TimeInterval>  '  + 
                             '                  <Start>2018-04-20T08:00:00</Start>  '  + 
                             '                  <Finish>2018-04-20T12:00:00</Finish>  '  + 
                             '                  <Grade>6628</Grade>  '  + 
                             '               </TimeInterval>  '  + 
                             '               <TimeInterval>  '  + 
                             '                  <Start>2018-04-20T12:00:00</Start>  '  + 
                             '                  <Finish>2018-04-20T16:00:00</Finish>  '  + 
                             '                  <Grade>6623</Grade>  '  + 
                             '               </TimeInterval>  '  + 
                             '               <TimeInterval>  '  + 
                             '                  <Start>2018-04-24T08:00:00</Start>  '  + 
                             '                  <Finish>2018-04-24T12:00:00</Finish>  '  + 
                             '                  <Grade>6595</Grade>  '  + 
                             '               </TimeInterval>  '  + 
                             '               <TimeInterval>  '  + 
                             '                  <Start>2018-04-24T12:00:00</Start>  '  + 
                             '                  <Finish>2018-04-24T16:00:00</Finish>  '  + 
                             '                  <Grade>6591</Grade>  '  + 
                             '               </TimeInterval>  '  + 
                             '               <TimeInterval>  '  + 
                             '                  <Start>2018-04-25T08:00:00</Start>  '  + 
                             '                  <Finish>2018-04-25T12:00:00</Finish>  '  + 
                             '                  <Grade>6562</Grade>  '  + 
                             '               </TimeInterval>  '  + 
                             '               <TimeInterval>  '  + 
                             '                  <Start>2018-04-25T12:00:00</Start>  '  + 
                             '                  <Finish>2018-04-25T16:00:00</Finish>  '  + 
                             '                  <Grade>6558</Grade>  '  + 
                             '               </TimeInterval>  '  + 
                             '               <TimeInterval>  '  + 
                             '                  <Start>2018-04-26T08:00:00</Start>  '  + 
                             '                  <Finish>2018-04-26T12:00:00</Finish>  '  + 
                             '                  <Grade>6528</Grade>  '  + 
                             '               </TimeInterval>  '  + 
                             '            </OptionalAppointments>  '  + 
                             '         </SXPExtendedTaskGetAppointmentsEx2Response>  '  + 
                             '      </s:Body>  '  + 
                             '  </s:Envelope>  ');
            
            String requestLabel = cont.getRequests().keyset().iterator().next();
            Test.setContinuationResponse(requestLabel, response);
            Test.invokeContinuationMethod(controller, cont);
            Test.stopTest();
            
            //Verify results
            System.assertNotEquals(null, controller.result);
        }
    }
    
    static testMethod void testSelectSlot(){
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        
        System.runAs(u) {
            setupTestData();
            
            Test.startTest();

            String message = '{"dateYear":2018,"dateMonth":4,"dateDay":17,"startHour":8,"startMinute":0,"endHour":12,"endMinute":0,"woliId":"' + woli.Id + '","jdeLine":"' + woli.JDELineItemNumber__c + '","isRequest":false,"isSelect":true}';
            ApexPages.currentPage().getParameters().put('message', message);
            TS_BookAppointmentVisualforceController controller = new TS_BookAppointmentVisualforceController();
            Continuation cont = controller.startRequest();
            HttpResponse response = new HttpResponse();
            response.setBody('   <s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/">  '  + 
                             '      <s:Body>  '  + 
                             '         <ProcessSlotResponse>  '  + 
                             '            <Success>True</Success>  '  + 
                             '         </ProcessSlotResponse>  '  + 
                             '      </s:Body>  '  + 
                             '  </s:Envelope>  ');
            
            String requestLabel = cont.getRequests().keyset().iterator().next();
            Test.setContinuationResponse(requestLabel, response);
            Test.invokeContinuationMethod(controller, cont);
            Test.stopTest();
            
            //Verify results
            System.assertNotEquals(null, controller.result);
        }
    }
    
    static testMethod void testLightningRelatedMethods(){
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        
        System.runAs(u) {
            setupTestData();
            
            Test.startTest();
            woli.WorkOrderLineItemType__c = 'Task';
            update woli;
            List<WorkOrderLineItem> openTasks = TS_BookAppointmentVisualforceController.getOpenTasks(c.Id);
            DateTime now = TS_BookAppointmentVisualforceController.getCurrentDateTime();
            Test.stopTest();
            
            //Verify results
            System.assert(openTasks.size() > 0);
            System.assertNotEquals(null, now);
        }
    }
    
    static testMethod void testValidateRequiredFields(){
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        
        System.runAs(u) {
            //Initialize test data
            setupTestData();
            
            WorkOrderLineItem blankWOLI = TS_TestDataFactory.createWorkOrderLineItem(wo.Id);         
            blankWOLI.Case__c = c.Id;
            blankWOLI.WorkOrderLineItemType__c = null;
            insert blankWOLI;
            
            Test.startTest();
            String message = '{"recordId":"' + blankWOLI.Id + '","start":"2018-04-01T00:00:00.000Z","finish":"2018-04-30T00:00:00.000Z","isRequest":true,"isSelect":false}';
            ApexPages.currentPage().getParameters().put('message', message);
            TS_BookAppointmentVisualforceController controller = new TS_BookAppointmentVisualforceController();
            Continuation cont = controller.startRequest();
            Test.stopTest();
            
            //Verify results
            System.assertEquals(null, controller.result);
        }
    }
    
    static testMethod void testValidateRequiredFields2(){
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        
        System.runAs(u) {
            //Initialize test data
            setupTestData();
            
            WorkOrderLineItem blankWOLI = TS_TestDataFactory.createWorkOrderLineItem(wo.Id);         
            blankWOLI.Case__c = c.Id;
            blankWOLI.WorkOrderLineItemType__c = 'Task';            
            blankWoli.WorkOrderId = wo.Id;
            blankWOLI.AccountLocation__c = [SELECT Id, Apttus_Config2__PostalCode__c,Apttus_Config2__City__c,Shipping_Street_Only__c,Shipping_Country_ISO__c FROM Apttus_Config2__AccountLocation__c LIMIT 1].Id;
            blankWOLI.JDELineItemNumber__c = '00001234';
            blankWOLI.PhysicalAsset__c = [SELECT Id, ProductCode__c FROM PhysicalAsset__c LIMIT 1].Id;
            blankWOLI.PricebookEntryId = [SELECT Id,Product2Id,Pricebook2Id, Product2.ProductCode, ProductCode FROM PricebookEntry where pricebook2.isStandard= false LIMIT 1].Id;
            insert blankWOLI;
            
            Test.startTest();
            String message = '{"recordId":"' + blankWOLI.Id + '","start":"2018-04-01T00:00:00.000Z","finish":"2018-04-30T00:00:00.000Z","isRequest":true,"isSelect":false}';
            ApexPages.currentPage().getParameters().put('message', message);
            TS_BookAppointmentVisualforceController controller = new TS_BookAppointmentVisualforceController();
            Continuation cont = controller.startRequest();
            Test.stopTest();
            
            //Verify results
            System.assertEquals(null, controller.result);
        }
    }
}