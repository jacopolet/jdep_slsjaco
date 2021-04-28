import { LightningElement, wire, api, track } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
//Method calls
import getOptionLines from '@salesforce/apex/APTS_AddRemoveOptionController.getRecsForModifyOptionAction';
import getOptionGroups from '@salesforce/apex/APTS_AddRemoveOptionController.getOptionGroupRecs';
import getRelatedOptions from '@salesforce/apex/APTS_AddRemoveOptionController.getOptions';
import determineOptionPrice from '@salesforce/apex/APTS_AddRemoveOptionController.determinePriceOfOptions';
import getRelatedAttributes from '@salesforce/apex/APTS_AddRemoveOptionController.getRelatedAttributes';
import getDefaultAttributesForBundle from '@salesforce/apex/APTS_AddRemoveOptionController.getDefaultAttributesForBundle';
//Labels
import RequiriedAttributeErrorMesssage from '@salesforce/label/c.APTS_NewUXRequiredAttributeErrorMessage';
import BPODiscountWarningMessage from '@salesforce/label/c.APTS_NewUXBPODiscountWarningMessage';
import StartDateGreaterEndDateErrorMessage from '@salesforce/label/c.APTS_NewUXStartDateIsGreaterEndDate';
import StartDateContStartdateErrorMessage from '@salesforce/label/c.APTS_NewUXStartDateIsLesContStartDate';
import EndDateAssetEndDateErrorMessage from '@salesforce/label/c.APTS_NewUXEndDateGreaterAssetEndDate';
import EndDateLessStartDateErrorMessage from '@salesforce/label/c.APTS_NewUXEndDateGreaterStartDate';
import BPOZeroNotAllowedMessage from '@salesforce/label/c.APTS_ModifyDiscountBPO';
import NetUnitPriceLessThanDiscAmt from '@salesforce/label/c.APTS_NewUXNetUnitPriceLessThanDiscAmt';
import EndDateLessThanNextReadyForInvDate from '@salesforce/label/c.APTS_NewUXEndDateLessThanNRID';
import EndDateGreaterThanTodayWarningMessage from '@salesforce/label/c.APTS_ABOWarningEndDateGrtThanToday';
import RemoveDummyMachineProductWarningMessage from '@salesforce/label/c.APTS_NewUXRemoveDummyMachineProduct';

import { refreshApex } from '@salesforce/apex';


const columns = [        
    { label: 'Option Group Name', fieldName: 'optionGroupText', type: 'text',cellAttributes:{class:{fieldName: 'modifiedLineItem'}}},
    { label: 'Asset Name',fieldName: 'assetName',type: 'text',cellAttributes:{class:{fieldName: 'modifiedLineItem'}}},
    { label: 'Charge Type', fieldName: 'chargeType', type: 'text',cellAttributes:{class:{fieldName: 'modifiedLineItem'}}} , 
    { label: 'Auto Renew', fieldName: 'autoRenew', type: 'Boolean',cellAttributes:{class:{fieldName: 'modifiedLineItem'}}} ,
    { label: 'Billing Frequency', fieldName: 'billingFrequency', type: 'text',cellAttributes:{class:{fieldName: 'modifiedLineItem'}}}, 
    { label: 'Original Start Date', fieldName: 'originalStartDate', type: 'date',cellAttributes:{class:{fieldName: 'modifiedLineItem'}}} ,   
    { label: 'Start Date', fieldName: 'startDate', type: 'date',cellAttributes:{class:{fieldName: 'modifiedLineItem'}}} ,
    { label: 'End Date', fieldName: 'endDate', type: 'date',cellAttributes:{class:{fieldName: 'modifiedLineItem'}}},
    { label: 'Selling Term', fieldName: 'sellingTerm', type: 'number',cellAttributes:{class:{fieldName: 'modifiedLineItem'}}},
    { label: 'Next Ready for Invoice Date', fieldName: 'nextInvoiceDate', type: 'date',cellAttributes:{class:{fieldName: 'modifiedLineItem'}}}, 
    { label: 'Base Price', fieldName: 'basePrice', type: 'number',cellAttributes:{class:{fieldName: 'modifiedLineItem'}}},
    { label: 'Base Price (Override)', fieldName: 'basePriceOverride', type: 'number',cellAttributes:{class:{fieldName: 'modifiedLineItem'}}},
    { label: 'Sub Type', fieldName: 'subType', type: 'String',cellAttributes:{class:{fieldName: 'modifiedLineItem'}}},
    { label: 'Discount %', fieldName: 'discountPercentage', type: 'number',cellAttributes:{class:{fieldName: 'modifiedLineItem'}}},
    { label: 'Discount Amount', fieldName: 'discountAmount', type: 'number',cellAttributes:{class:{fieldName: 'modifiedLineItem'}}},
    { label: 'Net Unit Price', fieldName: 'netUnitPrice', type: 'number',cellAttributes:{class:{fieldName: 'modifiedLineItem'}}},
    { label: 'Line status', fieldName: 'linestatus', type: 'text',cellAttributes:{class:{fieldName: 'modifiedLineItem'}}},      
]; 


