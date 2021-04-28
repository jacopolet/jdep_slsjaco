/**
 * Class Name 	: ACN_APIHandler
 * Tested In  	: ACN_APIHandlerTest
 */
public class ACN_ApiHandler {
  final public static String nsMC = 'http://exacttarget.com/wsdl/partnerAPI';
  final public static String nsSoap = 'http://schemas.xmlsoap.org/soap/envelope/';
  final public static String nsAddressing = 'http://schemas.xmlsoap.org/ws/2004/08/addressing';
  final public static String xsi = 'http://www.w3.org/2001/XMLSchema-instance';
  final public static String xsd = 'http://www.w3.org/2001/XMLSchema';
  final public static Integer retryAttempts = 1;
  final public static String credentialName = 'MarketingCloudOAuth';
  private class APIHandlerException extends Exception {
    Integer statusCode;
    String status;
    String source;
    string body;
    private APIHandlerException(
      String source,
      HttpResponse res,
      string message
    ) {
      this.statusCode = Integer.valueOf(res.getStatusCode());
      this.status = res.getStatus();
      this.source = source;
      this.body = res.getBody();
      // LogHelper.pushLog(
      //   'E',
      //   'ACN_APIHandler',
      //   source,
      //   'ERROR response from request',
      //   'status : ' +
      //   res.getStatus() +
      //   ', status code : ' +
      //   res.getStatusCode() +
      //   ', body : ' +
      //   res.getBody(),
      //   null
      // );
      this.setMessage(
        message == null
          ? source +
            ': Code=' +
            res.getStatusCode() +
            ' Status=' +
            res.getStatus() +
            ' Message=' +
            res.getBody()
          : message
      );
    }
  }
  private class AuthRequest {
    private String grant_type;
    private String client_id;
    private String client_secret;
    private Integer account_id;
  }
  @TestVisible
  private class AuthResponse {
    @TestVisible
    private String access_token;
    @TestVisible
    private String token_type;
    @TestVisible
    private Integer expires_in;
    @TestVisible
    private String scope;
    @TestVisible
    private String soap_instance_url;
    @TestVisible
    private String rest_instance_url;
  }

  /**
   * function for authentication into Maerketing Cloud.
   * Creates authObject with access token and instance urls into Org Cache.
   * @param {String} mid - Marketing Cloud instance id
   * @return {AuthResponse} authObject - response from the MC auth request
   */
  public static AuthResponse authenticate(String mid) {
    // LogHelper.pushLog(
    //   'L',
    //   'ACN_APIHandler',
    //   'authenticate',
    //   'input parameters',
    //   'mid ' + mid,
    //   null
    // );
    // Get a cached value if in platform cache
    AuthResponse authObject = (AuthResponse) Cache.Org.get(
      'local.' +
      credentialName +
      '.' +
      mid
    );
    if (authObject == null) {
      Http http = new Http();
      HttpRequest req = new HttpRequest();
      req.setEndpoint('callout:' + credentialName);
      req.setMethod('POST');
      req.setHeader('Content-Type', 'application/json;charset=UTF-8');
      AuthRequest obj = new AuthRequest();
      obj.grant_type = 'client_credentials';
      obj.client_id = '{!$Credential.UserName}';
      obj.client_secret = '{!$Credential.Password}';
      obj.account_id = integer.valueof(mid);

      // Set the body as a JSON object
      req.setBody(JSON.Serialize(obj));
      // LogHelper.pushLog(
      //   'L',
      //   'ACN_APIHandler',
      //   'authenticate',
      //   'request to be sent',
      //   'endpoint : ' +
      //   req.getEndpoint() +
      //   ', credential name : ' +
      //   credentialName +
      //   ', method : ' +
      //   req.getMethod() +
      //   ', body : ' +
      //   req.getBody(),
      //   null
      // );
      HttpResponse res = http.send(req);
      // LogHelper.pushLog(
      //   'L',
      //   'ACN_APIHandler',
      //   'authenticate',
      //   'response from request',
      //   'status : ' +
      //   res.getStatus() +
      //   ', status code : ' +
      //   res.getStatusCode() +
      //   ', body : ' +
      //   res.getBody(),
      //   null
      // );
      // Parse the JSON response
      if (res.getStatusCode() != 200) {
        throw new APIHandlerException('authenticate', res, null);
      } else {
        authObject = (AuthResponse) JSON.deserialize(
          res.getBody(),
          AuthResponse.class
        );
        Cache.Org.put(
          'local.' +
          credentialName +
          '.' +
          mid,
          authObject,
          integer.valueof(authObject.expires_in)
        );
      }
    }
    return authObject;
  }

