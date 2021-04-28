/*
* @author        Abram Vixen Reyes
* @date          Feb. 14, 2021
* @description   Batch class for TS_FileUpload LWC / TS_MassUploadServiceController
* @revision(s)
*/
global without sharing class TS_MassUploadServiceBatch implements Database.Batchable<sObject>, Database.Stateful{

    public String uniqueBatchIdentifier;
    public Integer numOfRecords = 0;
    public String csEvent;
    public String csAcceptable;
    public String csConditional;
    public String csOptional;
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        CustomLogging.push('start', 'TS_MassUploadServiceBatch');
        CustomLogging.pop();
        return Database.getQueryLocator(getQuery());
    }

    String getQuery(){
        CustomLogging.push('getQuery', 'TS_MassUploadServiceBatch');
        
        DescribeSObjectResult massUploadServiceObj = MassUploadServiceRecords__c.getSObjectType().getDescribe();
        List<String> fields = new List<String>(massUploadServiceObj.fields.getMap().keySet());
        
        CustomLogging.pop();
        return 'SELECT ' + String.join(fields,',') + 
               ' FROM ' + massUploadServiceObj.getName() + 
               ' WHERE Is_Processed__c = false ' + 
               ' AND Unique_Batch_Identifier__c = \'' + uniqueBatchIdentifier + '\' ';

               //' AND Product2.APTS_Material_Type__c IN (\'ZSPR\', \'ZSER\') ' + 
               //' AND TS_Click__c = true ';
    }
    
    global void execute(Database.BatchableContext BC, List<MassUploadServiceRecords__c> massUploadRecs) {
        CustomLogging.push('execute', 'TS_MassUploadServiceBatch');

        Boolean isInsert = csEvent == 'Insert' ? true : false;
        try{
            //ITERATE OVER MASS UPLOAD RECORDS AND CREATE INSTANCE OF THE OBJECT
            List<MassUploadServiceRecords__c> massUploadToUpdate = new List<MassUploadServiceRecords__c>();
            Map<Id, MassUploadServiceRecords__c> recIdMassUploadRecMap = new Map<Id, MassUploadServiceRecords__c>();            
			Map<String, String> validationErrorMap = validateCountrySettingRules(massUploadRecs);//Id, Validation Error Message
             
            List<SObject> sObjList = new List<SObject>();
            for(MassUploadServiceRecords__c var : massUploadRecs){
                Map<String, Object> recValues = (Map<String, Object>) JSON.deserializeUntyped(var.Record_Values__c);
                Id myId = var.Record_Id__c;

                try{
                    Schema.SObjectType sobjectType = myId.getSObjectType();
                    String sobjectName = sobjectType.getDescribe().getName();
                    
                    //Checking #1: Check if the object in CS is same as SObj of the record.                    
                    if(sobjectName != var.Object_Name__c){
                        var.ErrorMessage__c = 'Invalid Type.';
                        
                        if(isInsert){
                            massUploadToUpdate.add(var);
                        } else {
                            recIdMassUploadRecMap.put(myId, var);
                        }
                        continue;
                    }
                    //Checking #2: Check if the CS rules are fulfilled.
                    else if(validationErrorMap.containsKey(var.Id)){
                        var.ErrorMessage__c = validationErrorMap.get(var.Id);
                                                
                        if(isInsert){
                            massUploadToUpdate.add(var);
                        } else {
                            recIdMassUploadRecMap.put(myId, var);
                        }
                        continue;
                    }
                    
                } catch (Exception e){
                    var.ErrorMessage__c = String.valueOf(e.getMessage());
                    if(isInsert){
                        massUploadToUpdate.add(var);
                    } else {
                        recIdMassUploadRecMap.put(myId, var);
                    }
                    continue;
                }

                if(isInsert){
                    massUploadToUpdate.add(var);
                } else {
                    recIdMassUploadRecMap.put(myId, var);
                }

                //DECLARE A GENERIC SOBJECT CONTAINER
                sObject sObj = Schema.getGlobalDescribe().get(var.Object_Name__c).newSObject() ;

                //PUT ALL THE VALUES REQUIRED FROM MASS SERVICE RECORD TO THE ACTUAL RECORD
                if(myId != null) sObj.put('Id', myId);
                for(String objvar : recValues.keySet()){
                    sObj.put(objvar, String.valueOf(recValues.get(objvar)));
                }
                sObjList.add(sObj);                                
            }

            //NUMBER OF RECORDS PROCESSED TO BE DISPLAYED IN THE NOTIFICATION
            numOfRecords = numOfRecords + sObjList.size();

            if(!sObjList.isEmpty()){

                if(isInsert){

                } else if(!isInsert){
                    Database.SaveResult[] dbUpdate = Database.update(sObjList, false);
                    System.debug(dbUpdate);

                    for(Integer i=0; i < dbUpdate.size(); i++){
                        if (dbUpdate.get(i).isSuccess()){
                            
                            //UPDATE THE MASS SERVICE RECORD AS INDICATOR THAT IT IS ALREADY PROCESSED
                            if(recIdMassUploadRecMap.containsKey(dbUpdate.get(i).getId())){
                                recIdMassUploadRecMap.get(dbUpdate.get(i).getId()).Is_Processed__c = true;
                            }

                        } else if(!dbUpdate.get(i).isSuccess()){
                            Database.Error error = dbUpdate.get(i).getErrors().get(0);
                            String failedDML = error.getMessage();
                            if(recIdMassUploadRecMap.containsKey(sObjList.get(i).Id)){
                                recIdMassUploadRecMap.get(sObjList.get(i).Id).ErrorMessage__c = failedDML;
                            }
                         }
                    }
                }                
            }

            if(!recIdMassUploadRecMap.keySet().isEmpty()){
                Database.update(recIdMassUploadRecMap.values(), false);
            }

        } catch (Exception e){
            System.debug(e.getMessage());

            List<MassUploadServiceRecords__c> toUpdate = new List<MassUploadServiceRecords__c>();
            for(MassUploadServiceRecords__c var : massUploadRecs){
                var.ErrorMessage__c = e.getMessage();
                toUpdate.add(var);
            }
            
            update toUpdate;
        }

        CustomLogging.pop();
    }
    
    global void finish(Database.BatchableContext BC) {
        CustomLogging.push('finish', 'TS_MassUploadServiceBatch');

        // Get the Id for our custom notification type
        CustomNotificationType notificationType = 
        [SELECT Id, DeveloperName 
         FROM CustomNotificationType 
         WHERE DeveloperName='Mass_Upload_Service'];
    
        // Create a new custom notification
        Messaging.CustomNotification notification = new Messaging.CustomNotification();

        // Set the contents for the notification
        notification.setTitle('Mass Upload Service Completed. ' + 'Processed Records: ' + numOfRecords);
        notification.setBody('Your requested upload service is finished. If you need further assistance, please provide the reference # to your administrator. Ref. #: ' + uniqueBatchIdentifier);

        // Set the notification type and target
        notification.setNotificationTypeId(notificationType.Id);
        //notification.setTargetId('000000000000000AAA');
        //DOO 5427 - Pandian Sundaramoorthy - March 15, 2021
        notification.setTargetId(System.Label.TS_Massupload_Dummy_Id);
        
        // Actually send the notification
        try {
            notification.send(new Set<String>{String.valueOf(UserInfo.getUserId())});
            
            /*Karen Hung DOO-5397 Create CSV For the list of records with error then send it to email address of user performed and the email address in the related Resource of the user*/
            //get unprocessed records in the batch
            List<MassUploadServiceRecords__c> unprocessedRecords = [SELECT Id, Record_Id__c,Process_Name__c, Object_Name__c,Record_Values__c,ErrorMessage__c,CreatedBy.Name, CreatedBy.Email, CreatedById FROM MassUploadServiceRecords__c WHERE Unique_Batch_Identifier__c = :uniqueBatchIdentifier AND Is_Processed__c = false];
            if(unprocessedRecords != null && unprocessedRecords.size() > 0){
                
                Map<String, List<MassUploadServiceRecords__c>> userUploadsMap = new Map<String, List<MassUploadServiceRecords__c>>();
                
                Set<String> userIds = new Set<String>();
                for(MassUploadServiceRecords__c uploadRec : unprocessedRecords){
                    userIds.add(uploadRec.CreatedById);
                    if(userUploadsMap.containsKey(uploadRec.CreatedBy.Name)){
                        userUploadsMap.get(uploadRec.CreatedBy.Name).add(uploadRec);
                    }else{
                        userUploadsMap.put(uploadRec.Createdby.Name, new List<MassUploadServiceRecords__c>{uploadRec});
                    }   
                }
                
                
                List<String> recipients = new List<String>();
                Map<String, Resource__c> userResourceMap = new Map<String, Resource__c>();
                
                for(Resource__c res : [SELECT Id, RelatedUser__c,EmailAddress__c FROM Resource__c WHERE RelatedUser__c IN :userIds AND EmailAddress__c !=null]){
                    userResourceMap.put(res.RelatedUser__c, res);                              
                }
               
                List<Messaging.SingleEmailMessage> emailstoSend = new  List<Messaging.SingleEmailMessage>();
                
                Set<String> columns = new Set<String>();
                
                //csv content and email creation
                for(String userName: userUploadsMap.keySet()){

                    //Prepare csv content
                    String documentName = 'UPLOAD ERROR_BY_' + userName + ' ' + String.valueOf(Date.today());
                    
                    String csvRecords = '';
                    
                    for(MassUploadServiceRecords__c uploadServRec : userUploadsMap.get(userName)){
                        
                        // List down recipients
                        if(!recipients.contains(uploadServRec.Createdby.Email))recipients.add(uploadServRec.Createdby.Email);                                
                        Resource__c relatedResource = userResourceMap.get(uploadServRec.CreatedById);
                        if(relatedResource?.EmailAddress__c != null && !recipients.contains(relatedResource.EmailAddress__c)) recipients.add(relatedResource.EmailAddress__c);                        
                        
                        String recordStr = uploadServRec.Record_Values__c;
                        Map<String, Object> recValue = (Map<String, Object>)JSON.deserializeUntyped(recordStr);
                        columns.addAll(recValue.keySet());
                        
                        String row = '';
                        for(String keyVal: recValue.keySet()){
                            row = row + recValue.get(keyVal) + ';';
                        }
                        
                        csvRecords = csvRecords + uploadServRec.Record_Id__c + ';' + row + uploadServRec.ErrorMessage__c +'\n';
                        
                    }
                    
                    List<String> col = new List<String>(columns);
                    String apiColumns = String.join(col, ';');
                    String columnHeader = 'Id;' + apiColumns +';' + 'Error Message \n'; 
                    
                    String csvContent = columnHeader + csvRecords;
                    
                    //csv file prep
                    Messaging.EmailFileAttachment csvAttc = new Messaging.EmailFileAttachment();
                    blob csvBlob = Blob.valueOf(csvContent);
                    csvAttc.setFileName(documentName + '.csv');
                    csvAttc.setBody(csvBlob);
                    
                    //email body prep
                    String htmlBody = '<html><body><table width="100%" cellspacing="0" cellpadding="0" border="0" bgcolor="#4A3836" class="wrapper"><tbody><tr><td valign="top" align="center"><div style="max-width: 920px; margin: 0 auto;" class="webkit"><table width="100%" cellspacing="0" cellpadding="0" border="0" align="center">'+
                        '<tbody><tr><td width="53" class="em_spacer">&nbsp;</td><td valign="top" align="left" style="padding:10px 0 10px 0;"><table width="100%" cellspacing="0" cellpadding="0" border="0"><tbody>'+
                        '<tr><td width="146" valign="middle" align="left" class="em_logo"><a href="https://www.jacobsdouweegbertsprofessional.nl/" title="JDE PROFESSIONAL" alt="JDE - Professional - Logo" target="_blank" style="text-decoration:none;"><img width="146" height="48" border="0" class="em_logo" src="http://image.n.jacobsdouweegbertsprofessional.nl/lib/fe5515707c6300747211/m/1/825e39db-2f7b-46f7-b14f-0b3da26bb571.png" alt="JDE PROFESSIONAL" style="display:block;font-family:Arial, Helvetica, sans-serif;font-size:14px;line-height:20px;color:#ffffff;"></a></td>'+
                        '<td class="em_spacer">&nbsp;</td></tr></tbody></table></td><td width="53" class="em_spacer">&nbsp;</td></tr></tbody></table></div></td> </tr></tbody></table><br/><table width="100%" cellspacing="0" cellpadding="0" border="0" bgcolor="#FFFFFF" class="wrapper"'+
                        '<tbody>'+ 
                        '<tr>'+
                        '<td align="center" style="font-family: \'Open Sans\', Arial, sans-serif;font-size:32px;line-height:40px;color:#5D5958;padding: 10px 50px 10px 50px;max-width:920px;overflow:hidden;margin: 0px auto;">'+
                        '<p style="font-family: \'Open Sans\', Arial, sans-serif;font-size:32px;line-height:40px;font-weight:700;color:#2e2e2e;padding: 0px 20px 0px 20px;margin:  0px auto;text-align: -webkit-center;max-width: 90%;"><font style="vertical-align: inherit;"><font style="vertical-align: inherit;">Dear ' + userName + ',' +'</font></font></p>'+
                        '</td>'+
                        '</tr>'+
                        '<tr>'+
                        '<td align="center" style="text-wrap: normal;font-family: \'Open Sans\', Arial, sans-serif;font-size:22px;line-height:35px;color:#5D5958;margin: 0px auto;padding: 10px 40px 10px 40px;">'+
                        '<p style="font-family: \'Open Sans\', Arial, sans-serif;font-size: 22px;line-height: 35px;color: #5D5958;padding: 0px 20px 0px 20px;text-align: -webkit-center;width: 90%;margin: 0px auto;"><font style="vertical-align: inherit;"><font style="vertical-align: inherit;">Please see attached list of errors for Mass Upload Batch Ref.#: ' + uniqueBatchIdentifier + '.' + '</font></font></p>'+
                        '</td>'+
                        '</tr>'+
                        '<tr><td align="center" style="font-family:\'Open Sans\', Arial, sans-serif;font-size:32px;line-height:35px;color:#5D5958;padding: 25px 40px 25px 40px;max-width:920px;overflow:hidden;text-align: center;">'+
                        '<div class="">'+
                        '<p style="width: 50%;text-align: center;font-family: \'Open Sans\', Arial, sans-serif;font-size: 22px;line-height: 35px;color: #5D5958;padding: 0px 20px 0px 20px;margin: 0px auto;"><span style="font-family: \'Open Sans\', Arial, sans-serif;font-size:24px;line-height:40px;font-weight:700;color:#2e2e2e;padding:0px 20px 0px 0px;text-align: -webkit-center;max-width: 90%;margin: 0px auto;"><font style="vertical-align: inherit;"><font style="vertical-align: inherit;">Kind Regards,</font></font></span></p>'+
                        '<p style="margin: 0px auto;font-family: \'Open Sans\', Arial, sans-serif;font-size: 22px;line-height: 35px;color: #5D5958;padding: 0px 20px 0px 20px;text-align: center;max-width: 90%;"><span style="margin: 0px;font-family: \'Open Sans\', Arial, sans-serif;font-size: 22px;line-height: 35px;color: #5D5958;padding: 0px 20px 0px 20px;text-align: center;width: 100%;"><font style="vertical-align: inherit;"><font style="vertical-align: inherit;">Jacobs Douwe Egberts Professional</font></font></span></p>'+
                        '</div>'+
                        '</td>'+
                        '</tr><body></html>';

                    //email message prep
                    Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                    email.setUseSignature(false);
                    email.setToAddresses(recipients);
                    email.setSubject('Mass Upload Error on ' + String.valueOf(Datetime.now()) + ', Ref.#: ' + uniqueBatchIdentifier) ;
                    email.setHtmlBody(htmlBody);
                    email.setFileAttachments(new Messaging.EmailFileAttachment[]{csvAttc});
                    emailstoSend.add(email);
                    
                }
                if(!emailstoSend.isEmpty()){
                    Messaging.SendEmailResult [] r = Messaging.sendEmail(emailstoSend);   
                }                      
     
            }
            
        }
        catch (Exception e) {
            System.debug('Problem sending notification: ' + e.getMessage());
        }

        CustomLogging.pop();
    }
    
    Map<String, String> validateCountrySettingRules(List<MassUploadServiceRecords__c> massUploadRecs){
        Map<String, String> return_map = new Map<String, String>();//JDELineItemNumber, Error Message
        Map<String, List<String>> acceptable_field_value_map = new Map<String, List<String>>(); //field name, acceptable values
        Map<String, List<String>> conditional_field_value_map = new Map<String, List<String>>(); //field name+field value, conditional acceptable values            		
        List<String> optional_field_list = new List<String>(); //field_name
        
        //1. Get optional values from country setting
        if(csOptional != null){
            List<String> per_field_list = csOptional.split(',');  
            for(String per_field : per_field_list){  
                optional_field_list.add(per_field.toLowerCase());                
            }            
        }
        
        //2. Get acceptable values from country setting
        if(csAcceptable != null){                       
            List<String> per_field_list = csAcceptable.split(';');  
            for(String per_field : per_field_list){                        
                List<String> field_values_list = per_field.split(':');                
                String field_name = field_values_list[0].toLowerCase(); //Field1
                String acceptable_values = field_values_list[1].toLowerCase(); //Value1,Value2,Value3
                List<String> values_list = acceptable_values.split(',');
                for(String value : values_list){
                    if(acceptable_field_value_map.containsKey(field_name)){
                        acceptable_field_value_map.get(field_name).add(value);
                    }
                    else {
                        List<String> initial_values_list = new List<String>();
                        initial_values_list.add(value);
                        acceptable_field_value_map.put(field_name, initial_values_list);                                                                
                    }
                }
            }                
        }
        
        //3. Get conditional values from country setting
        if(csConditional != null){                
            List<String> per_field_list = csConditional.split(';');                    
            for(String per_field : per_field_list){
                List<String> field_values_list = per_field.split(':');
                String field_values = field_values_list[0].toLowerCase(); //Field1[Value1]
                List<String> field_name_value_list = field_values.split('\\[');
                String field_name = field_name_value_list[0];//Field1
                String field_value = field_name_value_list[1].replace(']','').toLowerCase();//Value1
                if(field_value == null || field_value == ''){
                    field_value = 'not null';
                }                        
                String acceptable_values = field_values_list[1].toLowerCase(); //RequiredField1,RequiredField2
                String uniqueKey = field_name.toLowerCase() + '_' + field_value.toLowerCase();
                List<String> values_list = acceptable_values.split(',');
                for(String value : values_list){
                    if(conditional_field_value_map.containsKey(uniqueKey)){
                        conditional_field_value_map.get(uniqueKey).add(value);
                    }
                    else {
                        List<String> initial_values_list = new List<String>();
                        initial_values_list.add(value);
                        conditional_field_value_map.put(uniqueKey, initial_values_list);                                                                
                    }
                }
            }                                 
        }         
        		        
        for(MassUploadServiceRecords__c var : massUploadRecs){      
            String error_string = null;       
			Map<String, Object> recValues = (Map<String, Object>) JSON.deserializeUntyped(var.Record_Values__c);   
            for(String field_name : recValues.keySet()){                                
                String field_value = String.valueOf(recValues.get(field_name)).toLowerCase();
                
                //1. Check if there are acceptable values
                if(acceptable_field_value_map.containsKey(field_name)){                                        
                    if(!(acceptable_field_value_map.get(field_name).contains(field_value))
                       && !((field_value == null || field_value == '') && optional_field_list.contains(field_name))
                      ){
                        List<String> acceptable_values_list = acceptable_field_value_map.get(field_name);                        
                        String acceptable_value_string;
                        for(String acceptable_value : acceptable_values_list){                            
                            acceptable_value_string = acceptable_value_string != null ? acceptable_value_string.toLowerCase() + ',' + acceptable_value.toLowerCase() : acceptable_value.toLowerCase();
                        }                        
                        error_string = 'Invalid picklist value for ' + field_name + '. Acceptable values: ' + acceptable_value_string;                        
                        return_map.put(var.Id, error_string);
                    }                               		
                } 
                    
                //2. Check if there are conditional values	
                String uniqueKey = field_name.toLowerCase() + '_' + field_value.toLowerCase();
                String uniqueKey_not_null = field_name.toLowerCase() + '_not null';                
				if((conditional_field_value_map.containsKey(uniqueKey) || conditional_field_value_map.containsKey(uniqueKey_not_null)) && error_string == null){                                         
                    List<String> conditional_field_list = conditional_field_value_map.get(uniqueKey) != null ? conditional_field_value_map.get(uniqueKey) : conditional_field_value_map.get(uniqueKey_not_null);                                		                                                            
                    for(String conditional_field : conditional_field_list){      
                        String conditional_field_lwr = conditional_field.toLowerCase();                         
                        if(!(recValues.get(conditional_field_lwr) != null && recValues.get(conditional_field_lwr) != '')){
                            error_string = conditional_field.toLowerCase() + ' is required when ' + field_name.toLowerCase() + ' is filled.';
                            return_map.put(var.Id, error_string); //Field B is required when Field A is filled.
                        }                                                                                            
                    }
                } 			                			                
            }                                                           
		}                        
        return return_map;
    }    
}