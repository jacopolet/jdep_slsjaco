/**********************************************************************************
 * @Author: Shahul
 * @Company: Accenture
 * @Description: Handles the Discount Bucketizing AND it's Resequencing
 * @Created Date: Oct 10, 2018
 * @History:
 *      <Name>              <Date>          <Description>
 *      Shahul              10.10.2018       Created
 **********************************************************************************/

global class APTS_DiscountBucketizing{

global APTS_DiscountBucketizing(){}

global static List<Apttus_Config2__AdjustmentLineItem__c> processAdjustmentLineItemfields(List<Apttus_Config2__AdjustmentLineItem__c> adjItems) 
{
    List<Apttus_Config2__AdjustmentLineItem__c> ReturnCERAdj=new List<Apttus_Config2__AdjustmentLineItem__c>();
    List<Apttus_Config2__AdjustmentLineItem__c> lstSeqAdjLineItems = new List<Apttus_Config2__AdjustmentLineItem__c>();
    list<string> AdjAppliesTo=new list<string>();
        if(adjItems!=null&&adjItems.size()>0){
        for (Apttus_Config2__AdjustmentLineItem__c adjustmentLineItem : adjItems) {

            if (adjustmentLineItem.Apttus_Config2__SubType__c == 'ZP03') {
                adjustmentLineItem.Apttus_Config2__Type__c = 'GSV';
                adjustmentLineItem.Apttus_Config2__Bucket__c = 'Bucket 1' ;
            }
            
            else if(adjustmentLineItem.Apttus_Config2__SubType__c == 'ZP02')
            {
                adjustmentLineItem.Apttus_Config2__Type__c = 'Inflation';
                adjustmentLineItem.Apttus_Config2__Bucket__c = 'Bucket 2' ;
            }
            
            else if (adjustmentLineItem.Apttus_Config2__SubType__c == 'ZP06') {

                adjustmentLineItem.Apttus_Config2__Type__c = 'PPR';
                adjustmentLineItem.Apttus_Config2__Bucket__c = 'Bucket 3' ;
            }

            else if (adjustmentLineItem.Apttus_Config2__SubType__c == 'ZP07') {

                adjustmentLineItem.Apttus_Config2__Type__c = 'PPR';
                adjustmentLineItem.Apttus_Config2__Bucket__c = 'Bucket 3' ;
            }

            else if (adjustmentLineItem.Apttus_Config2__SubType__c == 'ZP04') {

                adjustmentLineItem.Apttus_Config2__Type__c = 'TPR';
                adjustmentLineItem.Apttus_Config2__Bucket__c = 'Bucket 4' ;
            }

            else if (adjustmentLineItem.Apttus_Config2__SubType__c == 'ZP08') {

                adjustmentLineItem.Apttus_Config2__Type__c = 'TPR';
                adjustmentLineItem.Apttus_Config2__Bucket__c = 'Bucket 4' ;
            }

            else if (adjustmentLineItem.Apttus_Config2__SubType__c == 'ZP10') {

                adjustmentLineItem.Apttus_Config2__Type__c = 'TPR';
                adjustmentLineItem.Apttus_Config2__Bucket__c = 'Bucket 4' ;
            }

            else if (adjustmentLineItem.Apttus_Config2__SubType__c == 'ZX10') {

                adjustmentLineItem.Apttus_Config2__Type__c = 'TPR';
                adjustmentLineItem.Apttus_Config2__Bucket__c = 'Bucket 4' ;
            }

            else if (adjustmentLineItem.Apttus_Config2__SubType__c == 'ZP15') {

                adjustmentLineItem.Apttus_Config2__Type__c = 'BMC';
                adjustmentLineItem.Apttus_Config2__Bucket__c = 'Bucket 5' ;
            }

            else if (adjustmentLineItem.Apttus_Config2__SubType__c == 'ZP11') {

                adjustmentLineItem.Apttus_Config2__Type__c = 'BMC';
                adjustmentLineItem.Apttus_Config2__Bucket__c = 'Bucket 5' ;
            }

            else if (adjustmentLineItem.Apttus_Config2__SubType__c == 'ZP13') {

                adjustmentLineItem.Apttus_Config2__Type__c = 'BMC';
                adjustmentLineItem.Apttus_Config2__Bucket__c = 'Bucket 5' ;
            }


            else if (adjustmentLineItem.Apttus_Config2__SubType__c == 'ZP12') {

                adjustmentLineItem.Apttus_Config2__Type__c = 'BMC';
                adjustmentLineItem.Apttus_Config2__Bucket__c = 'Bucket 5' ;
            }

            else if (adjustmentLineItem.Apttus_Config2__SubType__c == 'YOCI') {

                adjustmentLineItem.Apttus_Config2__Type__c = 'YOCI';
                adjustmentLineItem.Apttus_Config2__Bucket__c = 'Bucket 6' ;
            }

            else if (adjustmentLineItem.Apttus_Config2__SubType__c == 'YOFT') {

                adjustmentLineItem.Apttus_Config2__Type__c = 'YOFT';
                adjustmentLineItem.Apttus_Config2__Bucket__c = 'Bucket 6' ;
            }
            AdjAppliesTo.add(adjustmentLineItem.Apttus_Config2__Bucket__c);
            system.debug('++shahul++' + AdjAppliesTo);
        }
            }
            if(adjItems!=null&&adjItems.size()>0) {
        for (Apttus_Config2__AdjustmentLineItem__c adjustmentLineItem1 : adjItems) 
        {
            if (AdjAppliesTo.contains('Bucket 1') && adjustmentLineItem1.Apttus_Config2__Bucket__c == 'Bucket 1') {
                adjustmentLineItem1.Apttus_Config2__AdjustmentAppliesTo__c = 'Starting Price';
            }

            if (AdjAppliesTo.contains('Bucket 2') && adjustmentLineItem1.Apttus_Config2__Bucket__c == 'Bucket 2') {
                if (AdjAppliesTo.contains('Bucket 1')) {
                    adjustmentLineItem1.Apttus_Config2__AdjustmentAppliesTo__c = 'Bucket 1';
                } else {
                    adjustmentLineItem1.Apttus_Config2__AdjustmentAppliesTo__c = 'Starting Price';
                }
            }

            if (AdjAppliesTo.contains('Bucket 3') && adjustmentLineItem1.Apttus_Config2__Bucket__c == 'Bucket 3') {
                if (AdjAppliesTo.contains('Bucket 2')) {
                    adjustmentLineItem1.Apttus_Config2__AdjustmentAppliesTo__c = 'Bucket 2';
                } else if (AdjAppliesTo.contains('Bucket 1')) {
                    adjustmentLineItem1.Apttus_Config2__AdjustmentAppliesTo__c = 'Bucket 1';
                } else {
                    adjustmentLineItem1.Apttus_Config2__AdjustmentAppliesTo__c = 'Starting Price';
                }
            }

            if (AdjAppliesTo.contains('Bucket 4') && adjustmentLineItem1.Apttus_Config2__Bucket__c == 'Bucket 4') {
                if (AdjAppliesTo.contains('Bucket 3')) {
                    adjustmentLineItem1.Apttus_Config2__AdjustmentAppliesTo__c = 'Bucket 3';
                } else if (AdjAppliesTo.contains('Bucket 2')) {
                    adjustmentLineItem1.Apttus_Config2__AdjustmentAppliesTo__c = 'Bucket 2';
                } else if (AdjAppliesTo.contains('Bucket 1')) {
                    adjustmentLineItem1.Apttus_Config2__AdjustmentAppliesTo__c = 'Bucket 1';
                } else {
                    adjustmentLineItem1.Apttus_Config2__AdjustmentAppliesTo__c = 'Starting Price';
                }

            }

            if (AdjAppliesTo.contains('Bucket 5') && adjustmentLineItem1.Apttus_Config2__Bucket__c == 'Bucket 5') {
                if (AdjAppliesTo.contains('Bucket 4')) {
                    adjustmentLineItem1.Apttus_Config2__AdjustmentAppliesTo__c = 'Bucket 4';
                } else if (AdjAppliesTo.contains('Bucket 3')) {
                    adjustmentLineItem1.Apttus_Config2__AdjustmentAppliesTo__c = 'Bucket 3';
                } else if (AdjAppliesTo.contains('Bucket 2')) {
                    adjustmentLineItem1.Apttus_Config2__AdjustmentAppliesTo__c = 'Bucket 2';
                } else if (AdjAppliesTo.contains('Bucket 1')) {
                    adjustmentLineItem1.Apttus_Config2__AdjustmentAppliesTo__c = 'Bucket 1';
                } else {
                    adjustmentLineItem1.Apttus_Config2__AdjustmentAppliesTo__c = 'Starting Price';
                }
            }
            
            if (AdjAppliesTo.contains('Bucket 6') && adjustmentLineItem1.Apttus_Config2__Bucket__c == 'Bucket 6') {
                if (AdjAppliesTo.contains('Bucket 5')) {
                    adjustmentLineItem1.Apttus_Config2__AdjustmentAppliesTo__c = 'Bucket 5';
                } else if (AdjAppliesTo.contains('Bucket 4')) {
                    adjustmentLineItem1.Apttus_Config2__AdjustmentAppliesTo__c = 'Bucket 4';
                } else if (AdjAppliesTo.contains('Bucket 3')) {
                    adjustmentLineItem1.Apttus_Config2__AdjustmentAppliesTo__c = 'Bucket 3';
                } else if (AdjAppliesTo.contains('Bucket 2')) {
                    adjustmentLineItem1.Apttus_Config2__AdjustmentAppliesTo__c = 'Bucket 2';
                }  else if (AdjAppliesTo.contains('Bucket 1')) {
                    adjustmentLineItem1.Apttus_Config2__AdjustmentAppliesTo__c = 'Bucket 1';
                }   else {
                    adjustmentLineItem1.Apttus_Config2__AdjustmentAppliesTo__c = 'Starting Price';
                }
            }
            
            ReturnCERAdj.add(adjustmentLineItem1);
        }
    }
       lstSeqAdjLineItems = resequenceAdjustmentLines(ReturnCERAdj);
        return lstSeqAdjLineItems;
 }
 
    global static List<Apttus_Config2__AdjustmentLineItem__c> resequenceAdjustmentLines (List<Apttus_Config2__AdjustmentLineItem__c> ReturnCERAdj)
    {
        Map<String,List<Apttus_Config2__AdjustmentLineItem__c>> mapToSequenceAdj = new Map<String,List<Apttus_Config2__AdjustmentLineItem__c>>();
        List<Apttus_Config2__AdjustmentLineItem__c> lstAdjustmentLineItems = new List<Apttus_Config2__AdjustmentLineItem__c>();

        for(Apttus_Config2__AdjustmentLineItem__c instAdjLineItem : ReturnCERAdj)
        {
            {    
                if(mapToSequenceAdj.containsKey(instAdjLineItem.Apttus_Config2__AdjustmentAppliesTo__c))
                    { List<Apttus_Config2__AdjustmentLineItem__c> lstAdjustment = new List<Apttus_Config2__AdjustmentLineItem__c>();
                      lstAdjustment = mapToSequenceAdj.get(instAdjLineItem.Apttus_Config2__AdjustmentAppliesTo__c);
                      lstAdjustment.add(instAdjLineItem);
                      mapToSequenceAdj.put(instAdjLineItem.Apttus_Config2__AdjustmentAppliesTo__c,lstAdjustment);
                    }
                    else
                    {
                      List<Apttus_Config2__AdjustmentLineItem__c> lstAdjustment = new List<Apttus_Config2__AdjustmentLineItem__c>();
                      lstAdjustment.add(instAdjLineItem);
                      mapToSequenceAdj.put(instAdjLineItem.Apttus_Config2__AdjustmentAppliesTo__c,lstAdjustment);
                    } 
            } 
        }
               List<String> lstString = new List<String>();
        for(String s : mapToSequenceAdj.keySet())
        {
        if(s=='Starting Price')
        s='Bucket 0';  
        lstString.add(s);
        } // here keySet List is sorted.
        lstString.sort();

        for(String instAdappto: lstString) 
        {
           if(instAdappto == 'Bucket 0') 
           instAdappto = 'Starting Price';
           lstAdjustmentLineItems.addAll(mapToSequenceAdj.get(instAdappto));
        }      
       
        return lstAdjustmentLineItems;
    }

}