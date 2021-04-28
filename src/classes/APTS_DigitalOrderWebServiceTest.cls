/*************************************************************
@Name: APTS_DigitalOrderWebService
@Author: Hariharan
@CreateDate: 12-04-2018
@Description: Test class for APTS_DigitalOrderWebService
******************************************************************/
@isTest
public class APTS_DigitalOrderWebServiceTest{  
    private static testMethod void testWebService(){
        APTS_DOEPIReqWrapper jsonInput = new APTS_DOEPIReqWrapper();
        jsonInput.SourceOrderNumber = 'sn-1233';
        String jSONClass =JSON.serialize(jsonInput);     
        test.startTest();
        RestRequest request = new RestRequest();
        RestResponse res = new RestResponse();
        request.requestUri = '/services/apexrest/DigitalOrder/';
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueof(jSONClass);
        RestContext.request = request;
        RestContext.response= res;
        APTS_DigitalOrderWebService.createDigitalOrder();
        test.stopTest();
    }

    private static testMethod void testSourceException(){
        APTS_DOEPIReqWrapper jsonInput = new APTS_DOEPIReqWrapper();
        String jSONClass =JSON.serialize(jsonInput);     
        test.startTest();
        RestRequest request = new RestRequest();
        RestResponse res = new RestResponse();
        request.requestUri = '/services/apexrest/DigitalOrder/';
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueof(jSONClass);
        RestContext.request = request;
        RestContext.response= res;
        APTS_DigitalOrderWebService.createDigitalOrder();
        test.stopTest();
    }

    private static testMethod void testLargeString(){   
        APTS_DOEPIReqWrapper jsonInput = new APTS_DOEPIReqWrapper();
        jsonInput.SourceOrderNumber = 'sn-1233';
        jsonInput.BillToCity = 'sn-1233323232323232';
        String jSONClass =JSON.serialize(jsonInput);
        while(jSONClass.length() < 131072){
            jSONClass = ',' + jSONClass;
        }
        test.startTest();
        RestRequest request = new RestRequest();
        RestResponse res = new RestResponse();
        request.requestUri = '/services/apexrest/DigitalOrder/';
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueof(jSONClass);
        RestContext.request = request;
        RestContext.response= res;
        APTS_DigitalOrderWebService.createDigitalOrder();
        test.stopTest();
    }
}