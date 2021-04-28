@isTest
public class ACN_APIHandlerTest {
  // public static ACN_MarketingCloud__mdt mockCustomMetadata(String mid) {
  //   return new ACN_MarketingCloud__mdt(
  //     Label = mid,
  //     DeveloperName = mid,
  //     Engagement__c = 'LWC_Engagement',
  //     EID__c = '111111111',
  //     mid__c = '999999999',
  //     SMSMessageId__c = 'MTo3ODow',
  //     Keyword__c = 'TEST',
  //     Engagement_History_Date_Range__c = 5
  //   );
  // }
  // public static List<ACN_MarketingCloud__mdt> mockCustomMetadata() {
  //   return new List<ACN_MarketingCloud__mdt>{
  //     new ACN_MarketingCloud__mdt(
  //       Label = 'Default',
  //       DeveloperName = 'Default,',
  //       Engagement__c = 'LWC_Engagement',
  //       EID__c = '111111111',
  //       mid__c = '222222222',
  //       SMSMessageId__c = 'MTo3ODow',
  //       Keyword__c = 'TEST',
  //       Engagement_History_Date_Range__c = 5
  //     ),
  //     new ACN_MarketingCloud__mdt(
  //       Label = 'Other',
  //       DeveloperName = 'Other',
  //       Engagement__c = 'LWC_Engagement_Other',
  //       EID__c = '111111111',
  //       mid__c = '111111111',
  //       SMSMessageId__c = 'MTo3ODow',
  //       Keyword__c = 'TEST',
  //       Engagement_History_Date_Range__c = 5
  //     )
  //   };
  // }

  @isTest
  public static void authSuccess() {
    Map<String, ACN_MarketingCloudMock.APIResponse> responseData = ACN_MarketingCloudMock.baseResponseData();

    Test.setMock(
      HttpCalloutMock.class,
      new ACN_MarketingCloudMock(responseData)
    );

    Test.startTest();
    // get Starting State cache (should be empty);
    ACN_APIHandler.AuthResponse authBefore = (ACN_APIHandler.AuthResponse) Cache.Org.get(
      'local.MarketingCloudOAuth.123'
    );
    ACN_APIHandler.AuthResponse res = ACN_APIHandler.authenticate('123');
    ACN_APIHandler.AuthResponse authAfter = (ACN_APIHandler.AuthResponse) Cache.Org.get(
      'local.MarketingCloudOAuth.123'
    );
    Test.stopTest();

    system.assertEquals(
      null,
      authBefore,
      'ACN_APIHandlerTest.authSuccess : cache is not empty when it should be'
    );
    system.assertNotEquals(
      null,
      authAfter,
      'ACN_APIHandlerTest.authSuccess : cache is empty but it shouldnt be'
    );

    system.assertEquals(
      'exampleaccesstoken',
      res.access_token,
      'ACN_APIHandlerTest.authSuccess : bad access_token'
    );
    system.assertEquals(
      'https://exampletenant.rest.marketingcloudapis.com/',
      res.rest_instance_url,
      'ACN_APIHandlerTest.authSuccess : bad rest_instance_url'
    );
    system.assertEquals(
      'https://exampletenant.soap.marketingcloudapis.com/',
      res.soap_instance_url,
      'ACN_APIHandlerTest.authSuccess : bad soap_instance_url'
    );
  }
  @isTest
  public static void authFailure() {
    Map<String, ACN_MarketingCloudMock.APIResponse> responseData = ACN_MarketingCloudMock.baseResponseData();
    //adding failure data
    responseData.put(
      'callout:MarketingCloudOAuth',
      new ACN_MarketingCloudMock.APIResponse(
        '{"error":"invalid_request","error_description":"Make sure that the client ID and client secret are valid and that the following parameters are not empty or null: client ID, client secret, and grant type.","error_uri":"https://developer.salesforce.com/docs"}',
        500
      )
    );

    Test.setMock(
      HttpCalloutMock.class,
      new ACN_MarketingCloudMock(responseData)
    );
    Test.startTest();
    try {
      ACN_APIHandler.authenticate('123');
      system.assert(false, 'Authentication error was not thrown');
    } catch (Exception ex) {
      system.assert(
        ex.getMessage().contains('error_description'),
        'error_description was not found in response: ' + ex.getMessage()
      );
    }

    Test.stopTest();
  }

