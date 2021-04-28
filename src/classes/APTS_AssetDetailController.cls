/* Author : Amit
 * Description: Class to display last billed orders to customer and its next billing details
 * Version: v1
 * */

public without sharing class APTS_AssetDetailController {
    private static string LINETYPE = 'Product/Service';
    private static string ORDER09 ='XD09';
    private static string ORDER12 ='XD12';
    private static string ZFLAG = 'Z';
    private static string PENDBILNG = 'Pending Billing';
    private static string PENDINV = 'Pending Invoice';
    private static string CONTRACTED = 'Contracted';
    private static string RECURRING = 'Recurring';
    private static string MONTH = 'Monthly';
    private static string QTRLY = 'Quarterly';
    private static string HLFYRLY = 'Half Yearly';
    private static string YRLY = 'Yearly';
    private static string OPNBRKT = ' (';
    private static string CLSBRKT = ') ';
    private static string DASH = '-';
    private static string ASSTOVERVIEWPAGE = 'Asset overview Page';
    private static string APEX = 'Apex';
    private static string EMPTY_STRING = '';
   
    
    @AuraEnabled
    public static AssetDetailOverView getAssetBillDetails(string assetId, string soldToAccId){
        AssetDetailOverView astOvrview = new AssetDetailOverView();
        try{
        map<string,Apttus_Config2__Order__c> mapInvoicedOrder = new map<string,Apttus_Config2__Order__c>();
        list<Apttus_Config2__Order__c> tempOrdXd09Zind = new list<Apttus_Config2__Order__c>();
        list<Apttus_Config2__Order__c> tempOrdXd12Zind = new list<Apttus_Config2__Order__c>();
        map<string,Apttus_Config2__Order__c> mapordToRem = new map<string,Apttus_Config2__Order__c>();
        map<string,Apttus_Config2__Order__c> mapordToRem12 = new map<string,Apttus_Config2__Order__c>();
        map<Apttus_Config2__Order__c,Apttus_Config2__OrderLineItem__c> mapOrdToLineItem = new map <Apttus_Config2__Order__c,Apttus_Config2__OrderLineItem__c>();
        map<Apttus_Config2__Order__c,Apttus_Config2__OrderLineItem__c> mapOrdToLineItem12 = new map <Apttus_Config2__Order__c,Apttus_Config2__OrderLineItem__c>();
        map<String,list<Apttus_Billing__BillingSchedule__c>> mapOrdBlng = new map<String,list<Apttus_Billing__BillingSchedule__c>>(); 
        datetime tempdate09 = datetime.newInstance(2019, 01, 01, 00, 00, 00);
        datetime tempdate09Fxdflag = datetime.newInstance(2019, 01, 01, 00, 00, 00);
        datetime tempdate09FxdflagAdmin = datetime.newInstance(2019, 01, 01, 00, 00, 00);
        datetime tempdate12Fxdflag = datetime.newInstance(2019, 01, 01, 00, 00, 00);
        
        datetime tempdate12 = datetime.newInstance(2019, 01, 01, 00, 00, 00);
        datetime tempdatePndInv = datetime.newInstance(4019, 01, 01, 00, 00, 00);
        Apttus_Config2__OrderLineItem__c oli = null;
        
        string currencyIso =  '';
        
        
        //SOQL to fetch XD09 / XD12 / XD09- Z indicator / XD12- Z 
        //indicator based selected asset.
        string[] ordtyp = new string[]{ORDER09,ORDER12} ;
        list<Apttus_Config2__Order__c> lstOrderDtl  =  [select Id, APTS_Total_Net_Price__c, Name, APTS_SAP_OrderType__c,
                                                        createdDate,
                                                        APTS_Invoice__c,
                                                        APTS_Invoice__r.name,
                                                        APTS_Invoice__r.APTS_Invoice_Link__c,
                                                        APTS_Fix_Term_Billing_Flag__c,
                                                        APTS_Sold_To_SAP_Customer_ID__c,
                                                        CurrencyIsoCode,
                                                        (select ID, Apttus_Config2__StartDate__c, Apttus_Config2__EndDate__c 
                                                        from Apttus_Config2__OrderLineItems__r  
                                                        where Apttus_Config2__LineType__c = :LINETYPE and 
                                                        Apttus_Config2__IsPrimaryLine__c = true and 
                                                        Apttus_Config2__AssetLineItemId__c = :assetId) 
                                                        from Apttus_Config2__Order__c 
                                                        where Apttus_Config2__SoldToAccountId__c = :soldToAccId
                                                        and APTS_SAP_OrderType__c IN: ordtyp 
                                                        and 
                                                        APTS_Order_Header_SAP_ID__c != null
                                                        
                                                       ];
        
        //Iterate over list of Admin orders to get last created Admin orders
        for(Apttus_Config2__Order__c ord : lstOrderDtl){
            oli = new Apttus_Config2__OrderLineItem__c();
            // Rent/ FOL / Sales / Consumption Model - XD09 with out Z indicator 
            if(ord.APTS_SAP_OrderType__c == ORDER09 && mapordToRem.containsKey(ord.APTS_Sold_To_SAP_Customer_ID__c) && ord.CreatedDate > tempdate09 &&  ord.APTS_Fix_Term_Billing_Flag__c !=ZFLAG){
                if(ord.Apttus_Config2__OrderLineItems__r.size()>0 && ord.Apttus_Config2__OrderLineItems__r.size() ==1){
                    oli = ord.Apttus_Config2__OrderLineItems__r;
                    mapOrdToLineItem.remove(mapordToRem.get(ord.APTS_Sold_To_SAP_Customer_ID__c));
                    mapordToRem.put(ord.APTS_Sold_To_SAP_Customer_ID__c,ord);
                    mapOrdToLineItem.put(ord,oli);
                    tempdate09 = ord.CreatedDate;
                }
            }else if(ord.APTS_SAP_OrderType__c == ORDER09 && ord.CreatedDate > tempdate09  && ord.APTS_Fix_Term_Billing_Flag__c !=ZFLAG){
                if(ord.Apttus_Config2__OrderLineItems__r.size()>0 && ord.Apttus_Config2__OrderLineItems__r.size()==1){
                    oli = ord.Apttus_Config2__OrderLineItems__r;
                    mapordToRem.put(ord.APTS_Sold_To_SAP_Customer_ID__c,ord);
                    mapOrdToLineItem.put(ord,oli);
                    tempdate09 = ord.CreatedDate;
                }
            }
            // CONSUMPTION XD12 - without Z Indicator  
            if(ord.APTS_SAP_OrderType__c == ORDER12 && mapordToRem12.containsKey(ord.APTS_Sold_To_SAP_Customer_ID__c) && ord.CreatedDate > tempdate12 && ord.APTS_Fix_Term_Billing_Flag__c !=ZFLAG){
                if(ord.Apttus_Config2__OrderLineItems__r.size()>0 && ord.Apttus_Config2__OrderLineItems__r.size()==1){
                    oli = ord.Apttus_Config2__OrderLineItems__r;
                    mapOrdToLineItem.remove(mapordToRem.get(ord.APTS_Sold_To_SAP_Customer_ID__c));
                    mapordToRem12.put(ord.APTS_Sold_To_SAP_Customer_ID__c,ord);
                    mapOrdToLineItem12.put(ord,oli);
                    tempdate12 = ord.CreatedDate;
                }
            }else if(ord.APTS_SAP_OrderType__c == ORDER12 && ord.CreatedDate > tempdate12 && ord.APTS_Fix_Term_Billing_Flag__c !=ZFLAG){
                
                if(ord.Apttus_Config2__OrderLineItems__r.size()>0 && ord.Apttus_Config2__OrderLineItems__r.size()==1){
                    oli = ord.Apttus_Config2__OrderLineItems__r;
                    mapordToRem12.put(ord.APTS_Sold_To_SAP_Customer_ID__c,ord);
                    mapOrdToLineItem12.put(ord,oli);
                    tempdate12 = ord.CreatedDate;
               }
            }
            
            // Rent / FOL / Sales - XD09 with Z indicator 
            if(ord.APTS_SAP_OrderType__c == ORDER09 && ord.APTS_Fix_Term_Billing_Flag__c ==ZFLAG && ord.CreatedDate > tempdate09Fxdflag){
                if(ord.Apttus_Config2__OrderLineItems__r.size()>0 && ord.Apttus_Config2__OrderLineItems__r.size()==1){
                    tempdate09Fxdflag = ord.CreatedDate;
                    if(!mapOrdToLineItem.isEmpty()){
                            mapOrdToLineItem.clear();
                            mapOrdToLineItem.put(ord,ord.Apttus_Config2__OrderLineItems__r);
                        
                    }else{
                        mapOrdToLineItem.put(ord,ord.Apttus_Config2__OrderLineItems__r);
                    }
                }
            }
            if(ord.APTS_SAP_OrderType__c == ORDER09 && ord.APTS_Fix_Term_Billing_Flag__c ==ZFLAG && ord.CreatedDate > tempdate09FxdflagAdmin){
                if(ord.Apttus_Config2__OrderLineItems__r.size()==0){
                    tempdate09FxdflagAdmin = ord.CreatedDate;
                    if(tempOrdXd09Zind.size()>0){
                        tempOrdXd09Zind.clear();
                        tempOrdXd09Zind.add(ord);
                    }else{
                        tempOrdXd09Zind.add(ord);
                    }
                }
            }
            // CONSUMTPION - with Z indicator 
            if(ord.APTS_SAP_OrderType__c == ORDER12 && ord.APTS_Fix_Term_Billing_Flag__c ==ZFLAG && ord.CreatedDate > tempdate12Fxdflag){
                if(ord.Apttus_Config2__OrderLineItems__r.size()>0 && ord.Apttus_Config2__OrderLineItems__r.size()==1){
                    tempdate12Fxdflag = ord.CreatedDate;
                    if(tempOrdXd12Zind.size()>0){
                        tempOrdXd12Zind.clear();
                        tempOrdXd12Zind.add(ord);
                    }else{
                        tempOrdXd12Zind.add(ord);
                    }
                }
            }
             currencyIso = ord.CurrencyIsoCode;   
        }
        
            
        // Iterate over list to populate last billing details for the invoiced admin order for XD09 
        // With or without Z indicator order - only the main machine orders. NO XD09 (FT admin order included)
        astOvrview.lstOrderdtl = new list<AdminOrderlist>();
        AdminOrderlist admOrdCls = null;
        // 
        for( Apttus_Config2__Order__c ordmp : mapOrdToLineItem.keySet()){
            admOrdCls = new AdminOrderlist();
            if(ordmp.APTS_SAP_OrderType__c == ORDER09){
                astOvrview.lastBillPrdStart = mapOrdToLineItem.get(ordmp).Apttus_Config2__StartDate__c;
                astOvrview.lastBillPrdEnd = mapOrdToLineItem.get(ordmp).Apttus_Config2__EndDate__c;
                astOvrview.lastBillAmt = ordmp.APTS_Total_Net_Price__c;
                admOrdCls.orderId = ordmp.Id;
                if(ordmp.APTS_Fix_Term_Billing_Flag__c == ZFLAG)
                    admOrdCls.OrderName = ordmp.Name+OPNBRKT+ordmp.APTS_SAP_OrderType__c+DASH+ZFLAG+CLSBRKT;
                else 
                    admOrdCls.OrderName = ordmp.Name+OPNBRKT+ordmp.APTS_SAP_OrderType__c+CLSBRKT;
                astOvrview.lstOrderdtl.add(admOrdCls);
                astOvrview.InvName =  ordmp.APTS_Invoice__r.name +OPNBRKT+ ordmp.name +CLSBRKT;
                astOvrview.InvId = ordmp.APTS_Invoice__c;
                astOvrview.Invlink =  ordmp.APTS_Invoice__r.APTS_Invoice_Link__c;
                astOvrview.currenyISOcd = ordmp.CurrencyIsoCode;
                
            }
            
            AdminOrderlist admOrdCls12 = null;
            for(Apttus_Config2__Order__c ordmp12 : mapOrdToLineItem12.keySet()){
                admOrdCls12 = new AdminOrderlist();
                if(ordmp12.APTS_SAP_OrderType__c == ORDER12){
                    admOrdCls12.orderId = ordmp12.Id;
                    admOrdCls12.OrderName = ordmp12.Name+OPNBRKT+ordmp12.APTS_SAP_OrderType__c+CLSBRKT;
                    astOvrview.lstOrderdtl.add(admOrdCls12);
                }
            }   
           
                        
            
        }
        
        
        string[] billFrq =  new string[]{MONTH,QTRLY,HLFYRLY,YRLY};
        string[] billStatus = new string[]{PENDBILNG,PENDINV};   
        //Fetch billing schedules that are in either pending invoiced or pending billing 
        list<Apttus_Billing__BillingSchedule__c> lstAssetDtl = [select Apttus_Billing__AssetLineItemId__r.APTS_Is_Primary_L1_Asset__c,
                                                                Apttus_Billing__AssetLineItemId__r.APTS_Is_Primary_L1_Asset__r.name,
                                                                Apttus_Billing__AssetLineItemId__r.APTS_Is_Primary_L1_Asset__r.APTS_Physical_Asset__r.SerialNumber__c,
                                                                Apttus_Billing__AssetLineItemId__r.APTS_Is_Primary_L1_Asset__r.APTS_Physical_Asset__c,
                                                                APTS_Admin_Order_Line__r.Apttus_Config2__OrderId__r.name,
                                                                APTS_Admin_Order_Line__r.Apttus_Config2__OrderId__r.APTS_SAP_OrderType__c,
                                                                APTS_Admin_Order_Line__r.Apttus_Config2__OrderId__c,
                                                                APTS_Admin_Order_Line__r.Apttus_Config2__OrderId__r.createdDate,
                                                                APTS_Admin_Order_Line__r.Apttus_Config2__OrderId__r.APTS_Total_Net_Price__c,
                                                                Apttus_Billing__PeriodStartDate__c,
                                                                Apttus_Billing__PeriodEndDate__c,
                                                                Apttus_Billing__Status__c,
                                                                Apttus_Billing__FeeAmount__c,
                                                                APTS_Invoice__c,
                                                                Apttus_Billing__AssetLineItemId__r.currencyIsocode,
                                                                APTS_Invoice__r.APTS_Invoice_Link__c
                                                                from Apttus_Billing__BillingSchedule__c where 
                                                                Apttus_Billing__AssetLineItemId__r.APTS_Is_Primary_L1_Asset__c =: assetId
                                                                and
                                                                Apttus_Billing__Status__c IN :billStatus
                                                                and Apttus_Billing__Type__c = :CONTRACTED
                                                                and Apttus_Billing__IsSuperseded__c = false
                                                                and Apttus_Billing__AssetLineItemId__r.Apttus_Config2__PriceType__c  =:RECURRING
                                                                and Apttus_Billing__AssetLineItemId__r.Apttus_Config2__BillingFrequency__c IN :billFrq
                                                                and Apttus_Billing__FeeAmount__c >= 0 
                                                                order by name
                                                               ];
        
        
        
        system.debug('lstAssetDtl --- > '+json.serialize(lstAssetDtl));
        if(!lstAssetDtl.isEmpty()){
            astOvrview.assetName =  lstAssetDtl[0].Apttus_Billing__AssetLineItemId__r.APTS_Is_Primary_L1_Asset__r.name; 
            astOvrview.physicalAsset = lstAssetDtl[0].Apttus_Billing__AssetLineItemId__r.APTS_Is_Primary_L1_Asset__r.APTS_Physical_Asset__r.SerialNumber__c; 
            astOvrview.assetId = lstAssetDtl[0].Apttus_Billing__AssetLineItemId__r.APTS_Is_Primary_L1_Asset__c; 
            astOvrview.physicalAssetId = lstAssetDtl[0].Apttus_Billing__AssetLineItemId__r.APTS_Is_Primary_L1_Asset__r.APTS_Physical_Asset__c; 
               
        }
        map<string,Apttus_Billing__BillingSchedule__c> mapAstBs = new map<string,Apttus_Billing__BillingSchedule__c>();
        for(Apttus_Billing__BillingSchedule__c bs : lstAssetDtl){
            system.debug('bs.APTS_Admin_Order_Line__r.Apttus_Config2__OrderId__c' +bs.APTS_Admin_Order_Line__r.Apttus_Config2__OrderId__c);
            system.debug('bs.APTS_Admin_Order_Line__r.Apttus_Config2__OrderId__c' +bs.APTS_Admin_Order_Line__r.Apttus_Config2__OrderId__r.createdDate);
            system.debug('bs.Apttus_Billing__Status__c' +bs.Apttus_Billing__Status__c);
            if( mapOrdBlng.containsKey(bs.APTS_Admin_Order_Line__r.Apttus_Config2__OrderId__c+DASH+bs.APTS_Admin_Order_Line__r.Apttus_Config2__OrderId__r.createdDate) && bs.APTS_Admin_Order_Line__c != null && bs.Apttus_Billing__Status__c == PENDINV){
                list<Apttus_Billing__BillingSchedule__c> bsLst = new list<Apttus_Billing__BillingSchedule__c>();
                  bsLst =   mapOrdBlng.get(bs.APTS_Admin_Order_Line__r.Apttus_Config2__OrderId__c+DASH+bs.APTS_Admin_Order_Line__r.Apttus_Config2__OrderId__r.createdDate);
                bsLst.add(bs);
                mapOrdBlng.put(bs.APTS_Admin_Order_Line__r.Apttus_Config2__OrderId__c+DASH+bs.APTS_Admin_Order_Line__r.Apttus_Config2__OrderId__r.createdDate,bsLst);
                
            }
            else if(bs.Apttus_Billing__Status__c == PENDINV ){
                list<Apttus_Billing__BillingSchedule__c> bslst = new list<Apttus_Billing__BillingSchedule__c>();
                bslst.add(bs);
                mapOrdBlng.put(bs.APTS_Admin_Order_Line__r.Apttus_Config2__OrderId__c+DASH+bs.APTS_Admin_Order_Line__r.Apttus_Config2__OrderId__r.createdDate,bsLst);
            }
            if(mapAstBs.containsKey(bs.Apttus_Billing__AssetLineItemId__c) && mapAstBs.get(bs.Apttus_Billing__AssetLineItemId__c).Apttus_Billing__PeriodStartDate__c < bs.Apttus_Billing__PeriodStartDate__c){
               
               mapAstBs.put(bs.Apttus_Billing__AssetLineItemId__c,mapAstBs.get(bs.Apttus_Billing__AssetLineItemId__c));
            }else{
               mapAstBs.put(bs.Apttus_Billing__AssetLineItemId__c,bs); 
                
            }
        }
        map<string,list<Apttus_Billing__BillingSchedule__c>> mapAdmPndInv = new map<string,list<Apttus_Billing__BillingSchedule__c>>();
        for(string key : mapOrdBlng.keySet()){
            datetime admdt = Datetime.valueOF(key.substringAfter(DASH));
            string ordname = key.substringBefore(DASH);
            if(admdt <tempdatePndInv){
                if(!mapAdmPndInv.isEmpty()){
                    mapAdmPndInv.clear();
                    mapAdmPndInv.put(key,mapOrdBlng.get(key)); 
                    tempdatePndInv = admdt;
                }else{
                    mapAdmPndInv.put(key,mapOrdBlng.get(key));     
                    tempdatePndInv = admdt;
                }
            }
           list<Apttus_Billing__BillingSchedule__c> fnllst = new list<Apttus_Billing__BillingSchedule__c>(); 
            for(string keyfnl : mapAdmPndInv.keyset()){
                fnllst = mapAdmPndInv.get(keyfnl);
                for(Apttus_Billing__BillingSchedule__c bsld : fnllst){
                    if( bsld.Apttus_Billing__PeriodStartDate__c < astOvrview.nxtBillPrdStart && astOvrview.nxtBillPrdStart !=null){
                        astOvrview.nxtBillPrdStart = bsld.Apttus_Billing__PeriodStartDate__c;
                    }else{
                        astOvrview.nxtBillPrdStart = bsld.Apttus_Billing__PeriodStartDate__c;
                    }
                    if( bsld.Apttus_Billing__PeriodEndDate__c < astOvrview.nxtBillPrdEnd && astOvrview.nxtBillPrdEnd !=null){
                        astOvrview.nxtBillPrdEnd = bsld.Apttus_Billing__PeriodEndDate__c;
                    }else{
                        astOvrview.nxtBillPrdEnd = bsld.Apttus_Billing__PeriodEndDate__c;
                    }
                    astOvrview.currenyISOcd = bsld.Apttus_Billing__AssetLineItemId__r.currencyIsocode;
                }
            } 
            astOvrview.nxtBillAmt = fnllst[0].APTS_Admin_Order_Line__r.Apttus_Config2__OrderId__r.APTS_Total_Net_Price__c;
        }
        if(astOvrview.nxtBillPrdStart == null && astOvrview.nxtBillPrdEnd == null && astOvrview.nxtBillAmt == null){
            astOvrview.nxtBillAmt =0.0;
            system.debug('mapAstBs -- >'+json.serialize(mapAstBs));
            for(string key : mapAstBs.keyset()){
                
                astOvrview.nxtBillAmt += mapAstBs.get(key).Apttus_Billing__FeeAmount__c;
                if(null == astOvrview.nxtBillPrdStart && null == astOvrview.nxtBillPrdEnd){
                    astOvrview.nxtBillPrdStart = mapAstBs.get(key).Apttus_Billing__PeriodStartDate__c;
                    astOvrview.nxtBillPrdEnd = mapAstBs.get(key).Apttus_Billing__PeriodEndDate__c;
                    astOvrview.currenyISOcd = mapAstBs.get(key).Apttus_Billing__AssetLineItemId__r.currencyIsocode;
                }
            }
           
        }
        AdminOrderlist admOrdClsFF12 = new AdminOrderlist();
        if(tempOrdXd12Zind.size()>0){
            admOrdClsFF12.orderId = tempOrdXd12Zind[0].Id;
            admOrdClsFF12.OrderName = tempOrdXd12Zind[0].Name+OPNBRKT+tempOrdXd12Zind[0].APTS_SAP_OrderType__c+DASH+(tempOrdXd12Zind[0].APTS_Fix_Term_Billing_Flag__c).toUppercase()+CLSBRKT;
            astOvrview.lstOrderdtl.add(admOrdClsFF12);
            
        }
        AdminOrderlist admOrdClsFF09 = new AdminOrderlist();
        if(tempOrdXd09Zind.size()>0){
            admOrdClsFF09.orderId = tempOrdXd09Zind[0].Id;
            admOrdClsFF09.OrderName = tempOrdXd09Zind[0].Name+OPNBRKT+tempOrdXd09Zind[0].APTS_SAP_OrderType__c+DASH+(tempOrdXd09Zind[0].APTS_Fix_Term_Billing_Flag__c).toUppercase()+CLSBRKT;
            astOvrview.lstOrderdtl.add(admOrdClsFF09);
            
        }
        if(null == astOvrview.currenyISOcd)
            astOvrview.currenyISOcd = currencyIso;
        }catch(exception ex){
            APTS_BIRUtils.logError(null,null,null,ex,APEX,ASSTOVERVIEWPAGE,EMPTY_STRING,false,false,EMPTY_STRING,true);
            
        }
        return astOvrview;
    }
    public class AssetDetailOverView{
        
        @AuraEnabled
        string assetName{get;set;}
        @AuraEnabled
        string assetId{get;set;}
        @AuraEnabled
        string physicalAssetId{get;set;}
        @AuraEnabled
        string physicalAsset{get;set;}
        @AuraEnabled
        date lastBillPrdStart{get;set;}
        @AuraEnabled
        date lastBillPrdEnd{get;set;}
        @AuraEnabled
        double lastBillAmt{get;set;}
        @AuraEnabled
        public list<AdminOrderlist> lstOrderdtl{get;set;}
        @AuraEnabled
        string InvName{get;set;}
        @AuraEnabled
        string InvId{get;set;}
        @AuraEnabled
        string Invlink{get;set;}
        @AuraEnabled
        date nxtBillPrdStart{get;set;}
        @AuraEnabled
        date nxtBillPrdEnd{get;set;}
        @AuraEnabled
        double nxtBillAmt{get;set;}
        @AuraEnabled
        string currenyISOcd{get;set;} 
    }
    public class AdminOrderlist{
        @AuraEnabled 
        string orderId{get;set;}
        @AuraEnabled
        string OrderName{get;set;}
    }
}