/*************************************************************
@Name: APTS_ATPResultWrapperTest
@Author: Galin Georgiev
@CreateDate: 19-02-2018
@Description: ATP result wrapper test class 
@UsedBy: APTS_ATPResultWrapper
******************************************************************/
//v100 19-02-2018 Galin Georgiev: Initial version.
//Comments in this format are mandatory for each change of code.
//Adding code comment example: v100++<< means start of changes and v100++>> means end of changes
//Removing code comment example: v100--<< means start of changes and v100-->> means end of changes

@isTest
private with sharing class APTS_ATPResultWrapperTest {

	@isTest static void test_ATPResultWrapper() {

		test.startTest();

		APTS_ATPResultWrapper oATPResultWrapper = new APTS_ATPResultWrapper();		
		APTS_ATPResultWrapper oATPResultWrapper1 = new APTS_ATPResultWrapper(null, null, null);		

		test.stopTest();		
	}
}