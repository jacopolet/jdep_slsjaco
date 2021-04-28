/**
* @author        Adrian Reyes
* @date          4.6.2018
* @description   Test class for ClickSoapApiCallout
* @revision(s)	 04.09.2018 Paul Aguiling - Added multiple test methods
*/
@isTest
private class ClickSoapApiCallout_Test {

	static List<Integration_Log__c> logLst = new List<Integration_Log__c>();

    @testSetup
    static void dataSetup() {
        //Custom settings is being shared by all test class, if another test class has already inserted the record 
        //this test class will throw "UNABLE_TO_LOCK_ROW, unable to obtain exclusive access to this record"
        try {
            TriggerSettings__c trg = TriggerSettings__c.getOrgDefaults();
            trg.CaseTrigger__c = true;
            trg.WorkOrderTrigger__c = true;
            trg.WorkOrderLineItemTrigger__c = true;
            upsert trg;      

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
    }

    /**
    * @author        Paul Aguiling
    * @date          04.09.2018           
    * @description   Method responsible for creating test data
    * @revision(s)
    */
	static void setupTestData() {
		Set<String> oBjectValues = new Set<String>();
        oBjectValues.add(INT_Constants.WOLI_CREATEUPDATETASK);
        oBjectValues.add(INT_Constants.CLICK_SESSIONID);
        oBjectValues.add(INT_Constants.CLICK_ATTACHMENT);
        oBjectValues.add(INT_Constants.CLICK_NOTIFICATION);
        oBjectValues.add(INT_Constants.WOLI_CREATEUPDATE_OPERATING_TASK);
        oBjectValues.add(INT_Constants.WOLI_CREATEUPDATE_COUNTERREADING_TASK);

        for (String eachOjectValue : oBjectValues) {
			Integration_Log__c iLog = new Integration_Log__c();
	    	iLog.Object__c =  eachOjectValue;
	        iLog.Object_Id__c = '1234567689';
	        iLog.Integration_Status__c = INT_Constants.INITIAL;
	        logLst.add(iLog);
    	}

    	insert logLst;

        IntegrationUserAndProfile__c integ = new IntegrationUserAndProfile__c(Click_Delete_Success_Logs__c = true, 
                                                                              Click_Token_Server__c = 'https://eu01-int.cloud.clicksoftware.com//SO/api/S3Token', 
                                                                              AWS_Endpoint__c = 'https://eu01-s3-store.s3.amazonaws.com/',
                                                                              AWS_Password__c = 'ClickJDE2016',
                                                                              AWS_Username__c = 'integration@JDEDev01');
        insert integ;
	}

   /**
    * @author        Paul Jarred Aguiling
    * @date          04.09.2018          
    * @description   Test method for execute.
    * @revision(s)
    */
    static testMethod void testExecute() {
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);

        System.runAs(u) {
        	setupTestData();
        	ClickSoapApiCallout csa = new ClickSoapApiCallout();
           	csa.iLogList = logLst;

           	Test.startTest();
        		System.enqueueJob(csa);
                System.assert(csa != null);
        	Test.stopTest();
        }
    }

   /**
    * @author        Paul Jarred Aguiling
    * @date          04.09.2018          
    * @description   Test method for execute.
    * @revision(s)
    */
    static testMethod void testExecute2() {
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);

        System.runAs(u) {
        	setupTestData();

        	List<Id> iLogListId = new List<Id>();
        	for (Integration_Log__c il : logLst) {
        		iLogListId.add(il.Id);
        	}

        	Test.startTest();
	        	ClickSoapApiCallout.execute2(iLogListId);
                System.assert(iLogListId != null);
        	Test.stopTest();
        }
    }
}