  @isTest
  public static void restRequestSuccess() {
    Map<String, ACN_MarketingCloudMock.APIResponse> responseData = ACN_MarketingCloudMock.baseResponseData();
    responseData.put(
      'https://exampletenant.rest.marketingcloudapis.com/successendpoint',
      new ACN_MarketingCloudMock.APIResponse('{"status":"success"}', 200)
    );

    Test.setMock(
      HttpCalloutMock.class,
      new ACN_MarketingCloudMock(responseData)
    );
    Test.startTest();
    Map<String, Object> res = ACN_APIHandler.restRequest(
      '123',
      '{"Test":"Test"}',
      'POST',
      'successendpoint'
    );
    Test.stopTest();
    system.assertEquals(
      'success',
      (String) res.get('status'),
      'ACN_APIHandlerTest.restRequestSuccess : Bad response'
    );
  }
  @isTest
  public static void restRequestFailure() {
    Map<String, ACN_MarketingCloudMock.APIResponse> responseData = ACN_MarketingCloudMock.baseResponseData();
    responseData.put(
      'https://exampletenant.rest.marketingcloudapis.com/failendpoint',
      new ACN_MarketingCloudMock.APIResponse('{"Test":"Test"}', 500)
    );

    Test.setMock(
      HttpCalloutMock.class,
      new ACN_MarketingCloudMock(responseData)
    );
    Test.startTest();
    try {
      ACN_APIHandler.restRequest(
        '123',
        '{"Test":"Test"}',
        'POST',
        'failendpoint'
      );
      system.assert(false, 'REST error was not thrown');
    } catch (Exception ex) {
      system.assertEquals(
        'restRequest: Code=500 Status=null Message={"Test":"Test"}',
        ex.getMessage(),
        'ACN_APIHandlerTest.restRequestFailure : Bad error message'
      );
    }
    Test.stopTest();
  }
  @isTest
  public static void restRequestTokenExpired() {
    Map<String, ACN_MarketingCloudMock.APIResponse> responseData = ACN_MarketingCloudMock.baseResponseData();
    responseData.put(
      'https://exampletenant.rest.marketingcloudapis.com/tokenexpiredendpoint',
      new ACN_MarketingCloudMock.APIResponse(
        '{"documentation":"https://developer.salesforce.com/docs/atlas.en-us.mc-apis.meta/mc-apis/error-handling.htm","errorcode":0,"message":"Not Authorized"}',
        401
      )
    );

    Test.setMock(
      HttpCalloutMock.class,
      new ACN_MarketingCloudMock(responseData)
    );
    Test.startTest();
    try {
      ACN_APIHandler.restRequest(
        '123',
        '{"Test":"Test"}',
        'POST',
        'tokenexpiredendpoint'
      );
      system.assert(false, 'REST error was not thrown');
    } catch (Exception ex) {
      system.debug(ex);
      system.assertEquals(
        3,
        Limits.getCallouts(),
        'ACN_APIHandlerTest.restRequestTokenExpired : unexpected number of callouts made'
      );
      system.assertEquals(
        'restRequest: Code=401 Status=null Message={"documentation":"https://developer.salesforce.com/docs/atlas.en-us.mc-apis.meta/mc-apis/error-handling.htm","errorcode":0,"message":"Not Authorized"}',
        ex.getMessage(),
        'ACN_APIHandlerTest.soapRetrieveSimpleRequestTokenExpired : Error thrown was different than expected'
      );
    }
    Test.stopTest();
  }
  @isTest
  public static void soapRetrieveSimpleRequestSuccess() {
    Map<String, ACN_MarketingCloudMock.APIResponse> responseData = ACN_MarketingCloudMock.baseResponseData();
    responseData.put(
      'https://exampletenant.soap.marketingcloudapis.com/Service.asmx',
      new ACN_MarketingCloudMock.APIResponse(
        ACN_MarketingCloudMock.exampleSoapBody(
          'RetrieveResponse',
          '<RetrieveResponseMsg xmlns="http://exacttarget.com/wsdl/partnerAPI"><OverallStatus>OK</OverallStatus><RequestID>b9ceb6ea-89a8-46cd-b779-d808f7fbeeb1</RequestID><Results xsi:type="NotSentEvent"><PartnerKey xsi:nil="true" /><ObjectID xsi:nil="true" /><SendID>26287</SendID><SubscriberKey>0030Y00000M0EdLQAV</SubscriberKey><EventType>NotSent</EventType></Results><Results xsi:type="NotSentEvent"><PartnerKey xsi:nil="true" /><ObjectID xsi:nil="true" /><SendID>50466</SendID><SubscriberKey>0030Y00000M0EdLQAV</SubscriberKey><EventType>NotSent</EventType></Results></RetrieveResponseMsg>'
        ),
        200
      )
    );

    Test.setMock(
      HttpCalloutMock.class,
      new ACN_MarketingCloudMock(responseData)
    );
    List<String> properties = new List<String>{ 'EventType' };
    ACN_APIHandler.SimpleFilter filter = new ACN_APIHandler.SimpleFilter(
      'EventType',
      'equals',
      'NotSent'
    );
    Test.startTest();
    Map<String, Object> res = ACN_APIHandler.soapRequest(
      '123',
      ACN_APIHandler.soapFactoryRetrieve('NotSentEvent', properties, filter)
    );
    Test.stopTest();
    system.assertEquals(
      '{"RetrieveResponseMsg":{"Results":[{"EventType":"NotSent","SubscriberKey":"0030Y00000M0EdLQAV","SendID":"26287","ObjectID":"","PartnerKey":""},{"EventType":"NotSent","SubscriberKey":"0030Y00000M0EdLQAV","SendID":"50466","ObjectID":"","PartnerKey":""}],"RequestID":"b9ceb6ea-89a8-46cd-b779-d808f7fbeeb1","OverallStatus":"OK"}}',
      JSON.serialize(res, true),
      'ACN_APIHandlerTest.soapRetrieveSimpleRequestSuccess : Response was not matching'
    );
  }
  @isTest
  public static void soapRetrieveComplexRequestSuccess() {
    Map<String, ACN_MarketingCloudMock.APIResponse> responseData = ACN_MarketingCloudMock.baseResponseData();
    responseData.put(
      'https://exampletenant.soap.marketingcloudapis.com/Service.asmx',
      new ACN_MarketingCloudMock.APIResponse(
        ACN_MarketingCloudMock.exampleSoapBody(
          'RetrieveResponse',
          '<RetrieveResponseMsg xmlns="http://exacttarget.com/wsdl/partnerAPI"><OverallStatus>OK</OverallStatus><RequestID>b9ceb6ea-89a8-46cd-b779-d808f7fbeeb1</RequestID><Results xsi:type="NotSentEvent"><PartnerKey xsi:nil="true" /><ObjectID xsi:nil="true" /><SendID>26287</SendID><SubscriberKey>0030Y00000M0EdLQAV</SubscriberKey><EventType>NotSent</EventType></Results><Results xsi:type="NotSentEvent"><PartnerKey xsi:nil="true" /><ObjectID xsi:nil="true" /><SendID>50466</SendID><SubscriberKey>0030Y00000M0EdLQAV</SubscriberKey><EventType>NotSent</EventType></Results></RetrieveResponseMsg>'
        ),
        200
      )
    );

    Test.setMock(
      HttpCalloutMock.class,
      new ACN_MarketingCloudMock(responseData)
    );
    List<String> properties = new List<String>{ 'EventType' };
    ACN_APIHandler.SimpleFilter left = new ACN_APIHandler.SimpleFilter(
      'ContactKey',
      'equals',
      '0030Y00000M0EdLQAV'
    );
    ACN_APIHandler.SimpleFilter right = new ACN_APIHandler.SimpleFilter(
      'EventType',
      'equals',
      new List<String>{ 'NotSent', 'Sent' }
    );
    ACN_APIHandler.ComplexFilter cf = new ACN_APIHandler.ComplexFilter(
      left,
      'AND',
      right
    );
    Test.startTest();
    Map<String, Object> res = ACN_APIHandler.soapRequest(
      '123',
      ACN_APIHandler.soapFactoryRetrieve('NotSentEvent', properties, null, cf)
    );
    Test.stopTest();
    system.assertEquals(
      '{"RetrieveResponseMsg":{"Results":[{"EventType":"NotSent","SubscriberKey":"0030Y00000M0EdLQAV","SendID":"26287","ObjectID":"","PartnerKey":""},{"EventType":"NotSent","SubscriberKey":"0030Y00000M0EdLQAV","SendID":"50466","ObjectID":"","PartnerKey":""}],"RequestID":"b9ceb6ea-89a8-46cd-b779-d808f7fbeeb1","OverallStatus":"OK"}}',
      JSON.serialize(res, true),
      'ACN_APIHandlerTest.soapRetrieveComplexRequestSuccess : Response was not matching'
    );
  }