  /**
   * Creates structure for soap request ( used in soap factory methods)
   * @param {DOM.Document} doc - document for creating the structure
   * @param {String} soapAction - Create/Update/Retrieve
   * @return {DOM.XmlNode} default xml template for soap request
   */
  public static dom.XmlNode soapFactoryTemplate(
    DOM.Document doc,
    String soapAction
  ) {
    dom.XmlNode envelope = doc.createRootElement('Envelope', nsSoap, 's');
    envelope.setNamespace('a', nsAddressing);
    dom.XmlNode header = envelope.addChildElement('Header', nsSoap, 's');
    header.addChildElement('Action', nsAddressing, null)
      .addTextNode(soapAction);
    header.addChildElement('To', nsAddressing, null)
      .addTextNode('{{soapEndPoint}}');
    header.addChildElement('fueloauth', null, null)
      .addTextNode('{{accessToken}}');
    dom.XmlNode body = envelope.addChildElement('Body', nsSoap, 's');
    body.setNamespace('xsi', xsi);
    body.setNamespace('xsd', xsd);
    return body;
  }

  /**
   * Custom Class to store soap properties
   */
  public class soapProperty {
    public String propertyName;
    public String propertyValue;
    public List<soapProperty> propertyList;

    public soapProperty(
      String propertyName,
      String propertyValue,
      List<soapProperty> propertyList
    ) {
      this.propertyName = propertyName;
      this.propertyValue = propertyValue;
      this.propertyList = propertyList;
    }
  }

  /**
   * Adds properties to the soap request body
   * @param {DOM.XmlNode} xml - soap request xml body
   * @param {List<soapProperty>} obj - list of soap properties object to add
   */
  public static void addProperties(dom.XmlNode xml, List<soapProperty> obj) {
    for (soapProperty prop : obj) {
      if (prop.propertyValue != null) {
        xml.addChildElement(prop.propertyName, null, null)
          .addTextNode(prop.propertyValue);
      } else if (prop.propertyList != null) {
        dom.XmlNode xmlChild = xml.addChildElement(
          prop.propertyName,
          null,
          null
        );
        addProperties(xmlChild, prop.propertyList);
      }
    }
  }

  @AuraEnabled
  /**
   * Helper method to call main restRequest function from Lightning components ( Aura/LWC)
   * @param {String} mid - Marketing Cloud instance Id
   * @param {String} payload - request body
   * @param {String} method - REST method
   * @param {String} endpoint - only the path, instance URL already known
   * @return {Map<String, Object>} JSON object from response
   */
  public static Map<String, Object> restRequest(
    String mid,
    String payload,
    String method,
    String endPoint
  ) {
    return restRequest(mid, payload, method, endPoint, null);
  }

