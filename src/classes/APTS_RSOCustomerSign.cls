/*************************************************************
@Name: APTS_RSOSyncDataWebService
@Author: Neev Shah
@CreateDate: 22-05-2018
@Description: Return Routes Info, Contracted Products
******************************************************************/
@RestResource(urlMapping='/RSOOrder/CustomerSignature/*')
global with sharing class APTS_RSOCustomerSign {

	
	@HttpPost
    global static void getRouteInfo(String SourceOrderNumber, String ImageString, String SAPEmpEmail, String FileName) {
    	system.debug('req body SourceOrderNumber = ' + SourceOrderNumber);
    	system.debug('req body imageString = ' + imageString);

    	if(String.isNotBlank(SourceOrderNumber) && String.isNotBlank(imageString)){
    		String sMsg = 'Customer Signature';
	    	APTS_Order_Interface_Log__c oInterfaceLogs = APTS_RSOOrderUtils.getInterfaceLog(null, 0, 0, SourceOrderNumber,'', null, 'RSOApp');
	    	if(oInterfaceLogs != null){
	    		oInterfaceLogs.APTS_Type__c = 'Attachment';
	    		insert oInterfaceLogs;

	    		if(String.isNotBlank(oInterfaceLogs.Id)){
		    		Attachment attach = new Attachment();
					attach.contentType = 'png';
					attach.name = 'CustomerSignature_' + SourceOrderNumber +  '.png';
					attach.parentId = oInterfaceLogs.Id;
					attach.body = EncodingUtil.base64Decode(imageString);
					insert attach;
					
					system.debug('attach ' + attach.Id);
		    	}
	    	}
		}
	}
}