public without sharing class SM_Survey {
  public class SurveyFilterException extends Exception {
  }
  public class SurveyFilter {
    public String question;
    public String operator;
    public String response;
  }
  /**
   * Checks a filter against a response to see if it should automate some action
   * @param fltrObj filter which should be used
   * @param sqr response to check filter against
   */
  public static Boolean EvaluateRule(
    SM_Survey.SurveyFilter fltrObj,
    SurveyQuestionResponse sqr
  ) {
    CustomLogging.push('EvaluateRule', 'SM_Survey');
    Set<String> thanSupport = new Set<String>{ 'Number', 'Date', 'DateTime' };
    Boolean isTrue = false;
    if (fltrObj.operator == 'equals') {
      if (fltrObj.response == sqr.ResponseShortText) {
        isTrue = true;
      }
    } else if (fltrObj.operator == 'notEquals') {
      if (fltrObj.response != sqr.ResponseShortText) {
        isTrue = true;
      }
    } else if (fltrObj.operator == 'greaterThan') {
      if (thanSupport.contains(sqr.Datatype)) {
        if (
          sqr.Datatype == 'Number' &&
          sqr.NumberValue > Double.valueOf(fltrObj.response)
        ) {
          isTrue = true;
        } else if (
          sqr.Datatype == 'Date' &&
          sqr.DateValue > Date.valueOf(fltrObj.response)
        ) {
          isTrue = true;
        }
      } else {
        throw new SM_Survey.SurveyFilterException(
          sqr.Datatype + ' unsupported in greater or less than operator'
        );
      }
    } else if (fltrObj.operator == 'lessThan') {
      if (thanSupport.contains(sqr.Datatype)) {
        if (
          sqr.Datatype == 'Number' &&
          sqr.NumberValue < Double.valueOf(fltrObj.response)
        ) {
          isTrue = true;
        } else if (
          sqr.Datatype == 'Date' &&
          sqr.DateValue < Date.valueOf(fltrObj.response)
        ) {
          isTrue = true;
        }
      } else {
        throw new SM_Survey.SurveyFilterException(
          sqr.Datatype + ' unsupported in greater or less than operator'
        );
      }
    } else if (fltrObj.operator == 'contains') {
      if (
        sqr.ResponseShortText.toLowerCase()
          .contains(fltrObj.response.toLowerCase())
      ) {
        isTrue = true;
      }
    } else if (fltrObj.operator == 'notContains') {
      if (
        !sqr.ResponseShortText.toLowerCase()
          .contains(fltrObj.response.toLowerCase())
      ) {
        isTrue = true;
      }
    }
    CustomLogging.pop();
    return isTrue;
  }
  /**
   * Invocable helper for request used for bulkification from Flow
   */
  public class EvaluateResponsesRequest {
    @InvocableVariable(required=true)
    public List<Survey_Automation__c> SurveyAutomationList;

    @InvocableVariable(required=true)
    public List<SurveyQuestionResponse> SurveyQuestionResponses;

    @InvocableVariable(required=true)
    public List<SurveyQuestion> SurveyQuestions;
  }
  /**
   * Invocable helper for response used for bulkification from Flow
   */
  public class EvaluateResponsesResponse {
    @InvocableVariable
    public Survey_Automation__c SurveyAutomation;
  }

  /**
   * Invocable method to validate a set of Responses against a set for Automation Rules
   * @param erList invocable list object used for bulkification
   */
  @InvocableMethod(
    label='Evaluate Survey Responses'
    description='Returns SurveyAutomation result if SurveyResponse passed validation against Survey Automation'
    category='Survey'
  )
  public static List<EvaluateResponsesResponse> EvaluateResponses(
    List<EvaluateResponsesRequest> erList
  ) {
    CustomLogging.push('EvaluateResponses', 'SM_Survey');
    List<EvaluateResponsesResponse> responseWrapper = new List<EvaluateResponsesResponse>();
    try {
      for (EvaluateResponsesRequest er : erList) {
        Map<Id, SurveyQuestion> questionMap = new Map<Id, SurveyQuestion>(
          er.SurveyQuestions
        );
        Boolean isTotalTrue = true;
        // try each of the automations until one passes
        for (Survey_Automation__c sa : er.SurveyAutomationList) {
          List<SM_Survey.SurveyFilter> fltrList = (List<SM_Survey.SurveyFilter>) JSON.deserialize(
            sa.Rule__c,
            List<SM_Survey.SurveyFilter>.class
          );

          for (SM_Survey.SurveyFilter fltrObj : fltrList) {
            //check each condition
            Boolean isTrue = false;
            for (SurveyQuestionResponse sqr : er.SurveyQuestionResponses) {
              //add question to child
              if (fltrObj.question == questionMap.get(sqr.QuestionId).Name) {
                isTrue = SM_Survey.EvaluateRule(fltrObj, sqr);
              }
            }
            // if one is false then fail all
            if (isTrue == false) {
              isTotalTrue = false;
              break;
            }
          }
          //if one of the criteria is true then exit loop
          if (isTotalTrue == true) {
            EvaluateResponsesResponse res = new EvaluateResponsesResponse();
            res.SurveyAutomation = sa;
            responseWrapper.add(res);
          }
        }
        if (isTotalTrue = false) {
          responseWrapper.add(null);
        }
      }
      CustomLogging.pop();
    } catch (Exception e) {
      CustomLogging.debugException(e);
      CustomLogging.pop();
      System.debug(e.getMessage() + '\n' + e.getStackTraceString());
    }
    return responseWrapper;
  }
}