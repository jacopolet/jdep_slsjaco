@isTest
global class APTS_ATPCheckHTTPCalloutMockImpl implements WebServiceMock {
    private static final String EMAIL = System.Label.APTS_Email;

    global void doInvoke(
        
        Object stub,
        Object request,
        Map<String, Object> response,
        String endpoint,
        String soapAction,
        String requestName,
        String responseNS,
        String responseName,
        String responseType) {

      //try{
        APTS_SAPWSStructure.BAPI_SALESORDER_SIMULATE_Response_element responseElem = new APTS_SAPWSStructure.BAPI_SALESORDER_SIMULATE_Response_element();
        responseElem.RETURN_x = new APTS_SAPWSStructure.BAPIRETURN();
        responseElem.RETURN_x.TYPE_x = 'S';

        responseElem.ORDER_SCHEDULE_EX = new APTS_SAPWSStructure.ORDER_SCHEDULE_EX_element();
        responseElem.ORDER_SCHEDULE_EX.item = new APTS_SAPWSStructure.BAPISDHEDU[0];
        APTS_SAPWSStructure.BAPISDHEDU BAPISDHEDU_elem = new APTS_SAPWSStructure.BAPISDHEDU();
        BAPISDHEDU_elem.CONFIR_QTY = '10';
        BAPISDHEDU_elem.ITM_NUMBER = '10';
        BAPISDHEDU_elem.REQ_DATE = '2017-02-08';
        BAPISDHEDU_elem.REQ_TIME = '00:00:00';
        responseElem.ORDER_SCHEDULE_EX.item.add(BAPISDHEDU_elem);

        responseElem.ORDER_CONDITION_EX = new APTS_SAPWSStructure.ORDER_CONDITION_EX_element();
        responseElem.ORDER_CONDITION_EX.item = new APTS_SAPWSStructure.BAPICOND[0];
        APTS_SAPWSStructure.BAPICOND BAPICOND_elem = new APTS_SAPWSStructure.BAPICOND();
        BAPICOND_elem.COND_TYPE = 'ZWST';
        BAPICOND_elem.ITM_NUMBER = '10';
        BAPICOND_elem.CONDVALUE = '100';
        responseElem.ORDER_CONDITION_EX.item.add(BAPICOND_elem);        

        response.put('response_x', responseElem);
            /* }
            catch(Exception e)
              {
        APTS_CustomLogging.createErrorLog(e.getTypeName(), 'Apex', e.getStackTraceString() ,'Order', ApexPages.currentPage().getParameters().get(Label.APTS_Id),'OM',false,true, EMAIL, true);
              } */
    }
}