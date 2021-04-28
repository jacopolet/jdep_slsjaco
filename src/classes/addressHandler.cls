public with sharing class addressHandler {
  public class adddressHandlerException extends Exception {
  }

  @AuraEnabled
  public static string validateEmail(String emailAddress) {
    List<String> validators = new List<String>{ 'SyntaxValidator', 'MXValidator', 'ListDetectiveValidator' };
    Map<String, Object> payload = new Map<String, Object>{ 'validators' => validators, 'email' => emailAddress };
    String mid = sfmcDefault__c.getOrgDefaults().eid__c;
    Map<String, Object> res = ACN_ApiHandler.restRequest(mid, JSON.serialize(payload), 'POST', 'address/v1/validateEmail');
    if (res.get('valid') == true) {
      return 'Ok';
    } else {
      throw new adddressHandlerException(String.valueOf(res.get('failedValidation')));
    }
  }
}