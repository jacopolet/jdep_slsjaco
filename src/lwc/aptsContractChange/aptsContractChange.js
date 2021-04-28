//v100 26-Mar-2021 DQ-5726 :Sneha Jaiwant : prevent user to press Submit button more than once
//v101 26-Mar-2021 DQ-5713 :Sneha Jaiwant : when providing a start date before the original start date the user should be blocked
import { LightningElement, wire, api, track } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import determineOptionPrice from '@salesforce/apex/APTS_ContractChangeNewUXController.determinePriceOfOptions';
import emtyStartDateWarning from '@salesforce/label/c.APTS_BillingSettingStartDateWarining';
import zeroDiscountWarning from '@salesforce/label/c.APTS_ModifyDiscountZero';
import negativeNetpriceError from '@salesforce/label/c.APTS_ModifyDiscountNegative';
import startDateWarning from '@salesforce/label/c.APTS_ModifyDiscountStartDate';
import bpoWarning from '@salesforce/label/c.APTS_ModifyDiscountBPO';
import getOptionLines from '@salesforce/apex/APTS_ContractChangeNewUXController.getRecsForModifyOptionAction';
import getDefaultAttributesForBundle from '@salesforce/apex/APTS_ContractChangeNewUXController.getDefaultAttributesForBundle';
import getDefaultAttributesForNewBundle from '@salesforce/apex/APTS_ContractChangeNewUXController.getDefaultAttributesForNewBundle';
import getAvailableTOC from '@salesforce/apex/APTS_ContractChangeNewUXController.getAvailableTOC';
import determineCTCOptionPrice from '@salesforce/apex/APTS_ContractChangeNewUXController.determineCTCOptionPrice';
import createOrder from '@salesforce/apex/APTS_ContractChangeNewUXController.createOrder';
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


import { refreshApex } from '@salesforce/apex';


const columns = [
    { label:'Asset Name',sortable:true, fieldName: 'assetName', type: 'text'},
    { label:'Contract',sortable:true, fieldName: 'typeOfContract', type: 'text'},
    { label:'Chargetype',sortable:true, fieldName: 'chargeType', type: 'text'},    
    { label: 'Base Price', sortable:true, fieldName: 'basePrice', type: 'text' },  
    { label: 'Selling Term', sortable:true, fieldName: 'sellingTerm', type: 'text'},
    { label: 'Start Date', sortable:true, fieldName: 'startDate', type: 'date'},
    { label: 'End Date', fieldName: 'endDate', type: 'date'},
    { label: 'Billing Frequency', fieldName: 'billingFrequency', type: 'text',cellAttributes:{class:{fieldName: 'billingFrequencyModified'}}} ,  	
    { label: 'Base Price Override', sortable:true, fieldName: 'basePriceOverride', type: 'text'}, 
    //{ label: 'SubType', sortable:true, fieldName: 'subType', type: 'text',cellAttributes:{class:{fieldName: 'netUnitPriceModified'}}} ,      
	{ label: 'Net Unit Price', fieldName: 'netUnitPrice', type: 'number',cellAttributes:{class:{fieldName: 'netUnitPriceModified'}}}        
];

