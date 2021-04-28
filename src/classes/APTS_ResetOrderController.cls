/*************************************************************
@Name: APTS_ResetOrderController
@Author: Galin Georgiev
@CreateDate: 06-12-2018
@Description:
@UsedBy:
******************************************************************/
//v100 06-12-2018 Galin Georgiev: Initial version.
//Comments in this format are mandatory for each change of code.
//Adding code comment example: v100++<< means start of changes and v100++>> means end of changes
//Removing code comment example: v100--<< means start of changes and v100-->> means end of changes

public with sharing class APTS_ResetOrderController {

	private Id orderId;

	public APTS_ResetOrderController() {

		orderId = ApexPages.currentPage().getParameters().get(APTS_OrderConstants.ID);
	}

	public PageReference resetOrder() {

		PageReference pageRef;

		List<Apttus_Config2__Order__c> orderList = [SELECT APTS_Lock_Order__c FROM Apttus_Config2__Order__c WHERE Id = : orderId LIMIT 1];

		if (!orderList.isEmpty()) {

			orderList[0].APTS_Lock_Order__c = false;
			orderList[0].Approval_Status__c = 'Not Submitted'; 

			APTS_OrderUtils.stopOrderTrigger();
			Database.update(orderList);
			APTS_OrderUtils.startOrderTrigger();
		}

		pageRef = new PageReference('/' + orderId);

		return pageRef;
	}
}