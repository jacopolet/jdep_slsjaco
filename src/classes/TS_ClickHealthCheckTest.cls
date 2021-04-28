/**
* @author        Abram Vixen Reyes
* @date          Feb 2, 2019
* @description   Test Class for TS_ClickHealthCheck
* @revision(s)
*/
@isTest
public with sharing class TS_ClickHealthCheckTest {
	static testMethod void test_CheckServerHealth(){
		Test.setMock(WebServiceMock.class, new TS_ClickHealthCheck_Mock());

		TS_ClickHealthCheck.CheckServerHealth_element CheckServerHealth_element = new TS_ClickHealthCheck.CheckServerHealth_element();
		TS_ClickHealthCheck.OptionalParameters_element OptionalParameters_element = new TS_ClickHealthCheck.OptionalParameters_element();
		TS_ClickHealthCheck.CheckServerHealthResponse_element CheckServerHealthResponse_element = new TS_ClickHealthCheck.CheckServerHealthResponse_element();
		TS_ClickHealthCheck.JDEServiceOptimizationPort JDEServiceOptimizationPort = new TS_ClickHealthCheck.JDEServiceOptimizationPort();

		Test.startTest();
			String respReturn = JDEServiceOptimizationPort.CheckServerHealth();
		Test.stopTest();

		System.assertEquals(respReturn, 'Success');
	}
}