export default class AptsModifyOptions extends LightningElement {
    @track columns = columns;
    @api bundleAssetId;
    allRecords;
    isLoaded;
    @track isOptionAdded;
    initalRecords;
    selectedAssetOptions;
    cascadeButtonLabel;
    //INPUT
    showOptionGroup;
    showRelatedOptions;
    selectedAction;
    selectedOptionGroup;
    selectedOptionGroupLabel;
    selectedOptions;
    selectedOptionLabel;
    selectedBasePriceOverride;
    selectedAutoRenew;
    checkedOptionValue;
    showAddButton;
    showRemoveButton;
    showStartDate;
    showEndDate;
    startDateValue;
    endDateValue;
    displayAllOptionGroups;
    displayAllOptions;
    hasAttributes;
    relatedAttributes;
    bundleAttributes;
    showAutoRenew;
    showBasePriceOverride;
    showBasePrice;
    modifiedbundleAttributes;
    hasBundleAttributes;
    optionGroupValue;
    oldRelatedAttributes;
    basePriceValue;
    billingFrequencyValue;
    //Table
    showTable;
    showAddTable;
    selectedAssetOptions;
    showDiscountType;
    selectedDiscountType;
    showDiscountAmt;
    selectedDiscountAmt;
    newlyAddedOptionClass= 'slds-is-edited slds-text-color_success customFontChanged';
    cancelledOptionClass= 'slds-is-edited slds-text-color_destructive customFontChanged';
    amendedOptionClass= 'slds-is-edited slds-text-color_weak customFontChanged';
    @track notification = {};
    updatedAssetOptionMap = new Map();
    label = {RequiriedAttributeErrorMesssage,BPODiscountWarningMessage,StartDateGreaterEndDateErrorMessage,StartDateContStartdateErrorMessage,EndDateAssetEndDateErrorMessage,EndDateLessStartDateErrorMessage,BPOZeroNotAllowedMessage,NetUnitPriceLessThanDiscAmt,EndDateLessThanNextReadyForInvDate,EndDateGreaterThanTodayWarningMessage,RemoveDummyMachineProductWarningMessage};
    @wire(getOptionLines, { bundelHeaderId: '$bundleAssetId' })
    wiredAssets({ error, data }) {
        this.isLoaded = false; 
        this.trackOneTimeChange=false;
        this.isOptionAdded=true;
        //console.log('this.assetid==BEFORE==>'+this.bundleAssetId);
        if(data){                
            let recs = []; 
            this.initalRecords = new Map();        
            for(let i=0; i<data.length; i++){
                let asset = {};
                asset.rowNumber = ''+(i+1);
                asset.assetLink = '/'+data[i].assetid;
                asset = Object.assign(asset, data[i]);    
                this.initalRecords.set(asset.assetid, data[i]);         
                recs.push(asset);
            }                          
            this.allRecords = recs;
            // dispaly table only if there is any records        
            this.populateAttributes();                         
        }else{
            this.error = error;
        }
    }

    get actionOptions() {
        return [
            //{ label: 'Update bundle attributes', value: 'UpdateBundleAttributes'},
            { label: 'Add an Option', value: 'addOption' },
            { label: 'Remove an Option', value: 'removeOption'}
        ];
    }
    handleOptionGroup(event){
        this.showAddButton=false;
        this.showRemoveButton=false;
        this.showOptionGroup=false;
        this.showRelatedOptions=false;
        this.showStartDate=false;
        this.showEndDate=false;
        this.selectedAction = event.target.value;
        this.hasAttributes=false;
        //console.log(this.selectedAction);
        if(this.selectedAction=='addOption'){
            this.showOptionGroup=true;
            this.showTable=false;
            this.showAddTable=true;
            this.showAutoRenew=false;
            this.showBillingFrequency=false;
            this.showBasePriceOverride=false;
            this.showBasePrice=false;
            this.showDiscountType=false;
            this.showDiscountAmt=false;
            this.populateOptionGroup();
        }
        else if(this.selectedAction=='removeOption'){
            this.showTable=true;
            this.showAddTable=false;
            this.showAutoRenew=false;
            this.showBillingFrequency=false;
            this.showBasePriceOverride=false;
            this.showBasePrice=false;
            this.showDiscountType=false;
            this.showDiscountAmt=false;
            this.selectedDiscountType=undefined;
            this.selectedDiscountAmt=undefined;
        }
        /*else if(this.selectedAction=='UpdateBundleAttributes'){
            this.showTable=false;
            this.showAddTable=false;
            this.hasAttributes=true;
            this.populateAttributes();
        }*/
    }
    populateAttributes(){
        //console.log('BUNDLE ASSSET ID =====>  '+this.bundleAssetId);
        if(this.bundleAssetId){
            getDefaultAttributesForBundle( {bundelAssetId: this.bundleAssetId} )
            .then((data) => {
                if(data){
                    //console.log('BUNDLE==ATTRIBUTES==>'+JSON.stringify(data));
                    //console.log('BUNDLE==ATTRIBUTES==>'+data.length);
                    if(data.length && data.length>0){
                        this.hasBundleAttributes=true;
                        this.bundleAttributes=data;
                        this.modifiedbundleAttributes=data;
                    } else{
                        this.hasBundleAttributes=false;
                    }
                }
            });
        }
        this.isLoaded = true;
        //console.log('BUNDLE relatedAttributes=========>'+this.bundleAttributes);
    }
    populateOptionGroup(){
        console.log('Bundle Attributes OGS====>'+JSON.stringify(this.bundleAttributes));
        getOptionGroups( {bundelHeaderId: this.bundleAssetId,allTableRecords: this.allRecords,bundleAttributes: JSON.stringify(this.bundleAttributes)} )
        .then((data) => {
            if(data){
                //console.log('this.assetid====>'+this.bundleAssetId);
                //console.log('OG data==LEN==>'+data.length); 
                let recs = [];
                for(const list of data){ 
                    //console.log('list===>'+JSON.stringify(list));
                    const option = {
                        label: list.Apttus_Config2__ProductOptionGroupId__r.Apttus_Config2__OptionGroupId__r.Name,
                        value: list.Apttus_Config2__ProductOptionGroupId__r.Apttus_Config2__OptionGroupId__c};
                    //console.log('option===>'+option);
                    //this.selectOptions.push(option);
                    recs.push(option);
                }
                this.displayAllOptionGroups=recs;
            }else{
                this.error = error;
            } 
          
        });
    }
    handleOptions(event){
        this.showAddButton=false;
        this.showRemoveButton=false;
        this.showEndDate=false;
        this.hasAttributes=false;
        this.selectedOptionGroup = event.target.value;
        this.selectedOptionGroupLabel=event.target.options.find(opt => opt.value === event.detail.value).label;
        //console.log(this.selectedOptionGroup);
        this.showRelatedOptions=true;
        this.populateOptions();
        this.showStartDate=false;
        this.showAutoRenew=false;
        this.showBillingFrequency=false;
        this.showBasePriceOverride=false;
        this.showBasePrice=false;
        this.showDiscountAmt=false;
        this.showDiscountType=false;
        this.billingFrequencyValue=undefined;
        this.basePriceValue=undefined;
    }

