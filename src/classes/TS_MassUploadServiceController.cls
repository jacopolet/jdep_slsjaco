/*
* @author        Abram Vixen Reyes
* @date          Feb. 14, 2021
* @description   Controller class for TS_FileUpload LWC
* @revision(s)
*/
public without sharing class TS_MassUploadServiceController {

    public class TS_MassUploadServiceControllerException extends Exception {}
    public static Boolean hasException = false;

    public class LightningResponse{
        @AuraEnabled
        public String returnValue;
        @AuraEnabled
        public String status;
        @AuraEnabled
        public String message;
  
        public LightningResponse(){
            this.returnValue = returnValue;
            this.status = status;
            this.message = message;
        }
    }
    
    @AuraEnabled
    public static string checkAccess(){
    	LightningResponse lResponse = new LightningResponse();
        try{
            
            List<Resource__c> resourceList = [SELECT Id, RLS_Portal_User__c FROM Resource__c WHERE RelatedUser__c =: UserInfo.getUserId() AND RLS_Portal_User__c = TRUE];
            List<Profile> profQuery = [SELECT Id, Name FROM Profile WHERE (PermissionsPrivacyDataAccess = true OR PermissionsCustomizeApplication = true OR Name = 'JDE-Admin-Functional Tester' OR Name = 'JDE - DevOps Profile') AND Id =: UserInfo.getProfileId()];
			
            if(!resourceList.isEmpty() || !profQuery.isEmpty()){
                lResponse.returnValue = 'true';
            } else {
                lResponse.returnValue = 'false';
            } 
            
            if (Test.isRunningTest() && hasException) {
                throw new TS_MassUploadServiceControllerException('Force to throw an exception');
            }
        }catch (Exception e){
            lResponse.status = 'ERROR';
            lResponse.message = 'Error: ' + e.getMessage() + '\nSTACK TRACE: ' + e.getStackTraceString();
        }
        
		return JSON.serialize(lResponse);   
    }

    @AuraEnabled
    public static string uploadFile(String fileName, String base64code, String processName, Boolean proceedProcessing, String delimiter){

        LightningResponse lResponse = new LightningResponse();
        try {
            
            String base64data = base64code;
            List<String> myFile = new List<String>();
            if(base64data != null){
                
                //STRING CLEANUP 1: REMOVE UTF-8 BOM(BYTE ORDER MARK)
                List<Integer> charArr= new Integer[]{65279};
                String convertedChar = String.fromCharArray(charArr);

                //STRING CLEANUP 2: CARRIAGE RETURN - DO SOME STRING CLEANUP BEFORE SPLITTING
                String myFileStr = EncodingUtil.base64Decode(base64data).toString().replaceAll('\\r', '').replaceFirst(convertedChar, '');
                myFile = myFileStr.trim().split('\n');    
            }

            List<CountrySetting__c> csVar = [SELECT Name, Object__c, Required_Fields__c, Optional_Fields__c, Event__c, Acceptable_Values__c, Conditional_Fields_Values__c FROM CountrySetting__c WHERE RecordType.Name = 'Mass Upload Service Settings' AND Name =: processName];

            if(!csVar.isEmpty() && myFile != null && !myFile.isEmpty()){
                
                String splitParam = ';';
                /* if(delimiter != null) splitParam = delimiter;
                System.debug('splitParam: ' + splitParam); */

                CountrySetting__c settingsVar = csVar[0];

                //replaceAll(',',splitParam) >> so no need to change the country setting fields
                List<String> headersUpload = myFile[0].trim().toLowerCase().replaceAll('\\s+','').split(splitParam);
                List<String> headersSettings = new List<String>();
                List<String> missingfieldsList = new List<String>();

                //if the text is not parsed due to absence of default delimiter, use the other one.
                if(!(headersUpload.size() > 1)){
                    splitParam = ',';
                    headersUpload = myFile[0].trim().toLowerCase().replaceAll('\\s+','').split(splitParam);
                }

                System.debug('headersUpload: ' + headersUpload);
                for(String str : headersUpload){
                    System.debug(str);
                }

                //VALIDATE HEADERS, PROCEED IF ALL REQUIRED FIELDS ARE PRESENT
                if(settingsVar.Required_Fields__c != null){
                    headersSettings = settingsVar.Required_Fields__c.replaceAll(',',splitParam).trim().toLowerCase().split(splitParam);

                    for(String varStr : headersSettings){
                        if(!headersUpload.contains(varStr)){
                            missingfieldsList.add(varStr);
                        }
                    }

                    if(!missingfieldsList.isEmpty()){
                        lResponse.status = 'ERROR';
                        lResponse.message = 'Some of the required fields are not in the uploaded CSV file. ' +  missingfieldsList;
                    } 
                    
                    //IF NO ISSUES FOUND IN THE HEADERS, CREATE THE FIELDS MAPPING AND THE MASS UPLOAD SERVICE RECORDS
                    else {
                        if(proceedProcessing) createMassUploadServiceRecords(myFile, settingsVar, processName, splitParam);
                    }
                }
            }

        } catch (Exception e) {
            System.debug(e.getMessage());
        }

        return JSON.serialize(lResponse); 
    }

    @AuraEnabled(cacheable=true)
    public static List<CountrySetting__c> getProcessCountrySettings(){
        return [
            SELECT Name, Object__c, Required_Fields__c, Optional_Fields__c, Event__c, Acceptable_Values__c, Conditional_Fields_Values__c
            FROM CountrySetting__c
            WHERE RecordType.Name = 'Mass Upload Service Settings' AND Active__c = true
        ];
    }

    private static void createMassUploadServiceRecords(List<String> myFile, CountrySetting__c csSetting, String processName, String splitParam){
        
        String batchUniqueIdentifier = String.valueOf(UserInfo.getUserId()) + String.valueOf(DateTime.now().getTime());
        List<String> headersUpload = myFile[0].trim().toLowerCase().replaceAll('\\s+','').split(splitParam);

        //CREATE ORDER-MAPPING OF REQUIRED FIELDS FROM THE UPLOADED FILE
        Map<String, Integer> requiredFieldsOrderMapping = new Map<String, Integer>();
        List<String> requiredFieldsList = csSetting.Required_Fields__c.replaceAll(',',splitParam).trim().toLowerCase().split(splitParam);
        for(String str: requiredFieldsList){
            for(Integer i=0; i < headersUpload.size(); i++){
                if(str == headersUpload[i]){
                    requiredFieldsOrderMapping.put(str, i);
                    continue;
                }
            }
        }

        //CREATE ORDER-MAPPING OF OPTIONAL FIELDS FROM THE UPLOADED FILE
        List<String> optionalFieldsList = new List<String>();
        Map<String, Integer> optionalFieldsOrderMapping = new Map<String, Integer>();
        if(csSetting.Optional_Fields__c != null){
            optionalFieldsList = csSetting.Optional_Fields__c.replaceAll(',',splitParam).trim().toLowerCase().split(splitParam);
            for(String str: optionalFieldsList){
                for(Integer i=0; i < headersUpload.size(); i++){
                    if(str == headersUpload[i]){
                        optionalFieldsOrderMapping.put(str, i);
                        continue;
                    }
                }
            }
        }

        //CREATE THE MAPPING OF VALUES AND CREATE THE MASS UPLOAD SERVICE RECORDS
        //(1) Iterate the content of the CSV file excluding the header
        List<MassUploadServiceRecords__c> musRecList = new List<MassUploadServiceRecords__c>();

        Integer i = 1;
        splitParam = '\\' + splitParam;
        for(String strVar: myFile){
            
            System.debug(strVar);
            if(i == 1) {
                i++;
                continue;
            }

            Map<String, String> fieldsAPIValue = new Map<String, String>();
            MassUploadServiceRecords__c musRec = new MassUploadServiceRecords__c();
            
            //CONVERT ALL COMMAS TO AVOID SPLITTING ISSUES
            String myFileString = replaceCommaBeforeSplit(strVar);
            List<String> myFileRowValues = myFileString.split(splitParam, -1);
            
            System.debug('myFileRowValues: ' + myFileRowValues);
            for(String str : myFileRowValues){
                System.debug(str);
            }

            //(2) GET ALL VALUES FROM THE REQUIRED FIELDS
            for(String str: requiredFieldsList){
                if(str == 'id') {
                    musRec.Record_Id__c = myFileRowValues[requiredFieldsOrderMapping.get(str)];
                    continue;
                }
                
                if(requiredFieldsOrderMapping.containsKey(str)) fieldsAPIValue.put(str, myFileRowValues[requiredFieldsOrderMapping.get(str)]);
            }
            
            //(3) GET ALL VALUES FROM THE OPTIONAL FIELDS
            if(!optionalFieldsList.isEmpty()){
                for(String str: optionalFieldsList){
                    if(optionalFieldsOrderMapping.containsKey(str)) fieldsAPIValue.put(str, myFileRowValues[optionalFieldsOrderMapping.get(str)]);
                }
            }

            musRec.Process_Name__c = processName;
            musRec.Object_Name__c = csSetting.Object__c;
            musRec.Unique_Batch_Identifier__c = batchUniqueIdentifier;
            musRec.Record_Values__c = JSON.serialize(FieldsAPIValue).replaceAll(':quotes:', '').replaceAll(':comma:', ',');
            musRecList.add(musRec);
            i++;
        }

        if(!musRecList.isEmpty()){
            insert musRecList;

            TS_MassUploadServiceBatch uploadServBatch = new TS_MassUploadServiceBatch();
            uploadServBatch.uniqueBatchIdentifier = batchUniqueIdentifier;
            uploadServBatch.csEvent = csSetting.Event__c;
            uploadServBatch.csAcceptable =  csSetting.Acceptable_Values__c;
            uploadServBatch.csConditional = csSetting.Conditional_Fields_Values__c;
            uploadServBatch.csOptional = csSetting.Optional_Fields__c;
            Database.executeBatch(uploadServBatch, 20);
        }
    }

    private static String replaceCommaBeforeSplit (String strToConvert){
        String csvLine = strToConvert;
        String prevLine = csvLine;
        Integer startIndex;
        Integer endIndex;
        
        try{
            while(csvLine.indexOf('"') > -1){
        
                if(startIndex == null){
                    startIndex = csvLine.indexOf('"');
                    csvLine = csvLine.substring(0, startIndex) + ':quotes:' + csvLine.substring(startIndex+1, csvLine.length());       
                } else{
                    if(endIndex == null){
                        endIndex = csvLine.indexOf('"');
                        csvLine = csvLine.substring(0, endIndex) + ':quotes:' + csvLine.substring(endIndex+1, csvLine.length());
                    }
                }

                if(startIndex != null && endIndex != null){

                    String sub = csvLine.substring(startIndex, endIndex);
                    sub = sub.replaceAll(',', ':comma:');
                    csvLine = csvLine.substring(0, startIndex) + sub + csvLine.substring(endIndex, csvLine.length());
                    startIndex = null;
                    endIndex = null;
                }
            }
        } catch (Exception e){
            System.debug(e);
        }

        return csvLine;
    }
}