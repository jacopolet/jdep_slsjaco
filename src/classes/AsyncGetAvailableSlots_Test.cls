/**
* @author        Adrian Reyes
* @date          04.17.2018           
* @description   Test class for AsyncGetAvailableSlots
* @revision(s)   
*/
@isTest
private class AsyncGetAvailableSlots_Test {
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
}