  @isTest
  public static void soapRetrieveSimpleRequestError() {
    Map<String, ACN_MarketingCloudMock.APIResponse> responseData = ACN_MarketingCloudMock.baseResponseData();
    responseData.put(
      'https://exampletenant.soap.marketingcloudapis.com/Service.asmx',
      new ACN_MarketingCloudMock.APIResponse(
        ACN_MarketingCloudMock.exampleSoapError(
          '<OverallStatus>Error: The Filter Property \'SubscriberKeya\' is not a retrievable property.</OverallStatus>'
        ),
        200
      )
    );

    Test.setMock(
      HttpCalloutMock.class,
      new ACN_MarketingCloudMock(responseData)
    );
    List<String> properties = new List<String>{ 'EventType' };
    ACN_APIHandler.SimpleFilter filter = new ACN_APIHandler.SimpleFilter(
      'EventType',
      'equals',
      'NotSent'
    );

    Test.startTest();
    try {
      ACN_APIHandler.soapRequest(
        '123',
        ACN_APIHandler.soapFactoryRetrieve('NotSentEvent', properties, filter)
      );
      system.assert(false, 'SOAP error was not thrown');
    } catch (Exception ex) {
      system.assertEquals(
        'Error: The Filter Property \'SubscriberKeya\' is not a retrievable property.',
        ex.getMessage(),
        'ACN_APIHandlerTest.soapRetrieveSimpleRequestError : Error thrown was different than expected'
      );
    }

    Test.stopTest();
  }

