public without sharing class ContentDocumentLinkTriggerHandler implements ITriggerHandler{
    public static Boolean isTriggerDisabled = true;
    public static ID accountId;
    public static ID documentId;
    public void beforeInsert(List<SObject> newNoteList){
    } 
 
    public void beforeUpdate(List<SObject> newNoteList, Map<Id, SObject> newItems, List<SObject> oldList, Map<Id, SObject> oldNoteMap){

    }
 
    public void beforeDelete(List<SObject> oldList, Map<Id, SObject> oldItems){
        
    }
 
    public void afterInsert(List<SObject> newNoteList, Map<Id, SObject> newItems){
        putNoteonAccount ((List<ContentDocumentLink>) newNoteList);
        attachmentOnAgreement((List<ContentDocumentLink>) newNoteList);
    }
 
    public void afterUpdate(List<SObject> newNoteList , Map<Id, SObject> newItems, List<SObject> oldList, Map<Id, SObject> oldNoteMap){
    }
 
    public void afterDelete(List<SObject> oldList, Map<Id, SObject> oldItems){
        
    }
 
    public void afterUndelete(List<SObject> newList, Map<Id, SObject> newItems){
        
    }
    
    public Boolean IsDisabled(){
        if (TriggerSettings__c.getInstance().ContentDocumentLinkTrigger__c == true) {
            return false;
        } else {
            return isTriggerDisabled;
        }
    }
    
    private static Set<ContentDocumentLink> compilecontentdocuments(List<ContentDocumentLink> contentlist, Map<Id,Id> objectmap){
        Set<ContentDocumentLink> noterelatedtoobject = new Set<ContentDocumentLink>();
        if (!contentlist.isEmpty() && !objectmap.isEmpty()){
            for (ContentDocumentLink cdlstamponObject : contentlist){
                 if (objectmap.get(cdlstamponObject.LinkedEntityId) != null && objectmap.get(cdlstamponObject.LinkedEntityId) != accountId){
                     accountId = objectmap.get(cdlstamponObject.LinkedEntityId);
                     documentId = cdlstamponObject.ContentDocumentId;
                     ContentDocumentLink stampnoteonobject = new ContentDocumentLink();
                     stampnoteonobject.ShareType = cdlstamponObject.ShareType;
                     stampnoteonobject.Visibility = cdlstamponObject.Visibility;
                     stampnoteonobject.ContentDocumentId = cdlstamponObject.ContentDocumentId;
                     stampnoteonobject.LinkedEntityId = objectmap.get(cdlstamponObject.LinkedEntityId);
                     noterelatedtoobject.add(stampnoteonobject);
                 }
            }
        }
        return noterelatedtoobject;
    }
    
    private static Set<ContentDocumentLink> compilecontentdocumentsfortwolayerobjects(List<ContentDocumentLink> contentlist, Map<Id,Id> objectmap, Map<Id,Id> objectmapsecondlayer){
        Set<ContentDocumentLink> noterelatedtoobject = new Set<ContentDocumentLink>();
        if (!contentlist.isEmpty() && !objectmap.isEmpty() && !objectmapsecondlayer.isEmpty()){
             for (ContentDocumentLink cdlstamponObject : contentlist){
                  if (objectmap.get(cdlstamponObject.LinkedEntityId) != null && objectmapsecondlayer.get(objectmap.get(cdlstamponObject.LinkedEntityId)) != accountId){
                      accountId = objectmapsecondlayer.get(objectmap.get(cdlstamponObject.LinkedEntityId));
                      documentId = cdlstamponObject.ContentDocumentId;
                      ContentDocumentLink stampnoteonobject = new ContentDocumentLink();
                      stampnoteonobject.ShareType = cdlstamponObject.ShareType;
                      stampnoteonobject.Visibility = cdlstamponObject.Visibility;
                      stampnoteonobject.ContentDocumentId = cdlstamponObject.ContentDocumentId;
                      stampnoteonobject.LinkedEntityId = objectmapsecondlayer.get(objectmap.get(cdlstamponObject.LinkedEntityId));
                      noterelatedtoobject.add(stampnoteonobject);
                  }
              }
        }
        return noterelatedtoobject;
    }
    
     //Added by Akhilesh - Registration form attachment and activation(Flex team 1) 
    public static void attachmentOnAgreement (List<ContentDocumentLink> newNoteList){
        List<Id> attachmentRelatedToAgreement = new List<Id>();
        List<Apttus__APTS_Agreement__c> agreementUpdateList = new List<Apttus__APTS_Agreement__c>();
        Map<id,id> contentDocAndAgreementIdMap = new Map<id, id>();
        
        for (ContentDocumentLink CDLRelated : newNoteList){
            if(String.valueOf(CDLRelated.LinkedEntityId).left(3) == 'a01' /*&& CDLRelated.ContentDocument.FileExtension == 'msg'*/){
                contentDocAndAgreementIdMap.put(CDLRelated.ContentDocumentId,CDLRelated.LinkedEntityId);
            }
        }
        
        //reason for below code - reference to content document from content document link is null
        for(ContentDocument cd: [SELECT Id, fileExtension FROM contentDocument WHERE id IN : contentDocAndAgreementIdMap.keyset()]){
            if(cd.fileExtension == 'msg'){
                attachmentRelatedToAgreement.add(contentDocAndAgreementIdMap.get(cd.Id));
            }
        }
        
        for(Apttus__APTS_Agreement__c tmpAggr : [SELECT Id, Apttus__Status__c, RecordType.DeveloperName FROM Apttus__APTS_Agreement__c WHERE Id IN :attachmentRelatedToAgreement]){
            if(tmpAggr.RecordType.DeveloperName == 'Registration_Form')
            {
                tmpAggr.Apttus__Status__c = 'Added';
                agreementUpdateList.add(tmpAggr);
            }
        }
        
        if(!agreementUpdateList.IsEmpty()){
            update agreementUpdateList;
        }
    }
    
    public static void putNoteonAccount (List<ContentDocumentLink> newNoteList){
        CustomLogging.push('putNoteonAccount', 'ContentDocumentLinkTriggerHandler');
        try {
          List<ContentDocumentLink> noterelatedtoTask = new List<ContentDocumentLink>();
          List<ContentDocumentLink> noterelatedtoContact = new List<ContentDocumentLink>();
          List<ContentDocumentLink> noterelatedtoOpportunity = new List<ContentDocumentLink>();
          List<ContentDocumentLink> noterelatedtoEvent = new List<ContentDocumentLink>();
          Set<Id> taskIDs = new Set<Id>();
          Set<Id> contactIDs = new Set<Id>();
          Set<Id> opportunityIDs = new Set<Id>();
          Set<Id> eventIDs = new Set<Id>();
          Set<ContentDocumentLink> finalizenotes = new Set<ContentDocumentLink>();
          for (ContentDocumentLink CDLRelated : newNoteList){
              if (String.valueOf(CDLRelated.LinkedEntityId).left(3) == '00T'){
                  noterelatedtoTask.add(CDLRelated);
              }
              else if (String.valueOf(CDLRelated.LinkedEntityId).left(3) == SM_Constants.contactPrefix){
                  noterelatedtoContact.add(CDLRelated);
              }
              else if (String.valueOf(CDLRelated.LinkedEntityId).left(3) == '006'){
                  noterelatedtoOpportunity.add(CDLRelated);
              }
              else if (String.valueOf(CDLRelated.LinkedEntityId).left(3) == '00U'){
                  noterelatedtoEvent.add(CDLRelated);
              }
          }
            
          if (!noterelatedtoTask.isEmpty()){
             Set<Id> taskrelatedtoppty = new Set<Id>();
             Set<Id> taskrelatedtoaccloc = new Set<Id>();
             Map <Id,Id> taskrelatedtoaccounts = new Map<Id,Id>();
             Map <Id,Id> taskrelatedtoopportunity = new Map <Id, Id>();
             Map <Id,Id> opportunityrelatedtoaccounts = new Map <Id, Id>();
             Map <Id,Id> taskrelatedtoaccountlocation = new Map <Id, Id>();
             Map <Id,Id> accountlocationrelatedtoaccounts = new Map <Id, Id>();
             for (ContentDocumentLink cdlIDs : noterelatedtoTask){
                 if (!taskIDs.contains(cdlIDs.LinkedEntityId)){
                     taskIDs.add(cdlIDs.LinkedEntityId);
                 }
             }
             
             if (!taskIDs.isEmpty()){
                 List<Task> taskrelatedtoaccount = [Select Id , WhatId, Touchpoint_Type__c from Task where ID IN: taskIDs];
                 if (!taskrelatedtoaccount.isEmpty()){
                     for (Task t : taskrelatedtoaccount){
                         if (t.WhatId != null){
                             if (String.valueOf(t.WhatId).left(3) == SM_Constants.accountPrefix && t.Touchpoint_Type__c != null){
                                taskrelatedtoaccounts.put(t.Id, t.WhatId);
                             }
                             else if (String.valueOf(t.WhatId).left(3) == SM_Constants.oppPrefix && t.Touchpoint_Type__c != null){
                                taskrelatedtoppty.add(t.WhatId);
                                taskrelatedtoopportunity.put(t.Id, t.WhatId);
                             }
                             else if (String.valueOf(t.WhatId).left(3) == Label.Account_Location_Prefix && t.Touchpoint_Type__c != null){
                                taskrelatedtoaccloc.add(t.WhatId);
                                taskrelatedtoaccountlocation.put(t.Id, t.WhatId);
                             }
                         }
                     }
                     if (!taskrelatedtoaccounts.isEmpty()){
                         finalizenotes = compilecontentdocuments(noterelatedtoTask, taskrelatedtoaccounts);
                     }
                     if (!taskrelatedtoppty.isEmpty()){
                         List<Opportunity> getaccountfromoppty = [Select Id, AccountID from Opportunity where ID IN: taskrelatedtoppty];
                          if (!getaccountfromoppty.isEmpty()){
                              for (Opportunity o : getaccountfromoppty){
                                  if (o.AccountId != null){
                                      opportunityrelatedtoaccounts.put(o.Id, o.AccountId);
                                  }
                              }
                              if (!opportunityrelatedtoaccounts.isEmpty()){
                                  finalizenotes = compilecontentdocumentsfortwolayerobjects(noterelatedtoTask, taskrelatedtoopportunity, opportunityrelatedtoaccounts);
                              }
                          }
                     }
                     
                     if (!taskrelatedtoaccloc.isEmpty()){
                          List<Apttus_Config2__AccountLocation__c> getaccountfromaccloc = [Select Id, Apttus_Config2__AccountId__r.Id from Apttus_Config2__AccountLocation__c where ID IN: taskrelatedtoaccloc];
                          if (!getaccountfromaccloc.isEmpty()){
                              for (Apttus_Config2__AccountLocation__c accloc : getaccountfromaccloc){
                                  if (accloc.Apttus_Config2__AccountId__r.Id != null){
                                      accountlocationrelatedtoaccounts.put(accloc.Id, accloc.Apttus_Config2__AccountId__r.Id);
                                  }
                              }
                              if (!accountlocationrelatedtoaccounts.isEmpty()){
                                  finalizenotes = compilecontentdocumentsfortwolayerobjects(noterelatedtoTask, taskrelatedtoaccountlocation, accountlocationrelatedtoaccounts);
                              }
                          }
                      }
                 }
             }
          }
          //contacthere
          if (!noterelatedtoContact.isEmpty()){
              for (ContentDocumentLink cdlIDs : noterelatedtoContact){
                  if (!contactIDs.contains(cdlIDs.LinkedEntityId)){
                      contactIDs.add(cdlIDs.LinkedEntityId);
                  }
              }
              
              if (!contactIDs.isEmpty()){
                  List<Contact> contactrelatedtoaccount = [Select Id, AccountID from Contact where ID IN: contactIDs];
                  if (!contactrelatedtoaccount.isEmpty()){
                      Map <Id,Id> contactrelatedtoaccounts = new Map <Id, Id>();
                      for (Contact c : contactrelatedtoaccount){
                          if (c.AccountId != null){
                              contactrelatedtoaccounts.put(c.Id, c.AccountId);
                          }
                      }
                      if (!noterelatedtoContact.isEmpty()){
                          finalizenotes = compilecontentdocuments(noterelatedtoContact, contactrelatedtoaccounts);
                      }
                  }
              }
          }
          //opptyhere
          if (!noterelatedtoOpportunity.isEmpty()){
              for (ContentDocumentLink cdlIDs : noterelatedtoOpportunity){
                  if (!opportunityIDs.contains(cdlIDs.LinkedEntityId)){
                      opportunityIDs.add(cdlIDs.LinkedEntityId);
                  }
              }
              
              if (!opportunityIDs.isEmpty()){
                  List<Opportunity> opportunityrelatedtoaccount = [Select Id, AccountID from Opportunity where ID IN: opportunityIDs];
                  if (!opportunityrelatedtoaccount.isEmpty()){
                      Map <Id,Id> opportunityrelatedtoaccounts = new Map <Id, Id>();
                      for (Opportunity o : opportunityrelatedtoaccount){
                          if (o.AccountId != null){
                              opportunityrelatedtoaccounts.put(o.Id, o.AccountId);
                          }
                      }
                      if (!opportunityrelatedtoaccounts.isEmpty()){
                          finalizenotes = compilecontentdocuments(noterelatedtoOpportunity, opportunityrelatedtoaccounts);
                      }
                  }
              }
          }
          
          if (!noterelatedtoEvent.isEmpty()){
              for (ContentDocumentLink cdlIDs : noterelatedtoEvent){
                  if (!eventIDs.contains(cdlIDs.LinkedEntityId)){
                      eventIDs.add(cdlIDs.LinkedEntityId);
                  }
              }
              
              if (!eventIDs.isEmpty()){
                  List<Event> eventrelatedtoaccount = [Select Id, WhatId from Event where ID IN: eventIDs];
                  Set<Id> eventrelatedtoppty = new Set<Id>();
                  Set<Id> eventrelatedtoaccloc = new Set<Id>();
                  Map <Id,Id> eventrelatedtoopportunity = new Map <Id, Id>();
                  Map <Id,Id> opportunityrelatedtoaccounts = new Map <Id, Id>();
                  Map <Id,Id> eventrelatedtoaccountlocation = new Map <Id, Id>();
                  Map <Id,Id> accountlocationrelatedtoaccounts = new Map <Id, Id>();
                  if (!eventrelatedtoaccount.isEmpty()){
                      Map <Id, Id> eventrelatedtoaccounts = new Map <Id, Id>();
                      for (Event e : eventrelatedtoaccount){
                          if (e.WhatId != null){
                              if (String.valueOf(e.WhatId).left(3) == SM_Constants.accountPrefix){
                                    eventrelatedtoaccounts.put(e.Id, e.WhatId);
                              }
                              else if (String.valueOf(e.WhatId).left(3) == SM_Constants.oppPrefix){
                                    eventrelatedtoppty.add(e.WhatId);
                                    eventrelatedtoopportunity.put(e.Id, e.WhatId);
                              }
                              else if (String.valueOf(e.WhatId).left(3) == Label.Account_Location_Prefix){
                                    eventrelatedtoaccloc.add(e.WhatId);
                                    eventrelatedtoaccountlocation.put(e.Id, e.WhatId);
                              }
                          }
                      }
                      if (!eventrelatedtoaccounts.isEmpty()){
                            finalizenotes = compilecontentdocuments(noterelatedtoEvent, eventrelatedtoaccounts);
                      }
                      if (!eventrelatedtoppty.isEmpty()){
                          List<Opportunity> getaccountfromoppty = [Select Id, AccountID from Opportunity where ID IN: eventrelatedtoppty];
                          if (!getaccountfromoppty.isEmpty()){
                              for (Opportunity o : getaccountfromoppty){
                                  if (o.AccountId != null){
                                      opportunityrelatedtoaccounts.put(o.Id, o.AccountId);
                                  }
                              }
                              if (!opportunityrelatedtoaccounts.isEmpty()){
                                  finalizenotes = compilecontentdocumentsfortwolayerobjects(noterelatedtoEvent, eventrelatedtoopportunity, opportunityrelatedtoaccounts);
                              }
                          }
                      }
                      if (!eventrelatedtoaccloc.isEmpty()){
                          List<Apttus_Config2__AccountLocation__c> getaccountfromaccloc = [Select Id, Apttus_Config2__AccountId__r.Id from Apttus_Config2__AccountLocation__c where ID IN: eventrelatedtoaccloc];
                          if (!getaccountfromaccloc.isEmpty()){
                              for (Apttus_Config2__AccountLocation__c accloc : getaccountfromaccloc){
                                  if (accloc.Apttus_Config2__AccountId__r.Id != null){
                                      accountlocationrelatedtoaccounts.put(accloc.Id, accloc.Apttus_Config2__AccountId__r.Id);
                                  }
                              }
                              if (!accountlocationrelatedtoaccounts.isEmpty()){
                                  finalizenotes = compilecontentdocumentsfortwolayerobjects(noterelatedtoEvent, eventrelatedtoaccountlocation, accountlocationrelatedtoaccounts);
                              }
                          }
                      }
                  }
              }
          }
        
        if (!finalizenotes.isEmpty()){
            List<ContentDocumentLink> insertnotes = new List<ContentDocumentLink>();
            insertnotes.addAll(finalizenotes);
            List <ContentDocumentLink> checkrecords = [Select Id, ContentDocumentId, LinkedEntityId from ContentDocumentLink where ContentDocumentId = :documentId AND LinkedEntityId = :accountId];
            if (checkrecords.size() == 0){
                insert insertnotes;
            }
        }
        
        
        
        } catch (Exception e){
            CustomLogging.debugException(e);
            CustomLogging.pop();
            System.debug(e.getMessage() + '\n' + e.getStackTraceString());
        }
    }
}