/**
* @author        Marvin Gatchalian
* @date          2.mar.2018
* @description   Apex class used to executes product synchronization 
* @revision(s)   6.08.2018 Paul Aguiling: KTS-1804 Modified listPrice value to 1 if equal to 0 or null
*                8.15.2018 Paul Aguiling: KTS 2060 Added mapping for currency iso code
*/
public without sharing class TS_ProductSynchronization_Execute {
    
    //Declaring all variables needed
    List <pricebook2> priceBookByOrg = new List <pricebook2>();
    List <pricebookentry> priceDefaultBookEntriesToBeUpsert = new List <pricebookentry>();

    //List <pricebookentry> priceBookEntriesToBeUpsert = new List <pricebookentry>();
    Map <pricebookentry, Apttus_Config2__PriceListItem__c> priceBookEntriesToBeUpsert = new 
    Map <pricebookentry, Apttus_Config2__PriceListItem__c>();
    
    Map <String, pricebook2> salesOrgPriceBookMap = new Map <String, pricebook2>();
    Map <Id, TS_ProductsWrapper> productsPliInfoMap = new Map <Id, TS_ProductsWrapper >();
    
    public List<pricebookentry> createDefaultPriceBook (List<Apttus_Config2__PriceListItem__c> priceListItems, 
                                                        Id standardPriceBookId) {
        /* try {                                                
            dataPrepration(priceListItems);
            
            //Create Default Price Book Entry for Standard Price Book
            for (Id eachProduct :productsPliInfoMap.keySet()) {

                pricebookentry pbe = new pricebookentry();
                pbe.Product2Id = eachProduct;
                pbe.Pricebook2Id = standardPriceBookId;
                pbe.UnitPrice = 1;
                pbe.TS_Load_Id__c = String.valueOf(eachProduct) + String.valueOf(standardPriceBookId);
                pbe.IsActive = true;
                pbe.TS_Click_Synchronized__c = true;    // To exclude pricebook entry with standard pricebook in sending to click 

                //KTS 2060 - Mapped currency iso code from price list item to price book entry - START
                TS_ProductsWrapper pw = new TS_ProductsWrapper();
                pw = productsPliInfoMap.get(eachProduct);

                if (pw.pli != null) { 
                    pbe.CurrencyIsoCode = pw.pli.CurrencyIsoCode;
                }
                //KTS 2060 - Mapped currency iso code from price list item to price book entry - END

                priceDefaultBookEntriesToBeUpsert.add(pbe);
            }
        } catch (Exception ex) {
            CustomLogging.debugException(ex);
            CustomLogging.pop();
            System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());
        } */

        dataPrepration(priceListItems);

        //This is to make sure that the standard pbentry with the same product and currency will not be inserted again, as BE, DE and NL has the same currency and just can share the same standard pricebook entry per product per currency.
        Set<String> currencyProductCombinationSet = new Set<String>(); 
        for (Apttus_Config2__PriceListItem__c eachLineItem : priceListItems) {

            //Get the correct pricebook
            if (salesOrgPriceBookMap.containsKey(eachLineItem.APTS_TS_Sales_Organization__c) && !currencyProductCombinationSet.contains(String.valueOf(eachLineItem.Apttus_Config2__ProductId__c) + String.valueOf(eachLineItem.CurrencyIsoCode))) {
                PriceBookEntry pbe = new PriceBookEntry();
                pbe.Product2Id = eachLineItem.Apttus_Config2__ProductId__c;
                pbe.Pricebook2Id = standardPriceBookId;       
                pbe.UnitPrice = 1;
                pbe.TS_Load_Id__c = String.valueOf(eachLineItem.Apttus_Config2__ProductId__c) + String.valueOf(standardPriceBookId) + String.valueOf(eachLineItem.CurrencyIsoCode);
                pbe.IsActive = true;
                pbe.TS_Click_Synchronized__c = true; // To exclude pricebook entry with standard pricebook in sending to click 

                if (eachLineItem != null) { 
                    pbe.CurrencyIsoCode = eachLineItem.CurrencyIsoCode;
                }

                currencyProductCombinationSet.add(String.valueOf(eachLineItem.Apttus_Config2__ProductId__c) + String.valueOf(eachLineItem.CurrencyIsoCode));                
                priceDefaultBookEntriesToBeUpsert.add(pbe);
            }
        }

        return priceDefaultBookEntriesToBeUpsert;
    }
    
    public Map<pricebookentry, Apttus_Config2__PriceListItem__c> 
                                createMatchedPriceBook (List<Apttus_Config2__PriceListItem__c> priceListItems) {
                                                            
        dataPrepration(priceListItems);
        
        //Create Matched Price Book Entry for Standard Price Book
        /* for (Id eachProduct : productsPliInfoMap.keySet()) {
            TS_ProductsWrapper pw = new TS_ProductsWrapper();
            pricebook2 matchedPriceBook = new pricebook2();

            //Get the correct pricebook
            if (productsPliInfoMap.containsKey(eachProduct)) {
                pw = productsPliInfoMap.get(eachProduct);

                if (salesOrgPriceBookMap.containsKey(pw.salesOrg)) {
                    pricebookentry pbe = new pricebookentry();
                    matchedPriceBook = salesOrgPriceBookMap.get(pw.salesOrg);
                    pbe.Product2Id = eachProduct;
                    pbe.Pricebook2Id = matchedPriceBook.id;          
                    pbe.UnitPrice = pw.listPrice != null? pw.listPrice : 1;
                    pbe.TS_Load_Id__c = String.valueOf(eachProduct) + String.valueOf(matchedPriceBook.id);
                    pbe.IsActive = true;
                    pw.pli.APTS_TS_Synchronized__c = true;
                    //priceBookEntriesToBeUpsert.add(pbe);

                    //KTS 2060 - Mapped currency iso code from price list item to price book entry - START
                    if (pw.pli != null) { 
                        pbe.CurrencyIsoCode = pw.pli.CurrencyIsoCode;
                    }
                    //KTS 2060 - Mapped currency iso code from price list item to price book entry - END
                    priceBookEntriesToBeUpsert.put(pbe, pw.pli);
                }
            }
        } */

        for (Apttus_Config2__PriceListItem__c eachLineItem : priceListItems) {
            PriceBook2 matchedPriceBook = new PriceBook2();

            //Get the correct pricebook
            if (salesOrgPriceBookMap.containsKey(eachLineItem.APTS_TS_Sales_Organization__c)) {
                PriceBookEntry pbe = new PriceBookEntry();
                matchedPriceBook = salesOrgPriceBookMap.get(eachLineItem.APTS_TS_Sales_Organization__c);
                pbe.Product2Id = eachLineItem.Apttus_Config2__ProductId__c;
                pbe.Pricebook2Id = matchedPriceBook.Id;          
                pbe.UnitPrice = eachLineItem.Apttus_Config2__ListPrice__c != null && eachLineItem.Apttus_Config2__ListPrice__c != 0? eachLineItem.Apttus_Config2__ListPrice__c : 1;
                pbe.TS_Load_Id__c = String.valueOf(eachLineItem.Apttus_Config2__ProductId__c) + String.valueOf(matchedPriceBook.Id);
                pbe.IsActive = true;
                pbe.TS_Click_Synchronized__c = false; //XEN REYES Nov. 22, 2018
                eachLineItem.APTS_TS_Synchronized__c = true;
                //priceBookEntriesToBeUpsert.add(pbe);

                if (eachLineItem != null) { 
                    pbe.CurrencyIsoCode = eachLineItem.CurrencyIsoCode;
                }
                priceBookEntriesToBeUpsert.put(pbe, eachLineItem);
            }
        } 

        return priceBookEntriesToBeUpsert;
    }
    
    
    private void dataPrepration (List<Apttus_Config2__PriceListItem__c> priceListItems) {
        Set <String> salesOrgCovered = new Set <String>();
        for (Apttus_Config2__PriceListItem__c eachPriceListItem :priceListItems) {
            TS_ProductsWrapper pw = new TS_ProductsWrapper();
            pw.listPrice = eachPriceListItem.Apttus_Config2__ListPrice__c != null && eachPriceListItem.Apttus_Config2__ListPrice__c != 0? eachPriceListItem.Apttus_Config2__ListPrice__c : 1;
            pw.salesOrg = eachPriceListItem.APTS_TS_Sales_Organization__c;
            pw.pli = eachPriceListItem;
            productsPliInfoMap.put(eachPriceListItem.Apttus_Config2__ProductId__c, pw);
            salesOrgCovered.add(eachPriceListItem.APTS_TS_Sales_Organization__c);
        }
        
        //Get pricebook based on list of sales org collected from Price List Item
        //Assumption Sales_Organization__c on Price Book is unique.
        priceBookByOrg = [Select id, Sales_Organization__c from pricebook2 where Sales_Organization__c in :salesOrgCovered];
        system.debug ('Covered Sales Org : ' + salesOrgCovered );
        system.debug ('Queried Price Book by Sales Org ' + priceBookByOrg);
        for(pricebook2 eachPB :priceBookByOrg){
            salesOrgPriceBookMap.put(eachPB.Sales_Organization__c, eachPB);
        }
    }    
}