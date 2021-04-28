@isTest
public with sharing class SM_SurveyTest {
  /**
   * NOTE: Generally speaking the survey objects have limited
   * ability to modify using DML. Therefore JSON serialization
   * has been used to avoid checks on editability of fields but
   * still provide sufficient testing
   */
  /**
   * Helper method to generate some example questions
   */
  private static List<SurveyQuestion> getQuestionList() {
    List<SurveyQuestion> questionlist = new List<SurveyQuestion>();
    questionList.add(
      (SurveyQuestion) json.deserialize(
        '{"id": "0Ku1q0000004DgPCAU","name":"How did you find the service?"}',
        SurveyQuestion.class
      )
    );
    questionList.add(
      (SurveyQuestion) json.deserialize(
        '{"id": "0Ku1q0000004DgPCAB","name":"Would you be willing to be contacted in for Quality Assurance Purposes"}',
        SurveyQuestion.class
      )
    );
    questionList.add(
      (SurveyQuestion) json.deserialize(
        '{"id": "0Ku1q0000004DgPCAR","name":"When did you contact Us?"}',
        SurveyQuestion.class
      )
    );
    questionList.add(
      (SurveyQuestion) json.deserialize(
        '{"id": "0Ku1q0000004DgPCAT","name":"Last General Question"}',
        SurveyQuestion.class
      )
    );
    questionList.add(
      (SurveyQuestion) json.deserialize(
        '{"id": "0Ku1q0000004DgPCAQ","name":"Some Text Answer"}',
        SurveyQuestion.class
      )
    );

    return questionList;
  }
  /**
   * Helper method to generate some example responses
   */
  private static List<SurveyQuestionResponse> getResponseList() {
    List<SurveyQuestionResponse> responselist = new List<SurveyQuestionResponse>();
    responseList.add(
      (SurveyQuestionResponse) json.deserialize(
        json.serialize(
          new Map<String, Object>{
            'ResponseShortText' => '2',
            'Datatype' => 'Number',
            'NumberValue' => 2,
            'QuestionId' => '0Ku1q0000004DgPCAU'
          }
        ),
        SurveyQuestionResponse.class
      )
    );
    responseList.add(
      (SurveyQuestionResponse) json.deserialize(
        json.serialize(
          new Map<String, Object>{
            'ResponseShortText' => 'Yes',
            'Datatype' => 'Text',
            'QuestionId' => '0Ku1q0000004DgPCAB'
          }
        ),
        SurveyQuestionResponse.class
      )
    );
    responseList.add(
      (SurveyQuestionResponse) json.deserialize(
        json.serialize(
          new Map<String, Object>{
            'ResponseShortText' => '2020-10-02',
            'Datatype' => 'Date',
            'DateValue' => Date.valueOf('2020-10-02'),
            'QuestionId' => '0Ku1q0000004DgPCAR'
          }
        ),
        SurveyQuestionResponse.class
      )
    );
    responseList.add(
      (SurveyQuestionResponse) json.deserialize(
        json.serialize(
          new Map<String, Object>{
            'ResponseShortText' => 'Like',
            'Datatype' => 'Boolean',
            'IsTrueOrFalse' => true,
            'QuestionId' => '0Ku1q0000004DgPCAT'
          }
        ),
        SurveyQuestionResponse.class
      )
    );
    responseList.add(
      (SurveyQuestionResponse) json.deserialize(
        json.serialize(
          new Map<String, Object>{
            'ResponseShortText' => 'Something Interesting',
            'Datatype' => 'Text',
            'QuestionId' => '0Ku1q0000004DgPCAQ'
          }
        ),
        SurveyQuestionResponse.class
      )
    );
    return responseList;
  }
  /**
   * Method to test passing scenario
   */
  private static testMethod void passCriteria() {
    String rule = '[{"question":"Some Text Answer", "operator": "contains","response": "Something" },{"question":"When did you contact Us?", "operator": "greaterThan","response": "2020-09-02" },{"question":"How did you find the service?", "operator": "lessThan","response": "3" },{"question":"Would you be willing to be contacted in for Quality Assurance Purposes", "operator": "equals","response": "Yes" }]';
    List<Survey_Automation__c> saList = new List<Survey_Automation__c>{
      new Survey_Automation__c(
        name = 'testclassautomation',
        Rule__c = rule,
        Queue_Name__c = 'NL - Survey',
        Action__c = 'Create Task'
      )
    };
    List<SurveyQuestion> questionList = getQuestionList();
    List<SurveyQuestionResponse> responseList = getResponseList();
    List<SM_Survey.EvaluateResponsesRequest> errList = new List<SM_Survey.EvaluateResponsesRequest>();
    SM_Survey.EvaluateResponsesRequest er = new SM_Survey.EvaluateResponsesRequest();
    er.SurveyAutomationList = saList;
    er.SurveyQuestions = questionList;
    er.SurveyQuestionResponses = responselist;
    errList.add(er);
    List<SM_Survey.EvaluateResponsesResponse> actions;
    Test.startTest();
    actions = SM_Survey.EvaluateResponses(errList);

    Test.stopTest();
    system.assertEquals(actions.size(), 1);
  }
  /**
   * Method to test failing scenario
   */
  private static testMethod void failCriteria() {
    String rule1 = '[{"question":"Some Text Answer", "operator": "contains","response": "Something" },{"question":"When did you contact Us?", "operator": "greaterThan","response": "2020-09-02" },{"question":"How did you find the service?", "operator": "lessThan","response": "3" },{"question":"Would you be willing to be contacted in for Quality Assurance Purposes", "operator": "equals","response": "No" }]';
    String rule2 = '[{"question":"Some Text Answer", "operator": "notContains","response": "Something" },{"question":"When did you contact Us?", "operator": "greaterThan","response": "2020-09-02" },{"question":"How did you find the service?", "operator": "lessThan","response": "3" },{"question":"Would you be willing to be contacted in for Quality Assurance Purposes", "operator": "equals","response": "No" }]';
    List<Survey_Automation__c> saList = new List<Survey_Automation__c>{
      new Survey_Automation__c(
        name = 'testclassautomation1',
        Rule__c = rule1,
        Queue_Name__c = 'NL - Survey',
        Action__c = 'Create Task'
      ),
      new Survey_Automation__c(
        name = 'testclassautomation2',
        Rule__c = rule2,
        Queue_Name__c = 'NL - Survey',
        Action__c = 'Create Task'
      )
    };
    List<SurveyQuestion> questionList = getQuestionList();
    List<SurveyQuestionResponse> responseList = getResponseList();
    List<SM_Survey.EvaluateResponsesRequest> errList = new List<SM_Survey.EvaluateResponsesRequest>();
    SM_Survey.EvaluateResponsesRequest er = new SM_Survey.EvaluateResponsesRequest();
    er.SurveyAutomationList = saList;
    er.SurveyQuestions = questionList;
    er.SurveyQuestionResponses = responselist;
    errList.add(er);
    List<SM_Survey.EvaluateResponsesResponse> actions;
    Test.startTest();
    actions = SM_Survey.EvaluateResponses(errList);

    Test.stopTest();
    system.assertEquals(actions.size(), 0);
  }
}