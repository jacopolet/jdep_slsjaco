/**********************************************************************************
* @Author: Keerthana
* @Company: Accenture
* @Description: Handles the Contents/file creation for Bizisland Account
* @Created Date: Oct 4, 2018
* @History:
*      <Name>              <Date>          <Description>
*      Shahul              10.04.2018       Created
**********************************************************************************/
global class APTS_ProductBizIsland implements Database.Batchable<sObject>, Database.Stateful {
   
    global String csvColumnHeader;
    global List<String> csvRowValues = new List<String>();
    private static final String BOX = 'SAP_BX';
    private static final String KILOGRAM = 'SAP_KGM';
    private static final String LITER = 'SAP_LTR';
    private static final String BOXUOM = 'BX';
    private static final String KILOGRAMUOM = 'KGM';
    private static final String LITERUOM = 'LTR';
    
   
    global Database.QueryLocator start(Database.BatchableContext BC){
        Bonsai__c customSetting = Bonsai__c.getAll().values();
        String query;
        if(customSetting.Delta_Load__c){
            APTS_BizIsland__mdt bizmdt = [Select APTS_Query__c from APTS_BizIsland__mdt where DeveloperName= :'ProductDelta'][0];
            query = bizmdt.APTS_Query__c; 
        }else if(customSetting.Full_Load__c){
            APTS_BizIsland__mdt bizmdt = [Select APTS_Query__c from APTS_BizIsland__mdt where DeveloperName= :'ProductFull'][0];
            query = bizmdt.APTS_Query__c;
        }else{
            APTS_BizIsland__mdt bizmdt = [Select APTS_Query__c from APTS_BizIsland__mdt where DeveloperName= :'ProductDelta'][0];
            query = bizmdt.APTS_Query__c;
        }
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<sObject> scope){
       
        Set<id> prodid = new Set<id>();
        //List<APTS_Sales_Org_Data__c> salesOrg;
        //List<Apttus_Config2__FrequencyConversionRate__c> freqqConverse = new List<Apttus_Config2__FrequencyConversionRate__c>();
        for(Product2 product : (List<Product2>) scope){
            if(product.id!= null){
                prodid.add(product.id);
            }
            //salesOrg = product.Sales_Org_Datas__r; 
        }
        Map<Id,List<Apttus_Config2__FrequencyConversionRate__c>> fcmap = new Map<id,List<Apttus_Config2__FrequencyConversionRate__c>>();
        //List<Apttus_Config2__FrequencyConversionRate__c> tempList;
        if(prodid.size()>0){
            for(Apttus_Config2__FrequencyConversionRate__c freqqConverse : [Select id,
                                                                                APTS_Denominator__c,
                                                                                Apttus_Config2__FromUom__c,
                                                                                APTS_Numerator__c,
                                                                                Apttus_Config2__ToUom__c,
                                                                                Apttus_Config2__ProductId__c 
                                                                            from Apttus_Config2__FrequencyConversionRate__c 
                                                                            where Apttus_Config2__FromUom__c='SAP_PCE' 
                                                                            AND Apttus_Config2__ToUom__c IN ('SAP_BX','SAP_KGM','SAP_LTR')
                                                                            AND Apttus_Config2__ProductId__c IN :prodid ORDER BY Apttus_Config2__ToUom__c
                                                                            LIMIT 50000]){
                List<Apttus_Config2__FrequencyConversionRate__c> tempList = new List<Apttus_Config2__FrequencyConversionRate__c>();
                if(fcmap.containsKey(freqqConverse.Apttus_Config2__ProductId__c)){
                    tempList = fcmap.get(freqqConverse.Apttus_Config2__ProductId__c);

                    if (!tempList.contains(freqqConverse)) {
                        tempList.add(freqqConverse);
                        fcmap.put(freqqConverse.Apttus_Config2__ProductId__c,tempList);
                    }
                }else{
                    tempList.add(freqqConverse);
                    fcmap.put(freqqConverse.Apttus_Config2__ProductId__c, new List<Apttus_Config2__FrequencyConversionRate__c>(tempList));
                }   
            }
        }
        system.debug('fcmap====>'+fcmap);
        Map<Id,List<Apttus_Config2__FrequencyConversionRate__c>> comboMap = new Map<id,List<Apttus_Config2__FrequencyConversionRate__c>>();
        if(prodid.size()>0){
            for(Apttus_Config2__FrequencyConversionRate__c freqqConverseCombo : [Select id,
                                                                                APTS_Denominator__c,
                                                                                Apttus_Config2__FromUom__c,
                                                                                APTS_Numerator__c,
                                                                                Apttus_Config2__ToUom__c,
                                                                                Apttus_Config2__ProductId__c 
                                                                            from Apttus_Config2__FrequencyConversionRate__c 
                                                                            where Apttus_Config2__FromUom__c='SAP_PCE' 
                                                                            AND Apttus_Config2__ToUom__c IN ('SAP_KGM','SAP_LTR')
                                                                            AND Apttus_Config2__ProductId__c IN :prodid
                                                                            ORDER BY Apttus_Config2__ToUom__c 
                                                                            LIMIT 50000]){
                  List<Apttus_Config2__FrequencyConversionRate__c> tempList = new List<Apttus_Config2__FrequencyConversionRate__c>();
                if(comboMap.containsKey(freqqConverseCombo.Apttus_Config2__ProductId__c)){
                    tempList = comboMap.get(freqqConverseCombo.Apttus_Config2__ProductId__c);

                    if (!tempList.contains(freqqConverseCombo)) {
                        tempList.add(freqqConverseCombo);
                        comboMap.put(freqqConverseCombo.Apttus_Config2__ProductId__c,tempList);
                    }
                }else{
                    tempList.add(freqqConverseCombo);
                    comboMap.put(freqqConverseCombo.Apttus_Config2__ProductId__c, new List<Apttus_Config2__FrequencyConversionRate__c>(tempList));
                }   
            }
        }
        system.debug('comboMap====>'+comboMap);
        for(Product2 a : (List<Product2>)scope){
            String Status;
            String disChan = '';
            String uom = '';
            String SellingUnit ='';
            String prodname ='';
            String assosalesorg ='';
            Decimal XBOX = 0.00;
            Decimal YBOX = 0.00; 
            String BunBox = '';
            Decimal XLKG;
            String AUnLKG = '';
            Decimal YLKG;
            String BunLKG = '';
            Boolean comboFound = false;
            if(a.CreatedDate.date() == System.Today()
                && a.LastModifiedDate.date() == System.Today()){
                if(a.isDeleted){
                    Status = 'Deleted';
                }else{
                     Status = 'New';
                }
            }else if(a.LastModifiedDate.date() != a.CreatedDate.date()){
                if(a.isDeleted){
                    Status = 'Deleted';
                }else{
                     Status='Modified'; 
                }
            }else {
                Status='Not Modified';
            }
            List<APTS_Sales_Org_Data__c> salesOrg = a.Sales_Org_Datas__r; 
            if(SalesOrg!= NULL 
                && SalesOrg.size()>0 
                && SalesOrg[0].APTS_Distribution_channel__c != NULL 
                && SalesOrg[0].APTS_Distribution_channel__c.contains('SAP_')){
                disChan =  (SalesOrg[0].APTS_Distribution_channel__c).replace('SAP_','');
            }   
            if(SalesOrg!= NULL 
                && SalesOrg.size()>0 
                && SalesOrg[0].APTS_Selling_Unit__c  != NULL 
                && SalesOrg[0].APTS_Selling_Unit__c.contains('SAP_')){
                SellingUnit =  SalesOrg[0].APTS_Selling_Unit__c.replace('SAP_','');
            }
            if(a.Apttus_Config2__Uom__c != NULL && a.Apttus_Config2__Uom__c.contains('SAP_')){
                uom = a.Apttus_Config2__Uom__c.replace('SAP_','');
            }else if (a.Apttus_Config2__Uom__c != NULL){
                uom = a.Apttus_Config2__Uom__c;
            }
            
            if(a.APTS_Associated_Sales_Org_DK__c != NULL && a.APTS_Associated_Sales_Org_DK__c.contains('SAP_')){
                assosalesorg = a.APTS_Associated_Sales_Org_DK__c.replace('SAP_','');
            }else if (a.APTS_Associated_Sales_Org_DK__c != NULL){
                assosalesorg = a.APTS_Associated_Sales_Org_DK__c;
            }
            
            if(a.Name != NULL && a.Name.contains(',')){
                prodname= a.Name.replace(',','.');
            }else if (a.Name!= NULL){
                prodname = a.Name;
            }
            if(!fcmap.isEmpty()
                && fcmap.containskey(a.id)
                && fcmap.get(a.id) != null){
                system.debug('Enters Main Loop====>');
                List<Apttus_Config2__FrequencyConversionRate__c> freqConverse = fcmap.get(a.id);
                for(Apttus_Config2__FrequencyConversionRate__c frequencyRec : freqConverse){
                    // To UOM ===> BOX
                    if(BOX.equalsIgnoreCase(frequencyRec.Apttus_Config2__ToUom__c)){
                        XBOX = frequencyRec.APTS_Denominator__c != null? frequencyRec.APTS_Denominator__c : 0.00;
                        YBOX = frequencyRec.APTS_Numerator__c != null? frequencyRec.APTS_Denominator__c : 0.00;
                        system.debug('XBOX Loop====>'+YBOX);
                        system.debug('YBOX Loop====>'+YBOX);
                        if(XBOX != null 
                            && YBOX != null
                            && frequencyRec.Apttus_Config2__FromUom__c != null){
                            if(frequencyRec.Apttus_Config2__FromUom__c.contains('SAP_')){
                                BunBox = frequencyRec.Apttus_Config2__FromUom__c.remove('SAP_');
                            }
                            system.debug('BunBox Loop====>'+BunBox);
                        }
                    }
                   
                    // To UOM KGM / Litre 
                    
                    if(LITER.equalsIgnoreCase(frequencyRec.Apttus_Config2__ToUom__c)){
                        if(frequencyRec.Apttus_Config2__FromUom__c.contains('SAP_')){
                                BunLKG = frequencyRec.Apttus_Config2__FromUom__c.remove('SAP_');
                        }
                        system.debug('BunLKG Loop====>'+BunLKG);
                        if(comboMap.containsKey(frequencyRec.Apttus_Config2__ProductId__c)
                            && comboMap.get(frequencyRec.Apttus_Config2__ProductId__c) != null){
                            List<Apttus_Config2__FrequencyConversionRate__c> comboElement = comboMap.get(frequencyRec.Apttus_Config2__ProductId__c);
                            for(Apttus_Config2__FrequencyConversionRate__c combo : comboElement){
                                if(KILOGRAM.equalsIgnoreCase(combo.Apttus_Config2__ToUom__c)){
                                    system.debug('===>Liter Denominator==>'+frequencyRec.APTS_Denominator__c);
                                    system.debug('===>Liter Numerator==>'+frequencyRec.APTS_Numerator__c);
                                    system.debug('===>Kiligram Denominator==>'+combo.APTS_Denominator__c);
                                    system.debug('===>Kiligram Numerator==>'+combo.APTS_Numerator__c);
                                  XLKG = frequencyRec.APTS_Denominator__c;
                                  YLKG = frequencyRec.APTS_Numerator__c;
                                  AUnLKG = LITERUOM;
                                  system.debug('XLKG Loop====>'+XLKG);
                                  system.debug('XLKG Loop====>'+YLKG);
                                  break;
                                }  
                            }
                       }
                    }
                    if(KILOGRAM.equalsIgnoreCase(frequencyRec.Apttus_Config2__ToUom__c)){
                        if(frequencyRec.Apttus_Config2__FromUom__c.contains('SAP_')){
                            BunLKG = frequencyRec.Apttus_Config2__FromUom__c.remove('SAP_');
                        }
                         system.debug('BunLKG Loop====>'+BunLKG);
                       if(comboMap.containsKey(frequencyRec.Apttus_Config2__ProductId__c)
                            && comboMap.get(frequencyRec.Apttus_Config2__ProductId__c) != null){
                            List<Apttus_Config2__FrequencyConversionRate__c> comboElement = comboMap.get(frequencyRec.Apttus_Config2__ProductId__c);
                            for(Apttus_Config2__FrequencyConversionRate__c combo : comboElement){
                                if(LITER.equalsIgnoreCase(combo.Apttus_Config2__ToUom__c)){
                                    XLKG = combo.APTS_Denominator__c;
                                    YLKG = combo.APTS_Numerator__c;
                                    AUnLKG = LITERUOM;
                                    system.debug('===>Liter Denominator==>'+combo.APTS_Denominator__c);
                                    system.debug('===>Liter Numerator==>'+combo.APTS_Numerator__c);
                                    system.debug('===>Kiligram Denominator==>'+frequencyRec.APTS_Denominator__c);
                                    system.debug('===>Kiligram Numerator==>'+frequencyRec.APTS_Numerator__c);
                                    system.debug('XLKG Loop====>'+XLKG);
                                    system.debug('XLKG Loop====>'+YLKG);
                                    break;
                                }
                            }
                       }
                    }
                }
                // Combo not fund
                for(Apttus_Config2__FrequencyConversionRate__c frequencyRec : freqConverse){
                    system.debug('LAst Loop====>'+BunBox);
                    system.debug('LAst Loop XLKG====>'+XLKG);
                    if(XLKG == null 
                        && KILOGRAM.equalsIgnoreCase(frequencyRec.Apttus_Config2__ToUom__c)){
                        XLKG  = frequencyRec.APTS_Denominator__c;
                        AUnLKG = KILOGRAMUOM;
                        if(frequencyRec.Apttus_Config2__FromUom__c.contains('SAP_')){
                            BunLKG = frequencyRec.Apttus_Config2__FromUom__c.remove('SAP_');
                        }
                        //BunLKG = frequencyRec.Apttus_Config2__FromUom__c;
                    }
                    if(YLKG == null 
                        && KILOGRAM.equalsIgnoreCase(frequencyRec.Apttus_Config2__ToUom__c)){
                        YLKG  = frequencyRec.APTS_Numerator__c;
                        AUnLKG = KILOGRAMUOM;
                        if(frequencyRec.Apttus_Config2__FromUom__c.contains('SAP_')){
                            BunLKG = frequencyRec.Apttus_Config2__FromUom__c.remove('SAP_');
                        }
                    }
                }
            }                                                                  
            String rowStrn =assosalesorg+','+disChan+','+a.ProductCode+','+prodname+','+a.APTS_Global_Product_Hierarchy__c+','+a.IsActive+','+uom+','+SellingUnit+','+a.APTS_Internatl_article_no_EANUPC_Piece__c+','+a.APTS_Length_Piece_Mtrs__c+','+a.APTS_Width_Piece_Mtrs__c+','+a.APTS_height_Piece_Mtrs__c+','+a.APTS_International_article_no_EANUPC_Box__c+','+XBOX+','+YBOX+','+BunBox+','+XLKG+','+AUnLKG+','+YLKG+','+BunLKG+','+Status;
            system.debug('==>rowStrn==>'+rowStrn);
            csvRowValues.add(rowStrn);
            /*disChan = '';
            uom = '';
            SellingUnit ='';
            //XBOX ='';
            //YBOX='';
            BunBox='';
            //XLKG = '';
            AUnLKG = '';
            //YLKG = '';
            BunLKG = '';*/
        }
    }
    
    global void finish(Database.BatchableContext BC){
        Bonsai__c cs = Bonsai__c.getAll().values();
        Date d=system.today();
        String Bon='Bonsai Request'+' '+d;
        list<BizIsland_Request__c> biz=[ SELECT Id, Name,Version__c FROM BizIsland_Request__c where name=:Bon];
        if(!biz.isEmpty()){
            csvColumnHeader ='Sales Organization,Distribution Channel,Product Number,Product Name,Product Hierarchy,Product is Active,Base Uom,Packing Unit,PC EAN,PC Length,PC Width,PC Height,Box EAN,XBOX,YBOX,BunBox,X LKG,AUn LKG,Y LKG,BunLKG,Status \n';
            String csvFile = csvColumnHeader + String.join(csvRowValues,'\n');
            APTS_BizIslandContentGenerator bizz=new APTS_BizIslandContentGenerator();
        if(cs.Delta_Load__c){
            String documentName = ' DELTA REPORT PRODS_TO_BONSAI';
            bizz.addAttachmentsToBonsai(biz[0],csvFile,documentName);
     }else if(cs.Full_Load__c){
            String documentName = 'FULL REPORT PRODS_TO_BONSAI';
             bizz.addAttachmentsToBonsai(biz[0],csvFile,documentName);
            }
            APTS_ProductBizIslandlevel prd = new APTS_ProductBizIslandlevel();
            Database.executeBatch(prd,200);
        }
            
    }
}