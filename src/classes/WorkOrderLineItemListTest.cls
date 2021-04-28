@isTest(seeAllData=false)
private class WorkOrderLineItemListTest {

	private static testMethod void test() {
        Account newAccount = new Account(Name='Sample Account', Phone='+31302979111');
        insert newAccount;
        String newAccountId = [Select Id from Account where Name='Sample Account' Limit 1].Id;
        
        Contact con=TS_TestDataFactory.createContact();
        con.Accountid=newAccountId;
        con.lastName='Test';
        con.Preferred_Language__c='SAP_NL';
        insert con;
        
        Resource__c testResource = TS_TestDataFactory.createResourceSingle('Test Resource');
        testResource.relateduser__c=userInfo.getUserId();
        insert testResource;
        
        Case case1=TS_TestDataFactory.createFieldServiceCase();
        case1.SalesOrganization__c='SAP_0333';
        case1.NoETANotification__c=false;
        case1.contactId=con.Id;
        insert case1;
        
        WorkOrder parentWO = TS_TestDataFactory.createWorkOrder();
        parentWO.CaseId = case1.Id;
        parentWO.contactId=con.Id;
        parentWO.WorkOrderType__c = Label.TS_Case_SubType_CorrectMaint;
        try{insert parentWO;}
        catch (Exception e){  system.debug(e);}
         list<WorkOrderLineItem> lst_Wolis=new list<WorkOrderLineItem>();
         WorkOrderLineItem woliParent1 = TS_TestDataFactory.createWorkOrderLineItem(parentWO.Id);
         woliParent1.Status = 'Open';
         woliParent1.WorkOrderLineItemType__c = Label.TS_Type_Task;     
         woliParent1.Case__c = case1.Id;     
         woliParent1.WorkOrderType__c = 'S40';
         woliParent1.Installation_Date_S40__c=system.now();
         woliParent1.WorkOrderId=parentWO.id;
         woliParent1.executingEngineer__c=testResource.Id;
         woliparent1.SLADate__c=system.now();
         woliParent1.BookAppointmentFinish__c=system.now();
         woliParent1.LatestAppointmentTime__c=system.now();
         woliParent1.startDate__c=system.now();
         lst_Wolis.add(woliParent1);
         WorkOrderLineItem woliParent2 = TS_TestDataFactory.createWorkOrderLineItem(parentWO.Id);
         woliParent2.Status = 'Open';
         woliParent2.WorkOrderLineItemType__c = Label.TS_Type_Task;     
         woliParent2.Case__c = case1.Id;     
         woliParent2.WorkOrderType__c = 'S41';
         woliParent2.WorkOrderId=parentWO.id;
         woliParent2.executingEngineer__c=testResource.Id;
         woliparent2.SLADate__c=system.now();
         woliParent2.startDate__c=system.now();
         woliParent2.BookAppointmentFinish__c=system.now();
         woliParent2.LatestAppointmentTime__c=system.now();
         lst_Wolis.add(woliParent2);
         WorkOrderLineItem woliParent3 = TS_TestDataFactory.createWorkOrderLineItem(parentWO.Id);
         woliParent3.Status = 'Open';
         woliParent3.WorkOrderLineItemType__c = Label.TS_Type_Task;     
         woliParent3.Case__c = case1.Id;     
         woliParent3.WorkOrderType__c = 'S41';
         woliParent3.WorkOrderId=parentWO.id;
         woliParent3.executingEngineer__c=testResource.Id;
         woliparent3.SLADate__c=system.now();
         woliParent3.startDate__c=system.now();
         woliParent3.outsideSLA__C=true;
         woliParent3.LatestAppointmentTime__c=system.now();
         lst_Wolis.add(woliParent3);
         try{
             insert lst_Wolis;
             system.debug('lst_Wolis is:'+lst_Wolis);
         }
         catch(Exception e){  system.debug(e.getMessage());}
         //lst_Wolis.clear();
         list<WorkOrderLineItem> lst_Wolis2;//=new list<WorkOrderLineItem>();
         lst_Wolis2=[select id, status from workorderlineitem where id in :lst_Wolis limit 3 ];
         lst_Wolis2[0].Status='Scheduled';
         lst_Wolis2[1].Status='Completed';
         lst_Wolis2[2].Status='Completed';
         update lst_Wolis2;
         
         test.startTest();
         PageReference pageRef = Page.WorkOrderLineItem;
         Test.setCurrentPage(pageRef); 
         WorkOrderLineItemList WList=new WorkOrderLineItemList();
         system.assertEquals(1, WList.openWolis.size());
         system.assertEquals(2, WList.closedWolis.size());
         
         test.stopTest();
         
	}

}