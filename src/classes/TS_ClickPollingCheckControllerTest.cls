/**
* @author        Abram Vixen Reyes
* @date          Feb 2, 2019
* @description   Test Class for TS_ClickPollingCheckController
* @revision(s)
*/
@IsTest
public with sharing class TS_ClickPollingCheckControllerTest {
	static testMethod void test_getStatus(){
		Test.setMock(WebServiceMock.class, new TS_ClickHealthCheck_Mock());

		Test.startTest();
			String respReturn = TS_ClickPollingCheckController.getStatus();
		Test.stopTest();

		System.assertEquals(respReturn, 'Success');
	}
    
    static testMethod void test_getStatusException(){
        TS_ClickHealthCheck_Mock mockWebService = new TS_ClickHealthCheck_Mock();
        mockWebService.hasException = true;
        
		Test.setMock(WebServiceMock.class, mockWebService);

		Test.startTest();
			String respReturn = TS_ClickPollingCheckController.getStatus();
		Test.stopTest();
        
        System.assertEquals(respReturn, null);
        
	}
}