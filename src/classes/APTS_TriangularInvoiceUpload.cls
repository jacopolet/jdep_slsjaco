/**
 * Author : Amit Singh 
 * Author2: Erik Rupert , Venky
 * Class : APTS_TriangularInvoiceUpload
 * Description : To upload Order data for Triangular Invoicing
 * Version : V1
 * *
 * */
//V101 Aarthi Pitchai 23-Apr-2020 Unplanned return changes

public without sharing class  APTS_TriangularInvoiceUpload {
    
    @RemoteAction
    public static string parseData(String jsondata){
    try{
        list<APTS_TriangleInvoiceOrders__c> lstPrjs = new list<APTS_TriangleInvoiceOrders__c>();
        // these will be rows of errors to update in salesforce
        list<APTS_TriangleInvoiceOrders__c> errorRecords = new list<APTS_TriangleInvoiceOrders__c>();
        // Generate unique key for this set of uploaded data 
        String hashString = '1000' + String.valueOf(Datetime.now().formatGMT('yyyy-MM-dd HH:mm:ss.SSS'));
        Blob hash = Crypto.generateDigest('MD5', Blob.valueOf(hashString));
        String uniqueKey = EncodingUtil.convertToHex(hash);
        system.debug('batchID' + uniqueKey);
        // PART ONE: Process the user-submitted Excel data into Salesforce staging table via json object
        // Get ID of current user to store in staging table
        string currentUserId = UserInfo.getUserId();
        system.debug(Logginglevel.ERROR,'currentUser::::' + currentUserId); 
        List<Map<String, Object>> myMaps = new List<Map<String, Object>>();
        String filestring = '';
        Map<String, Object> metafile = (Map<String, Object>) JSON.deserializeUntyped(jsondata);

        //Read the data of Excel for specified sheet name, in this case is "Order Export Tab".
        for (Object obj : (List<Object>) metafile.get('Order Export Tab')) 
        { 
            myMaps.add((Map<String, Object>)obj);
            filestring += JSON.serialize(obj)+'\n';
        }        
        List<String> inovicedataLineBody = new List<String>();
        for(String attachBody : filestring.split('\n',-1))
        {
            inovicedataLineBody.add(attachBody);
        }
                
        system.debug(Logginglevel.ERROR,'invoiceDataLineBody === >' +inovicedataLineBody);
        // countSize used like an 'i' for looping purposes
        integer countSize = 1;
        for(string jsonbody : inovicedataLineBody)
        {
            APTS_TriangleInvoiceOrders__c jscls= new APTS_TriangleInvoiceOrders__c();
            system.debug(Logginglevel.ERROR,'inovicedataLineBody == >'+ inovicedataLineBody.size() + 'Counter Size == > '+countSize);
            if(countSize < inovicedataLineBody.size()){
                Map<String, Object> meta = (Map<String, Object>) JSON.deserializeUntyped(jsonbody);
                system.debug(Logginglevel.ERROR,'meta pre  === >'+json.serialize(meta));
                for(String jsonKey : meta.keyset())
                {
                    if(string.isNotBlank((String)meta.get(jsonKey))){
                        //Get the value of Column by column name
                        if(jsonKey.equalsignorecase('orderReference')){
                            //system.debug(Logginglevel.ERROR,'**** orderReference = '+meta.get(jsonKey));
                            jscls.OrderReference__c = string.valueOf(meta.get(jsonKey));
                        }  
                        if(jsonKey.equalsignorecase('account')){
                            //system.debug(Logginglevel.ERROR,'**** account = '+meta.get(jsonKey));
                            jscls.Account__c    = string.valueOf(meta.get(jsonKey));
                        }
                        if(jsonKey.equalsignorecase('PO')){
                            //system.debug(Logginglevel.ERROR,'**** PO = '+meta.get(jsonKey));
                            jscls.PO__c    = string.valueOf(meta.get(jsonKey));
                        }
                        if(jsonKey.equalsignorecase('Invoice remarks')){
                            //system.debug(Logginglevel.ERROR,'**** Invoice remarks = '+meta.get(jsonKey));
                            jscls.Invoice_Remarks__c    = string.valueOf(meta.get(jsonKey));
                        }
                        if(jsonKey.equalsignorecase('Pricing date')){
                            //system.debug(Logginglevel.ERROR,'**** Pricing date = '+meta.get(jsonKey));
                            jscls.Pricing_Date__c    = string.valueOf(meta.get(jsonKey));
                        }
                        if(jsonKey.equalsignorecase('sapCustomerId')){
                            //system.debug(Logginglevel.ERROR,'**** sapCustomerId = '+meta.get(jsonKey));
                            jscls.SAP_Customer_ID__c    = string.valueOf(meta.get(jsonKey));
                        }
                        if(jsonKey.equalsignorecase('sapOrderType')){
                            //system.debug(Logginglevel.ERROR,'**** sapOrderType = '+meta.get(jsonKey));
                            jscls.SAP_OrderType__c = string.valueOf(meta.get(jsonKey));
                        }
                        if(jsonKey.equalsignorecase('orderSubType')){
                            //system.debug(Logginglevel.ERROR,'**** orderSubType = '+meta.get(jsonKey));
                            jscls.Order_Sub_Type__c = string.valueOf(meta.get(jsonKey));
                        }
                        if(jsonKey.equalsignorecase('reqDelivDate')){
                            //system.debug(Logginglevel.ERROR,'**** reqDelivDate = '+meta.get(jsonKey));
                            jscls.Requested_Delivery_Date__c = string.valueOf(meta.get(jsonKey));
                        }
                        if(jsonKey.equalsignorecase('soldTo')){
                            //system.debug(Logginglevel.ERROR,'**** soldTo = '+meta.get(jsonKey));
                            jscls.SoldTo__c = string.valueOf(meta.get(jsonKey));
                        }
                        if(jsonKey.equalsignorecase('billTo')){
                               // system.debug(Logginglevel.ERROR,'**** billTo = '+meta.get(jsonKey));
                                jscls.BillTo__c = string.valueOf(meta.get(jsonKey));
                        }
                        if(jsonKey.equalsignorecase('payer')){
                                //system.debug(Logginglevel.ERROR,'**** payer = '+meta.get(jsonKey));
                                jscls.Payer__c = string.valueOf(meta.get(jsonKey));
                        }
                        if(jsonKey.equalsignorecase('accountLocation')){
                                //system.debug(Logginglevel.ERROR,'**** accountLocation = '+meta.get(jsonKey));
                                jscls.AccountLocationSapId__c = string.valueOf(meta.get(jsonKey));
                        }
                        if(jsonKey.equalsignorecase('product'))                                             {
                                //system.debug(Logginglevel.ERROR,'**** product = '+meta.get(jsonKey));
                                jscls.ProductId__c = string.valueOf(meta.get(jsonKey));
                        } 
                        if(jsonKey.equalsignorecase('quantity')){
                                //system.debug(Logginglevel.ERROR,'**** quantity = '+meta.get(jsonKey));
                                jscls.Quantity__c = integer.valueOf(meta.get(jsonKey));
                        }
                        if(jsonKey.equalsignorecase('sellingUom')){
                               // system.debug(Logginglevel.ERROR,'**** sellingUom = '+meta.get(jsonKey));
                                jscls.SellingUom__c = string.valueOf(meta.get(jsonKey));                                                                                                                                                                               
                        }
                        if(jsonKey.equalsignorecase('Stock Partner')){
                            //system.debug(Logginglevel.ERROR,'**** Stock Partner = '+meta.get(jsonKey));
                            jscls.APTS_Stock_Partner__c = string.valueOf(meta.get(jsonKey));
                        }  
                        //V101 ++ <<
                        if(jsonKey.equalsignorecase('Order Reason')){
                            //system.debug(Logginglevel.ERROR,'**** order Reason = '+meta.get(jsonKey));
                            jscls.Order_Reason__c = string.valueOf(meta.get(jsonKey));
                        }   
                        //V101 ++ >> 
                        // Add userID and batchID
                        jscls.UploadedByUserId__c = currentUserId;
                        jscls.BatchId__c = uniqueKey;
                    }
            
                }
                lstPrjs.add(jscls);
                countSize++;
            }
        }
        system.debug(Logginglevel.ERROR,'lstPrjs ===> '+JSON.serialize(lstPrjs)); // lstPrjs now contains all the user uploaded data 
        // now insert 1stPrjs into Salesforce 'staging table' 
        insert lstPrjs;
       // only select back the records for which 'NeedsProcessing' field is still checked
        List<APTS_TriangleInvoiceOrders__c> allOrders = [SELECT BillTo__c,Name,Id,SAP_Customer_ID__c,HasError__c,
        OrderReference__c,Payer__c,AccountLocationSapId__c,Pricing_Date__c, Invoice_Remarks__c, ProductId__c,PO__c, Quantity__c,ErrorMessage__c, Requested_Delivery_Date__c,SAP_OrderType__c,Order_Sub_Type__c, SellingUom__c,
        SoldTo__c,APTS_Stock_Partner__c,Order_Reason__c FROM APTS_TriangleInvoiceOrders__c WHERE  UploadedByUserId__c =:currentUserId AND BatchId__c =:uniqueKey];
        system.debug(LoggingLevel.ERROR, 'size of allorders*' + allOrders.size());
        system.debug(Logginglevel.ERROR, 'recordId test' + allOrders[0].Id);        
        ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////                                                                                                                                                                                                                   
        // now create a map so that we can loop through orders one by one         
        map<string,list<APTS_TriangleInvoiceOrders__c>> mapjscls = new map<string,list<APTS_TriangleInvoiceOrders__c>>();
        for(APTS_TriangleInvoiceOrders__c js : allOrders){
            system.debug(Logginglevel.ERROR,'js.orderReference' + js.OrderReference__c);
            if(mapjscls.containsKey(js.OrderReference__c))
            {
                list<APTS_TriangleInvoiceOrders__c> newcls = new list<APTS_TriangleInvoiceOrders__c>();
                newcls = mapjscls.get(js.OrderReference__c);
                newcls.add(js);
                mapjscls.put(js.OrderReference__c,newcls);      
            }
            else
            {
                list<APTS_TriangleInvoiceOrders__c> lstpr =  new list<APTS_TriangleInvoiceOrders__c>();
                lstpr.add(js);
                mapjscls.put(js.OrderReference__c,lstpr);
            }
        }
        system.debug(Logginglevel.ERROR,'mapjscls  ===> '+json.serialize(mapjscls));
        string batchId = '';
        APTS_TriangularInvoiceOrderCreationBatch orderCreationbatch = new APTS_TriangularInvoiceOrderCreationBatch(uniqueKey,mapjscls );
        Integer batchSize = Integer.valueOf(label.APTS_TriAngularInvoiceBatch);
        Database.Executebatch(orderCreationbatch,batchSize);
               
        // Display message to the User 
            
    // APTS_AgreementLoadBatchHelper.modifyTriggers(setTriggers, 'Activate');           
     } catch(Exception ex){APTS_CustomLogging.createErrorLog(ex.getTypeName(), 'Apex', ex.getStackTraceString(), 'TriangleInvoiceOrders', null, 'OM', false, false, null, true);}
     return 'OK';
     }  // end of main method
  
    // this method can be used to keep track of limits
    @TestVisible
    static private string getLimits()
    {        
            string limitstring = ''; 
            try{       
            limitstring += 'Query Limits: '+ Limits.getQueries() + '/' + Limits.getLimitQueries() +'\n';
            limitstring += 'DML Rows Limits: '+Limits.getDMLRows()+'/' + Limits.getLimitDMLRows()+'\n';
            limitstring += 'Heap Size Limits: '+Limits.getHeapSize()+'/' +Limits.getLimitHeapSize()+'\n';
            limitstring += 'Query Return Limits: '+Limits.getQueryRows()+'/' + Limits.getLimitQueryRows()+'\n';      
            limitstring += 'Aggregate Queries: '+Limits.getAggregateQueries()+'/' + Limits.getLimitAggregateQueries();
            limitstring += 'Callouts: '+Limits.getCallouts()+'/' +Limits.getLimitCallouts();    
            limitstring += 'CPU Time: '+Limits.getCpuTime()+'/' +Limits.getLimitCpuTime();
            limitstring += 'DML Statements: '+Limits.getDMLStatements()+'/' +Limits.getLimitDMLStatements();
            limitstring += 'Email Invocations: '+Limits.getEmailInvocations()+'/' +Limits.getLimitEmailInvocations();    
            limitstring += 'Future Calls: '+Limits.getFutureCalls()+'/' +Limits.getLimitFutureCalls();     
            limitstring += 'Query Locator Rows: '+Limits.getQueryLocatorRows() +'/'+Limits.getLimitQueryLocatorRows();     
            }catch(Exception ex){APTS_CustomLogging.createErrorLog(ex.getTypeName(), 'Apex', ex.getStackTraceString(), 'TriangleInvoiceOrders', null, 'OM', false, false, null, true);}
            return limitstring;       
    }

}