/**
 * Class Name : APTS_CustomErrorLogging
 * Description : Custom Logging class to facilitate Exception Handling for OTC functionalities
 * Author : Venky Muppalaneni
 * Date Created : 06-10-2020
 **/
public without sharing class APTS_CustomErrorLogging {

    private static List<APTS_Error_Object__c> insertList = new List<APTS_Error_Object__c> ();
    public static String transactionId;
    private static String transactionIdFormat='dd_MM_yyyy_HH:mm:ss';
    /**Method Name : sendEmail
     * Description : Method to send email based on input parameters
     **/
    public static void sendEmail(List<String> toAddresses, String subject, String mailBody, String senderName) {
        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage> ();
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(toAddresses);
        mail.setReplyTo('test@test.com');
        mail.setSenderDisplayName(senderName);
        mail.setSubject(subject);
        mail.setHtmlBody(mailBody);
        mails.add(mail);
        if(!Test.isRunningTest())
        Messaging.sendEmail(mails);
    }

    /**Method Name : assign transaction id
     * Description : Method to assign transaction id
     **/
    public static void assignTransactionId(string transId) {
        transactionId=transId!=null?transId :(system.now()).format(transactionIdFormat);
    }

    /**Method Name : createErrorLog
     * Description : Method to create and return Error Object records whenever an exception is caught
     **/
    public static APTS_Error_Object__c createErrorLog(String name, String type, String Description, String objectName, String objectId, String stream, Boolean reprocess, Boolean notify, String recipients, Boolean create, Id orderId, Set<Id> orderIdSet,String errorMessage) {
        

        APTS_Error_Object__c error = new APTS_Error_Object__c();
        APTS_Error_Object__c error1 = new APTS_Error_Object__c();
        if(String.isNotBlank(errorMessage)) error.APTS_Error_Description__c=(errorMessage.length()>250?errorMessage.substring(0, 250):errorMessage);
        if (String.isNotBlank(description)) error.APTS_Description_Of_Error__c = description;
        error.APTS_Error_Date__c = Date.Today();
        if (String.isNotBlank(name)) error.APTS_Error_Name__c = name;
        if (String.isNotBlank(type)) error.APTS_Error_Type__c = type;
        if (String.isNotBlank(recipients)) error.APTS_Notification_Recipients__c = recipients;
        error.APTS_Notify__c = notify;
        if (String.isNotBlank(objectName)) error.APTS_Parent_Object_Name__c = objectName;
        if (String.isNotBlank(objectId)) error.APTS_Parent_Id__c = String.valueof(objectId);
        error.APTS_Reprocess__c = reprocess;
        if (String.isNotBlank(stream)) error.APTS_Stream__c = stream;
        if (String.isNotBlank(orderId))
        {
            error.APTS_OrderId__c = orderId;
            error.APTS_TransactionId__c = transactionId!=null?transactionId:(system.now()).format(transactionIdFormat);
        }
        insertList.add(error);
        if(orderIdSet != null){
            for (id recordId : orderIdSet)
            {
                if (String.isNotBlank(orderId) && !orderIdSet.contains(orderId))
                {
                    error1 = new APTS_Error_Object__c();
                    error1.APTS_OrderId__c = recordId;
                    error1.APTS_TransactionId__c = transactionId!=null?transactionId:(system.now()).format(transactionIdFormat);
                    insertList.add(error1);
                }
            }
        }

        
        if (notify && String.isNotBlank(recipients)) {
            List<String> emailids = new List<String> ();
            emailids.addAll(recipients.split(',', - 1));
            sendEmail(emailids, 'Exception Occurred for ' + stream + ' of type ' + type, 'Hi<br></br>Please find below the Exception that has occurred ' + '<br></br><b>Name</b> : ' + name + '<br></br><b>Object Name</b> : ' + objectName + '<br></br><b>Object Id</b> : ' + objectId + '<br></br>' + description, 'Apttus Admin');
        }
        return error;
    }

    public static void saveErrorLog()
    {
        if (insertList.size() > 0) upsert insertList;

    }
}