  /**
   * Method to send REST request
   * @param {String} mid - Marketing Cloud instance Id
   * @param {String} payload - request body
   * @param {String} method - REST method
   * @param {String} endpoint - only the path, instance URL already known
   * @param {Integer} attempts - number of attempts for sending the request ( not in use currently)
   * @return {Map<String, Object>} JSON object from response
   */
  public static Map<String, Object> restRequest(
    String mid,
    String payload,
    String method,
    String endPoint,
    Integer attempts
  ) {
    HttpRequest req = new HttpRequest();

    // LogHelper.pushLog(
    //   'L',
    //   'ACN_APIHandler',
    //   'restRequest',
    //   'input parameters',
    //   'mid ' +
    //   mid +
    //   ', payload ' +
    //   payload +
    //   ', method ' +
    //   method +
    //   ', endPoint' +
    //   endPoint +
    //   ', attempts ' +
    //   attempts,
    //   null
    // );
    attempts = attempts == null ? retryAttempts : attempts;
    AuthResponse auth = authenticate(mid);
    Http http = new Http();
    String restEndpoint = auth.rest_instance_url + endPoint;
    req.setEndpoint(restEndpoint);
    req.setTimeout(90000);
    req.setMethod(method);
    req.setHeader('Content-Type', 'application/json');
    req.setHeader('Authorization', 'Bearer ' + auth.access_token);
    if (!String.isBlank(payload)) {
      req.setBody(payload);
    }
    // LogHelper.pushLog(
    //   'L',
    //   'ACN_APIHandler',
    //   'restRequest',
    //   'request to be sent',
    //   'endpoint : ' +
    //   req.getEndpoint() +
    //   ', Authorization : ' +
    //   req.getHeader('Authorization') +
    //   ', method : ' +
    //   req.getMethod() +
    //   ', body : ' +
    //   req.getBody(),
    //   null
    // );

    HttpResponse res = http.send(req);

    // LogHelper.pushLog(
    //   'L',
    //   'ACN_APIHandler',
    //   'restRequest',
    //   'response from request',
    //   'status : ' +
    //   res.getStatus() +
    //   ', status code : ' +
    //   res.getStatusCode() +
    //   ', body : ' +
    //   res.getBody(),
    //   null
    // );
    if (res.getStatusCode() == 401 && attempts > 0) {
      attempts--;
      return restRequest(mid, payload, method, endPoint, attempts);
    } else if (res.getStatusCode() > 399) {
      throw new APIHandlerException('restRequest', res, null);
    } else {
      Map<String, Object> json = (Map<String, Object>) JSON.deserializeUntyped(
        res.getBody()
      );
      return json;
    }
  }

  /**
   * Method prepares soap request body for Creating elements
   * @param {String} objectType - object in Marketing Cloud
   * @param {List<List<soapProperty>>} objectList - soap properties ( records) for upsert
   * @param {Boolean} upsertRecord - determines if the records should be updated
   * @return {DOM.Document} ready XML document fro request
   */
  public static DOM.Document soapFactoryCreate(
    String objectType,
    List<List<soapProperty>> objectList,
    Boolean upsertRecord
  ) {
    DOM.Document doc = new DOM.Document();
    dom.XmlNode body = soapFactoryTemplate(doc, 'Create');
    dom.XmlNode msgInner = body.addChildElement('CreateRequest', null, null);
    msgInner.setAttribute('xmlns', 'http://exacttarget.com/wsdl/partnerAPI');
    //if upsert then add to save options
    if (upsertRecord) {
      dom.XmlNode msgOptions = msgInner
        .addChildElement('Options', null, null)
        .addChildElement('SaveOptions', null, null)
        .addChildElement('SaveOption', null, null);
      msgOptions.addChildElement('PropertyName', null, null).addTextNode('*');
      msgOptions.addChildElement('SaveAction', null, null)
        .addTextNode('UpdateAdd');
    }

    for (List<soapProperty> obj : objectList) {
      dom.XmlNode msgObj = msgInner.addChildElement('Objects', null, null);
      msgObj.setAttribute('xsi:type', objectType);
      addProperties(msgObj, obj);
    }
    return doc;
  }

  /**
   * Method prepares soap request body for Creating elements
   * @param {String} soapObject - object in Marketing Cloud
   * @param {List<Map<String, String>>} properties - soap properties ( records) for upsert
   * @param {Boolean} upsertRecord - determines if the records should be updated
   * @return {DOM.Document} ready XML document fro request
   */
  public static DOM.Document soapFactoryCreate(
    String soapObject,
    List<Map<String, String>> properties,
    Boolean upsertRecord
  ) {
    DOM.Document doc = new DOM.Document();
    dom.XmlNode body = soapFactoryTemplate(doc, 'Create');
    dom.XmlNode msgInner = body.addChildElement('CreateRequest', null, null);
    msgInner.setAttribute('xmlns', 'http://exacttarget.com/wsdl/partnerAPI');
    //if upsert then add to save options
    if (upsertRecord) {
      dom.XmlNode msgOptions = msgInner
        .addChildElement('Options', null, null)
        .addChildElement('SaveOptions', null, null)
        .addChildElement('SaveOption', null, null);
      msgOptions.addChildElement('PropertyName', null, null).addTextNode('*');
      msgOptions.addChildElement('SaveAction', null, null)
        .addTextNode('UpdateAdd');
    }

    for (Map<String, String> prop : properties) {
      dom.XmlNode msgObj = msgInner.addChildElement('Objects', null, null);
      msgObj.setAttribute('xsi:type', soapObject);
      for (String key : prop.keySet()) {
        msgObj.addChildElement(key, null, null).addTextNode(prop.get(key));
      }
    }
    return doc;
  }

