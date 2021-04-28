@isTest
private class passToFlowTaskVFController_Test {

	private static testMethod void test() {
        List<Task> testtask = new List<Task>();
        Task tt = new Task();
        tt.Subject = 'sdf';
        tt.Touchpoint_Type__c = 'INBOUND CALL';
        tt.Task_Source__c = 'SFDC';
        testtask.add(tt);
        Task t1t = new Task();
        t1t.Subject = 'sdf';
        t1t.Touchpoint_Type__c = 'INBOUND CALL';
        t1t.Task_Source__c = 'SFDC';
        testtask.add(t1t);
        
        insert testtask;
        
        Test.startTest();
        Test.setCurrentPage(Page.Task_Accept_Task);
        ApexPages.StandardSetController stdSetController = new ApexPages.StandardSetController(testtask);
        stdSetController.setSelected(testtask);
        passToFlowTaskVFController ext = new passToFlowTaskVFController(stdSetController);
        Test.stopTest();
	}

}