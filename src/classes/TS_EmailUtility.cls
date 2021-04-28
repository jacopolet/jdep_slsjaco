/**
* @author        Paul Jarred Aguiling
* @date          9.27.2017           
* @description   Utility class for sending email with PDF attachments and generated links
* @revision(s)   12.05.2017 Paul Aguiling KTS 357 - Updated methods for additional logics and refractored class for readability
*/
global with sharing class TS_EmailUtility {

    //Variable used for visualforce component generated link (TS_EmailUtilityLink)
    public static List<ContentDistribution> contentList {get; set;}

    /**
    * @author        Paul Jarred Aguiling
    * @date          9.27.2017
    * @description   Class variables invoked from the process builder
    * @revision(s)
    */
    global class TS_EmailAttributes {
        @InvocableVariable(required=false)
        global Id recordId;

        @InvocableVariable(required=false)
        global Id targetRecipientId;

        @InvocableVariable(required=false)
        global String emailAddress;

        @InvocableVariable(required=false)
        global String emailAddress2; //added by Archi to support two email address for process builder in a single email

        @InvocableVariable(required=false)
        global String emailfromAddress; //added by Archi to support default from address

        @InvocableVariable(required=false)
        global String ccAddress;

        @InvocableVariable(required=false)
        global String bccAddress;

        @InvocableVariable(required=false)
        global String replyTo;

        @InvocableVariable(required=false)
        global String emailTemplateName;
        //Added by Ata
        @InvocableVariable(required=false)
        global String emailTemplateType;
        //if hasToGenerateLink is true then the links to the files will be generated in visualforce components that can be embeded in the email template( only
        //visualforce email template)
        @InvocableVariable(required=false)
        global Boolean hasToGenerateLink;

        @InvocableVariable(required=false)
        global Boolean hasToGenerateAttachment;

        @InvocableVariable(required=false)
        global Boolean hasToGenerateLinkWithPDF;

        @InvocableVariable(required=false)
        global String selectedlanguage;

        @InvocableVariable(required=false)
        global String selectedCountry;// added by Archi

        @InvocableVariable(required=false)
        global Id emailParentID;// added by Archi to create emailmessage record with this parent id

        @InvocableVariable(required=false)
        global String emailSubject;

        @InvocableVariable(required=false)
        global Boolean hasEmailMessage;

        @InvocableVariable(required=false)
        global Id filesId;

        @InvocableVariable(required=false)
        global Id filesId2;

        @InvocableVariable(required=false)
        global Id filesId3;

        @InvocableVariable(required=false)
        global String setManualEmailBody;

        @InvocableVariable(required=false)
        global Boolean isTargetNotRecepient;
    }

    /**
    * @author        Paul Jarred Aguiling
    * @date          9.27.2017
    * @description   Wrapper class for files attachment
    * @revision(s)
    */
    public class PDFAttachmentWrapper {
        public String name;
        public Blob attachFile;
        public Messaging.EmailFileAttachment linkAttachment;
        public String fileExt;

        public PDFAttachmentWrapper(String name, Blob fileAttach, Messaging.EmailFileAttachment efa, String fileExt) {
            this.name = name;
            this.attachFile = fileAttach;
            this.linkAttachment = efa;
            this.fileExt = fileExt;
        }
    }

    /**
    * @author        Paul Jarred Aguiling
    * @date          9.27.2017
    * @description   Wrapper class for messaging send email inputs
    * @revision(s)
    */
    public class EmailAttributesWrapper {
        public String emailAd;

        public String ccAddress;
        public String bccAddress;
        public String emailSubj;
        public String replyToAddress;
        public String emailAd2; //added by Archi to accomodate list of email address.
        public String defaultfromaddress; //added by Archi
        public String manualEmailBody;//added by Archi

        public EmailAttributesWrapper(String emailAd, String ccAddress, String bccAddress, String emailSubj, String replyToAddress, String emailAd2, string defaultfromaddress, String manualEmailBody) {
            this.emailAd = emailAd;

            this.ccAddress = ccAddress;
            this.bccAddress = bccAddress;
            this.emailSubj = emailSubj;
            this.replyToAddress = replyToAddress;
            this.emailAd2 = emailAd2; //added by Archi
            this.defaultfromaddress =defaultfromaddress ; //added by Archi
            this.manualEmailBody= manualEmailBody;//added by Archi
        }
    }

    /**
    * @author        Paul Jarred Aguiling
    * @date          9.27.2017
    * @description   Method responsible for sending email with attachments
    * @revision(s)
    */
    @InvocableMethod
    global static void sendEmailWithAttachment(List<TS_EmailAttributes> emailAttributes) {
        CustomLogging.push('sendEmailWithAttachment', 'TS_EmailUtility');
        Set<Id> sObjectIds = new Set<Id>();
        Map<Id, Id> mapOfFilesId = new Map<Id, Id>();
        Map<Id, List<Id>> recordIdsMap = new Map<Id, List<Id>>();
        Boolean templateFlag = false;
        Map<Id, List<Id>> contentDocLinkMap = new Map<Id, List<Id>>();
        List<Id> contentDocListId = new List<Id>();
        Set<List<Id>> validateFilesId = new Set<List<Id>>();
        Map<Id, List<ContentDistribution>> contentDistMap;
        Map<Id, PDFAttachmentWrapper> contVrMap = new Map<Id, PDFAttachmentWrapper>();

        //Iterate list of record id from process builder
        for(TS_EmailAttributes objId: emailAttributes) {
            sObjectIds.add(objId.recordId);

            //Determine salesforce files not directly related to record object
            if (objId.filesId != null || objId.filesId2 != null || objId.filesId3 != null) {
                recordIdsMap.put(objId.recordId, new List<Id>());

                if (objId.filesId != null) {
                    recordIdsMap.get(objId.recordId).add(objId.filesId);
                    mapOfFilesId.put(objId.filesId, objId.filesId);
                    sObjectIds.add(objId.filesId);
                }

                if (objId.filesId2 != null) {
                    recordIdsMap.get(objId.recordId).add(objId.filesId2);
                    mapOfFilesId.put(objId.filesId2, objId.filesId2);
                    sObjectIds.add(objId.filesId2);
                }

                if (objId.filesId3 != null) {
                    recordIdsMap.get(objId.recordId).add(objId.filesId3);
                    mapOfFilesId.put(objId.filesId3, objId.filesId3);
                    sObjectIds.add(objId.filesId3);
                }
            } else {
                recordIdsMap.put(objId.recordId, null);
            }
            //get template name, language, country
        }

        contentDistMap = getContentDocumentLink(sObjectIds);

        if (sObjectIds != null && sObjectIds.size() > 0) {
            //Query the related files as per record and files Id. ContentDocumentId is the Id of the files and LinkedEntityId is the id of case.
            List<ContentDocumentLink> contentDocList = [SELECT ContentDocumentId, LinkedEntityId FROM ContentDocumentLink WHERE LinkedEntityId IN :sObjectIds];

            //Retrieve files Id
            Map<Id, List<Id>> filesIdMap = new Map<Id, List<Id>>();
            for (ContentDocumentLink cntntDocLink: contentDocList) {
                if (mapOfFilesId.get(cntntDocLink.LinkedEntityId) != null) {
                    //Validate if key id is already in place (key id should be unique per content document)
                    if (filesIdMap.containsKey(cntntDocLink.LinkedEntityId)) {
                        filesIdMap.get(cntntDocLink.LinkedEntityId).add(cntntDocLink.ContentDocumentId);
                    } else {
                        filesIdMap.put(cntntDocLink.LinkedEntityId, new List<Id>{cntntDocLink.ContentDocumentId});
                    }
                }
            }

            for (ContentDocumentLink cntntDocLink: contentDocList) {
                //Validate if record/key id is already in place (key id should be unique per content document)
                if (contentDocLinkMap.containsKey(cntntDocLink.LinkedEntityId)) {

                    //Add content document id on the list based on record id
                    contentDocLinkMap.get(cntntDocLink.LinkedEntityId).add(cntntDocLink.ContentDocumentId);

                    //Validate if files id is related to the record id
                    if (recordIdsMap.get(cntntDocLink.LinkedEntityId) != null && validateFilesId.add(recordIdsMap.get(cntntDocLink.LinkedEntityId))) {
                        for (Id initialfileId : recordIdsMap.get(cntntDocLink.LinkedEntityId)) {
                            for (Id fileId: filesIdMap.get(initialfileId)) {
                                contentDocLinkMap.get(cntntDocLink.LinkedEntityId).add(fileId);
                            }
                        }
                    }
                    //Insert new list of record/key ids
                } else {
                    if (mapOfFilesId.isEmpty() || recordIdsMap.get(cntntDocLink.LinkedEntityId) != null) {
                        contentDocLinkMap.put(cntntDocLink.LinkedEntityId, new List<Id>{cntntDocLink.ContentDocumentId});
                    }
                }

                //Add all content document ids
                contentDocListId.add(cntntDocLink.ContentDocumentId);
            }

            //Retrieve ContentVersion records based on ContentDocumentIds
            for (ContentVersion contVr: [SELECT Title, VersionData, FileExtension, ContentDocumentId FROM ContentVersion WHERE ContentDocumentId IN :contentDocListId]) {
                PDFAttachmentWrapper pWrap = new PDFAttachmentWrapper(contVr.Title, contVr.VersionData, null, contVr.FileExtension);
                contVrMap.put(contVr.ContentDocumentId, pWrap);
            }
        }

        List<EmailMessage> emailmsgToInsert = new List<EmailMessage>();
        for (TS_EmailAttributes emailAtt: emailAttributes) {

            //Concatenate template name with preferred language
            String templateName ;
            String defaultTemplate;
            //Added by Ata
            if(String.isNotBlank(emailAtt.emailTemplateType)) {
                Map<String, String> templateMap = getTemplateName(emailAtt.emailTemplateName, emailAtt.selectedCountry, emailAtt.emailTemplateType);
                if (templateMap != null && templateMap.size() > 0) {
                    templateName = templateMap.get(emailAtt.emailTemplateName + '_' + emailAtt.selectedCountry + '_' + emailAtt.selectedlanguage);
                    defaultTemplate = templateMap.get(emailAtt.emailTemplateName + '_' + emailAtt.selectedCountry + '_default');
                }else{
                    //if no template found then break and stop the flow
                    templateFlag = true;
                    break;
                }
            }else {
                //commented by Ata
                if (!String.isblank(emailAtt.selectedlanguage)  && !String.isblank(emailAtt.selectedCountry) ){
                    templateName = emailAtt.emailTemplateName + '_' + emailAtt.selectedCountry + emailAtt.selectedlanguage;
                } else if (!String.isblank(emailAtt.selectedCountry)) {
                    templateName = emailAtt.emailTemplateName + '_' + emailAtt.selectedCountry;
                    defaultTemplate = emailAtt.emailTemplateName;
                } else {
                    templateName = emailAtt.emailTemplateName;
                    defaultTemplate = emailAtt.emailTemplateName;
                }
            }
            //Determine if email should have PDF attachment or generated URL
            List<PDFAttachmentWrapper> pdfList = new List<PDFAttachmentWrapper>();

            //Generate pdf attachments with links
            if (emailAtt.hasToGenerateLinkWithPDF != null && emailAtt.hasToGenerateLinkWithPDF) {
                PDFAttachmentWrapper pdfWrap = new PDFAttachmentWrapper(null, null,  generateHyperlinksPDF(emailAtt.recordId, true, 'JDE_Files'), null);
                pdfList.add(pdfWrap);
                //Generate pdf attachments
            } else if (emailAtt.hasToGenerateAttachment != null && emailAtt.hasToGenerateAttachment) {
                if (contentDocLinkMap.get(emailAtt.recordId) != null) {
                    for (Id contentDocId: contentDocLinkMap.get(emailAtt.recordId)) {
                        pdfList.add(contVrMap.get(contentDocId));
                    }
                }
                //Generate links
            } else if (emailAtt.hasToGenerateLink != null && emailAtt.hasToGenerateLink) {
                if (contentDistMap != null && contentDistMap.size() > 0) {
                    contentList = contentDistMap.get(emailAtt.recordId);
                    //System.debug(contentList);
                }
            }

            //Set values for the email attribute wrapper class
            EmailAttributesWrapper emailAttWrap = new EmailAttributesWrapper(emailAtt.emailAddress, emailAtt.ccAddress, emailAtt.bccAddress,
                    emailAtt.emailSubject, emailAtt.replyTo, emailAtt.emailAddress2,
                    emailAtt.emailfromaddress, emailAtt.setManualEmailBody);

            //###### START: TS email Utility: sending the email #######
            //Generate PDF Attachments
            Messaging.SingleEmailMessage semail = sendEmailwithPDFAttachment(templateName, emailAtt.targetRecipientId,
                    emailAtt.recordId, pdfList, emailAttWrap,
                    defaultTemplate, emailAtt.isTargetNotRecepient);

            //###### END: TS email Utility: sending the email #######

            if (emailAtt.hasEmailMessage != null && emailAtt.hasEmailMessage) {
                EmailMessage emailMsg = new EmailMessage();
                String emailtoaddress;

                if (emailAtt.targetRecipientId != null) {
                    emailtoaddress = emailAtt.targetRecipientId;
                }

                if (semail.getToAddresses() != null && semail.getToAddresses().size() > 0) {
                    emailtoaddress = emailtoaddress + ', ' + String.join(semail.getToAddresses(), ', ');
                }

                emailMsg.ToAddress = emailtoaddress; //emailAtt.targetRecipientId+', '+string.join(semail.getToAddresses(),', ');//emailAtt.targetRecipientId;

                if (semail.getSubject() != null){
                    emailMsg.Subject= semail.getSubject() ;
                } else {
                    if (emailAtt.emailSubject != null) {
                        emailMsg.Subject = emailAtt.emailSubject;
                    } else {
                        emailMsg.Subject = 'Email subject is not defined';
                    }
                }

                //emailMsg.Subject= semail.getSubject != null? semail.getSubject:emailAtt.emailSubject!=null:emailAtt.emailSubject: 'Subject is not defined';
                //emailMsg.HtmlBody= semail.getHtmlBody();
                emailMsg.TextBody = semail.getPlainTextBody();
                if (emailAtt.emailParentID!=null) emailMsg.ParentId = emailAtt.emailParentID; //emailAtt.recordId;
                else emailMsg.ParentId = emailAtt.recordId;
                //emailMsg.ParentId = emailAtt.emailParentID; //emailAtt.recordId;
                emailMsg.MessageDate = System.now();
                emailmsgToInsert.add(emailMsg);
            }
        }

        try {
            //Insert list of emails in the related object record
            if (emailmsgToInsert.size()>0 && templateFlag == false)
                insert emailmsgToInsert;

        } catch (Exception ex) {
            CustomLogging.debugException(ex);
            CustomLogging.pop();
            throw new EmailUtilException ('[U-03] Unable to save list of email messages in the related object, if has email is true, check email parent ID. Error: '+ ex );
        }

        Customlogging.pop();
    }



    /**
    * @author         Ata Khan
    * @date           15.02.2019
    * @description    Method responsible for searching for appropriate email template
    * @revision(s)
    */
    public static Map<String, String> getTemplateName(String templateName, String country, String templateType){
        Map<String, String> templateMap = new Map<String, String>();
        String recordType = Schema.SObjectType.CountrySetting__c.getRecordTypeInfosByName().get('Email Template Settings').getRecordTypeId();

        if(String.isNotBlank(templateName) && String.isNotBlank(country) && String.isNotBlank(templateType)){
            String newTemplateName = templateName + '%'; // Template_type__c =: templateType AND
            List<CountrySetting__c> cSettings = [SELECT Id,Default_template__c,Language__c,Template_type__c,Template_Unique_Name__c,Country__c FROM CountrySetting__c WHERE Name LIKE :newTemplateName AND Active__c = true AND Country__c =: country and recordtypeId =: recordType];

            if(cSettings != null && cSettings.size() > 0){
                for(CountrySetting__c cs:cSettings){
                    templateMap.put(templateName +'_'+cs.Country__c+'_'+cs.Language__c, cs.Template_Unique_Name__c);
                    if(cs.default_template__c == true){
                        templateMap.put(templateName +'_'+cs.Country__c+'_default', cs.Template_Unique_Name__c);
                    }
                }
            }
        }
        return templateMap;
    }

    /**
    * @author         Paul Jarred Aguiling
    * @date           9.25.2017
    * @description    Method responsible for throwing an exception
    * @revision(s)
    */
    public class EmailUtilException extends Exception {}

    /**
    * @author         Paul Jarred Aguiling
    * @date           9.25.2017
    * @description    Method responsible for getting generated links
    * @revision(s)
    */
    public static Map<Id, List<ContentDistribution>> getContentDocumentLink(Set<Id> sObjectIds) {
        CustomLogging.push('getContentDocumentLink', 'TS_EmailUtility');
        Map<Id, List<ContentDistribution>> contentDistMap = new Map<Id, List<ContentDistribution>>();

        for (ContentDistribution contentDist: [SELECT Id, Name, DistributionPublicUrl, RelatedRecordId
        FROM ContentDistribution
        WHERE RelatedRecordId IN :sObjectIds]) {

            if (contentDistMap.containsKey(contentDist.RelatedRecordId)) {
                contentDistMap.get(contentDist.RelatedRecordId).add(contentDist);
            } else {
                contentDistMap.put(contentDist.RelatedRecordId, new List<ContentDistribution>{contentDist});
            }
        }

        CustomLogging.pop();
        return contentDistMap;
    }

    /**
    * @author         Paul Jarred Aguiling
    * @date           9.25.2017
    * @description    Method responsible for sending the corresponding email attachments
    * @param          templateApiName   Name of email template that will be used
    * @param          targetObjId       Must be a Contact, User, Lead Id. Also used in merge fields of template recipient
    * @param          whatId            Must be an SObject that is used in the merge fields of the template relatedTo
    * @param          attachFiles       List of files needs to be attach in the email
    * @param          emailInput        Collection of email attributes
    * @revision(s)
    */
    private static Messaging.SingleEmailMessage sendEmailwithPDFAttachment(String templateApiName, ID targetObjId, Id whatId, List<PDFAttachmentWrapper> attachFiles,
            EmailAttributesWrapper emailInput, String defEmailTemp, Boolean isTargetNotRecepient) {
        CustomLogging.push('sendEmailwithPDFAttachment', 'TS_EmailUtility');
        List<Attachment> attachmentToInsert = new List<Attachment>();
        List<Messaging.EmailFileAttachment> lstFileAttachments = new List<Messaging.EmailFileAttachment>();
        for (PDFAttachmentWrapper pdfWrapper: attachFiles) {
            if (pdfWrapper.Name != null) {
                Attachment attachmnt = new Attachment();
                attachmnt.Body = pdfWrapper.attachFile;
                attachmnt.Name = pdfWrapper.name;
                attachmnt.IsPrivate = false;
                attachmnt.ParentId = whatId;
                attachmentToInsert.add(attachmnt);

                Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
                efa.setFileName(pdfWrapper.name + '.' + pdfWrapper.fileExt);
                efa.setBody(pdfWrapper.attachFile);
                lstFileAttachments.add(efa);
            } else {
                //Add list of pdf attachments with URL
                lstFileAttachments.add(pdfWrapper.linkAttachment);
            }
        }

        //if (!attachmentToInsert.isEmpty())
        //insert attachmentToInsert;

        //---sending email with email template must have template id and target object id ---//
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setInReplyTo(emailInput.replyToAddress);
        email.setSubject(emailInput.emailSubj);

        if (emailinput.ManualEmailBody != null && !emailinput.ManualEmailBody.equals('')) {
            email.setHtmlBody(emailinput.manualEmailBody);
        } else {
            Id templateId;
            try {
                List<EmailTemplate> emailTemp = [SELECT id, Name FROM EmailTemplate WHERE developername =: templateApiName];
                if (emailTemp != null && emailTemp.size() > 0) {
                    for (EmailTemplate emp: emailTemp) {
                        templateId = emp.Id;
                    }
                } else {
                    templateId = [SELECT id, Name FROM EmailTemplate WHERE developername =: defEmailTemp].id;
                }
            } catch (Exception e) {
                throw new EmailUtilException ('[U-03] Unable to locate EmailTemplate using name: ' + templateApiName +
                        ' refer to Setup | Communications Templates ' + templateApiName);
            }

            //TODO: In case of 'targetobjectids' email address field is null. Workaround is to create dummy contact to insert in setTargetObjectId then set 
            //this attribute 'email.setTreatTargetObjectAsRecipient(false)' 

            if(isTargetNotRecepient != null && isTargetNotRecepient == true){
                email.setTreatTargetObjectAsRecipient(false);
            }

            email.setTargetObjectId(targetObjId);
            email.setTemplateId(templateId);
        }

        email.setWhatId(whatId);
        email.setFileAttachments(lstFileAttachments);

        //--------added by Archi--------------//
        if (emailInput.defaultfromaddress!=null && !emailInput.defaultfromaddress.equals ('')) {
            OrgWideEmailAddress oweaID = [select Id from OrgWideEmailAddress where Address =: emailInput.defaultfromaddress limit 1];

            if (oweaID != null) {
                email.setOrgWideEmailAddressId(oweaID.Id);
            }
        }

        List<string> extraemailaddress = new list<string>();
        if (emailInput.emailAd != null && !emailInput.emailAd.equals ('')) {
            extraemailaddress.add(emailInput.emailAd);
        }

        if (emailInput.emailAd2 != null && !emailInput.emailAd2.equals('')) {
            extraemailaddress.add(emailInput.emailAd2);
        }

        if (extraemailaddress!= null && extraemailaddress.size()>0) {
            email.setToAddresses(extraemailaddress);
        }

        if (emailInput.bccAddress != null && !emailInput.bccAddress.equals('')) {
            email.setBccAddresses(new List<String>{emailInput.bccAddress});
        }

        if (emailInput.ccAddress != null && !emailInput.ccAddress.equals('')) {
            email.setCcAddresses(new List<String>{emailInput.ccAddress});
        }

        //email.setSaveAsActivity(saveAsActivity);      // Save email as activity on the targetObjId (i.e. Contact). Note activity can't be saved on Users  
        //System.debug(LoggingLevel.INFO,'** entered sendTemplatedEmail, to:' + toRecipients + ' cc:' + ccRecipients +  ' templateId:' + templateId + ' tagetObjId:' + targetObjId + 
        //                ' whatId:' + whatId + ' orgWideEmailId: ' + orgWideEmailId);

        try {
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email});
        } catch (EmailException e) {
            throw new EmailUtilException('[U-02] TS_EmailUtility: sendEmailwithPDFAttachment error. ' + e.getMessage());
        }

        CustomLogging.pop();
        return email;
    }

    /**
    * @author         Archi Delphinanto
    * @date           9.25.2017
    * @description    Generate a page with a list of hyperlink. It is asssumed that the Salesforce file 
    *                 has been linked to SF ContentDistribution to get public URL
    * @param          objectid      It should be the RelatedRecordID  for Salesforce ContentDistribution,
    * @param          showAsPDF     True: attachment is in form of PDF, false:in form of html
    * @param          whatId        The name of the file for the attachment, i.e. without extension (file format can only be pdf or html).
    * @return         EmailFileAttachment  Contains a PDF page with a list of hyperlinks related to the objectid
    * @revision(s)
    */
    public static Messaging.EmailFileAttachment generateHyperlinksPDF(String objectid, boolean showAsPDF, String attcfilename) {
        CustomLogging.push('generateHyperlinksPDF', 'TS_EmailUtility');
        PageReference hyperlinkpage = Page.TS_EmailUtility_Hyperlink;

        hyperlinkpage.getParameters().put('id',objectid);
        if (showAsPDF!=null && showAsPDF == false) {
            hyperlinkpage.getParameters().put('showAsPDF',String.valueOf(showAsPDF));
            attcfilename = attcfilename + '.html';
        } else {
            attcfilename =  attcfilename + '.pdf';
        }

        hyperlinkpage.setRedirect(true);
        Blob b;

        if (Test.isRunningTest()) {
            b = Blob.valueOf('UNIT.Test');
        } else {
            b = hyperlinkpage.getContent();
        }

        Messaging.EmailFileAttachment ema= new Messaging.EmailFileAttachment();
        ema.setBody(b);
        ema.setFileName(attcfilename);
        CustomLogging.pop();
        return ema;
    }
}