/**
* @author        Paul Jarred Aguiling
* @date          02.21.2018           
* @description   Test class for TS_AsyncExecutionSalesTrigger
* @revision(s)   
*/
@isTest
private class TS_AsyncExecutionSalesTrigger_Test {

    /**
    * @author        Paul Aguiling
    * @date          02.21.2018        
    * @description   Method responsible for queueable execute method
    * @revision(s)
    */
    static testMethod void testExecute() {
        User usr = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);

        System.runAs(usr) {

            WorkOrderTrigger__c wotObjLineItem = new WorkOrderTrigger__c();
            wotObjLineItem.GenerateServiceOrder__c = true;
            wotObjLineItem.SalesOrganization__c = 'SAP_0333';
            wotObjLineItem.Type__c = Label.TS_WOTType_Header;
            wotObjLineItem.OrderType__c = Label.TS_WOTOrderType_Installation;
            wotObjLineItem.RequestedActivityDate__c = Date.today();
            wotObjLineItem.Subject__c = 'Test Subject Line Item';
            wotObjLineItem.Description__c = 'Test Description Line Item';
            wotObjLineItem.Stopover__c = false;

            insert wotObjLineItem;

            List<Id> parentOrderIdList = new List<Id>{wotObjLineItem.Id};

            TS_AsyncExecutionSalesTrigger queueableSalesTrigger = new TS_AsyncExecutionSalesTrigger();
            queueableSalesTrigger.parentOrderIdList = parentOrderIdList;
            ID jobID = System.enqueueJob(queueableSalesTrigger);

            Test.startTest();
                System.assert(jobID != null);
            Test.stopTest();
        }
    }
    
    /**
    * @author        Adrian Reyes
    * @date          05.09.2018        
    * @description   Test force throw exception
    * @revision(s)
    */
    static testMethod void testException() {
        TS_AsyncExecutionSalesTrigger.hasException = true;
        User usr = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);

        System.runAs(usr) {

            WorkOrderTrigger__c wotObjLineItem = new WorkOrderTrigger__c();
            wotObjLineItem.GenerateServiceOrder__c = true;
            wotObjLineItem.SalesOrganization__c = 'SAP_0333';
            wotObjLineItem.Type__c = Label.TS_WOTType_Header;
            wotObjLineItem.OrderType__c = Label.TS_WOTOrderType_Installation;
            wotObjLineItem.RequestedActivityDate__c = Date.today();
            wotObjLineItem.Subject__c = 'Test Subject Line Item';
            wotObjLineItem.Description__c = 'Test Description Line Item';
            wotObjLineItem.Stopover__c = false;

            insert wotObjLineItem;

            List<Id> parentOrderIdList = new List<Id>{wotObjLineItem.Id};

            TS_AsyncExecutionSalesTrigger queueableSalesTrigger = new TS_AsyncExecutionSalesTrigger();
            queueableSalesTrigger.parentOrderIdList = parentOrderIdList;
            ID jobID = System.enqueueJob(queueableSalesTrigger);
            
            System.assert(TS_AsyncExecutionSalesTrigger.hasException);
        }
    }
}