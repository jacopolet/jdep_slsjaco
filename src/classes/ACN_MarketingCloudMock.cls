@isTest
global class ACN_MarketingCloudMock implements HttpCalloutMock {
  private Map<String, APIResponse> responseMap;
  public ACN_MarketingCloudMock(Map<String, APIResponse> responseMap) {
    this.responseMap = responseMap;
  }

  public class APIResponse {
    String message;
    Integer httpCode;
    public APIResponse(String message, Integer httpCode) {
      this.message = message;
      this.httpCode = httpCode;
    }
  }
  @TestVisible
  private static Map<String, APIResponse> baseResponseData() {
    return new Map<String, APIResponse>{
      'callout:MarketingCloudOAuth' => new APIResponse(
        '{"access_token":"exampleaccesstoken","token_type":"Bearer","expires_in":1079,"scope":"examplescope","soap_instance_url":"https://exampletenant.soap.marketingcloudapis.com/","rest_instance_url":"https://exampletenant.rest.marketingcloudapis.com/"}',
        200
      )
    };
  }

  global HTTPResponse respond(HTTPRequest request) {
    HttpResponse res = new HttpResponse();
    res.setHeader('Content-Type', request.getHeader('Content-Type'));
    system.debug(request.getEndpoint());
    if (this.responseMap.get(request.getEndpoint()) == null) {
      // not in response map send 404 response
      res.setStatusCode(404);
      if (request.getHeader('Content-Type').contains('application/json')) {
        // check that the inbound payload is actually valid json
        JSON.deserializeUntyped(request.getBody());
        res.setBody(
          '{"documentation":"https://developer.salesforce.com/docs/atlas.en-us.mc-apis.meta/mc-apis/error-handling.htm","errorcode":404,"message":"Not Found"}'
        );
      } else {
        //check that the inbound payload is actually valid xml
        XMLSerializer serializer = new XMLSerializer();
        try {
          serializer.deSerializeUnTyped(request.getBody());
          res.setBody(
            '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd"><html xmlns="http://www.w3.org/1999/xhtml"><body><div id="header"><h1>Server Error</h1></div></body></html>'
          );
        } catch (Exception ex) {
          // if invalid xml then server responds with bad request
          res.setBody('Bad Request');
        }
      }
    } else {
      APIResponse resMap = this.responseMap.get(request.getEndpoint());
      res.setStatusCode(resMap.httpCode);
      res.setBody(resMap.message);
    }
    return res;
  }
  //this is used by all the following examples
  final private static String ENV1 = '<?xml version="1.0" encoding="utf-8"?><soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:wsa="http://schemas.xmlsoap.org/ws/2004/08/addressing" xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd" xmlns:wsu="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd"><env:Header xmlns:env="http://www.w3.org/2003/05/soap-envelope"><wsa:Action>';
  final private static String ENV2 = '</wsa:Action><wsa:MessageID>urn:uuid:ee50c580-754c-4ded-841e-b10f8def0241</wsa:MessageID><wsa:RelatesTo>urn:uuid:7e0cca04-57bd-4481-864c-6ea8039d2ea0</wsa:RelatesTo><wsa:To>http://schemas.xmlsoap.org/ws/2004/08/addressing/role/anonymous</wsa:To><wsse:Security><wsu:Timestamp wsu:Id="Timestamp-1f59f358-4b15-48f2-81e5-106e30cd6d48"><wsu:Created>2020-12-29T16:33:23Z</wsu:Created><wsu:Expires>2020-12-29T16:38:23Z</wsu:Expires></wsu:Timestamp></wsse:Security></env:Header><soap:Body>';
  final private static String ENV3 = '</soap:Body></soap:Envelope>';
  @TestVisible
  private static String exampleSoapFault(String replaceWith) {
    return (ENV1 +
      'http://schemas.xmlsoap.org/ws/2004/08/addressing/fault</wsa:Action><wsa:MessageID>urn:uuid:aa01474f-5868-4165-8c65-c9a58f05bc78</wsa:MessageID><wsa:RelatesTo>urn:uuid:7e0cca04-57bd-4481-864c-6ea8039d2ea0</wsa:RelatesTo><wsa:To>http://schemas.xmlsoap.org/ws/2004/08/addressing/role/anonymous</wsa:To><wsse:Security><wsu:Timestamp wsu:Id="Timestamp-ce9f16b2-1997-406f-a3c4-da5b1a354a5c"><wsu:Created>2020-12-29T09:59:38Z</wsu:Created><wsu:Expires>2020-12-29T10:04:38Z</wsu:Expires></wsu:Timestamp></wsse:Security></env:Header><soap:Body><soap:Fault><soap:Code><soap:Value xmlns:q0="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd">q0:Security</soap:Value></soap:Code><soap:Reason><soap:Text xml:lang="en">{{toReplace}}</soap:Text></soap:Reason><soap:Node>https://mc-wq0dnnwwpgg455p7nkxw1b0my.soap.marketingcloudapis.com/Service.asmx</soap:Node></soap:Fault></soap:Body></soap:Envelope>')
      .replace('{{toReplace}}', replaceWith);
  }
  @TestVisible
  private static String exampleSoapError(String replaceWith) {
    return (ENV1 +
      'RetrieveResponse</wsa:Action><wsa:MessageID>urn:uuid:b2ba3824-67fe-4e24-93b8-f8d1cdacf4d6</wsa:MessageID><wsa:RelatesTo>urn:uuid:7e0cca04-57bd-4481-864c-6ea8039d2ea0</wsa:RelatesTo><wsa:To>http://schemas.xmlsoap.org/ws/2004/08/addressing/role/anonymous</wsa:To><wsse:Security><wsu:Timestamp wsu:Id="Timestamp-1e5ed425-a725-4982-90f3-c5a385764a55"><wsu:Created>2020-12-30T15:30:58Z</wsu:Created><wsu:Expires>2020-12-30T15:35:58Z</wsu:Expires></wsu:Timestamp></wsse:Security></env:Header><soap:Body><RetrieveResponseMsg xmlns="http://exacttarget.com/wsdl/partnerAPI">{{toReplace}}<RequestID>8bdd3a71-85c0-4c1c-878b-11af49460db0</RequestID></RetrieveResponseMsg></soap:Body></soap:Envelope>')
      .replace('{{toReplace}}', replaceWith);
  }
  @TestVisible
  private static String exampleSoapBody(String type, String main) {
    return ENV1 + type + ENV2 + main + ENV3;
  }
}