  @isTest
  public static void soapRetrieveTokenExpired() {
    Map<String, ACN_MarketingCloudMock.APIResponse> responseData = ACN_MarketingCloudMock.baseResponseData();
    responseData.put(
      'https://exampletenant.soap.marketingcloudapis.com/Service.asmx',
      new ACN_MarketingCloudMock.APIResponse(
        ACN_MarketingCloudMock.exampleSoapFault('Token Expired'),
        500
      )
    );

    Test.setMock(
      HttpCalloutMock.class,
      new ACN_MarketingCloudMock(responseData)
    );
    List<String> properties = new List<String>{ 'EventType' };
    ACN_APIHandler.SimpleFilter filter = new ACN_APIHandler.SimpleFilter(
      'EventType',
      'equals',
      'NotSent'
    );

    Test.startTest();
    try {
      ACN_APIHandler.soapRequest(
        '123',
        ACN_APIHandler.soapFactoryRetrieve('NotSentEvent', properties, filter)
      );
      system.assert(false, 'SOAP error was not thrown');
    } catch (Exception ex) {
      system.assertEquals(
        3,
        Limits.getCallouts(),
        'ACN_APIHandlerTest.soapRetrieveTokenExpired : unexpected number of callouts made'
      );
      system.assertEquals(
        'Code: q0:Security. Reason: Token Expired',
        ex.getMessage(),
        'ACN_APIHandlerTest.soapRetrieveSimpleRequestTokenExpired : Error thrown was different than expected'
      );
    }
    Test.stopTest();
  }