  /**
   * Method prepares soap request body for Updating elements
   * @param {String} soapObject - object in Marketing Cloud
   * @param {List<Map<String, String>>} properties - soap properties ( records) for update
   * @return {DOM.Document} ready XML document fro request
   */
  public static DOM.Document soapFactoryUpdate(
    String soapObject,
    List<Map<String, String>> properties
  ) {
    DOM.Document doc = new DOM.Document();
    dom.XmlNode body = soapFactoryTemplate(doc, 'Update');
    dom.XmlNode msgInner = body.addChildElement('UpdateRequest', null, null);
    msgInner.setAttribute('xmlns', 'http://exacttarget.com/wsdl/partnerAPI');
    for (Map<String, String> prop : properties) {
      dom.XmlNode msgObj = msgInner.addChildElement('Objects', null, null);
      msgObj.setAttribute('xsi:type', soapObject);
      for (String key : prop.keySet()) {
        msgObj.addChildElement(key, null, null).addTextNode(prop.get(key));
      }
    }
    return doc;
  }
  /**
   * Simple Function to support only simple filters
   * @param {String} soapObject - object in Marketing Cloud
   * @param {List<Map<String, String>>} properties - properties to retrieve with the call
   * @param {SimpleFilter} filter - filtering criteria
   * @return {DOM.Document} ready XML document fro request
   */
  public static DOM.Document soapFactoryRetrieve(
    String soapObject,
    List<String> properties,
    SimpleFilter simpleFilter
  ) {
    return soapFactoryRetrieve(soapObject, properties, simpleFilter, null);
  }

  /**
   * Method prepares soap request body for Retrieve elements
   * @param {String} soapObject - object in Marketing Cloud
   * @param {List<Map<String, String>>} properties - properties to retrieve with the call
   * @param {SimpleFilter} filter - filtering criteria
   * @param {ComplexFilter} filter - filtering criteria with at most two filter conditions
   * @return {DOM.Document} ready XML document fro request
   */
  public static DOM.Document soapFactoryRetrieve(
    String soapObject,
    List<String> properties,
    SimpleFilter simpleFilter,
    ComplexFilter complexFilter
  ) {
    DOM.Document doc = new DOM.Document();
    dom.XmlNode body = soapFactoryTemplate(doc, 'Retrieve');
    dom.XmlNode msg = body.addChildElement('RetrieveRequestMsg', null, null);
    msg.setAttribute('xmlns', 'http://exacttarget.com/wsdl/partnerAPI');
    dom.XmlNode msgInner = msg.addChildElement('RetrieveRequest', null, null);
    msgInner.addChildElement('ObjectType', null, null).addTextNode(soapObject);
    for (String prop : properties) {
      msgInner.addChildElement('Properties', null, null).addTextNode(prop);
    }
    if (simpleFilter != null || complexFilter != null) {
      addFilterNode(msgInner, simpleFilter, complexFilter);
    }
    return doc;
  }

  /**
   * Method to call main soapRequest function
   * @param {String} mid - Marketing Cloud instance Id
   * @param {DOM.Document} xml - request body
   * @return {Map<String, Object>} JSON object from response
   */
  public static Map<String, Object> soapRequest(String mid, DOM.Document xml) {
    return soapRequest(mid, xml, null);
  }