/*
    // Success Responses
    if (this.resultType == MockResultType.SUCCESS) {
      res.setStatusCode(200);
      if (request.getEndpoint().contains('MarketingCloudOAuth')) {
        res.setBody(
          '{"access_token":"access_token","expires_in":1200,"token_type":"Bearer","rest_instance_url":"tenant.rest.marketingcloudapis.com/","soap_instance_url":"tenant.soap.marketingcloudapis.com/","scope": "email_read email_write email_send"}'
        );
      } else if (this.customResponse != null) {
        res.setBody(this.customResponse);
      } else if (
        request.getEndpoint()
          .contains('tenant.rest.marketingcloudapis.com/response/success')
      ) {
        res.setBody('{"status":"success"}');
      } else if (
        request.getEndpoint().contains('tenant.soap.marketingcloudapis.com') &&
        request.getBody().contains('RetrieveRequestMsg')
      ) {
        res.setBody(setXmlBody('RetrieveResponseMsg'));
      } else if (
        request.getEndpoint().contains('tenant.soap.marketingcloudapis.com') &&
        request.getBody().contains('UpdateRequest')
      ) {
        res.setBody(setXmlBody('UpdateResponse'));
      } else if (
        request.getEndpoint().contains('tenant.soap.marketingcloudapis.com') &&
        request.getBody().contains('CreateRequest')
      ) {
        res.setBody(setXmlBody('CreateResponse'));
      } else if (
        request.getEndpoint()
          .contains(
            'tenant.rest.marketingcloudapis.com/messaging/v1/messageDefinitionSends/'
          ) && request.getEndpoint().endsWith('/send')
      ) {
        Map<String, Object> o = (Map<String, Object>) JSON.deserializeUntyped(
          request.getBody()
        );
        Map<String, Object> oTo = (Map<String, Object>) o.get('To');
        system.assert(oTo != null, 'To value must be populated');
        system.assert(
          oTo.get('Address') != null,
          'To.Address value must be populated'
        );
        system.assert(
          oTo.get('ContactAttributes') != null,
          'To.ContactAttributes value must be populated'
        );
        system.assert(
          oTo.get('SubscriberKey') != null,
          'To.SubscriberKey value must be populated'
        );
        system.assertEquals('POST', request.getMethod());
        res.setBody('{"status":"success"}');
      } else if (
        request.getEndpoint()
          .contains(
            'tenant.rest.marketingcloudapis.com/messaging/v1/messageDefinitionSends/'
          ) && request.getEndpoint().endsWith('/sendBatch')
      ) {
        List<Object> oList = (List<Object>) JSON.deserializeUntyped(
          request.getBody()
        );
        Map<String, Object> o = (Map<String, Object>) oList[0];
        Map<String, Object> oTo = (Map<String, Object>) o.get('To');
        system.assert(oTo != null, 'To value must be populated');
        system.assert(
          oTo.get('Address') != null,
          'To.Address value must be populated'
        );
        system.assert(
          oTo.get('ContactAttributes') != null,
          'To.ContactAttributes value must be populated'
        );
        system.assert(
          oTo.get('SubscriberKey') != null,
          'To.SubscriberKey value must be populated'
        );
        system.assertEquals('POST', request.getMethod());
        res.setBody('{"status":"success"}');
      }
    } else {
      // Error Responses
      res.setStatusCode(400);
      if (request.getEndpoint().contains('MarketingCloudOAuth')) {
        res.setBody(
          '{"error": "Test_invalid_client","error_description": "Test : Invalid client ID. Use the client ID in Marketing Cloud Installed Packages.","error_uri": "https://developer.salesforce.com/docs"}'
        );
      } else if (this.customResponse != null) {
        res.setBody(this.customResponse);
      } else if (
        request.getEndpoint()
          .contains('tenant.rest.marketingcloudapis.com/response/failure')
      ) {
        res.setStatus('Test Error');
      } else if (
        request.getEndpoint().contains('tenant.soap.marketingcloudapis.com') &&
        request.getBody().contains('RetrieveRequestMsg')
      ) {
        res.setBody(
          '<?xml version="1.0" encoding="utf-8"?>' +
          '<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:wsa="http://schemas.xmlsoap.org/ws/2004/08/addressing" xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd" xmlns:wsu="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd">' +
          '<soap:Body>' +
          '<RetrieveResponseMsg xmlns="http://exacttarget.com/wsdl/partnerAPI">' +
          '<Results xsi:type="Retrieve">' +
          '<StatusCode>Error</StatusCode>' +
          '<StatusMessage>Test failure soap response</StatusMessage>' +
          '</Results>' +
          '</RetrieveResponseMsg>' +
          '</soap:Body>' +
          '</soap:Envelope>'
        );
      } else if (
        request.getEndpoint().contains('tenant.soap.marketingcloudapis.com') &&
        request.getBody().contains('FaultString')
      ) {
        res.setBody('FaultString');
      } else if (
        request.getEndpoint().contains('tenant.soap.marketingcloudapis.com') &&
        request.getBody().contains('FaultRetry')
      ) {
        res.setBody(setXmlFaultReason('Token Expired'));
      }
    }
    return res;
  }

  private static String setXmlBody(String replaceWith) {
    return ('<?xml version="1.0" encoding="utf-8"?>' +
      '<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:wsa="http://schemas.xmlsoap.org/ws/2004/08/addressing" xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd" xmlns:wsu="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd">' +
      '<soap:Body>' +
      '<{{toReplace}} xmlns="http://exacttarget.com/wsdl/partnerAPI">' +
      '<OverallStatus>OK</OverallStatus>' +
      '<Results xsi:type="Retrieve">' +
      '<PartnerKey xsi:nil="true" />' +
      '<ObjectID xsi:nil="true" />' +
      '<Test>true</Test>' +
      '</Results>' +
      '</{{toReplace}}>' +
      '</soap:Body>' +
      '</soap:Envelope>')
      .replace('{{toReplace}}', replaceWith);
  };
  private static String setXmlFaultReason(String replaceWith) {
    return ('<?xml version="1.0" encoding="utf-8"?><soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:wsa="http://schemas.xmlsoap.org/ws/2004/08/addressing" xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd" xmlns:wsu="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd"><env:Header xmlns:env="http://www.w3.org/2003/05/soap-envelope"><wsa:Action>http://schemas.xmlsoap.org/ws/2004/08/addressing/fault</wsa:Action><wsa:MessageID>urn:uuid:aa01474f-5868-4165-8c65-c9a58f05bc78</wsa:MessageID><wsa:RelatesTo>urn:uuid:7e0cca04-57bd-4481-864c-6ea8039d2ea0</wsa:RelatesTo><wsa:To>http://schemas.xmlsoap.org/ws/2004/08/addressing/role/anonymous</wsa:To><wsse:Security><wsu:Timestamp wsu:Id="Timestamp-ce9f16b2-1997-406f-a3c4-da5b1a354a5c"><wsu:Created>2020-12-29T09:59:38Z</wsu:Created><wsu:Expires>2020-12-29T10:04:38Z</wsu:Expires></wsu:Timestamp></wsse:Security></env:Header><soap:Body><soap:Fault><soap:Code><soap:Value xmlns:q0="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd">q0:Security</soap:Value></soap:Code><soap:Reason><soap:Text xml:lang="en">{{toReplace}}</soap:Text></soap:Reason><soap:Node>https://mc-wq0dnnwwpgg455p7nkxw1b0my.soap.marketingcloudapis.com/Service.asmx</soap:Node></soap:Fault></soap:Body></soap:Envelope>')
      .replace('{{toReplace}}', replaceWith);
  }
  */