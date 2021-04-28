/*************************************************************
@Name: APTS_OrderLineItemWrapperTest
@Author: Galin Georgiev
@CreateDate: 19-02-2018
@Description: Order line item wrapper test class 
@UsedBy: APTS_OrderLineItemWrapper
******************************************************************/
//v100 19-02-2018 Galin Georgiev: Initial version.
//Comments in this format are mandatory for each change of code.
//Adding code comment example: v100++<< means start of changes and v100++>> means end of changes
//Removing code comment example: v100--<< means start of changes and v100-->> means end of changes

@isTest
private with sharing class APTS_OrderLineItemWrapperTest {

	@isTest static void test_OrderLineItemWrapper() {

		test.startTest();

		APTS_OrderLineItemWrapper oOrderLineItemWrapper = new APTS_OrderLineItemWrapper();
		APTS_OrderLineItemWrapper oOrderLineItemWrapper1 = new APTS_OrderLineItemWrapper(true, null, 1);

		test.stopTest();		
	}

}