  /**
   * Method to send SOAP request
   * @param {String} mid - Marketing Cloud instance Id
   * @param {DOM.Document} xml - request body
   * @param {Integer} attempts - number of attempts for sending the request
   * @return {Map<String, Object>} JSON object from response
   */
  public static Map<String, Object> soapRequest(
    String mid,
    DOM.Document xml,
    Integer attempts
  ) {
    // LogHelper.pushLog(
    //   'L',
    //   'ACN_APIHandler',
    //   'soapRequest',
    //   'input parameters',
    //   'mid ' +
    //   mid +
    //   ', xml ' +
    //   xml +
    //   ', attempts ' +
    //   attempts,
    //   null
    // );
    attempts = attempts == null ? retryAttempts : attempts;
    AuthResponse auth = authenticate(mid);
    Http http = new Http();
    HttpRequest req = new HttpRequest();
    String soapEndpoint = auth.soap_instance_url + 'Service.asmx';

    // push log message
    req.setEndpoint(soapEndpoint);
    req.setTimeout(90000);
    req.setMethod('POST');
    req.setHeader('Content-Type', 'text/xml');
    String xmlString = xml
      .toXmlString()
      .replace('{{soapEndPoint}}', soapEndpoint)
      .replace('{{accessToken}}', auth.access_token);
    req.setBody(xmlString);
    // LogHelper.pushLog(
    //   'L',
    //   'ACN_APIHandler',
    //   'soapRequest',
    //   'request to be sent',
    //   'endpoint : ' +
    //   req.getEndpoint() +
    //   ', method : ' +
    //   req.getMethod() +
    //   ', body : ' +
    //   req.getBody(),
    //   null
    // );
    HttpResponse res = http.send(req);
    // LogHelper.pushLog(
    //   'L',
    //   'ACN_APIHandler',
    //   'soapRequest',
    //   'response from request',
    //   'status : ' +
    //   res.getStatus() +
    //   ', status code : ' +
    //   res.getStatusCode() +
    //   ', body : ' +
    //   res.getBody(),
    //   null
    // );
    if (res.getBody().contains('Token Expired') && attempts > 0) {
      // retry call as may just need new token
      attempts--;
      return soapRequest(mid, xml, attempts);
    } else {
      // call response (500, 200 or other) to be parsed. parser contains error checks
      return xmlParse(res, new Set<String>{ 'Results', 'Property' });
    }
  }

  /**
   * Helper method to get all data from ACN_MarketingCloud__mdt, where all BU relevant information are stored
   */
  // public static Map<String, ACN_MarketingCloud__mdt> getMetadata() {
  //   Map<String, ACN_MarketingCloud__mdt> mapToReturn = new Map<String, ACN_MarketingCloud__mdt>();
  //   List<ACN_MarketingCloud__mdt> mList = Test.isRunningTest()
  //     ? ACN_APIHandlerTest.mockCustomMetadata()
  //     : [
  //         SELECT
  //           Label,
  //           EID__c,
  //           mid__c,
  //           SMSMessageId__c,
  //           Keyword__c,
  //           Engagement_History_Date_Range__c
  //         FROM ACN_MarketingCloud__mdt
  //       ];

  //   for (ACN_MarketingCloud__mdt data : mList) {
  //     mapToReturn.put(data.Label, data);
  //   }
  //   return mapToReturn;
  // }

  // /**
  //  * Helper method to get all data from ACN_MarketingCloud__mdt, where all BU relevant information are stored
  //  * @param {String} bu - business unit name
  //  */
  // public static ACN_MarketingCloud__mdt getMetadata(String bu) {
  //   if (Test.isRunningTest()) {
  //     return ACN_APIHandlerTest.mockCustomMetadata(bu);
  //   } else {
  //     List<ACN_MarketingCloud__mdt> rowToReturn = [
  //       SELECT
  //         Label,
  //         Engagement__c,
  //         EID__c,
  //         mid__c,
  //         SMSMessageId__c,
  //         Keyword__c,
  //         Engagement_History_Date_Range__c
  //       FROM ACN_MarketingCloud__mdt
  //       WHERE developername = :bu
  //     ];
  //     return rowToReturn[0];
  //   }
  // }

  /**
   * Custom Class to store filter properties used in request
   */
  public class SimpleFilter {
    public String Property;
    public String SimpleOperator;
    public String Value;
    public List<String> Values;

    public SimpleFilter(
      String soapProperty,
      String soapSimpleOperator,
      String soapValue
    ) {
      this.Property = soapProperty;
      this.SimpleOperator = soapSimpleOperator;
      this.Value = soapValue;
    }
    public SimpleFilter(
      String soapProperty,
      String soapSimpleOperator,
      List<String> soapValue
    ) {
      this.Property = soapProperty;
      this.SimpleOperator = soapSimpleOperator;
      this.Values = soapValue;
    }
  }

  /**
   * Custom Class to store filter properties used in request
   */
  public class ComplexFilter {
    public SimpleFilter LeftOperand;
    public String LogicalOperator;
    public SimpleFilter RightOperand;

