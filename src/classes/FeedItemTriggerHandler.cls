/**
* @author        Karen Hung
* @date          03.12.2020
* @description   Class responsible for the trigger business logic of FeedItem object
* @revision(s)   
*/
public with sharing class FeedItemTriggerHandler implements ITriggerHandler {
    
    //exception variables
    public static Boolean hasException = false;
    public class FeedItemTriggerHandlerException extends Exception {}
    
    public static Boolean isTriggerDisabled = true;
    
    public void BeforeInsert(List<SObject> newList) {
      
    }

    public void BeforeUpdate(List<SObject> newList, Map<Id, SObject> newItems, List<SObject> oldList, Map<Id, SObject> oldMap) {
   		
    }

    public void BeforeDelete(List<SObject> oldList, Map<Id, SObject> oldItems) {
		
    }

    public void AfterInsert(List<SObject> newList, Map<Id, SObject> newItems) {
        CustomLogging.push('AfterInsert', 'FeedItemTriggerHandler');
		
        //DOO-4556 expose chatter content in related/parent case
        createCaseComment(newItems);
        
		CustomLogging.pop();       
    }

    public void AfterUpdate(List<SObject> newList, Map<Id, SObject> newItems, List<SObject> oldList, Map<Id, SObject> oldMap) {

    }

    public void AfterDelete(List<SObject> oldList, Map <Id, SObject> oldItems) {

    }

    public void AfterUndelete(List<SObject> newList, Map <Id, SObject> newItems) {

    }

    public Boolean IsDisabled() {
        if (TriggerSettings__c.getInstance().FeedItemTrigger__c == true) {
            return false;
        } else {
            return isTriggerDisabled;
        }
    }
    
    /*
     * Created by: Karen Hung
     * Created Date: December 3, 2020
     * Description: DOO-4556 Expose all Chatter content in related/parent case
     *
	 */
    public void createCaseComment(Map<Id, SObject> newItems){
        CustomLogging.push('createCaseComment', 'FeedItemTriggerHandler');
        
        try{
            
            Map<Id,FeedItem> itemsMap = (Map<Id,FeedItem>) newItems;
            List<CaseComment> commentsToInsert =  new List<CaseComment>();
            
            Map<String,List<FeedItem>> parentFeedIdMap = new Map<String,List<FeedItem>>();
            
           	Map<Id,FeedItem> extFeedItem = new Map<Id,FeedItem>([SELECT Id, Parent.Type FROM FeedItem WHERE Id IN :itemsMap.KeySet()]);
            
            for(FeedItem feed : itemsMap.values()){            
                if(feed.Type == TS_Constants.TEXTPOST && 
                   feed.Type != TS_Constants.CASECOMMENTPOST &&
                   (extFeedItem.get(feed.Id).Parent.Type == TS_Constants.OBJ_APINAME_CASE || extFeedItem.get(feed.Id).Parent.Type == TS_Constants.TS_Type_Task)){
                       if(parentFeedIdMap.containsKey(feed.ParentId)){
                           parentFeedIdMap.get(feed.ParentId).add(feed);    
                       }else{
                           parentFeedIdMap.put(feed.ParentId,new List<FeedItem>{feed});	    
                       }   
                   }	    
            }
             
            if(!parentFeedIdMap.isEmpty()){
                
                //get mapping of case and list of tasks for feeds from the tasks
                Map<String, List<String>> caseTasksMap = new Map<String, List<String>>();
                Map<Id, Task> taskMap = new Map<Id, Task>([SELECT Id, WhatId FROM Task WHERE Id IN :parentFeedIdMap.keySet() AND What.Type = :TS_Constants.OBJ_APINAME_CASE]);
                
                if(taskMap != null && !taskMap.isEmpty()){
                    for(Task taskRec : taskMap.values()){
                        if(caseTasksMap.containsKey(taskRec.WhatId)){
                            caseTasksMap.get(taskRec.WhatId).add(taskRec.Id);   
                        }else{
                            caseTasksMap.put(taskRec.WhatId, new List<String>{taskRec.Id});   
                        }                   
                    }
                }
                
                //collate all case parent of feed item and parent case of task parent of feed item
                Map<Id, Case> caseMap = new Map<Id, Case>([SELECT Id, Type FROM Case WHERE (Id IN :parentFeedIdMap.keySet() OR Id IN :caseTasksMap.keySet()) AND Type IN (:TS_Constants.CASE_TYPE_COMPLAINT, :TS_Constants.CASE_TYPE_CUSTOMERCARE)]);
                
                if(caseMap != null && !caseMap.isEmpty()){
                    for(Case cse : [SELECT Id FROM Case WHERE Id IN :caseMap.keySet()]){
                        if(parentFeedIdMap.containsKey(cse.Id)){
                            for(FeedItem feed : parentFeedIdMap.get(cse.Id)){
                                
                                CaseComment cseComment = createComment(feed.body, cse.Id);                           
                                commentsToInsert.add(cseComment);
                                
                            }
                        }
                        
                        if(caseTasksMap.containsKey(cse.Id)){
                            for(String caseTask: caseTasksMap.get(cse.Id)){
                                for(FeedItem taskFeed : parentFeedIdMap.get(caseTask)){
                                    
                                    CaseComment cseComment = createComment(taskFeed.body, cse.Id);                      
                                    commentsToInsert.add(cseComment);
                                    
                                } 
                            }                        
                        }
                    }   
                }            
                
                
                if(!commentsToInsert.isEmpty()){
                    insert commentsToInsert;    
                }     
            }
            
            if(Test.isRunningTest() && hasException) {
                throw new FeedItemTriggerHandlerException('Force to throw an exception');
            }
            
        }catch(Exception ex){
            CustomLogging.debugException(ex);
            CustomLogging.pop();
            System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());            
        }
 
        CustomLogging.pop();             
    }
    
    public CaseComment createComment(String feedBody, String parentId){
        CustomLogging.push('createComment', 'FeedItemTriggerHandler');

        CaseComment cseComment = new CaseComment();
        cseComment.ParentId = parentId;
        cseComment.CommentBody = feedBody.left(4000);
        cseComment.CommentBody = cseComment.CommentBody.stripHtmlTags();
        system.debug(cseComment.CommentBody.length());
        CustomLogging.pop();
        return cseComment;
    }

}