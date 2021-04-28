/*
* @author        Marvin Gatchalian
* @date          8.mar.2018          
* @description   Test class for TS_ProductsWrapper
* @revision(s)
*/


@isTest
public with sharing class TS_ProductsWrapper_Test {

    private static testMethod void TS_ProductsWrapper() {
		
		Test.startTest();
			Map <Integer, TS_ProductsWrapper> intWrapperMap = new Map <Integer, TS_ProductsWrapper>();
			
		    TS_ProductsWrapper pw = new TS_ProductsWrapper();
        	pw.listPrice = 1;
        	pw.salesOrg = '0333';
        	intWrapperMap.put(0, pw);
        	
        	TS_ProductsWrapper pwCheck = new TS_ProductsWrapper();
        	pwCheck = intWrapperMap.get(0);
        	system.assertequals(pwCheck.listPrice, 1);
        	system.assertequals(pwCheck.salesOrg, '0333');
		Test.stopTest();
	    	
    }
}