    public ComplexFilter(
      SimpleFilter soapLeftOperand,
      String soapLogicalOperator,
      SimpleFilter soapRightOperand
    ) {
      this.LeftOperand = soapLeftOperand;
      this.LogicalOperator = soapLogicalOperator;
      this.RightOperand = soapRightOperand;
    }
  }
  /**
   * Method to add filter (complex with one level or simple) to payload request
   */
  public static void addFilterNode(
    DOM.XmlNode msgInner,
    SimpleFilter sf,
    ComplexFilter cf
  ) {
    dom.XmlNode filterNode = msgInner.addChildElement('Filter', null, null);
    if (sf != null) {
      // this is using simple filter only
      filterNode.setAttribute('xsi:type', 'SimpleFilterPart');
      filterNode.addChildElement('Property', null, null)
        .addTextNode(sf.Property);
      filterNode.addChildElement('SimpleOperator', null, null)
        .addTextNode(sf.SimpleOperator);
      if (sf.Value != null) {
        filterNode.addChildElement('Value', null, null).addTextNode(sf.Value);
      } else {
        for (String Value : sf.Values) {
          filterNode.addChildElement('Value', null, null).addTextNode(Value);
        }
      }
    } else {
      // this is using complex filter
      filterNode.setAttribute('xsi:type', 'ComplexFilterPart');
      dom.XmlNode left = filterNode.addChildElement('LeftOperand', null, null);
      left.setAttribute('xsi:type', 'SimpleFilterPart');
      left.addChildElement('Property', null, null)
        .addTextNode(cf.LeftOperand.Property);
      left.addChildElement('SimpleOperator', null, null)
        .addTextNode(cf.LeftOperand.SimpleOperator);
      if (cf.LeftOperand.Value != null) {
        left.addChildElement('Value', null, null)
          .addTextNode(cf.LeftOperand.Value);
      } else {
        for (String Value : cf.LeftOperand.Values) {
          left.addChildElement('Value', null, null).addTextNode(Value);
        }
      }
      filterNode.addChildElement('LogicalOperator', null, null)
        .addTextNode(cf.LogicalOperator);
      dom.XmlNode right = filterNode.addChildElement(
        'RightOperand',
        null,
        null
      );
      right.setAttribute('xsi:type', 'SimpleFilterPart');
      right.addChildElement('Property', null, null)
        .addTextNode(cf.RightOperand.Property);
      right.addChildElement('SimpleOperator', null, null)
        .addTextNode(cf.RightOperand.SimpleOperator);
      if (cf.RightOperand.Value != null) {
        right.addChildElement('Value', null, null)
          .addTextNode(cf.RightOperand.Value);
      } else {
        for (String Value : cf.RightOperand.Values) {
          right.addChildElement('Value', null, null).addTextNode(Value);
        }
      }
    }
  }

  /*
   * Generic SOAP Response handler. Checks for basic errors otherwise passes
   */
  public static Map<String, Object> xmlParse(
    HttpResponse res,
    Set<String> arrayProperties
  ) {
    if (res.getBody() == 'Bad Request') {
      throw new APIHandlerException('xmlParse', res, null);
    } else {
      XMLSerializer serializer = new XMLSerializer();
      Map<String, Object> body = (Map<String, Object>) ((Map<String, Object>) ((Map<String, Object>) serializer.deSerializeUnTyped(
            res.getBody(),
            arrayProperties
          ))
          .get('Envelope'))
        .get('Body');
      system.debug(body);
      if (body.get('Fault') != null) {
        Map<String, Object> fault = (Map<String, Object>) body.get('Fault');
        String message =
          'Code: ' +
          (String) ((Map<String, Object>) fault.get('Code')).get('Value') +
          '. Reason: ' +
          (String) ((Map<String, Object>) fault.get('Reason')).get('Text');
        throw new APIHandlerException('xmlParse', res, message);
      } else if (
        body.get('RetrieveResponseMsg') != null &&
        ((String) ((Map<String, Object>) body.get('RetrieveResponseMsg'))
            .get('OverallStatus'))
          .contains('Error')
      ) {
        throw new APIHandlerException(
          'xmlParse',
          res,
          ((String) ((Map<String, Object>) body.get('RetrieveResponseMsg'))
            .get('OverallStatus'))
        );
      }
      return body;
    }
  }
}