    populateOptions(){
        getRelatedOptions( {bundelHeaderId: this.bundleAssetId,optionGroupId : this.selectedOptionGroup,allTableRecords : this.allRecords,bundleAttributes: this.bundleAttributes} )
        .then((data) => {
            if(data){
                //console.log('$$this.assetid==OP==>'+this.bundleAssetId);
                //console.log('$$this.selectedOptionGroup==>'+this.selectedOptionGroup);
                //console.log('$$OG data==LEN=OP=>'+data.length); 
                let recs = [];
                for(const list of data){ 
                   // console.log('$$list=OP==>'+JSON.stringify(list));
                    const option = {
                        label: list.Apttus_Config2__ComponentProductId__r.Name,
                        value: list.Apttus_Config2__ComponentProductId__c};
                    //console.log('$$option=OP==>'+option);
                    //this.selectOptions.push(option);
                    recs.push(option);
                }
                this.displayAllOptions=recs;
            }else{
                this.error = error;
            } 
          
        });
    }
    handleDatesChange(event){
        console.log('Date=====>'+event.target.value);
        this.showAddButton=false;
        this.showRemoveButton=false;
        this.showBasePrice=false;
        if(this.selectedAction=='addOption' && event.target.value){
            this.startDateValue = event.target.value;
            this.showAutoRenew=true;
            this.showBillingFrequency=true;
            this.showBasePriceOverride=true;
            this.showBasePrice=true;
            this.showDiscountType=true;
            this.basePriceValue=undefined;
            this.billingFrequencyValue=undefined;
            this.showAddButton=true;
            console.log('BUNDLE ASSET ID==VALUE=======>'+this.bundleAssetId);
            console.log('OPTION PRODUCT==VALUE=======>'+this.selectedOptions);
            console.log('OPTION GROUP LABEL=======>'+this.selectedOptionLabel);
            console.log('START DATE VALUE=======>'+ this.startDateValue);
            console.log('ITS ATTRIBUTES=======>'+JSON.stringify(this.relatedAttributes));
            console.log('ITS BUNDLE ATTRIBUTES======>'+JSON.stringify(this.bundleAttributes));
            determineOptionPrice( {bundelHeaderId: this.bundleAssetId,optionProductId: this.selectedOptions,optionProductName: this.selectedOptionLabel,expectedStartDate : this.startDateValue,optionGroupName : this.selectedOptionGroupLabel,allTableRecords : this.allRecords,autoRenew: this.selectedAutoRenew,basePriceOverride: this.selectedBasePriceOverride,discountType :this.selectedDiscountType,discountValue : this.selectedDiscountAmt,billingFrequency : this.billingFrequencyValue,optionAttributes: this.relatedAttributes,bundleAttributes : this.bundleAttributes} )
            .then((data) => {
                for(let i=0; i<data.length; i++){
                    let asset = {};
                    asset.rowNumber = ''+(i+1);
                    asset = Object.assign(asset, data[i]);
                    console.log('asset==VALUE=======>'+JSON.stringify(asset));
                    if(asset.linestatus=='New' && asset.productid==this.selectedOptions){
                        console.log('this.basePriceValue===IN LOOP======>'+asset.basePrice);
                        console.log('this.billingFrequency===IN LOOP======>'+asset.billingFrequency);
                        this.basePriceValue=asset.basePrice;
                        this.billingFrequencyValue = asset.billingFrequency;
                    }
                }
            });
            console.log('this.billingFrequencyValue=========>'+this.billingFrequencyValue);
            console.log('this.basePriceValue=========>'+this.basePriceValue);
            this.showBasePrice=true;
        }
        else if(this.selectedAction=='removeOption' && event.target.value){
            this.endDateValue = event.target.value;
            this.showRemoveButton=true;
        }
    }
    handleDatesAndTable(event){
        //console.log('event.target.value========>'+event.target.value);
        //console.log('event.detail========>'+JSON.stringify(event.detail));
        this.selectedOptionLabel=event.target.options.find(opt => opt.value === event.detail.value).label;
        //this.showAddButton=false;
        this.showRemoveButton=false;
        this.selectedOptions=event.target.value;
        if(this.selectedAction=='addOption'){
            this.showEndDate=false;
            /*if(this.selectedOptions!=null && this.selectedOptions!='' && this.selectedOptions!=undefined){
                this.showBasePriceOverride=true;
            }else{
                this.showBasePriceOverride=false;
            }*/
            this.populateOptionAttributes();
           // console.log('relatedAttributes=========>'+this.relatedAttributes);
            this.startDateValue=undefined;
            this.showStartDate=true;
            this.showAutoRenew=false;
            this.showBillingFrequency=false;
            this.showBasePriceOverride=false;
            this.showBasePrice=false;
            this.showDiscountType=false;
            this.basePriceValue=undefined;
            this.billingFrequencyValue=undefined;
            this.selectedBasePriceOverride=undefined;
            this.showAddButton=false;
            determineOptionPrice( {bundelHeaderId: this.bundleAssetId,optionProductId: this.selectedOptions,optionProductName: this.selectedOptionLabel,expectedStartDate : this.startDateValue,optionGroupName : this.selectedOptionGroupLabel,allTableRecords : this.allRecords,autoRenew: this.selectedAutoRenew,basePriceOverride: this.selectedBasePriceOverride,discountType :this.selectedDiscountType,discountValue : this.selectedDiscountAmt,billingFrequency: this.billingFrequencyValue,optionAttributes: this.relatedAttributes,bundleAttributes : this.bundleAttributes} )
            .then((data) => {
                for(let i=0; i<data.length; i++){
                    let asset = {};
                    asset.rowNumber = ''+(i+1);
                    asset = Object.assign(asset, data[i]);
                    console.log('asset==VALUE=======>'+JSON.stringify(asset));
                    if(asset.linestatus=='New' && asset.productid==this.selectedOptions){
                        console.log('this.basePriceValue===IN LOOP======>'+asset.basePrice);
                        console.log('this.billingFrequency===IN LOOP======>'+asset.billingFrequency);
                        this.basePriceValue=asset.basePrice;
                        this.billingFrequencyValue = asset.billingFrequency;
                    }
                }
            });
        }
        else if(this.selectedAction=='removeOption'){
            this.showEndDate=true;
            this.showStartDate=false;
            this.showDiscountType=false;
            this.showDiscountAmt=false;
            this.relatedAttributes=undefined;
            this.basePriceValue=undefined;
            this.selectedBasePriceOverride=undefined;
        }
    }

