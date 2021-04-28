public class PerfectExperienceQueueable implements Queueable{
    List<Apttus__APTS_Agreement__c> agreeList = new List<Apttus__APTS_Agreement__c>();
    public PerfectExperienceQueueable (List<Apttus__APTS_Agreement__c> agreements) {
        if (agreements <> null) {
            this.agreeList = agreements;
        }
    }
    
    public void execute(QueueableContext context) {
       if (!agreeList.isEmpty()) {
           Set<Id> acctId = new Set<Id>();
           List<Account> acctRelToAgreementList = new List<Account>();
           List<Apttus__AgreementLineItem__c> agreementLineItemList = new List<Apttus__AgreementLineItem__c>();
           Map<Id, Apttus__AgreementLineItem__c> machineBundleMap = new Map<Id, Apttus__AgreementLineItem__c>();
           Map<Id, Apttus__AgreementLineItem__c> serviceProductMap = new Map<Id, Apttus__AgreementLineItem__c>();
           Map<Id, Apttus__AgreementLineItem__c> ingredientsCoffee = new Map<Id, Apttus__AgreementLineItem__c>();
           Map<Id, Apttus__AgreementLineItem__c> ingredientsTea = new Map<Id, Apttus__AgreementLineItem__c>();
           Map<Id, Apttus__AgreementLineItem__c> moreStandaloneMilk = new Map<Id, Apttus__AgreementLineItem__c>();
           Map<Id, Apttus__AgreementLineItem__c> moreStandaloneSugar = new Map<Id, Apttus__AgreementLineItem__c>();
           Map<Id, Apttus__AgreementLineItem__c> moreStandaloneCacao = new Map<Id, Apttus__AgreementLineItem__c>();
           Map<Id, Apttus__AgreementLineItem__c> moreStandaloneCGP = new Map<Id, Apttus__AgreementLineItem__c>();
           Map<Id, Apttus__AgreementLineItem__c> moreStandaloneTDA = new Map<Id, Apttus__AgreementLineItem__c>();
           Map<Id, Apttus__AgreementLineItem__c> serviceStandalone = new Map<Id, Apttus__AgreementLineItem__c>();
           Apttus__AgreementLineItem__c tempMachineBundle = new Apttus__AgreementLineItem__c();
           Apttus__AgreementLineItem__c tempserviceProduct = new Apttus__AgreementLineItem__c();
           Apttus__AgreementLineItem__c tempingredientCoffee = new Apttus__AgreementLineItem__c();
           Apttus__AgreementLineItem__c tempingredientTea = new Apttus__AgreementLineItem__c();
           Apttus__AgreementLineItem__c tempmoreStandaloneMilk = new Apttus__AgreementLineItem__c();
           Apttus__AgreementLineItem__c tempmoreStandaloneSugar = new Apttus__AgreementLineItem__c();
           Apttus__AgreementLineItem__c tempmoreStandaloneCacao = new Apttus__AgreementLineItem__c();
           Apttus__AgreementLineItem__c tempmoreStandaloneCGP = new Apttus__AgreementLineItem__c();
           Apttus__AgreementLineItem__c tempmoreStandaloneTDA = new Apttus__AgreementLineItem__c();
           Apttus__AgreementLineItem__c tempserviceStandalone = new Apttus__AgreementLineItem__c();
           List<Perfect_Experience_Survey__c> aliPESurveyList = new List<Perfect_Experience_Survey__c>();
           List<Account> accountToUpdate = new List<Account>();
           Map<String, String> labelValueMap = new Map<String, String>();
           Perfect_Experience_Survey__c aliPESurvey = new Perfect_Experience_Survey__c();
           Set<Id> acctIdSet = new Set<Id>();
    
           Schema.DescribeFieldResult F = Product2.APTS_Product_Family2__c.getDescribe();
           List<Schema.PicklistEntry> P = F.getPicklistValues();
           for(Schema.PicklistEntry pl : P){
               labelValueMap.put(pl.getValue(), pl.getLabel());
           }
           
           System.debug('labelValueMap: ' + labelValueMap);
            
           for (Apttus__APTS_Agreement__c a : agreeList) {
               System.debug('a.APTS_Sold_To__c' + a.APTS_Sold_To__c);
               if (a.APTS_Sold_To__c != Null) {
                    acctId.add(a.APTS_Sold_To__c);
               }
           }
           
           System.debug('acctId: ' + acctId);
           if (acctId != Null) { 
               acctRelToAgreementList = [Select Id, Agreement_Based_Survey_Created__c
                                         FROM Account
                                         WHERE Id IN :acctId AND Agreement_Based_Survey_Created__c = false];
           }
           
           System.debug('acctRelToAgreementList ' + acctRelToAgreementList); 
           System.debug('acctRelToAgreementList.size()' + acctRelToAgreementList.size());
           if (acctRelToAgreementList.size() > 0) {
               agreementLineItemList = [Select Id, APTS_Machine_Bundle__c, APTS_Service_Product__c, APTS_Bundle_Option__c,
                                        APTS_Ingredient_Standalone__c, APTS_Services_Standalone__c,
                                        APTS_More_Standalone__c, Apttus__AgreementId__r.Id, Apttus__AgreementId__r.APTS_Sold_To__c,
                                        Apttus_CMConfig__ClassificationHierarchy__c, APTS_Ingredient_Option_Product_Family__c
                                        FROM Apttus__AgreementLineItem__c
                                        WHERE Apttus__AgreementId__r.APTS_Sold_To__c IN :acctRelToAgreementList];
                                          
                System.debug('agreementLineItemList:' + agreementLineItemList); 
                Product_Categories__c pcSettings = Product_Categories__c.getValues(UserInfo.getProfileId());
                Product_Categories__c pcSettingsDefault = Product_Categories__c.getOrgDefaults();
                SObjectType pcObj = Schema.getGlobalDescribe().get('Product_Categories__c');
                Map<String,Schema.SObjectField> pcfields = pcObj.getDescribe().fields.getMap();
                Map<String, String> productCategory = new Map<String, String>();
                Map<String, Decimal> pScoreMap = new Map<String, Decimal>();
                
                System.debug('pcSettings: ' + pcSettings);
                System.debug('pcSettingsDefault: ' + pcSettingsDefault);
                System.debug('pcfields: ' + pcfields.values());
                
                for (Schema.SObjectField pclabel : pcfields.values()) {
                    Schema.DescribeFieldResult dfield = pclabel.getDescribe(); 
                    System.debug('dfield: ' + dfield);
                    System.debug('!@# ' + dfield.getLabel().replace('-', '|'));
                    System.debug('dfield.isCustom(): ' + dfield.isCustom());
                    if (dfield.isCustom()) {
                        if (pcSettings <> Null) {
                            productCategory.put((String) dfield.getLabel().replace('-', '|'), (String) pcSettings.get(dfield.getName()));
                        } else {
                            productCategory.put((String) dfield.getLabel().replace('-', '|'), (String) pcSettingsDefault.get(dfield.getName()));
                        }
                    }
                }
                
                System.debug('productCategory: ' + productCategory);
                
                List<Perfect_Experience_Score__c> peScores = new List<Perfect_Experience_Score__c>([Select Id, Name, Category_Score__c, Category__c
                                                                                                    FROM Perfect_Experience_Score__c
                                                                                                    WHERE Category__c IN :productCategory.values()]);
                
                System.debug('peScores: ' + peScores);
                for (String pcVal : productCategory.values()) {
                    System.debug('pcVal: ' + pcVal);
                    for (Perfect_Experience_Score__c pScore : peScores) {
                      System.debug('pScore: ' + pScore.Category__c);
                      if (pScore.Category__c == pcVal) {
                          pScoreMap.put(pcVal, pScore.Category_Score__c);
                      } 
                    }
                }
                
                System.debug('pScoreMap: ' + pScoreMap);
                String categorySubSubTempM;
                String categorySubTempM;
                Decimal cScoreM = 100;
                String categorySubSubTempSP;
                String categorySubTempSP;
                Decimal cScoreSP = 100;
                String categorySubSubTempICoffee;
                String categorySubTempICoffee;
               	String categorySubSubTempITea;
                String categorySubTempITea;
                Decimal cScoreI = 100;
                String categorySubSubTempS;
                String categorySubTempS; 
                Decimal cScoreS = 100;
                String categorySubSubTempMS;
                String categorySubTempMS;
                Decimal cScoreMSM = 100;
                Decimal cScoreMSS = 100;
                Decimal cScoreMSC = 100;
                Decimal cScoreMSCups = 100;
                Decimal cScoreMSTA = 100;
                for (Apttus__APTS_Agreement__c agreement : agreeList) {
                    for (Apttus__AgreementLineItem__c agreementLineItem : agreementLineItemList) {
                        System.debug('agreementLineItem: ' + agreementLineItem);
                        System.debug('agreement.Id: ' + agreement.Id);
                        System.debug('agreementLineItem.Apttus__AgreementId__c: ' + agreementLineItem.Apttus__AgreementId__c);
                        System.debug('agreementLineItem.Apttus_CMConfig__ClassificationHierarchy__c:' + agreementLineItem.Apttus_CMConfig__ClassificationHierarchy__c);
                        if (agreementLineItem != Null) {
                            if (agreementLineItem.Apttus__AgreementId__c == agreement.Id) {
                                if (agreementLineItem.Apttus_CMConfig__ClassificationHierarchy__c != Null) {
                                    String categorySubSub = agreementLineItem.Apttus_CMConfig__ClassificationHierarchy__c.substringBeforeLast('|');
                                    System.debug('categorySubSub: ' + categorySubSub);
                                    String categorySub = categorySubSub.substringBeforeLast(' |');
                                    System.debug('categorySub: ' + categorySub);
                                    System.debug('pScoreMap.get(productCategory.get(categorySub)): ' + pScoreMap.get(productCategory.get(categorySub)));
                                    System.debug('pScoreMap.get(productCategory.get(agreementLineItem.Apttus_CMConfig__ClassificationHierarchy__c)): ' + pScoreMap.get(productCategory.get(agreementLineItem.Apttus_CMConfig__ClassificationHierarchy__c)));
                                    String categoryingBundle = agreementLineItem.Apttus_CMConfig__ClassificationHierarchy__c.substringBefore(' |');
                                    System.debug('categoryingBundle: ' + categoryingBundle);
                                     
                                     if (agreementLineItem.APTS_Machine_Bundle__c == true && pScoreMap.get(productCategory.get(categorySub)) < cScoreM) {
                                         tempMachineBundle = new Apttus__AgreementLineItem__c();
                                         tempMachineBundle = agreementLineItem;
                                         categorySubSubTempM = tempMachineBundle.Apttus_CMConfig__ClassificationHierarchy__c.substringBeforeLast('|');
                                         categorySubTempM = categorySubSubTempM.substringBeforeLast(' |');
                                         cScoreM = pScoreMap.get(productCategory.get(categorySubTempM));
                                         System.debug('Score:' + pScoreMap.get(productCategory.get(categorySubTempM)));
                                         machineBundleMap.put(agreement.Id, tempMachineBundle);
                                     }
                                     
                                     if (agreementLineItem.APTS_Service_Product__c == true && pScoreMap.get(productCategory.get(categorySub)) < cScoreSP) {
                                         tempserviceProduct = new Apttus__AgreementLineItem__c();
                                         tempserviceProduct = agreementLineItem;  
                                         categorySubSubTempSP = tempserviceProduct.Apttus_CMConfig__ClassificationHierarchy__c.substringBeforeLast('|');
                                         categorySubTempSP = categorySubSubTempSP.substringBeforeLast(' |');
                                         cScoreSP = pScoreMap.get(productCategory.get(categorySubTempSP));
                                         System.debug('Score:' + pScoreMap.get(productCategory.get(categorySubTempSP)));
                                         serviceProductMap.put(agreement.Id, tempserviceProduct);
                                     }
                                     
                                     if ((agreementLineItem.APTS_Bundle_Option__c == true && pScoreMap.get(productCategory.get(labelValueMap.get(agreementLineItem.APTS_Ingredient_Option_Product_Family__c))) < cScoreI) || (agreementLineItem.APTS_Ingredient_Standalone__c == true && pScoreMap.get(productCategory.get(categorySub)) < cScoreI) && categoryingBundle == 'Coffee') {
                                         tempingredientCoffee = new Apttus__AgreementLineItem__c();
                                         tempingredientCoffee = agreementLineItem;
                                         if (agreementLineItem.APTS_Ingredient_Standalone__c == true) {
                                            categorySubSubTempICoffee = tempingredientCoffee.Apttus_CMConfig__ClassificationHierarchy__c.substringBeforeLast('|'); 
                                         } else {
                                            categorySubSubTempICoffee = tempingredientCoffee.APTS_Ingredient_Option_Product_Family__c.substringBeforeLast('|'); 
                                         }
                                         categorySubTempICoffee = categorySubSubTempICoffee.substringBeforeLast(' |');
                                         cScoreI = pScoreMap.get(productCategory.get(categorySubTempICoffee));
                                         System.debug('Score:' + pScoreMap.get(productCategory.get(categorySubTempICoffee)));
                                         ingredientsCoffee.put(agreement.Id, tempingredientCoffee);
                                          
                                     }
                                     
                                     if ((agreementLineItem.APTS_Bundle_Option__c == true && pScoreMap.get(productCategory.get(labelValueMap.get(agreementLineItem.APTS_Ingredient_Option_Product_Family__c))) < cScoreI) || (agreementLineItem.APTS_Ingredient_Standalone__c == true && pScoreMap.get(productCategory.get(agreementLineItem.Apttus_CMConfig__ClassificationHierarchy__c)) < cScoreI) && categoryingBundle == 'Tea') {
                                         tempingredientTea = new Apttus__AgreementLineItem__c();
                                         tempingredientTea = agreementLineItem;
                                          if (agreementLineItem.APTS_Ingredient_Standalone__c == true) {
                                            categorySubSubTempITea = tempingredientTea.Apttus_CMConfig__ClassificationHierarchy__c; 
                                            cScoreI = pScoreMap.get(productCategory.get(categorySubSubTempITea));
                                         } else {
                                            categorySubSubTempITea = tempingredientTea.APTS_Ingredient_Option_Product_Family__c.substringBeforeLast('|'); 
                                            categorySubTempITea = categorySubSubTempITea.substringBeforeLast(' |');
                                            cScoreI = pScoreMap.get(productCategory.get(categorySubTempITea));
                                         }
                                         
                                         System.debug('Score:' + cScoreI);
                                         ingredientsTea.put(agreement.Id, tempingredientTea);
                                          
                                     }
                                     
                                     if (agreementLineItem.APTS_Services_Standalone__c == true && pScoreMap.get(productCategory.get(categorySub)) < cScoreS){
                                         tempserviceStandalone = new Apttus__AgreementLineItem__c();
                                         tempserviceStandalone = agreementLineItem;
                                         categorySubSubTempS = tempserviceStandalone.Apttus_CMConfig__ClassificationHierarchy__c.substringBeforeLast('|');
                                         categorySubTempS = categorySubSubTempS.substringBeforeLast(' |');
                                         cScoreS =  pScoreMap.get(productCategory.get(categorySubTempS));
                                         System.debug('Score:' + pScoreMap.get(productCategory.get(categorySubTempS)));
                                         serviceStandalone.put(agreement.Id, tempserviceStandalone); 
                                     }
                                     
                                     if (agreementLineItem.APTS_More_Standalone__c == true && pScoreMap.get(productCategory.get(categorySub)) < cScoreMSM && productCategory.get(categorySub).contains('Milk')) {
                                         tempmoreStandaloneMilk = new Apttus__AgreementLineItem__c();
                                         tempmoreStandaloneMilk = agreementLineItem;
                                         categorySubSubTempMS = tempmoreStandaloneMilk.Apttus_CMConfig__ClassificationHierarchy__c.substringBeforeLast('|');
                                         categorySubTempMS = categorySubSubTempMS.substringBeforeLast(' |');
                                         cScoreMSM = pScoreMap.get(productCategory.get(categorySubTempMS));
                                         System.debug('Score:' + pScoreMap.get(productCategory.get(categorySubTempMS)));
                                         moreStandaloneMilk.put(agreement.Id, tempmoreStandaloneMilk); 
                                     }
                                     
                                     if (agreementLineItem.APTS_More_Standalone__c == true && pScoreMap.get(productCategory.get(categorySub)) < cScoreMSS && productCategory.get(categorySub).contains('Sugar')) {
                                         tempmoreStandaloneSugar = new Apttus__AgreementLineItem__c();
                                         tempmoreStandaloneSugar = agreementLineItem;
                                         categorySubSubTempMS = tempmoreStandaloneSugar.Apttus_CMConfig__ClassificationHierarchy__c.substringBeforeLast('|');
                                         categorySubTempMS = categorySubSubTempMS.substringBeforeLast(' |');
                                         cScoreMSS = pScoreMap.get(productCategory.get(categorySubTempMS));
                                         System.debug('Score:' + pScoreMap.get(productCategory.get(categorySubTempMS)));
                                         moreStandaloneSugar.put(agreement.Id, tempmoreStandaloneSugar); 
                                     }
                                     
                                     if (agreementLineItem.APTS_More_Standalone__c == true && pScoreMap.get(productCategory.get(categorySub)) < cScoreMSC && productCategory.get(categorySub).contains('Cacao')) {
                                         tempmoreStandaloneCacao = new Apttus__AgreementLineItem__c();
                                         tempmoreStandaloneCacao = agreementLineItem;
                                         categorySubSubTempMS = tempmoreStandaloneCacao.Apttus_CMConfig__ClassificationHierarchy__c.substringBeforeLast('|');
                                         categorySubTempMS = categorySubSubTempMS.substringBeforeLast(' |');
                                         cScoreMSC = pScoreMap.get(productCategory.get(categorySubTempMS));
                                         System.debug('Score:' + pScoreMap.get(productCategory.get(categorySubTempMS)));
                                         moreStandaloneCacao.put(agreement.Id, tempmoreStandaloneCacao); 
                                     }
                                     
                                     if (agreementLineItem.APTS_More_Standalone__c == true && pScoreMap.get(productCategory.get(categorySub)) < cScoreMSCups && (productCategory.get(categorySub).contains('Cups') || productCategory.get(categorySub).contains('Glasses & Porcelain'))) {
                                         tempmoreStandaloneCGP = new Apttus__AgreementLineItem__c();
                                         tempmoreStandaloneCGP = agreementLineItem;
                                         categorySubSubTempMS = tempmoreStandaloneCGP.Apttus_CMConfig__ClassificationHierarchy__c.substringBeforeLast('|');
                                         categorySubTempMS = categorySubSubTempMS.substringBeforeLast(' |');
                                         cScoreMSCups = pScoreMap.get(productCategory.get(categorySubTempMS));
                                         System.debug('Score:' + pScoreMap.get(productCategory.get(categorySubTempMS)));
                                         moreStandaloneCGP.put(agreement.Id, tempmoreStandaloneCGP); 
                                     }
                                     
                                     if (agreementLineItem.APTS_More_Standalone__c == true && pScoreMap.get(productCategory.get(categorySub)) < cScoreMSTA && (productCategory.get(categorySub).contains('Tea display') || productCategory.get(categorySub).contains('Accessoires'))) {
                                         tempmoreStandaloneTDA = new Apttus__AgreementLineItem__c();
                                         tempmoreStandaloneTDA = agreementLineItem;
                                         categorySubSubTempMS = tempmoreStandaloneTDA.Apttus_CMConfig__ClassificationHierarchy__c.substringBeforeLast('|');
                                         categorySubTempMS = categorySubSubTempMS.substringBeforeLast(' |');
                                         cScoreMSTA = pScoreMap.get(productCategory.get(categorySubTempMS));
                                         System.debug('Score:' + pScoreMap.get(productCategory.get(categorySubTempMS)));
                                         moreStandaloneTDA.put(agreement.Id, tempmoreStandaloneTDA); 
                                     }
                                     
                                      system.debug('machineBundleMap: ' + machineBundleMap.values());
                                      system.debug('serviceProductMap: ' + serviceProductMap.values());
                                      system.debug('ingredientsCoffee: ' + ingredientsCoffee.values());
                                      system.debug('ingredientsTea: ' + ingredientsTea.values());
                                      system.debug('moreStandalone Milk: ' + moreStandaloneMilk.values());
                                      system.debug('moreStandalone Sugar: ' + moreStandaloneSugar.values());
                                      system.debug('moreStandalone Cacao: ' + moreStandaloneCacao.values());
                                      system.debug('moreStandalone CGP: ' + moreStandaloneCGP.values());
                                      system.debug('serviceStandalone TDA: ' + moreStandaloneTDA.values());
                                     
                                     aliPESurvey.Account__c = agreement.APTS_Sold_To__c;
                                     aliPESurvey.Agreement_Based_Survey__c = true;
                                     aliPESurvey.Visit_Date__c = agreement.Apttus__Contract_Start_Date__c;
                                     aliPESurvey.IsActive__c = true;
                                     aliPESurvey.Comm_Non_Comm__c = 'Non Commercial';
                                     
                                     if (!machineBundleMap.isEmpty()) {
                                        for (Apttus__AgreementLineItem__c assetlineitem : machineBundleMap.values()) {
                                            String categorySubSubingBundle = assetlineitem.Apttus_CMConfig__ClassificationHierarchy__c.substringBeforeLast('|');
                                            System.debug('categorySubSubingBundle: ' + categorySubSubingBundle);
                                            String categorySubingBundle = categorySubSubingBundle.substringBeforeLast(' |');
                                            System.debug('categorySubingBundle: ' + categorySubingBundle);
                                            System.debug('assetlineitem.Apttus_CMConfig__ClassificationHierarchy__c.contains(Coffee Kitchen): ' + assetlineitem.Apttus_CMConfig__ClassificationHierarchy__c.contains('Coffee Kitchen'));
                                            if (assetlineitem.Apttus_CMConfig__ClassificationHierarchy__c.contains('Coffee Kitchen')) {
                                              aliPESurvey.Barista_Station__c = 'Yes';
                                            } else {
                                              aliPESurvey.Machine__c = 'Machine Yes'; 
                                            }
                                            
                                            if (assetlineitem.Apttus_CMConfig__ClassificationHierarchy__c.contains('Cabinets')) {
                                              aliPESurvey.Display_Accessoires__c = productCategory.get(categorySubingBundle);
                                            }
                                        }
                                    } else {
                                        aliPESurvey.Machine__c = 'Machine No';
                                    }
                                    
                                    if (!serviceProductMap.isEmpty()) {
                                        System.debug('ServiceProductMap');
                                        for (Apttus__AgreementLineItem__c assetlineitems : serviceProductMap.values()) {
                                           aliPESurvey.Service_Training__c = 'Service Yes';
                                        }
                                    } 
                                    
                                    if (!serviceStandalone.isEmpty()) {
                                        System.debug('serviceStandalone');
                                        for (Apttus__AgreementLineItem__c assetlineitems : serviceStandalone.values()) {
                                          aliPESurvey.Service_Training__c = 'Service Yes';
                                        }
                                    }
                                    
                                    if (serviceProductMap.isEmpty() && serviceStandalone.isEmpty()) {
                                        aliPESurvey.Service_Training__c = 'Service No';
                                    }
                                    
                                    if (!ingredientsCoffee.isEmpty()) {
                                        System.debug('ingredients Coffee');
                                        for (Apttus__AgreementLineItem__c assetlineitem : ingredientsCoffee.values()) {
                                            String categorySubSubingBundle = assetlineitem.Apttus_CMConfig__ClassificationHierarchy__c.substringBeforeLast('|');
                                            System.debug('categorySubSubingBundle: ' + categorySubSubingBundle);
                                            String categorySubingBundle = categorySubSubingBundle.substringBeforeLast(' |');
                                            System.debug('categorySubingBundle: ' + categorySubingBundle);
                                            aliPESurvey.Coffee__c = productCategory.get(categorySubingBundle);   
                                        }
                                    }
                                    
                                    if (!ingredientsTea.isEmpty()) {
                                        System.debug('ingredients Tea');
                                        for (Apttus__AgreementLineItem__c assetlineitem : ingredientsTea.values()) {
                                            // String categorySubSubingBundle = assetlineitem.Apttus_CMConfig__ClassificationHierarchy__c.substringBeforeLast('|');
                                            // System.debug('categorySubSubingBundle: ' + categorySubSubingBundle);
                                            String categorySubingBundle = assetlineitem.Apttus_CMConfig__ClassificationHierarchy__c.substringBeforeLast(' |');
                                            System.debug('categorySubingBundle: ' + categorySubingBundle);
                                            aliPESurvey.Tea__c = productCategory.get(assetlineitem.Apttus_CMConfig__ClassificationHierarchy__c);
                                        }
                                    }
                                    
                                    if (!moreStandaloneMilk.isEmpty()) {
                                        System.debug('Milk');
                                        for (Apttus__AgreementLineItem__c assetlineitem : moreStandaloneMilk.values()) {
                                            String categorySubSubingBundle = assetlineitem.Apttus_CMConfig__ClassificationHierarchy__c.substringBeforeLast('|');
                                            System.debug('categorySubSubingBundle: ' + categorySubSubingBundle);
                                            String categorySubingBundle = categorySubSubingBundle.substringBeforeLast(' |');
                                            System.debug('categorySubingBundle: ' + categorySubingBundle);
                                            aliPESurvey.Milk__c = productCategory.get(categorySubingBundle);
                                        }
                                    } else {
                                        aliPESurvey.Milk__c = 'Milk No';
                                    }
                                    
                                    if (!moreStandaloneSugar.isEmpty()) {
                                        System.debug('ingredients Tea');
                                        for (Apttus__AgreementLineItem__c assetlineitem : moreStandaloneSugar.values()) {
                                            String categorySubSubingBundle = assetlineitem.Apttus_CMConfig__ClassificationHierarchy__c.substringBeforeLast('|');
                                            System.debug('categorySubSubingBundle: ' + categorySubSubingBundle);
                                            String categorySubingBundle = categorySubSubingBundle.substringBeforeLast(' |');
                                            System.debug('categorySubingBundle: ' + categorySubingBundle);
                                            aliPESurvey.Sugar__c = productCategory.get(categorySubingBundle);
                                        }
                                    } else {
                                        aliPESurvey.Sugar__c = 'Sugar No';
                                    }
                                    
                                    if (!moreStandaloneCacao.isEmpty()) {
                                        System.debug('ingredients Cacao');
                                        for (Apttus__AgreementLineItem__c assetlineitem : moreStandaloneCacao.values()) {
                                            String categorySubSubingBundle = assetlineitem.Apttus_CMConfig__ClassificationHierarchy__c.substringBeforeLast('|');
                                            System.debug('categorySubSubingBundle: ' + categorySubSubingBundle);
                                            String categorySubingBundle = categorySubSubingBundle.substringBeforeLast(' |');
                                            System.debug('categorySubingBundle: ' + categorySubingBundle);
                                            aliPESurvey.Cacao__c = productCategory.get(categorySubingBundle);
                                        }
                                    } else {
                                        aliPESurvey.Cacao__c = 'Cacao No';
                                    }
                                    
                                    if (!moreStandaloneCGP.isEmpty()) {
                                        System.debug('ingredients CGP');
                                        for (Apttus__AgreementLineItem__c assetlineitem : moreStandaloneCGP.values()) {
                                            String categorySubSubingBundle = assetlineitem.Apttus_CMConfig__ClassificationHierarchy__c.substringBeforeLast('|');
                                            System.debug('categorySubSubingBundle: ' + categorySubSubingBundle);
                                            String categorySubingBundle = categorySubSubingBundle.substringBeforeLast(' |');
                                            System.debug('categorySubingBundle: ' + categorySubingBundle);
                                            aliPESurvey.Cups_Glasses_Porcelain__c = productCategory.get(categorySubingBundle);
                                        }
                                    } else {
                                        aliPESurvey.Cups_Glasses_Porcelain__c = 'Cups / Glasses & Porcelain No';
                                    }
                                    
                                    if (!moreStandaloneTDA.isEmpty()) {
                                        System.debug('ingredients TDA');
                                        for (Apttus__AgreementLineItem__c assetlineitem : moreStandaloneTDA.values()) {
                                            String categorySubSubingBundle = assetlineitem.Apttus_CMConfig__ClassificationHierarchy__c.substringBeforeLast('|');
                                            System.debug('categorySubSubingBundle: ' + categorySubSubingBundle);
                                            String categorySubingBundle = categorySubSubingBundle.substringBeforeLast(' |'); 
                                            System.debug('categorySubingBundle: ' + categorySubingBundle);
                                            aliPESurvey.Display_Accessoires__c = productCategory.get(categorySubingBundle);
                                        }
                                    } 
                                    
                                    if (acctIdSet.add(agreement.APTS_Sold_To__c)) {
                                        aliPESurveyList.add(aliPESurvey);
                                        System.debug('aliPESurveyList: ' + aliPESurveyList);
                                    }
                                }
                            }
                        }
                    }
                }
                
                
                if (!aliPESurveyList.isEmpty()) {
                    insert aliPESurveyList;
                    
                    List<Account> acctRecList = new List<Account>();    
                    Set<Id> acctIdinPE = new Set<Id>();
                    for (Perfect_Experience_Survey__c pe : aliPESurveyList) {
                      acctIdinPE.add(pe.Account__c);
                    }
                    acctRecList = [Select Id, Agreement_Based_Survey_Created__c
                                   FROM Account
                                   WHERE Id IN : acctIdinPE];
                    
                    for (Account acctRec : acctRecList) {
                      acctRec.Agreement_Based_Survey_Created__c = true;
                      accountToUpdate.add(acctRec);
                    }
                    
                    if (!accountToUpdate.isEmpty()) {
                        update accountToUpdate;
                    }
               
                }
           }
       }
    }
}