export default class AptsContractChange extends LightningElement {
    @track columns = columns;
    @api bundleAssetId;
    allRecords;
    isLoaded;
    valueChosen;
    showWarranty;
    @track isOptionAdded;
    initalRecords;
    selectedAssetOptions;
    cascadeButtonLabel;
    newhasBundleAttributes;
    newbundleAttributes;
   newmodifiedbundleAttributes;
   bpoValue;
   attr;
    //INPUT
    showOptionGroup;
    dataChangedClass= 'slds-is-edited slds-text-color_success customFontChanged';
    typeValue;
    bShowActionModal ;
    bShowChangeAssetModal ;
    showRelatedOptions;
    selectedAction;
    setInstOrderId;
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
    originalStartDate;
    displayAllOptionGroups;
    displayAllOptions;
    orderStatus;
    hasAttributes;
    allNewBundleRecs;
    relatedAttributes;
    bundleAttributes;
    ContractTypes;
    showAutoRenew;
    showBasePriceOverride;
    showBasePrice;
    modifiedbundleAttributes;
    hasBundleAttributes;
    optionGroupValue;
    oldRelatedAttributes;
    basePriceValue;
    billingFrequencyValue;
    disableProceed=false;//v101
    oldContractTrue=false;//v101
    newContractTrue=false;//v101
    notTrial=false;//v101
    @track bstatusModal = false;//v100
    //Table
    showTable;
    showAddTable;
    showDiscountType;
    selectedDiscountType;
    showDiscountAmt;
    selectedDiscountAmt;
    newlyAddedOptionClass= 'slds-is-edited slds-text-color_success customFontChanged';
    cancelledOptionClass= 'slds-is-edited slds-text-color_destructive customFontChanged';
    amendedOptionClass= 'slds-is-edited slds-text-color_weak customFontChanged';
    @track notification = {};
    updatedAssetOptionMap = new Map();
    label = {RequiriedAttributeErrorMesssage,BPODiscountWarningMessage,StartDateGreaterEndDateErrorMessage,StartDateContStartdateErrorMessage,EndDateAssetEndDateErrorMessage,EndDateLessStartDateErrorMessage,BPOZeroNotAllowedMessage,NetUnitPriceLessThanDiscAmt,EndDateLessThanNextReadyForInvDate};
    @wire(getOptionLines, { bundelHeaderId: '$bundleAssetId' })
    wiredAssets({ error, data }) {
        this.isLoaded = false; 
        this.trackOneTimeChange=false;
        this.isOptionAdded=true;
        this.bShowChangeAssetModal=true;
        //console.log('this.assetid==BEFORE==>'+this.bundleAssetId);
        if(data){                
            let recs = []; 
            this.initalRecords = new Map();        
            for(let i=0; i<data.length; i++){
                let asset = {};
                asset.rowNumber = ''+(i+1);
                asset.assetLink = '/'+data[i].assetid;
                asset = Object.assign(asset, data[i]);  
                this.originalStartDate = data[i].originalStartDate;  
                this.initalRecords.set(asset.assetid, data[i]);         
                recs.push(asset);
                                
            }                          
            this.allRecords = recs;
            // dispaly table only if there is any records        
            this.populateAttributes(); 
            console.log('136 :: bundle asset Id :: '+this.bundleAssetId);
            this.getAvailableTypeOfContracts();
                              
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

/*CTC PAR Restriction for TOC  */
    getAvailableTypeOfContracts()
    {
        //picklistOptionValues = []; // Contains the options for the Picklist
                if(this.bundleAssetId){
            getAvailableTOC( {bundelAssetId: this.bundleAssetId} )
            .then((data) => {
                if(data){
                    console.log('Lavanya'+ data);
                    if(data.length && data.length>0){
                        
                            this.ContractTypes=data;
                        
                        console.log('Lavanya ct'+ this.ContractTypes);
                    }
                }
            });

           
        }
    }
/*CTC Call New Bundle Attributes */
    assignValue(event)
    {
        this.valueChosen = event.target.value;
        //v101++<<
        this.newContractTrue =false;
        if((this.valueChosen === `Free On Loan`) || (this.valueChosen === `Rent`)  || (this.valueChosen === `RentBuy`)){
            console.log('Lavanya new toc1111'+this.valueChosen);
            this.newContractTrue=true;
        }    
        //v101++>>          
        this.populateAttributesforNewBundle();
    }
	
	
/*CTC  New Bundle Attributes */
    populateAttributesforNewBundle()
    {
        if(this.bundleAssetId){
            getDefaultAttributesForNewBundle( {bundelAssetId: this.bundleAssetId,newContract: this.valueChosen} )
            .then((data) => {
                if(data){
                    console.log('Lavanya new toc'+this.valueChosen);
                    if(data.length && data.length>0){
                        this.newhasBundleAttributes=true;
                        this.newbundleAttributes=data;
                        this.newmodifiedbundleAttributes=data;
                    } else{
                        this.newhasBundleAttributes=false;
                    }
                }
            });
        }
    }
	
	
/*CTC  OLD Bundle Attributes */
    populateAttributes(){
    console.log('BUNDLE ASSSET ID =====>  '+this.bundleAssetId);
        if(this.bundleAssetId){
            getDefaultAttributesForBundle( {bundelAssetId: this.bundleAssetId} )
                .then((data) => {
                if(data){
                    console.log('BUNDLE==ATTRIBUTES==>'+JSON.stringify(data));
                    console.log('BUNDLE==ATTRIBUTES==>'+data.length);
                    this.oldContractTrue=false;//v101
                    this.notTrial=false;//v101
                    if(data.length && data.length>0){                        
                        this.hasBundleAttributes=true;
                        this.bundleAttributes=data;
                        this.modifiedbundleAttributes=data;
                        //v101++<<
                        if((data[0].assignedValue === `Free On Loan`) || (data[0].assignedValue === `Rent`)  || (data[0].assignedValue === `RentBuy`)){
                            console.log('@@1'+data[0].assignedValue);
                            this.oldContractTrue=true;
                        }
                        if((data[0].assignedValue === `Trial`)){
                            this.notTrial=true;
                        }
                        //v101++>>
                        if(data[0].StartDate && data[0].StartDate!= null)
                        this.startDateValue=data[0].StartDate;
                        if(data[0].EndDate && data[0].EndDate!= null)
                        this.endDateValue=data[0].EndDate;
                        console.log('Lavanya sd'+this.startDateValue);
                        console.log('Lavanya ed'+this.endDateValue);
                        

                    } else{
                        this.hasBundleAttributes=false;
                    }
                }
            });
        }
        this.isLoaded = true;
        //console.log('BUNDLE relatedAttributes=========>'+this.bundleAttributes);
    }
	

    
    

    handleDatesChange(event){
        console.log('Date=====>'+event.target.value);
        //v101++<<
        var today = new Date();
        var dd = String(today.getDate()).padStart(2, '0');
        var mm = String(today.getMonth() + 1).padStart(2, '0'); 
        var yyyy = today.getFullYear();
        today = yyyy + '-' + mm + '-' + dd;
		//v101++>>
        if(event.target.value){
            this.startDateValue=event.target.value;
            this.disableProceed=false;//v101
            if(this.startDateValue < this.originalStartDate)
            {
                this.showToast(false,`${startDateWarning}`,'error','sticky');
                this.disableProceed=true;//v101

            }
            //v101++<<
            if(!this.notTrial){
                if(this.startDateValue < today)
                {
                    this.showToast(false,`The Startdate cannot be in the past.`,'error','sticky');
                    this.disableProceed=true;
                }
              
                if(this.newContractTrue && this.oldContractTrue)
                {
                   if(this.originalStartDate == today){
                    this.showToast(false,`Today's date cannot be equal to originalstartdate.`,'error','sticky');
                    this.disableProceed=true;
                }
                }
            }
            //v101++>>
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
       
    }
 

    openPrevious()
    {
        this.bShowChangeAssetModal = true;
        this.bShowActionModal = false;
        this.isLoaded=true;  
    }

    openModal()
    {
        this.bShowActionModal = true;
        this.bShowChangeAssetModal = false;
       
        let recs = []; 
        console.log('Lavanya'+this.allRecords.length);
        for(let i=0; i<this.allRecords.length; i++){
            //this.selectedOptions.= this.allRecords[i].productid;
            recs.push(this.allRecords[i].productid);          
        } this.selectedOptions = recs;
        console.log(this.selectedOptions);
            determineCTCOptionPrice( {bundelHeaderId: this.bundleAssetId,bundleAttributes : this.newbundleAttributes,expectedStartDate : this.startDateValue, optionIds : this.selectedOptions} )
            .then((data) => {

                let recs = []; 
                if(data && data.length>0)    
                {  
                   
                   
                    for(let i=0; i<data.length; i++){

                        let newBundle = {};
                        newBundle.assetName = data[i].assetName;
                        newBundle.basePrice = data[i].basePrice;   
                        newBundle.typeOfContract = data[i].typeOfContract;                    
                        newBundle.sellingTerm =data[i].sellingTerm;
                        newBundle.startDate = data[i].startDate;
                        newBundle.endDate = data[i].endDate;
                        newBundle.chargeType = data[i].chargeType;
                        newBundle.basePriceOverride=data[i].basePriceOverride;
                        newBundle.billingFrequency=data[i].billingFrequency;
                        newBundle.subType=data[i].subType;
                        newBundle.netUnitPrice=data[i].netUnitPrice;
                        console.log('Lavanya final'+JSON.stringify(data[i].netUnitPrice));                       
                        newBundle = Object.assign(newBundle, data[i]); 
                        recs.push(newBundle);
                       
                    } this.allNewBundleRecs = recs;
                }
            })
        
       
       
    }
    createOrder() {   
        
        console.log('Inside open Modal'+this.startDateValue);
        console.log('Inside'+this.allNewBundleRecs);
        this.orderStatus = true;//v100
        createOrder( {bundelAssetId: this.bundleAssetId,finalWrapperData:JSON.stringify(this.allNewBundleRecs),startDateValue:this.startDateValue} )
        .then((data) => {
            console.log('Data'+JSON.stringify(data));
            if(data){
                console.log('Inside order'+JSON.stringify(data));
                 this.showToast( 'Success','Order Created Succesfully -> Id = '+data.Id, 'success');
                    this.orderStatus = false;
                    this.bShowActionModal = false;
                    this.bstatusModal = true;//v100 
                    //this.allNewBundleRecs = undefined;  
                               
            }
                    
        })


    
    }

    handleSelectedItem(event){const selectedRows = event.detail;  
        
        this.selectedAssetOptions = undefined;
        this.cascadeButtonLabel = undefined;   
        if(selectedRows && selectedRows.length > 0){
            this.selectedAssetOptions =  selectedRows;
           
            this.cascadeButtonLabel = `Cascade to ${this.selectedAssetOptions.length} Options`; 
        }   
    }


validateData()
    {
        if(this.typeValue && this.typeValue ==0){
            this.showToast(false,`${zeroDiscountWarning}`,'warning','sticky'); 
        }
        if(this.bpoValue && this.bpoValue ==0){
            this.showToast(false,`${bpoWarning}`,'warning','sticky'); 
        }
        if(!this.startDateValue){
            this.showToast(false, `${emtyStartDateWarning}`, 'warning', 'sticky');
        }

        return true;
    }
	
    handleCascade(event) {    
        this.isLoaded=false;     
        let modifiedData = [];
        let modifiedSellingTermData = [];
        let assetRecords = [];
        console.log(this.template);
        // while( Element.template.querySelector('button')!=null){
        //     this.template.querySelector('.toastClose').click();
        // }
		
        if(this.validateData() && this.selectedAssetOptions){
			console.log('Lavanya Multiselect'+JSON.stringify(this.selectedAssetOptions));
            let assetOptions = this.selectedAssetOptions;
            let selectedOptionMap = assetOptions.reduce(function(map, obj) {
                map[obj.productid] = obj;
               // console.log('lavanya map'+JSON.stringify(obj));
                return map;
            }, {});  
            let inValidLineItem=false;
            this.allNewBundleRecs.forEach(ele => {  
                let modifiedrecord;
                console.log('Lavanya outside selecOption'+JSON.stringify(selectedOptionMap));
                if(ele.productid in selectedOptionMap ){
                    if(this.billingFreqValue)
                        {
                            ele.billingFrequency = this.billingFreqValue;
                            ele.billingFrequencyModified = this.dataChangedClass;
                            console.log('Lavanya bf change'+ ele.billingFrequency);
                            console.log('Lavanya bf change'+ ele.billingFrequencyModified);
                        }
                    if(this.bpoValue){
                        ele.basePriceOverride=this.bpoValue;
                        console.log('Lavanya bpo inside'+this.bpoValue);
                        ele.bpoModified = this.dataChangedClass;
                        if(this.bpoValue>0){
                            ele.netUnitPrice=this.bpoValue;
                            console.log('Lavany ele.netUnitPrice'+ele.netUnitPrice);
                           ele.netUnitPriceModified= this.dataChangedClass;
                        }

                       

                        if(!this.typeValue){
                            if(ele.discountPercentage){
                                ele.netUnitPrice= ((ele.basePriceOverride &&ele.basePriceOverride>0) ?(ele.basePriceOverride - ((ele.discountPercentage/100)*ele.basePriceOverride)):(ele.basePrice - ((ele.discountPercentage/100)*ele.basePrice)));
                                ele.netUnitPriceModified= this.dataChangedClass;
                                console.log('Lavany ele.netUnitPrice'+ele.netUnitPrice);
                            }
                            else if(ele.discountAmount){
                                ele.netUnitPrice=((ele.basePriceOverride &&ele.basePriceOverride>0)?(ele.basePriceOverride -ele.discountAmount):(ele.basePrice -ele.discountAmount));
                               // ele.netUnitPriceModified= this.dataChangedClass;
                            }
                        }
                        
                    }
                    
                    if(this.typeValue){
                        if(this.discountTypeValue==="Percentage"){
                        ele.percentageModified = this.dataChangedClass; 
                        ele.discountTypeValue = this.discountTypeValue;        
                            ele.discountPercentage = this.typeValue ;
                            delete ele['discountAmount'];
                            ele.amountModified='';
                            ele.subType='ZP06';
                            ele.netUnitPrice= ((ele.basePriceOverride &&ele.basePriceOverride>0) ?(ele.basePriceOverride - ((this.typeValue/100)*ele.basePriceOverride)):(ele.basePrice - ((this.typeValue/100)*ele.basePrice)));
                        }
                        else if(this.discountTypeValue==="Amount"){
                            ele.discountTypeValue = this.discountTypeValue;   
                            ele.amountModified = this.dataChangedClass;  
                            ele.subType='ZP06';       
                            ele.discountAmount = this.typeValue ;
                            delete ele['discountPercentage'];
                            ele.percentageModified='';
                            ele.netUnitPrice=((ele.basePriceOverride &&ele.basePriceOverride>0)?(ele.basePriceOverride -this.typeValue):(ele.basePrice -this.typeValue));
                        }
                        
                       ele.netUnitPriceModified= this.dataChangedClass;
                    }
                    
                    console.log('ele.endDate==>'+ele.endDate);
                    if(this.startDateValue){
                        console.log('ele.startDate==>'+this.startDateValue);
                        ele.startDate= this.startDateValue;
                       // ele.startDateModified = this.dataChangedClass;
                    }

                   
                    console.log('Working==>');
                    if(this.typeValue && this.subTypeValue){
                        ele.subType=this.subTypeValue;
                      //  ele.subTypeModified = this.dataChangedClass;
                    }
                }
                console.log('Working1--'+ele.subType);
                console.log('ele====>'+JSON.stringify(ele));
                if(ele.netUnitPrice<0){
                    this.showToast(false,`${negativeNetpriceError}`,'error','sticky');
                    inValidLineItem=true;
                }
                
                /*if(ele.basePriceOverride &&
                ( ele.discountPercentage || ele.discountAmount ) &&
                (ele.percentageModified === this.dataChangedClass ||
                    ele.amountModified === this.dataChangedClass ||
                    ele.bpoModified === this.dataChangedClass ||
                    ele.startDateModified)){
                    this.showToast(false,`Please note that you have provided a discount on top of a BPO.`,'warning','sticky');
                   
                }*/
               
                if( ele.percentageModified === this.dataChangedClass ||  ele.amountModified === this.dataChangedClass ||ele.bpoModified === this.dataChangedClass ||ele.billingFrequencyModified === this.dataChangedClass){
                    modifiedrecord= Object.assign({}, ele); 
                    ['rowNumber', 'assetLink','percentageModified','amountModified','startDateModified','bpoModified','netUnitPriceModified','subTypeModified','billingFrequencyModified'].forEach(e => delete modifiedrecord[e]);
                    assetRecords.push(modifiedrecord);
                    
                console.log('modifiedrecord==>'+modifiedrecord);
                console.log('assetRecords===>'+assetRecords);
                //console.log('ele==>'+ele);
                console.log('billingFrequencyModified==>'+ele.billingFrequencyModified);
                }
               
                modifiedData.push(ele);
                this.allNewBundleRecs = modifiedData;
                this.template.querySelector('c-apts-lwc-datatable').handleTotalRecordsChange(this.allNewBundleRecs);
               
                console.log('Lavanya NUP'+ele.netUnitPrice); 
                console.log('The End'+JSON.stringify(modifiedData));
            });   
            
                      
        }
    } 

   

    get options() {
        return [
            { label: 'Permanent Discount', value: 'ZP06' },
            { label: 'Additional Permanent Discount', value: 'ZP07' },
            { label: 'Temporary Discount (Manual)', value: 'ZP04' },
			{ label: 'Promotional Discount', value: 'ZP08' },
            { label: 'Promotional Discount (Coupons)', value: 'ZP10' },
            { label: 'Free Of Charge (100% Discount)', value: 'ZX10' },
			{ label: 'Brand Marketing Campaign (Budget)', value: 'ZP15' },
            { label: 'Business Development Funds (YER)', value: 'ZP11' },
            { label: 'Business Development Funds (PPR)', value: 'ZP13' },
			{ label: 'Efficiency Discount', value: 'ZP12' },
            { label: 'Consignment Ingredients', value: 'YOCI' },
			{ label: 'Fixed term', value: 'YOFT' },
            { label: 'Discount Surcharge GSV', value: 'ZP03' },
            { label: 'Inflation correction', value: 'ZP02' },
        ];
    }
    get discountType() {
        return [
            { label: 'Discount %', value: 'Percentage' },
            { label: 'Discount Amount', value: 'Amount' }
            
        ];
    }

    
    handleSubTypeChange(event) {
        this.subTypeValue = event.detail.value;
    }
    handleDiscountTypeChange(event) {
        this.discountTypeValue = event.detail.value;
    }

    handleBillingFreqChange(event) {
        this.billingFreqValue = event.detail.value;
    }

    handleTypeValueChange(event) {
        if(event.detail.value && event.detail.value.indexOf(".")>0){
            event.detail.value.replace(".","");
        }
        this.typeValue = event.detail.value;
        if(this.typeValue){
            this.disableStartDate=false;
        }
        else if(!this.bpoValue){
            this.disableStartDate=true;
        }

    }
    handleBPOChange(event) {
        if(event.detail.value && event.detail.value.indexOf(".")>0){
            event.detail.value.replace(".","");
        }
        this.bpoValue = event.detail.value;
        if(this.bpoValue){
            this.disableStartDate=false;
        }
        else if(!this.typeValue){
            this.disableStartDate=true;
        }
    }
    handleStartDateChange(event) {
        this.discountStartDateValue = event.detail.value;
       
    }

    

    handleNewBundleAttributes(event){
        let modifiedBundleAttributes2 = [];
        var hasAllowSalesPriceOptions=false;
		console.log('Lavanya inside handleAttrinute'+this.valueChosen);
        console.log("Bundle selected value:" + event.detail.value);
        console.log("Bundle selected fieldname :" + event.target.fieldName);
        this.newbundleAttributes.forEach(bundleAttrib => {
            //console.log("B LOOP : fieldname " + bundleAttrib.attributeFieldName);
            //console.log("B LOOP : value " + bundleAttrib.assignedValue);
            //console.log("B LOOP : readonly " + bundleAtt  rib.readOnly);
            let bundleAttObj = {};
            bundleAttObj = Object.assign(bundleAttObj,bundleAttrib); 
            if(bundleAttObj.attributeFieldName==event.target.fieldName){
                console.log("B LOOP : FIELD NAME " + bundleAttrib.attributeFieldName);
                console.log("B LOOP : ASSIGNEDVALUE " + bundleAttrib.assignedValue);
                bundleAttObj.assignedValue = event.detail.value;
            }
            console.log("B LOOP : OUTSIDE " + JSON.stringify(bundleAttObj));
            modifiedBundleAttributes2.push(bundleAttObj);   
            //bundleAttrib = Object.assign({}, bundleAttrib);
        });
        console.log("B LOOP : OUTSIDE " + JSON.stringify(modifiedBundleAttributes2));
        this.newbundleAttributes=modifiedBundleAttributes2;
        
        console.log("Related NEW BUNDLE Attributes :" + this.newbundleAttributes);
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
        console.log('Lavanya billingFrequencyValue'+this.billingFrequencyValue);
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