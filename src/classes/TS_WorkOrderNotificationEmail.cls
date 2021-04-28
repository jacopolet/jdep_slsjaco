/**
* @author        Ata
* @date          13.02.2019           
* @description   Class for sending email to Engineers when task is assigned to them
* @revision(s)   
*/
global without sharing class TS_WorkOrderNotificationEmail {


    /**
    * @author         Ata
    * @date           13.02.2019 
    * @description    Method responsible for throwing an exception
    * @revision(s)
    */ 
    public class EmailUtilException extends Exception {}
    public static Boolean hasException = false;
    /**
    * @author        Ata
    * @date          13.02.2019           
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
        global String emailfromAddress; 
        
        @InvocableVariable(required=false)
        global Boolean hasEmailMessage;
        
        @InvocableVariable(required=false)
        global String ccAddress;

        @InvocableVariable(required=false)
        global String bccAddress;

        @InvocableVariable(required=false)
        global String replyTo;

        @InvocableVariable(required=false)
        global String emailTemplateName;
        
        @InvocableVariable(required=false)
        global String selectedlanguage;

        @InvocableVariable(required=false)
        global String selectedCountry;

        @InvocableVariable(required=false)
        global Boolean isTargetNotRecepient;
        
        @InvocableVariable(required=false)
        global Boolean emailParentID;
    }
    /**
    * @author        Ata Khan
    * @date          13.2.2019          
    * @description   Method responsible for sending email for Executing Engineer
    * @revision(s)
    */
    @InvocableMethod
    global static void sendWorkOderEmail(List<TS_EmailAttributes> emailAttributes) {
        CustomLogging.push('sendWorkOderEmail', 'TS_WorkOrderNotificationEmail');
        //DOO 5427 - Pandian Sundaramoorthy - March 15, 2021
        List<String> templateNameList = new List<String>();
        List<String> emailFromAddressList = new List<String>();
        Map<String, Id> templateNameMap = new Map<String, Id>();
        Map<String, Id> emailFromAddressMap = new Map<String, Id>();
        
        for(TS_EmailAttributes emailAtt: emailAttributes){
            templateNameList.add(emailAtt.emailTemplateName);
            emailFromAddressList.add(emailAtt.emailfromaddress);
        }
        
        if(!templateNameList.isEmpty()){
            for(EmailTemplate emailTemp : [SELECT Id, developername FROM EmailTemplate WHERE developername IN : templateNameList]){
                templateNameMap.put(emailTemp.developername, emailTemp.Id);
            }
        }
        
        if(!emailFromAddressList.isEmpty()){
            for(OrgWideEmailAddress orgWide : [SELECT Id, Address FROM OrgWideEmailAddress WHERE Address IN : emailFromAddressList]){
                emailFromAddressMap.put(orgWide.Address, orgWide.Id);
            }
        }
        
        for (TS_EmailAttributes emailAtt: emailAttributes) {

            //Concatenate template name with preferred language
            String templateName = emailAtt.emailTemplateName;
            Id templateId;

            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();   
            email.setInReplyTo(emailAtt.replyTo);
            //email.setSubject(emailAtt.emailSubject);      

            try {
                if (Test.isRunningTest() && hasException) {
                    throw new EmailUtilException('Force to throw an exception');
                }
                //EmailTemplate emailTemp = [SELECT id, Name FROM EmailTemplate WHERE developername =: templateName limit 1];
                //if(emailTemp != null){
                //DOO 5427 - Pandian Sundaramoorthy - March 15, 2021
                if(!templateNameMap.isEmpty() && templateNameMap.containsKey(templateName)){
                    //templateId = emailTemp.Id;
                    templateId = templateNameMap.get(templateName);
                }else{
                    throw new EmailUtilException('sendWorkOderEmail : TS_WorkOrderNotificationEmail error. Template not found');
                }                   
            } catch (Exception e) {
                CustomLogging.debugException(e);
                CustomLogging.pop();
                //throw new EmailUtilException ('Unable to locate EmailTemplate using name: ' + templateName + 
                          //' refer to Setup | Communications Templates ' + templateName );
            } 
            
            if(emailAtt.isTargetNotRecepient != null && emailAtt.isTargetNotRecepient == true){
                email.setTreatTargetObjectAsRecipient(false);
            }
            
            email.setTargetObjectId(emailAtt.targetRecipientId);
            email.setTemplateId(templateId);


            email.setWhatId(emailAtt.recordId);
            try {
                //--------added by Archi--------------//
                if (emailAtt.emailfromaddress != null && !emailAtt.emailfromaddress.equals ('')) {
                    
                    /* OrgWideEmailAddress oweaID = [select Id from OrgWideEmailAddress where Address = :emailAtt.emailfromaddress limit 1];
                    if (oweaID != null) {
                        email.setOrgWideEmailAddressId(oweaID.Id);
                    } */

                    //ALM 6743 - Xen Reyes - April 15, 2019
                    //List<OrgWideEmailAddress> oweaID = [SELECT Id FROM OrgWideEmailAddress WHERE Address = :emailAtt.emailfromaddress LIMIT 1];
                    //if (!oweaID.isEmpty()) {
                    //DOO 5427 - Pandian Sundaramoorthy - March 15, 2021
                    if(!emailFromAddressMap.isEmpty() && emailFromAddressMap.containsKey(emailAtt.emailfromaddress)){
                        //email.setOrgWideEmailAddressId(oweaID[0].Id);
                        email.setOrgWideEmailAddressId(emailFromAddressMap.get(emailAtt.emailfromaddress));
                    }

                }
            }catch (Exception e) {
                CustomLogging.debugException(e);
                CustomLogging.pop();
            }
            String toAddress;
            String bccAddress;
            String ccAddress;
            
            if (String.isNotBlank(emailAtt.emailAddress)) {
                toAddress = emailAtt.emailAddress.trim().remove(',').remove(';').removeEnd('.');
            }
            if (String.isNotBlank(emailAtt.bccAddress)) {
                bccAddress = emailAtt.bccAddress.trim().remove(',').remove(';').removeEnd('.');
            }
            if (String.isNotBlank(emailAtt.ccAddress)) {
                ccAddress = emailAtt.ccAddress.trim().remove(',').remove(';').removeEnd('.');
            }
            
            if (String.isNotBlank(toAddress)) {
                email.setToAddresses(new List<String>{toAddress});
            }

            if (String.isNotBlank(bccAddress)) {
                email.setBccAddresses(new List<String>{bccAddress});
            }

            if (String.isNotBlank(ccAddress)) {
                email.setCcAddresses(new List<String>{ccAddress});
            }
            
            try {
                if (Test.isRunningTest() && hasException) {
                    throw new EmailUtilException('Force to throw an exception');
                }
                Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email});
            } catch (Exception e) {
                System.debug('Exception:::'+e);
                CustomLogging.debugException(e);
                CustomLogging.pop();
                //throw new EmailUtilException('TS_WorkOrderNotificationEmail: sendWorkOderEmail error. ' + e.getMessage());
            } 
        }
        CustomLogging.pop(); 
    }
}