    populateOptionAttributes(){
        getRelatedAttributes( {optionProductId: this.selectedOptions,optionGroupText : this.selectedOptionGroupLabel,bundleAttributes : this.bundleAttributes} )
        .then((data) => {
            if(data){
                //console.log('DATA LENGTH==ATTRIBUTES==>'+data.length);
                if(data.length && data.length>0){
                    this.hasAttributes=true;
                    this.relatedAttributes=data;
                    this.oldRelatedAttributes=this.relatedAttributes;
                } else{
                    this.hasAttributes=false;
                }
            }
        });
    }
    
    handleSelectedItem(event){
        var hasExistingLines;
        this.showEndDate = false;
        this.showRemoveButton=false;
        this.showDiscountType=false;
        this.showDiscountAmt=false;
        this.checkedOptionValue = event.detail;
        let selectedOptionlines = [];  
        console.log('selectedRows=====>'+JSON.stringify(this.checkedOptionValue));
        console.log('selectedRows==LEN===>'+this.checkedOptionValue.length);        
        if(this.checkedOptionValue!=undefined && this.checkedOptionValue!=null && this.checkedOptionValue.length > 0 && this.selectedAction=='removeOption'){
            //selectedOptionlines = this.checkedOptionValue;
            this.checkedOptionValue.forEach(option => {
                selectedOptionlines.push(option.productid);
            });
            console.log('selectedOptionlines===>'+selectedOptionlines); 
            this.allRecords.forEach(record => {
                if(record.linestatus!='New' && selectedOptionlines.includes(record.productid)){
                    console.log('record.linestatus===>'+record.linestatus);
                    console.log('selectedOptionlines===>'+selectedOptionlines);
                    hasExistingLines=true;
                }
            });
            console.log('hasExistingLines===>'+hasExistingLines);
            if(hasExistingLines){
                this.showEndDate = true;
            }else{
                this.showRemoveButton=true;
            }
            //this.endDateValue = null;
            //this.showRemoveButton=true;
        }
    }

