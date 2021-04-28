/*************************************************************
@Name: APTS_DigitalOrderWebService
@Author: Neev Shah
@CreateDate: 26-03-2018
@Description: Webservice which will receive data for Digital Order
******************************************************************/
@RestResource(urlMapping='/DigitalOrder/*')
global with sharing class APTS_DigitalOrderWebService{
    private final static String STATUS_NEW = 'New';
    private static final String EMAIL = System.Label.APTS_Email;

    /** Method Name :createDigitalOrder
    * Description : HttpPost Method would, stores data from external system
    **/
    @HttpPost
    global static void createDigitalOrder(){
        RestRequest oHttpReq = RestContext.request;

        try{
            String sReqData = oHttpReq.requestbody.tostring();
            System.debug('sReqData = ' + sReqData);

            if(String.isNotBlank(sReqData)){
                Map<String, Object> mapJson = (Map<String, Object>)JSON.deserializeUntyped(sReqData);

                if(mapJson != NULL && mapJson.containsKey('SourceOrderNumber')){
                    String sSourceOrderNumber = (String) mapJson.get('SourceOrderNumber');
                    System.debug('mapJson = ' + mapJson);
                    System.debug('SourceOrderNumber = ' + sSourceOrderNumber);

                    if(String.isNotBlank(sSourceOrderNumber)){
                        List<APTS_Order_Interface_Log__c> listLogss = [SELECT id FROM APTS_Order_Interface_Log__c WHERE APTS_SourceOrderNumber__c =: sSourceOrderNumber LIMIT 1];

                        if(listLogss.isEmpty()){
                            Integer startIndex = 0, lastIndex = 0, fieldLen = 131072, strLen = sReqData.length(), sequence = 0;
                            if(Test.isRunningTest()){
                                fieldLen = 20;
                            }

                            lastIndex = getLastIndex(lastIndex, strLen, fieldLen);
                            System.debug(' lastIndex = ' + lastIndex);
                            APTS_Order_Interface_Log__c oParentLog = getInterfaceLog(NULL, startIndex, lastIndex, sSourceOrderNumber, sReqData, NULL);
                            
                            if(oParentLog != NULL){
                                Database.insert(oParentLog, FALSE);
                                System.debug('oParentLog Id = ' + oParentLog.Id);

                                if(String.isNotBlank(oParentLog.Id) && (fieldLen < strLen)){
                                    List<APTS_Order_Interface_Log__c> listInterfaceLog = new List<APTS_Order_Interface_Log__c>();
                                    while(TRUE){
                                        startIndex = lastIndex;
                                        lastIndex = getLastIndex(lastIndex, strLen, fieldLen);
                                        System.debug('startIndex = ' + startIndex + ' lastIndex = ' + lastIndex);
                                        System.debug('substr =  ' + sReqData.substring(startIndex, lastIndex));

                                        APTS_Order_Interface_Log__c oLog = getInterfaceLog(sequence, startIndex, lastIndex, sSourceOrderNumber, sReqData, oParentLog.Id);
                                        System.debug('oLog = ' + oLog);
                                        listInterfaceLog.add(oLog);
                                        sequence ++;

                                        if(lastIndex == strLen){
                                            break;
                                        }
                                    }
                                    System.debug('listInterfaceLog = ' + listInterfaceLog);
                                    
                                    if(!listInterfaceLog.isEmpty()){
                                        Database.insert(listInterfaceLog, FALSE);
                                        System.debug('listInterfaceLog = ' + listInterfaceLog);
                                    }else{
                                        setHTTPResponseData(500, 'APEX_ERROR', 'ERROR while saving data, please try again.');
                                    }
                                }
                            }

                            if(oParentLog == NULL || String.isBlank(oParentLog.Id)){
                                setHTTPResponseData(500, 'APEX_ERROR', 'ERROR while saving data, please try again.');
                            }
                        }else{
                            setHTTPResponseData(400, 'DUP_SOURCE_ORDER_NUM', 'Duplicate SourceOrderNumber.');
                        }                    
                    }else{
                        setHTTPResponseData(400, 'BLANK_SOURCE_ORDER_NUM', 'SourceOrderNumber cannot be empty.');
                    }
                }else{
                    setHTTPResponseData(400, 'BLANK_SOURCE_ORDER_NUM', 'SourceOrderNumber cannot be empty.');
                }
            }else{
                setHTTPResponseData(400, 'BLANK_REQ_BODY', 'Request Body cannot be empty.');
            }
        }catch(Exception oEx){
            APTS_CustomLogging.createErrorLog(oEx.getTypeName(), 'Apex', oEx.getStackTraceString() ,'Order', ApexPages.currentPage().getParameters().get(Label.APTS_Id),'OM',false,true, EMAIL, true);
            System.debug('Exception stack trace : ' + oEx.getStackTraceString());
            setHTTPResponseData(500, 'APEX_ERROR', oEx.getMessage());
        }
    }

    /** Method Name :getLastIndex
    * Description : Method would, return index for substring
    **/
    private static Integer getLastIndex(Integer lastIndex, Integer strLen, Integer fieldLen){
        if(strLen < fieldLen){
            lastIndex = strLen;
        }else if(lastIndex < strLen){
            if((lastIndex + fieldLen) < strLen){
                lastIndex += fieldLen;
            }else{
                lastIndex = strLen;
            }
        }
        return lastIndex;
    }

    /** Method Name :getInterfaceLog
    * Description : Method would, return getInterfaceLog
    **/
   private static APTS_Order_Interface_Log__c getInterfaceLog(Integer sequence, Integer startIndex, Integer lastIndex, String sSourceOrderNumber, String sReqData, Id parentId){
        APTS_Order_Interface_Log__c oLog = new APTS_Order_Interface_Log__c();
        oLog.APTS_SourceOrderNumber__c = sSourceOrderNumber;
        oLog.APTS_Message__c = sReqData.substring(startIndex, lastIndex);
        oLog.APTS_Status__c = STATUS_NEW;
        if(String.isNotBlank(parentId)){
            oLog.APTS_Sequence__c = sequence;
            oLog.APTS_Parent_Log__c = parentId;
        }
        return oLog;
    }

    /** Method Name :getResponse
    * Description : Method would,set http response data
    **/
    private static void setHTTPResponseData(Integer statusCode, String errorCode, String message){
        JSONGenerator oResJSON = JSON.createGenerator(true);
        oResJSON.writeStartObject();
        if(String.isNotBlank(errorCode)){
            oResJSON.writeStringField('errorCode', errorCode);
        }
        oResJSON.writeStringField('message', message);
        oResJSON.writeEndObject();

        RestResponse oHttpResp = RestContext.response;
        oHttpResp.addHeader('Content-Type', 'application/json');
        oHttpResp.responseBody = Blob.valueOf(oResJSON.getAsString());
        oHttpResp.statusCode = statusCode;
    }
}