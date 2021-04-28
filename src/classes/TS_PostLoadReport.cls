//-------------------------------------------------------------------------------------------//
// Author       :   Karen Mae Hung
// Created Date :   Jan 11, 2021
// Usage        :   DOO-5148 Apex Class to process portload report to be sent to third party
//-------------------------------------------------------------------------------------------//
public without sharing class TS_PostLoadReport {
	
    //for Exception 
    public static Boolean hasException = false;
    public class TS_PostLoadReportException extends Exception {}
    
    public static Boolean SOQL_OVERRIDE = false;
    public static String NEW_SOQL_STRING;

    /******************************************************************************
     * Karen Hung
     * 19.01.2021   Method to create csv file document of postload reports
     * 				and send them to third party operators
    ******************************************************************************/
    public static void generateAndSendReport(Date taskDate, Integer createdDateAdj){
        CustomLogging.push('generateAndSendReport', 'TS_PostLoadReport');
        
        try{
            
            Date createdDateadjusted = Date.today().addDays(createdDateAdj);
            DateTime createdDateStart = DateTime.newInstance(createdDateadjusted.year(), createdDateadjusted.month(), createdDateadjusted.day(), 0, 0, 0);
            DateTime createdDateEnd = DateTime.newInstance(createdDateadjusted.year(), createdDateadjusted.month(), createdDateadjusted.day(), 23, 59, 59);
            DateTime taskDateStart = DateTime.newInstance(taskDate.year(), taskDate.month(), taskDate.day(), 0, 0, 0);
            DateTime taskDateEnd = DateTime.newInstance(taskDate.year(), taskDate.month(), taskDate.day(), 23, 59, 59);
            
            List<WorkOrderLineItem> wolisCreated = [SELECT Id, WorkOrderId, WorkOrderType__c, JDELineItemNumber__c, Status, OP_CancelationReasonMachine__c, CreatedBy.LastName, WorkOrder.WorkOrderNumber,WorkOrder.Early_Start_Date__c,  WorkOrderLineItemType__c, AccountLocation__c, SLADate__c,
                                                    AccountLocation__r.Name,  AccountLocation__r.Apttus_Config2__Street__c, AccountLocation__r.Apttus_Config2__City__c, AccountLocation__r.Apttus_Config2__PostalCode__c, AccountLocation__r.Third_Party_Resource__c,
                                                    AccountLocation__r.Third_Party_Resource__r.EmailAddress__c, AccountLocation__r.Third_Party_Resource__r.Name, Operating_Bucket__c,
                                                    PhysicalAsset__r.Name, PhysicalAsset__r.Product__r.Name, PhysicalAsset__r.Building__c, PhysicalAsset__r.Floor__c, PhysicalAsset__r.Area__c, PhysicalAsset__r.CustomerReferenceNumber__c
                                                    FROM WorkOrderLineItem 
                                                    WHERE WorkOrderType__c = :TS_Constants.WO_TYPE_S20_MACHINECARE
                                                    AND WorkOrderLineItemType__c != :TS_Constants.ACTIVITY_LARGE
                                                    AND OPG_Source__c IN ('OPG Daily Batch')
                                                    AND SLADate__c >= :taskDateStart AND SLADate__c <= :taskDateEnd
                                                    AND CreatedDate >= :createdDateStart AND CreatedDate <= :createdDateEnd
                                                    AND AccountLocation__r.Third_Party_Resource__c != null 
                                                    AND AccountLocation__r.Third_Party_Resource__r.EmailAddress__c != null
                                                    ORDER BY WorkOrder.Early_Start_Date__c, AccountLocation__r.Account_Location_ID__c, PhysicalAsset__r.Name];

            if(SOQL_OVERRIDE){
            	wolisCreated = Database.query(NEW_SOQL_STRING); 
            }
            
            if((wolisCreated != null && wolisCreated.size() > 0)){
                
                Map<String, List<String>> resourceTasksMap =  new Map<String, List<String>>();
                Map<String, Integer> woAssetTypeCountMap = new Map<String, Integer>();
                
                //summarize count of woli per workorder, asset and activity type
                /*AggregateResult[] taskCount = [SELECT count(Id) woliCount, WorkOrderId, PhysicalAsset__c, WorkOrderLineItemType__c FROM WorkOrderLineItem WHERE Id IN :wolisCreated GROUP BY WorkOrderId, PhysicalAsset__c, WorkOrderLineItemType__c];
                for(AggregateResult agr : taskCount){
                    String woPAType = (String) agr.get('WorkOrderId') + (String) agr.get('PhysicalAsset__c') + (String) agr.get('WorkOrderLineItemType__c');
                    woAssetTypeCountMap.put(woPAType, (Integer) agr.get('woliCount'));    
                }*/
                
                Set<String> assetTypeString = new Set<String>();
                
                for(WorkOrderLineItem woli: wolisCreated){
                    
                    //String woAssetType = String.valueOf(woli.WorkOrderId) + woli.PhysicalAsset__c + woli.WorkOrderLineItemType__c;
                    //if(!assetTypeString.contains(woAssetType)){
                        //String row values                    
                        String EARLY_START_DATE = String.valueOf(woli.WorkOrder.Early_Start_Date__c);
                        String ACCLOC_NAME = woli.AccountLocation__r.Name != null ? woli.AccountLocation__r.Name : '';
                        String ACCLOC_STREET = woli.AccountLocation__r.Apttus_Config2__Street__c != null ? woli.AccountLocation__r.Apttus_Config2__Street__c.replace(';', ' ') : '';
                        String ACCLOC_CITY = woli.AccountLocation__r.Apttus_Config2__City__c != null ? woli.AccountLocation__r.Apttus_Config2__City__c.replace(';', ' ') : '';
                        String ACCLOC_PC = woli.AccountLocation__r.Apttus_Config2__PostalCode__c != null ? woli.AccountLocation__r.Apttus_Config2__PostalCode__c.replace(';', ' ') : '';
                        String OPSCHED_PHYSICALASSET =  woli.PhysicalAsset__r.Name != null ? woli.PhysicalAsset__r.Name : '';
                        String PHA_PRODUCTNAME = woli.PhysicalAsset__r.Product__r.Name != null ? woli.PhysicalAsset__r.Product__r.Name.replace(';', ' ') : '';
                        String PHA_BUILDING = woli.PhysicalAsset__r.Building__c != null ? woli.PhysicalAsset__r.Building__c.replace(';', ' ') : '';
                        String PHA_FLOOR = woli.PhysicalAsset__r.Floor__c != null ? woli.PhysicalAsset__r.Floor__c.replace(';', ' ') : '';
                        String PHA_AREA = woli.PhysicalAsset__r.Area__c != null ? woli.PhysicalAsset__r.Area__c.replace(';', ' ') : '';
                        String PHA_CUSTOMERREF = woli.PhysicalAsset__r.CustomerReferenceNumber__c != null ? woli.PhysicalAsset__r.CustomerReferenceNumber__c.replace(';', ' ') : '';
                        String ACTIVITY_TYPE = woli.WorkOrderLineItemType__c == TS_Constants.ACTIVITY_CUPS ? TS_Constants.ACTIVITY_REFILL : woli.WorkOrderLineItemType__c;
                    	String OPG_BUCKET = woli.Operating_Bucket__c != null ? woli.Operating_Bucket__c : '';
                        //String FIELD_VALUE = woAssetTypeCountMap.containsKey(woAssetType) ? String.valueOf(woAssetTypeCountMap.get(woAssetType)) : '1';
                        //String IS_HOLIDAY = locationwithHoliday.containsKey(woli.AccountLocation__c) ? 'TRUE' : 'FALSE';
                        String JDELINEITEMNUMBER = ' ' + woli.JDELineItemNumber__c;
                        String WOLI_ID = woli.Id;
                        String WORKORDERTYPE = woli.WorkOrderType__c;
                        String STATUS = woli.Status == TS_Constants.WOLI_STATUS_OPEN ? ' ' : woli.Status;
                        String CANCELATION_REASON = woli.OP_CancelationReasonMachine__c != null ? woli.OP_CancelationReasonMachine__c : '';
                        
                        String ROW_STRING = EARLY_START_DATE + ';' + ACCLOC_NAME + ';' + ACCLOC_STREET + ';' + ACCLOC_CITY + ';' + ACCLOC_PC + ';' + OPSCHED_PHYSICALASSET + ';' + PHA_PRODUCTNAME + ';' + PHA_BUILDING + ';' + PHA_FLOOR + ';' + PHA_AREA + ';' + PHA_CUSTOMERREF + ';' + 
                            				ACTIVITY_TYPE + ';' + OPG_BUCKET + ';' + JDELINEITEMNUMBER + ';' + WOLI_ID + ';' + WORKORDERTYPE + ';' + STATUS + ';' + CANCELATION_REASON;
                        
                        //put the rowvalues per resource
                        if(resourceTasksMap.containsKey(woli.AccountLocation__r.Third_Party_Resource__c)){
                            resourceTasksMap.get(woli.AccountLocation__r.Third_Party_Resource__c).add(ROW_STRING);
                        }else{
                            resourceTasksMap.put(woli.AccountLocation__r.Third_Party_Resource__c, new List<String>{ROW_STRING});
                        }                       
                        
                        //assetTypeString.add(woAssetType);                        
                    //}
                }
                
                if(!resourceTasksMap.isEmpty()){
                    Map<Resource__c, Document> resourceDocMap = new Map<Resource__c, Document>(); 
                    List<Folder> folders = [SELECT Id, Name FROM Folder WHERE Name = 'Third Party Postload Report'];
                    
                    List<Document> doctoInsert = new List<Document>();
                    DateTime dt = taskDate;
                    String myDomain = Url.getOrgDomainUrl().toExternalForm();
                    String initialURL = myDomain + '/servlet/servlet.FileDownload?file=';
                    
                    //document creation
                    for(Resource__c res : [SELECT Id, Name, EmployeeFirstName__c, EmployeeLastName__c, EmailAddress__c FROM Resource__c WHERE Id IN :resourceTasksMap.keySet()]){
                        if(!folders.isEmpty()){
                            String documentName = 'POSTLOAD_ROUTE_OPERATING_FOR_' + res.Name + '_' + String.valueOf(dt.format('MMMdd')) + ' ' + String.valueOf(Datetime.now());
                            String csvColumnHeader = 'Activity Date;Account Location Name;Account Location Street;Account Location City;Account Location PC;Physical Asset;PhA Product Name;PhA Building;PhA Floor;PhA Area;PhA Customer Reference;Activity Type;OPG Bucket;JDE Line Item Number;Id;WorkOrderType__c;Status;OP_CancelationReasonMachine__c \n';
                            String csvFile = csvColumnHeader + String.join(resourceTasksMap.get(res.Id), '\n');
                            
                            Document doc = new Document(Name = documentName, Body = Blob.valueOf(csvFile), FolderId = folders[0].Id, Type = 'csv', ContentType = 'application/vnd.ms-excel');
                            
                            doctoInsert.add(doc);
                            resourceDocMap.put(res,doc);
                        }
                        
                    }
                    
                    if(!doctoInsert.isEmpty()){
                        Database.SaveResult[] insertDocs = Database.insert(doctoInsert, false);
                    }

                   if(!resourceDocMap.isEmpty()){
                       
                       List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
                                     
                       for(Resource__c eng : resourceDocMap.keySet()){
                           
                           String htmlBody = '<html><body><table width="100%" cellspacing="0" cellpadding="0" border="0" bgcolor="#4A3836" class="wrapper"><tbody><tr><td valign="top" align="center"><div style="max-width: 920px; margin: 0 auto;" class="webkit"><table width="100%" cellspacing="0" cellpadding="0" border="0" align="center">'+
                            '<tbody><tr><td width="53" class="em_spacer">&nbsp;</td><td valign="top" align="left" style="padding:10px 0 10px 0;"><table width="100%" cellspacing="0" cellpadding="0" border="0"><tbody>'+
                             '<tr><td width="146" valign="middle" align="left" class="em_logo"><a href="https://www.jacobsdouweegbertsprofessional.nl/" title="JDE PROFESSIONAL" alt="JDE - Professional - Logo" target="_blank" style="text-decoration:none;"><img width="146" height="48" border="0" class="em_logo" src="http://image.n.jacobsdouweegbertsprofessional.nl/lib/fe5515707c6300747211/m/1/825e39db-2f7b-46f7-b14f-0b3da26bb571.png" alt="JDE PROFESSIONAL" style="display:block;font-family:Arial, Helvetica, sans-serif;font-size:14px;line-height:20px;color:#ffffff;"></a></td>'+
                             '<td class="em_spacer">&nbsp;</td></tr></tbody></table></td><td width="53" class="em_spacer">&nbsp;</td></tr></tbody></table></div></td> </tr></tbody></table><br/><table width="100%" cellspacing="0" cellpadding="0" border="0" bgcolor="#FFFFFF" class="wrapper"'+
                               '<tbody>'+ 
                                '<tr>'+
                                  '<td align="center" style="font-family: \'Open Sans\', Arial, sans-serif;font-size:32px;line-height:40px;color:#5D5958;padding: 10px 50px 10px 50px;max-width:920px;overflow:hidden;margin: 0px auto;">'+
                                     '<p style="font-family: \'Open Sans\', Arial, sans-serif;font-size:32px;line-height:40px;font-weight:700;color:#2e2e2e;padding: 0px 20px 0px 20px;margin:  0px auto;text-align: -webkit-center;max-width: 90%;"><font style="vertical-align: inherit;"><font style="vertical-align: inherit;">Dear ' + eng.EmployeeFirstName__c + ' ' + eng.EmployeeLastName__c + ',' +'</font></font></p>'+
                                  '</td>'+
                               '</tr>'+
                               '<tr>'+
                                  '<td align="center" style="text-wrap: normal;font-family: \'Open Sans\', Arial, sans-serif;font-size:22px;line-height:35px;color:#5D5958;margin: 0px auto;padding: 10px 40px 10px 40px;">'+
                                     '<p style="font-family: \'Open Sans\', Arial, sans-serif;font-size: 22px;line-height: 35px;color: #5D5958;padding: 0px 20px 0px 20px;text-align: -webkit-center;width: 90%;margin: 0px auto;"><font style="vertical-align: inherit;"><font style="vertical-align: inherit;">Please see attached list of operating route tasks for ' +  String.valueOf(taskDate) + '.' + '</font></font></p>'+
                                  '</td>'+
                               '</tr>'+
                               '<tr><td align="center" style="font-family:\'Open Sans\', Arial, sans-serif;font-size:32px;line-height:35px;color:#5D5958;padding: 25px 40px 25px 40px;max-width:920px;overflow:hidden;text-align: center;">'+
                                     '<div class="">'+
                                       '<p style="width: 50%;text-align: center;font-family: \'Open Sans\', Arial, sans-serif;font-size: 22px;line-height: 35px;color: #5D5958;padding: 0px 20px 0px 20px;margin: 0px auto;"><span style="font-family: \'Open Sans\', Arial, sans-serif;font-size:24px;line-height:40px;font-weight:700;color:#2e2e2e;padding:0px 20px 0px 0px;text-align: -webkit-center;max-width: 90%;margin: 0px auto;"><font style="vertical-align: inherit;"><font style="vertical-align: inherit;">Kind Regards,</font></font></span></p>'+
                                        '<p style="margin: 0px auto;font-family: \'Open Sans\', Arial, sans-serif;font-size: 22px;line-height: 35px;color: #5D5958;padding: 0px 20px 0px 20px;text-align: center;max-width: 90%;"><span style="margin: 0px;font-family: \'Open Sans\', Arial, sans-serif;font-size: 22px;line-height: 35px;color: #5D5958;padding: 0px 20px 0px 20px;text-align: center;width: 100%;"><font style="vertical-align: inherit;"><font style="vertical-align: inherit;">Jacobs Douwe Egberts Professional</font></font></span></p>'+
                                     '</div>'+
                                  '</td>'+
                               '</tr><body></html>';
                           
                           Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                           email.setUseSignature(false);
                           email.setToAddresses(new String[] { eng.EmailAddress__c});
                           email.setSubject('Postload Report for Operating Route Tasks for ' + String.valueOf(taskDate));
                           email.setHtmlBody(htmlBody);                       
                           email.setEntityAttachments(new Id[]{resourceDocMap.get(eng).Id});
                           email.setWhatId(eng.Id);
                           emails.add(email);
                           
                       }                 
                       
                       if(!emails.isEmpty()){
                           Messaging.SendEmailResult [] r = Messaging.sendEmail(emails);   
                       }                       
                   }
                }               
                
            }
            
            //Exception for test class purposes
            if (Test.isRunningTest() && hasException) {
                throw new TS_PostLoadReportException('Force to throw an exception');
            }
            
        }catch(Exception ex) {
            CustomLogging.debugException(ex);
            CustomLogging.pop();
            System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());
        }        
    }
}