    handleAdd(event){
        //console.log('WRAPPER VALUE IS : '+JSON.stringify(this.relatedAttributes));
        //console.log('this.selectedOptionLabel=======>'+ this.selectedOptionLabel)
        //console.log('this.selectedOptionGroupLabel=======>'+this.selectedOptionGroupLabel);
        //console.log('this.startDateValue=======>'+this.startDateValue);
        //Add an entry in the table 
        this.isOptionAdded=false;
        console.log('VALIDATE ===>'+this.validateCart());
        if(this.displayAllOptions!=null && this.displayAllOptions.length>0 && this.validateCart()){
            var invalidData;
            var includeFS='No';
            var wtsChangebyFilled;
            var dontHideDetails=false;
            var minOriginalStartDate;
            let recs = []; 
            recs = this.allRecords;  
            let newlyAddedOptions = []; 
            //console.log('this.assetid====>'+this.bundleAssetId);
            //console.log('this.BPO====>'+this.selectedBasePriceOverride);
            if(this.selectedBasePriceOverride==null || this.selectedBasePriceOverride==''){
                this.selectedBasePriceOverride=undefined;
            }

            if(this.bundleAttributes){
                this.bundleAttributes.forEach(bundleAttrib => {
                    console.log('bundleAttrib.fieldName===>'+bundleAttrib.attributeFieldName);
                    console.log('bundleAttrib.assignedValue===>'+bundleAttrib.assignedValue);
                    if(bundleAttrib.attributeFieldName=='APTS_Include_Free_Service__c' && bundleAttrib.assignedValue=='Yes'){
                        includeFS='Yes';
                    }
                    if(bundleAttrib.attributeFieldName=='APTS_WTS_Changed_By__c' && bundleAttrib.assignedValue != undefined){
                        wtsChangebyFilled = true;
                    }
                });
            }
            console.log('includeFS===>'+includeFS);
            determineOptionPrice( {bundelHeaderId: this.bundleAssetId,optionProductId: this.selectedOptions,optionProductName: this.selectedOptionLabel,expectedStartDate : this.startDateValue,optionGroupName : this.selectedOptionGroupLabel,allTableRecords : this.allRecords,autoRenew: this.selectedAutoRenew,basePriceOverride: this.selectedBasePriceOverride,discountType :this.selectedDiscountType,discountValue : this.selectedDiscountAmt,billingFrequency : this.billingFrequencyValue,optionAttributes: this.relatedAttributes,bundleAttributes : this.bundleAttributes} )
             .then((data) => {
                if(data){ 
                    //console.log('data=======>'+JSON.stringify(data));               
                    let recs = [];       
                    for(let i=0; i<data.length; i++){
                        let asset = {};
                        invalidData=false;
                        asset.rowNumber = ''+(i+1);
                        asset = Object.assign(asset, data[i]);
                        if(asset.linestatus=='New'){
                            asset.modifiedLineItem=this.newlyAddedOptionClass;
                            asset.assetid=null;
                            minOriginalStartDate = asset.originalStartDate;
                            asset.originalStartDate=asset.startDate;
                        } 
                        if(asset.linestatus=='Cancelled'){
                            asset.modifiedLineItem=this.cancelledOptionClass;
                        }
                        if(asset.linestatus=='Amended'){
                            asset.modifiedLineItem=this.amendedOptionClass;
                        }
                        if(asset.linestatus=='New' && asset.startDate>=asset.endDate){
                            this.showToast(false,this.label.StartDateGreaterEndDateErrorMessage,'error','pester');
                            invalidData=true;
                            dontHideDetails=true;
                        }
                        if(asset.linestatus=='New' && asset.startDate<minOriginalStartDate){
                            this.showToast(false,this.label.StartDateContStartdateErrorMessage,'error','pester');
                            invalidData=true;
                            dontHideDetails=true;
                        }
                        if(asset.linestatus=='New' && asset.netUnitPrice<0){
                            this.showToast(false,this.label.NetUnitPriceLessThanDiscAmt,'error','pester');
                            invalidData=true;
                            dontHideDetails=true;
                        }
                        if(asset.linestatus=='New' && asset.optionGroupText == 'Value Added Service' && !wtsChangebyFilled){
                            this.showToast(false,'Please fill in the WTS Changed by field before submitting the order.','warning','sticky');
                        }
                        console.log('INVALID FLAG====>'+invalidData);
                        //console.log('***********asset.rowNumber===>'+asset.rowNumber);
                        //console.log('***********asset.linestatus===>'+asset.linestatus);  
                        if(invalidData==false){       
                            recs.push(asset);
                        }
                    } 
                    console.log('recs====>'+JSON.stringify(recs));
                    console.log('dontHideDetails====>'+dontHideDetails);        
                    if(recs){                 
                        this.allRecords = recs;
                        if(dontHideDetails==false){
                            this.dispatchEvent(
                                new CustomEvent("changedbundleattributes", {
                                bubbles:true,
                                composed:true,
                                detail: this.bundleAttributes
                                })
                            );
                            this.dispatchEvent(
                                new CustomEvent("selectedassets", {
                                    bubbles:true,
                                    composed:true,
                                    detail: this.allRecords
                                })
                            );
                            this.template.querySelectorAll('lightning-combobox').forEach(each => {
                                console.log('each value =====>'+ each.name);
                                console.log('each value =====>'+ each.value);
                                if(each.name!='actionTypeCB'){
                                    each.value = '';
                                }
                            }); 
                            console.log('Reached here=====>');
                            this.template.querySelector('c-apts-lwc-datatable').handleTotalRecordsChange(this.allRecords);
                            // this.template.querySelector('c-apts-lwc-datatable').setRecordsToDisplay();
                            this.populateOptionGroup(); 
                            this.populateOptions();  
                            this.discountTypes;
                            this.showRelatedOptions=false;
                            this.showBasePriceOverride=false;
                            this.showAutoRenew=false;
                            this.showBillingFrequency=false;
                            this.showStartDate=false;
                            this.showAddButton=false;
                            this.hasAttributes=false;
                            this.showDiscountType=false;
                            this.showDiscountAmt=false;
                            this.selectedAutoRenew=undefined;
                            this.selectedDiscountAmt=undefined;
                            this.selectedDiscountType=undefined;
                            this.selectedBasePriceOverride=undefined;
                            this.selectedOptionLabel=undefined;
                            this.showBasePrice=false;
                            this.basePriceValue=undefined;
                        }
                    }
                    //console.log('***********this.allRecords===>'+JSON.stringify(this.allRecords));
                    // dispaly table only if there is any records                 
                }else{
                    this.error = error;
                } 
            }); 
            //this.showToast(false,this.selectedOptionLabel+' has been added to the cart!','success','pester'); 
        }
        this.isOptionAdded=true;
    }
    handleRemove(event){
        this.isLoaded=false;
        var invalidData;
        var dontHideDetails=false;
        var todayDate = new Date();
        var todayDateFormated= todayDate.getFullYear()+"-"+(todayDate.getMonth()+1)+"-"+todayDate.getDate();
        let cancelledRecords = [];
        let modifiedRecords = [];
        let cancelledOptionLines = this.checkedOptionValue;
        //console.log('çancelled lines===>'+JSON.stringify(cancelledOptionLines));
        console.log('this.endDateValue===>'+this.endDateValue);
        let selectedOptionMap = cancelledOptionLines.reduce(function(map, obj) {
            map[obj.productid] = obj;
            return map;
        }, {});
        this.allRecords.forEach(optionObj => {  
            let modifiedrecord;
            invalidData=false;
            if(optionObj.productid in selectedOptionMap){
                if(this.endDateValue && this.endDateValue>optionObj.endDate){
                    this.showToast(false,this.label.EndDateAssetEndDateErrorMessage,'error','pester');
                    invalidData=true;
                    dontHideDetails=true;
                }
                if(this.endDateValue && this.endDateValue<=optionObj.startDate){
                    this.showToast(false,this.label.EndDateLessStartDateErrorMessage,'error','pester');
                    invalidData=true;
                    dontHideDetails=true;
                }
                console.log('todayDate=========>'+todayDateFormated);
                if(invalidData==false && this.endDateValue && this.endDateValue>todayDateFormated){
                    this.showToast(false,this.label.EndDateGreaterThanTodayWarningMessage,'warning','sticky');
                }
                console.log('endDateValue===>'+this.endDateValue);
                console.log('nextInvoiceDate===>'+optionObj.nextInvoiceDate);
                if(invalidData==false && this.endDateValue<optionObj.nextInvoiceDate){
                    this.showToast(false,this.label.EndDateLessThanNextReadyForInvDate,'warning','sticky');
                }
                if(invalidData==false){ 
                    if(optionObj.linestatus=='Existing' || optionObj.linestatus=='Cancelled' || optionObj.linestatus=='Amended'){
                        optionObj.linestatus='Cancelled';
                        optionObj.endDate=this.endDateValue;
                        optionObj.modifiedLineItem=this.cancelledOptionClass;
                        modifiedrecord= Object.assign({}, optionObj);
                        ['rowNumber','optionGroupText','assetName','chargeType','startDate','endDate','nextInvoiceDate','linestatus'].forEach(e => delete modifiedrecord[e]);
                        cancelledRecords.push(modifiedrecord);
                        modifiedRecords.push(optionObj);
                    }
                    console.log('optionObj.linestatus======>'+optionObj.linestatus);
                    if(optionObj.linestatus=='Cancelled'){
                        this.showToast(false,optionObj.assetName+' has been cancelled!','success','pester');
                    }
                    if(optionObj.linestatus=='New'){
                        this.showToast(false,optionObj.assetName+' has been removed from cart!','success','pester');
                    }
                }
            }
            if(dontHideDetails==false && !(optionObj.productid in selectedOptionMap)){
                modifiedRecords.push(optionObj);
            }
        })
        /*var inputElem = document.getElementsByTagName("input");
        console.log('inputElem==========>'+inputElem);
        console.log('inputElem===OBJ=======>'+inputElem.SecureNodeList);
        for(var i=0; i<inputElem.length; i++){
            console.log('inputElem.type=====>'+inputElem.type);
            console.log('inputElem.name======>'+inputElem.name);
            console.log('inputElem.checked======>'+inputElem.checked);
            /*if(inputElem[i].id.indexOf("checkedone")!=-1)
                inputElem[i].checked = cb.checked;
        }*/
        if( dontHideDetails==false){
            console.log('input==========>'+this.template.querySelectorAll('input'));
            this.template.querySelectorAll('input').forEach(each => {
                console.log('each value =====>'+ each.name);
                console.log('each value =====>'+ each.type);
                console.log('each value =====>'+ each.value);
                if(each.name!='actionTypeCB'){
                    each.value = '';
                }
            });  
            this.allRecords = modifiedRecords;
            this.relatedAttributes=undefined;
            this.endDateValue=undefined;
            this.dispatchEvent(
                new CustomEvent("changedbundleattributes", {
                bubbles:true,
                composed:true,
                detail: this.bundleAttributes
                })
            );
            this.dispatchEvent(
                new CustomEvent("selectedassets", {
                    bubbles:true,
                    composed:true,
                    detail: this.allRecords
                })
            );
            this.template.querySelector('c-apts-lwc-datatable').handleTotalRecordsChange(this.allRecords);
        }
        // this.template.querySelector('c-apts-lwc-datatable').setRecordsToDisplay();
        //console.log('assetRecords===========>'+JSON.stringify(cancelledRecords));
        //console.log('modifiedRecords===========>'+JSON.stringify(modifiedRecords));
        //console.log('this.allRecords===========>'+JSON.stringify(this.allRecords));
        this.isLoaded=true;
    }
    handleOptionAttributes(event){
        let modifiedOptionAttributes = [];
        var hidePaymentAttributes=false;
        console.log("Option selected value:" + event.detail.value);
        console.log("Option selected fieldname :" + event.target.fieldName);
        if(event.target.fieldName=='APTS_Type_of_Payment_System__c'){
            if(event.detail.value=='Closed system (customer card)' || event.detail.value=='Hybrid system'){
                hidePaymentAttributes=true;
            }else{
                console.log("OLD RELATED ATTRIBUTES==" + JSON.stringify(this.oldRelatedAttributes));
                if(this.oldRelatedAttributes && this.oldRelatedAttributes.length>0){
                    this.relatedAttributes=this.oldRelatedAttributes;
                }
            }
        }
        this.relatedAttributes.forEach(optionAttrib => {
            let optionAttObj = {};
            optionAttObj = Object.assign(optionAttObj,optionAttrib); 
            console.log("LOOP : fieldname " + optionAttrib.attributeFieldName);
            console.log("LOOP : value " + optionAttrib.assignedValue);
            console.log("LOOP : readonly " + optionAttrib.readOnly);
            console.log("hidePaymentAttributes   " + hidePaymentAttributes);
            if(optionAttObj.attributeFieldName==event.target.fieldName){
                optionAttObj.assignedValue=event.detail.value;
            }
            if(hidePaymentAttributes==false || (hidePaymentAttributes==true && optionAttObj.attributeFieldName!='APTS_Hospitality_card_used__c')){
                modifiedOptionAttributes.push(optionAttObj);
            }   
        });
        this.relatedAttributes=modifiedOptionAttributes;
        this.basePriceValue=undefined;
        this.billingFrequencyValue=undefined;
        determineOptionPrice( {bundelHeaderId: this.bundleAssetId,optionProductId: this.selectedOptions,optionProductName: this.selectedOptionLabel,expectedStartDate : this.startDateValue,optionGroupName : this.selectedOptionGroupLabel,allTableRecords : this.allRecords,autoRenew: this.selectedAutoRenew,basePriceOverride: this.selectedBasePriceOverride,discountType :this.selectedDiscountType,discountValue : this.selectedDiscountAmt,optionAttributes: this.relatedAttributes,bundleAttributes : this.bundleAttributes} )
        .then((data) => {
            for(let i=0; i<data.length; i++){
                let asset = {};
                asset.rowNumber = ''+(i+1);
                asset = Object.assign(asset, data[i]);
                console.log('asset==VALUE=======>'+JSON.stringify(asset));
                if(asset.linestatus=='New' && asset.productid==this.selectedOptions){
                    console.log('this.basePriceValue===IN LOOP======>'+asset.basePrice);
                    this.basePriceValue=asset.basePrice;
                    this.billingFrequencyValue = asset.billingFrequency;
                }
            }
        });
        console.log("Related Attributes :" +JSON.stringify(this.relatedAttributes));
    }
    handleBundleAttributes(event){
        let modifiedBundleAttributes2 = [];
        var hasAllowSalesPriceOptions=false;
        console.log("Bundle selected value:" + event.detail.value);
        console.log("Bundle selected fieldname :" + event.target.fieldName);
        this.bundleAttributes.forEach(bundleAttrib => {
            //console.log("B LOOP : fieldname " + bundleAttrib.attributeFieldName);
            //console.log("B LOOP : value " + bundleAttrib.assignedValue);
            //console.log("B LOOP : readonly " + bundleAtt  rib.readOnly);
            let bundleAttObj = {};
            bundleAttObj = Object.assign(bundleAttObj,bundleAttrib); 
            if(bundleAttObj.attributeFieldName==event.target.fieldName){
                console.log("B LOOP : FIELD NAME " + bundleAttrib.attributeFieldName);
                console.log("B LOOP : ASSIGNEDVALUE " + bundleAttrib.assignedValue);
                bundleAttObj.assignedValue = event.detail.value;
                if(bundleAttrib.attributeFieldName=='APTS_Allow_sales_price_for_options__c' && bundleAttrib.assignedValue!=event.detail.value){
                    hasAllowSalesPriceOptions=true;
                }
            }
            console.log("B LOOP : OUTSIDE " + JSON.stringify(bundleAttObj));
            modifiedBundleAttributes2.push(bundleAttObj);   
            //bundleAttrib = Object.assign({}, bundleAttrib);
        });
        console.log("B LOOP : OUTSIDE " + JSON.stringify(modifiedBundleAttributes2));
        this.bundleAttributes=modifiedBundleAttributes2;
        if(hasAllowSalesPriceOptions){
            this.populateOptionAttributes();
        }
        console.log("Related BUNDLE Attributes :" + this.bundleAttributes);
    }
    handleAutoRenew(event){
        console.log("B LOOP : OUTSIDE " + JSON.stringify(this.bundleAttributes));
        //console.log("You selected Auto renew:" + event.target.checked);
        this.selectedAutoRenew=event.target.checked;

    }
    handleBasePriceOverride(event){
        //console.log("You selected BPO:" + event.target.value);
        this.selectedBasePriceOverride=event.target.value;
    }
    get discountTypes() {
        return [
            { label: 'Discount %', value: 'Discount%' },
            { label: 'Discount Amount', value: 'DiscountAmount'}
        ];
    }
    handleDiscountType(event){
        this.showDiscountAmt=true;
        this.selectedDiscountType=event.target.value;
    }
    handleDiscountAmount(event){
        //console.log("You selected BPO:" + event.target.value);
        this.selectedDiscountAmt=event.target.value;
    }


