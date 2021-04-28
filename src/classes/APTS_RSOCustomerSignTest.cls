@isTest
private class APTS_RSOCustomerSignTest {
	
	@isTest static void test_getRouteInfo() {
		JSONGenerator gen = JSON.createGenerator(true);
        gen.writeStartObject();
        gen.writeStringField('SAPEmpEmail', 'testRSO@JDECoffee.com');
        gen.writeStringField('SourceOrderNumber', 'testRSO1');
        gen.writeStringField('ImageString', 'testRSO@JDECoffee.com');
        gen.writeStringField('FileName', 'testRSO.png');
        gen.writeEndObject();
        String jSONClass = gen.getAsString();
 
        test.startTest();
        RestRequest request = new RestRequest();
        RestResponse res = new RestResponse();
        request.requestUri = '/services/apexrest/RSOOrder/SyncData/';
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueof(jSONClass);
        RestContext.request = request;
        RestContext.response= res;
        APTS_RSOCustomerSign.getRouteInfo('testRSO', 'testRSO', 'testRSO@JDECoffee.com', 'testRSO.png');

        List<APTS_Order_Interface_Log__c> listLogs = [SELECT Id FROM APTS_Order_Interface_Log__c LIMIT 1];
        System.assertEquals(TRUE, !listLogs.isEmpty());
        if(!listLogs.isEmpty()){
        	List<Attachment> listAttachment = [SELECT Id FROM Attachment WHERE parentId = :listLogs[0].Id];
        	System.assertEquals(TRUE, !listAttachment.isEmpty());
        }
        test.stopTest();
	}
}