  @isTest
  public static void soapCreateRequestPropertiesSuccess() {
    Map<String, ACN_MarketingCloudMock.APIResponse> responseData = ACN_MarketingCloudMock.baseResponseData();
    responseData.put(
      'https://exampletenant.soap.marketingcloudapis.com/Service.asmx',
      new ACN_MarketingCloudMock.APIResponse(
        ACN_MarketingCloudMock.exampleSoapBody(
          'CreateResponse',
          '<CreateResponse xmlns="http://exacttarget.com/wsdl/partnerAPI"><Results><StatusCode>OK</StatusCode><StatusMessage>Data Extension created.</StatusMessage><OrdinalID>0</OrdinalID><NewID>0</NewID><NewObjectID>f6085316-484b-eb11-b81a-48df37d1de8b</NewObjectID><Object xsi:type="DataExtension"><PartnerKey xsi:nil="true" /><ObjectID>f6085316-484b-eb11-b81a-48df37d1de8b</ObjectID><CustomerKey>DougDevTraining</CustomerKey><Name>DougDevTraining</Name><IsSendable>true</IsSendable><SendableDataExtensionField><PartnerKey xsi:nil="true" /><ObjectID xsi:nil="true" /><CustomerKey>SubscriberKey</CustomerKey><Name>Subscriber Key</Name><FieldType>Text</FieldType></SendableDataExtensionField><SendableSubscriberField><Name>Subscriber Key</Name><Value /></SendableSubscriberField><Fields><Field><PartnerKey xsi:nil="true" /><ObjectID xsi:nil="true" /><CustomerKey>SubscriberKey</CustomerKey><Name>Subscriber Key</Name><MaxLength>50</MaxLength><IsRequired>true</IsRequired><IsPrimaryKey>true</IsPrimaryKey><FieldType>Text</FieldType></Field><Field><PartnerKey xsi:nil="true" /><ObjectID xsi:nil="true" /><CustomerKey>EmailAddress</CustomerKey><Name>Email Address</Name><IsRequired>true</IsRequired><IsPrimaryKey>true</IsPrimaryKey><FieldType>EmailAddress</FieldType></Field></Fields></Object></Results><RequestID>053c55a3-0b70-4fa4-8f6e-3a93cd95e812</RequestID><OverallStatus>OK</OverallStatus></CreateResponse>'
        ),
        200
      )
    );

    Test.setMock(
      HttpCalloutMock.class,
      new ACN_MarketingCloudMock(responseData)
    );
    List<List<ACN_APIHandler.soapProperty>> objects = new List<List<ACN_APIHandler.soapProperty>>{
      new List<ACN_APIHandler.soapProperty>{
        new ACN_APIHandler.soapProperty(
          'Test',
          'true',
          new List<ACN_APIHandler.soapProperty>()
        )
      }
    };
    Test.startTest();
    Map<String, Object> res = ACN_APIHandler.soapRequest(
      '123',
      ACN_APIHandler.soapFactoryCreate('Data Extension', objects, true)
    );
    Test.stopTest();
    system.assert(
      res.keySet().equals(new Set<String>{ 'CreateResponse' }),
      'ACN_APIHandlerTest.soapCreateRequestPropertiesSuccess : Response key was not matching "CreateResponse"'
    );
  }
  @isTest
  public static void soapCreateRequestMapSuccess() {
    Map<String, ACN_MarketingCloudMock.APIResponse> responseData = ACN_MarketingCloudMock.baseResponseData();
    responseData.put(
      'https://exampletenant.soap.marketingcloudapis.com/Service.asmx',
      new ACN_MarketingCloudMock.APIResponse(
        ACN_MarketingCloudMock.exampleSoapBody(
          'CreateResponse',
          '<CreateResponse xmlns="http://exacttarget.com/wsdl/partnerAPI"><Results><StatusCode>OK</StatusCode><StatusMessage>Data Extension created.</StatusMessage><OrdinalID>0</OrdinalID><NewID>0</NewID><NewObjectID>f6085316-484b-eb11-b81a-48df37d1de8b</NewObjectID><Object xsi:type="DataExtension"><PartnerKey xsi:nil="true" /><ObjectID>f6085316-484b-eb11-b81a-48df37d1de8b</ObjectID><CustomerKey>DougDevTraining</CustomerKey><Name>DougDevTraining</Name><IsSendable>true</IsSendable><SendableDataExtensionField><PartnerKey xsi:nil="true" /><ObjectID xsi:nil="true" /><CustomerKey>SubscriberKey</CustomerKey><Name>Subscriber Key</Name><FieldType>Text</FieldType></SendableDataExtensionField><SendableSubscriberField><Name>Subscriber Key</Name><Value /></SendableSubscriberField><Fields><Field><PartnerKey xsi:nil="true" /><ObjectID xsi:nil="true" /><CustomerKey>SubscriberKey</CustomerKey><Name>Subscriber Key</Name><MaxLength>50</MaxLength><IsRequired>true</IsRequired><IsPrimaryKey>true</IsPrimaryKey><FieldType>Text</FieldType></Field><Field><PartnerKey xsi:nil="true" /><ObjectID xsi:nil="true" /><CustomerKey>EmailAddress</CustomerKey><Name>Email Address</Name><IsRequired>true</IsRequired><IsPrimaryKey>true</IsPrimaryKey><FieldType>EmailAddress</FieldType></Field></Fields></Object></Results><RequestID>053c55a3-0b70-4fa4-8f6e-3a93cd95e812</RequestID><OverallStatus>OK</OverallStatus></CreateResponse>'
        ),
        200
      )
    );

    Test.setMock(
      HttpCalloutMock.class,
      new ACN_MarketingCloudMock(responseData)
    );
    List<Map<String, String>> objects = new List<Map<String, String>>{
      new Map<String, String>{ 'Test' => 'true' }
    };
    Test.startTest();
    Map<String, Object> res = ACN_APIHandler.soapRequest(
      '123',
      ACN_APIHandler.soapFactoryCreate('Data Extension', objects, true)
    );
    Test.stopTest();
    system.assert(
      res.keySet().equals(new Set<String>{ 'CreateResponse' }),
      'ACN_APIHandlerTest.soapCreateRequestMapSuccess : Response key was not matching "CreateResponse"'
    );
  }
  @isTest
  public static void soapUpdateRequestSuccess() {
    Map<String, ACN_MarketingCloudMock.APIResponse> responseData = ACN_MarketingCloudMock.baseResponseData();
    responseData.put(
      'https://exampletenant.soap.marketingcloudapis.com/Service.asmx',
      new ACN_MarketingCloudMock.APIResponse(
        ACN_MarketingCloudMock.exampleSoapBody(
          'UpdateResponse',
          '<UpdateResponse xmlns="http://exacttarget.com/wsdl/partnerAPI"><Results><StatusCode>OK</StatusCode><StatusMessage>Data Extension updated.</StatusMessage><OrdinalID>0</OrdinalID><Object xsi:type="DataExtension"><PartnerKey xsi:nil="true" /><ObjectID>f6085316-484b-eb11-b81a-48df37d1de8b</ObjectID><CustomerKey>DougDevTrainingUpdated</CustomerKey></Object></Results><RequestID>e548a938-2f73-4d04-bd5f-bffdbbbda0d9</RequestID><OverallStatus>OK</OverallStatus></UpdateResponse>'
        ),
        200
      )
    );

    Test.setMock(
      HttpCalloutMock.class,
      new ACN_MarketingCloudMock(responseData)
    );
    List<Map<String, String>> objects = new List<Map<String, String>>{
      new Map<String, String>{ 'Test' => 'true' }
    };
    Test.startTest();
    Map<String, Object> res = ACN_APIHandler.soapRequest(
      '123',
      ACN_APIHandler.soapFactoryUpdate('Data Extension', objects)
    );
    Test.stopTest();
    system.assert(
      res.keySet().equals(new Set<String>{ 'UpdateResponse' }),
      'ACN_APIHandlerTest.soapUpdateRequestSuccess : Response key was not matching "UpdateResponse"'
    );
  }
}