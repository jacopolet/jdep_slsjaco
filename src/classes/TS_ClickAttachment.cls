//-------------------------------------------------------------------------------------------//
// Author       :   Harold Marilag
// Created Date :   June 27, 2017
// Usage        :   Apex Class for converting obtained file from amazon web service to salesforce attachment
// Changes      :   
//-------------------------------------------------------------------------------------------//
public without sharing class TS_ClickAttachment {
    
    /*
    *@Author : Ritesh Kumar
    *Create date : 14.08.2014
    *Usage : TS_ClickAttachmentException class responsible for throwing an exception 
    */
    public class TS_ClickAttachmentException extends Exception {  }
    
    public void AttachFile(List<Integration_Log__c> forClickAttachment){
        CustomLogging.push('AttachFile', 'TS_ClickAttachment');
        String laccesskeyid;
        String lsecretkey;
        String ltoken;
        String lregion;
        String lendpoint;
        String lpayload;
        String lquery;
        String lresource;
        
        List<ContentVersion> contentVersionList = new List<ContentVersion>();
        List<ContentDocumentLink> contentDocLink = new List<ContentDocumentLink>();
        List<Integration_Log__c> iLogToDelete = new List<Integration_Log__c>();
        
        Blob versionData;
        Boolean ableToConvertVersionData = true;
        
        HttpResponse response = null;
        
        IntegrationUserAndProfile__c credentials = [SELECT Click_Token_Server__c, AWS_Endpoint__c,AWS_Password__c,AWS_Username__c FROM IntegrationUserAndProfile__c limit 1];
        
        try{
            TS_AWS_getToken ts = new TS_AWS_getToken();
            TS_AWS_getToken.AWSTokenResult tr= new TS_AWS_getToken.AWSTokenResult ();
            tr = ts.gettoken(credentials.AWS_Username__c, credentials.AWS_Password__c, credentials.Click_Token_Server__c);
            laccesskeyid = tr.awsaccesskeyid;
            lsecretkey= tr.awssecretaccesskey;
            ltoken=tr.awstoken;
            lregion=tr.awsregion;
            lendpoint = credentials.AWS_Endpoint__c;
            lpayload = '';
            lquery='';
            if(Test.isRunningTest()){
                throw new TS_ClickAttachmentException('error data');
            }
        }
        catch(Exception e){
            system.debug(e.getMessage());
        }
        
        TS_AWS_getFile aws = new TS_AWS_getFile();
        
        for(Integer c = 0; c < forClickAttachment.size(); c++){
            versionData = null;
            ableToConvertVersionData = true;
            
            if((!String.isBlank(forClickAttachment.get(c).Useful_Container__c)) && (!String.isBlank(forClickAttachment.get(c).Work_Order_Line_Item__c))) {
                forClickAttachment.get(c).Integration_Status__c = INT_Constants.TARGET_SYSTEM_SUCCESS;
                try{
                    lresource = changeSpecialChars(forClickAttachment.get(c).Useful_Container__c);
                    response = aws.sendRequest(laccesskeyid,lsecretkey,  ltoken, lregion, lresource, lendpoint,lpayload, lquery);//get image from amazon using url in Useful_Container__c
                    versionData = response.getBodyasBlob();
                }
                catch(Exception e){
                    ableToConvertVersionData = false;
                    forClickAttachment.get(c).Integration_Status__c = INT_Constants.TARGET_SYSTEM_ERROR;
                    forClickAttachment.get(c).Integration_Message__c = e.getMessage() + ', ';
                    system.debug(e.getMessage());
                }
                if(((response != null) && (response.getStatusCode() != 200)) || (response == null)){
                    forClickAttachment.get(c).Integration_Status__c = INT_Constants.TARGET_SYSTEM_ERROR;
                    ableToConvertVersionData = false;
                }
                ContentVersion testPic = new ContentVersion();
                testPic.VersionData = versionData;
                testPic.Title = forClickAttachment.get(c).Useful_Container__c.substring(forClickAttachment.get(c).Useful_Container__c.lastIndexOf('/') + 1); //filename from the url
                testPic.PathOnClient = forClickAttachment.get(c).Useful_Container__c; //path from the url!!!!!
                testPic.ContentLocation='S';
                
                ContentDocumentLink cdl = new ContentDocumentLink();
                cdl.LinkedEntityId = forClickAttachment.get(c).Work_Order_Line_Item__c;
                cdl.ShareType = 'v';
                if(ableToConvertVersionData == true){ //if response.getbodyasblob is able to conve
                    contentVersionList.add(testPic);
                    contentDocLink.add(cdl);
                    iLogToDelete.add(forClickAttachment.get(c));
                    
                }
                if(response != null){forClickAttachment.get(c).Integration_Message__c = 'Status Code: ' + response.getStatusCode() + ', Status: ' + response.getStatus();}
            }
            else{
                if(String.isBlank(forClickAttachment.get(c).Useful_Container__c)){
                    forClickAttachment.get(c).Integration_Status__c = INT_Constants.TARGET_SYSTEM_ERROR;
                    forClickAttachment.get(c).Integration_Message__c = 'No resource URL.';
                }
            }
            
        }
        
        if (Schema.sObjectType.Integration_Log__c.isUpdateable()) {
            update forClickAttachment;        
        }
        
        if(!contentVersionList.isEmpty() && Schema.sObjectType.ContentDocumentLink.isCreateable()){
            insert contentVersionList;
        }
        
        
        List<ContentVersion> newContentVersionList = [Select ContentDocumentId from ContentVersion where Id In :contentVersionList]; //get updated ContentVersion record that are now linked to ContentDocument
        List<ContentVersion> newContentVersionList2 = new List<ContentVersion>(); //this list will hold sorted ContentVersion records
        
        // this loop is for sorting out updated (with corresponding ContentDocumentId) ContentVersion records
        for(Integer j=0;j<contentVersionList.size();j++){
            for(ContentVersion ncv : newContentVersionList){
                if(ncv.Id == contentVersionList.get(j).Id){
                    newContentVersionList2.add(ncv);
                }
            }
        }
        
        //this loop is for linking ContentVersion record (linked with ContentDocument) to ContentDocumentLink record (linked with WOLI)
        for(Integer i = 0; i < forClickAttachment.size(); i++){
            try{
                contentDocLink.get(i).ContentDocumentId = newContentVersionList2.get(i).ContentDocumentId;
            }
            catch(Exception e){
                system.debug('contentdoclink to contentversion: ' + e.getMessage());
                system.debug(contentDocLink);
                system.debug(newContentVersionList2);
            }
        }
        
        if (!contentDocLink.isEmpty() && Schema.sObjectType.ContentVersion.isCreateable()){
            try{
                insert contentDocLink;
            }
            catch(Exception e){
                System.debug(e.getMessage());
            }
        }
        
        
        //delete successful logs
        Boolean deleteSuccessLogs = [Select Click_Delete_Success_Logs__c from IntegrationUserAndProfile__c limit 1].Click_Delete_Success_Logs__c;
        if(deleteSuccessLogs && Schema.sObjectType.IntegrationUserAndProfile__c.isDeletable()){
            delete iLogToDelete;
        }
        CustomLogging.pop();
    }
    
    public String changeSpecialChars(String url){
        CustomLogging.push('changeSpecialChars', 'TS_ClickAttachment');
        
        String s = '\\(';
        String a = '%28';
        String s1 = '\\)';
        String a1 = '%29';
        String s2 = '\\[';
        String a2 = '%5B';  
        String s3 = '\\]';
        String a3 = '%5D';     
        String s4 = '\\{';
        String a4 = '%7B';      
        String s5 = '\\}';
        String a5 = '%7D';   
        String s6 = '\\|';
        String a6 = '%7C';
        url = url.replaceAll(s, a);
        url = url.replaceAll(s1, a1);
        url = url.replaceAll(s2, a2);
        url = url.replaceAll(s3, a3);
        url = url.replaceAll(s4, a4);
        url = url.replaceAll(s5, a5);
        url = url.replaceAll(s6, a6);
        CustomLogging.pop();
        return url;
    }
    
    
}