/*************************************************************
@Name: APTS_RSOCreateOrderWebService
@Author: Neev Shah
@CreateDate: 29-05-2018
@Description: APTS_RSOCreateOrderWebService to store incoming data from Mobile
******************************************************************/

@RestResource(urlMapping='/RSOOrder/CreateOrder/*')
global with sharing class APTS_RSOCreateOrderWebService {
    private final static String STATUS_NEW = 'New';
    private static final String EMAIL = System.Label.APTS_Email;

    public class CreateOrderWrapper{
        public String RSOEmployeeEmail{get;set;}
        public String Source{get;set;}
        public List<APTS_DOEPIReqWrapper> Orders{get;set;}
    }


    /** Method Name :createRSOOrder
    * Description : HttpPost Method would, stores data from external system
    **/
    @HttpPost
    global static void createRSOOrder(){
        RestRequest oHttpReq = RestContext.request;
        
        try{
            String sReqData = oHttpReq.requestbody.tostring();
            
            //get data from HTTP Request Body
            Map<String, Object> mapJson = (Map<String, Object>)JSON.deserializeUntyped(sReqData);
            CreateOrderWrapper oOrderWrapper = (CreateOrderWrapper)JSON.deserialize(sReqData, CreateOrderWrapper.class);
            
            //validate routesales email
            String sEmpEmail = (String) mapJson.get('RSOEmployeeEmail');
            String sSource = (String) mapJson.get('Source');
            List<Object> listOrderJSON = (List<Object>)mapJson.get('Orders');
            
            // if not null, then store records in Interface log table (staging)
            if(String.isNotBlank(sEmpEmail) && String.isNotBlank(sSource) && listOrderJSON != NULL && !listOrderJSON.isEmpty()){
                //get all source number
                List<String> listSourceNumber = new List<String>();
                for(Object instance : (List<Object>)mapJson.get('Orders')){
                    Map<String, Object> mapOrderJSon = (Map<String, Object>)instance;
                    mapOrderJSon.put('RSOEmployeeEmail', sEmpEmail);
                    instance = (Object) mapOrderJSon;
                    String sSourceOrderNumber = (String) mapOrderJSon.get('SourceOrderNumber');
                
                    if(String.isNotBlank(sSourceOrderNumber)){
                        listSourceNumber.add(sSourceOrderNumber);
                    }
                }
                
                //check for duplicate source number
                Map<String, String> mapDupSourceNumber = new Map<String, String>();
                for (APTS_Order_Interface_Log__c oLog :  [SELECT id, APTS_SourceOrderNumber__c FROM APTS_Order_Interface_Log__c WHERE APTS_SourceOrderNumber__c IN :listSourceNumber LIMIT 1]){
                    mapDupSourceNumber.put(oLog.APTS_SourceOrderNumber__c, oLog.id);
                }

                //iterate through records
                Map<String, APTS_Order_Interface_Log__c> mapParentLog = new Map<String, APTS_Order_Interface_Log__c>();
                Map<String, APTS_RSOOrderUtils.OrderInterfaceWrapper> mapInterfaceWrapper = new Map<String, APTS_RSOOrderUtils.OrderInterfaceWrapper>();
                List<APTS_Order_Error_Log__c> listErrorLog = new List<APTS_Order_Error_Log__c>();
                Group csQueue = APTS_DigitalOrderBatchHelper.getCSQueue(); 
                for(Object instance : (List<Object>)mapJson.get('Orders')){ 
                    Map<String, Object> mapOrderJSon = (Map<String, Object>)instance;
                    String sSourceOrderNumber = (String) mapOrderJSon.get('SourceOrderNumber');
                    
                    if(String.isNotBlank(sSourceOrderNumber)){
                        String objJSONStr = JSON.serializePretty(instance);
                        APTS_RSOOrderUtils.OrderInterfaceWrapper oWrapper = APTS_RSOOrderUtils.getInterfaceLogExtOrder(objJSONStr, sSource, sSourceOrderNumber);
                        if(oWrapper != NULL){
                            //change status to error if blank or duplicate source order number
                            if(String.isBlank(sSourceOrderNumber) || mapDupSourceNumber.containsKey(sSourceOrderNumber)){
                                String sErrmsg = 'Duplicate source number';
                                if(String.isBlank(sSourceOrderNumber)){
                                    sErrmsg = 'No source number found in request';
                                }

                               //error log for duplicate source number
                                APTS_Order_Error_Log__c oErrorLog = APTS_RSOOrderUtils.createErrorLog(sErrmsg, sSourceOrderNumber, NULL, NULL, NULL, csQueue);
                                if(oErrorLog != NULL){
                                    listErrorLog.add(oErrorLog);
                                }

                                oWrapper.parentLog.APTS_Status__c = 'Error';
                            }
                            mapParentLog.put(oWrapper.sSourceNum, oWrapper.parentLog);
                            mapInterfaceWrapper.put(oWrapper.sSourceNum, oWrapper);
                        }
                    }
                }

                if(!mapParentLog.isEmpty()){
                    insert mapParentLog.values();
                }
            }else{
                //error
                if(String.isBlank(sEmpEmail)){
                    APTS_RSOOrderUtils.setHTTPResponseData(501, 'NO_EMAIL', 'RSO Employee email is mandatory.');
                }else if(String.isBlank(sSource)){
                    APTS_RSOOrderUtils.setHTTPResponseData(501, 'BLANK_SOURCE', 'Source cannot be empty.');
                }else if(listOrderJSON == NULL || listOrderJSON.isEmpty()){
                    APTS_RSOOrderUtils.setHTTPResponseData(501, 'NO_ORDERS', 'Order List cannot be empty.');
                }
            }
        }catch(Exception e){
            //APTS_CustomLogging.createErrorLog(e.getTypeName(), 'Apex', e.getStackTraceString() ,'Order', ApexPages.currentPage().getParameters().get(Label.APTS_Id),'OM',false,true, EMAIL, true);
            APTS_RSOOrderUtils.setHTTPResponseData(400, 'APEX_ERROR', e.getMessage());
        }
    }
}