    validateCart(){
        //console.log('VALIDATION : ATTRIBUTES ===>'+JSON.stringify(this.relatedAttributes));
        //console.log('VALIDATION RECORDS======>'+JSON.stringify(this.allRecords));
        var hasErrors;
        if(this.relatedAttributes){
            this.relatedAttributes.forEach(optionAttObj => {
                if(optionAttObj.required==true && (optionAttObj.assignedValue==null || optionAttObj.assignedValue==undefined || optionAttObj.assignedValue=='')){
                    this.showToast(false,this.label.RequiriedAttributeErrorMesssage,'error','dismissable');
                    hasErrors=true;
                }
            });
        }
        console.log('selectedBasePriceOverride======>'+this.selectedBasePriceOverride);
        console.log('selectedDiscountType======>'+this.selectedDiscountType);
        console.log('selectedDiscountAmt======>'+this.selectedDiscountAmt);
        console.log('this.BPODiscountWarningMessage======>'+this.label.BPODiscountWarningMessage);
        if(this.selectedBasePriceOverride && this.selectedDiscountType && this.selectedDiscountAmt){
            console.log('WARNING MESSAGE=====');
            this.showToast(false,this.label.BPODiscountWarningMessage,'warning','sticky');
            //hasErrors=true;
        }
        if(this.selectedDiscountType && this.selectedDiscountType=='Discount%' && this.selectedDiscountAmt>100){
            console.log('ERROR MESSAGE===DISC MORE 100==');
            this.showToast(false,'Dear user, more than 100% discount is not allowed!','error','pester');
            hasErrors=true;
        }
        if(this.selectedBasePriceOverride && this.selectedBasePriceOverride==0){
            console.log('WARNING MESSAGE===BPO 0==');
            this.showToast(false,this.label.BPOZeroNotAllowedMessage,'error','pester');
            hasErrors=true;
        }
        if(this.selectedOptionLabel=='CORRECTION PRODUCT FOR MACHINE'){
            console.log('WARNING MESSAGE=====');
            this.showToast(false,this.label.RemoveDummyMachineProductWarningMessage,'warning','sticky');
        }
        if(hasErrors){
            return false;
        }else{
            return true;
        }
    }
    showToast(title,message,variant,mode) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant:variant,
            mode: mode
        });
        this.dispatchEvent(event);
    }

    handleBillingFrequency(event){
        this.billingFrequencyValue=event.detail.value;
    }
    get billingFrequencies(){
        return [
            { label: 'Hourly', value: 'Hourly' },
            { label: 'Daily', value: 'Daily' },
            { label: 'Monthly', value: 'Monthly' },
			{ label: 'Quarterly', value: 'Quarterly' },
            { label: 'Half Yearly', value: 'Half Yearly' },
            { label: 'Yearly', value: 'Yearly' },
			{ label: 'One Time', value: 'One Time' }
        ];
    }
}