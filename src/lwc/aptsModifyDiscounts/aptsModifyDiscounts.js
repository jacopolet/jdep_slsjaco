/**********************************************************************
Name: aptsModifyDiscounts
Date: 07 July 2020
Author: Venky Muppalaneni
Change Verison History: 
**********************************************************************/
import { LightningElement, track ,wire,api } from 'lwc';

import getOptionLines from '@salesforce/apex/APTS_CreateConversionOrderController.getOptionLines';
import reCalculateSellingTermForOptions from '@salesforce/apex/APTS_CreateConversionOrderController.reCalculateSellingTermForOptions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent'
import emtyStartDateWarning from '@salesforce/label/c.APTS_BillingSettingStartDateWarining';
import zeroDiscountWarning from '@salesforce/label/c.APTS_ModifyDiscountZero';
import negativeNetpriceError from '@salesforce/label/c.APTS_ModifyDiscountNegative';
import startDateWarning from '@salesforce/label/c.APTS_ModifyDiscountStartDate';
import bpoWarning from '@salesforce/label/c.APTS_ModifyDiscountBPO';


const columns = [    
    { label:'Asset Name',sortable:true, fieldName: 'assetLink', type: 'url', typeAttributes: {label: {fieldName: 'name'}, tooltip:'Go to detail page', target: '_blank'}},
    { label: 'Charge Type', fieldName: 'chargeType', type: 'text'} ,
    { label: 'Billing Frequency', fieldName: 'billingFrequency', type: 'text'} , 
    { label: 'Pending Invoice Date', fieldName: 'minPendingInvoice', type: 'date'} ,
    { label: 'Next Invoice Date', fieldName: 'nextInvoiceDate', type: 'date'} ,
    { label: 'Original Start Date', fieldName: 'originalStartDate', type: 'date'} ,
	{ label: 'Start Date', fieldName: 'startDate', type: 'date' ,cellAttributes:{class:{fieldName: 'startDateModified'}}} ,
    { label: 'End Date', fieldName: 'endDate', type: 'date'} , 
    { label: 'Selling Term', fieldName: 'sellingTerm', type: 'number',cellAttributes:{class:{fieldName: 'sellingTermModified'}}},
	{ label: 'Base Price', fieldName: 'basePrice', type: 'number'} ,
    { label: 'Base Price Override', fieldName: 'basePriceOverride', type: 'number',cellAttributes:{class:{fieldName: 'bpoModified'}}} ,
	{ label: 'Discount Amount', fieldName: 'discountAmount', type: 'number',cellAttributes:{class:{fieldName: 'amountModified'}}} ,
	{ label: 'Discount %', fieldName: 'discountPercentage', type: 'number',cellAttributes:{class:{fieldName: 'percentageModified'}}} ,
	{ label: 'Net Unit Price', fieldName: 'netUnitPrice', type: 'number',cellAttributes:{class:{fieldName: 'netUnitPriceModified'}}} ,     
]; 

export default class AptsModifyDiscounts extends LightningElement {
    @api recordId;
    columns = columns;
    allRecords;
    selectedAssetOptions;
    cascadeButtonLabel;
    typeValue;
    bpoValue;
    startDateValue;
    isLoaded;
    initalRecords;
    @track updatedsellingterm;
    dataChangedClass= 'slds-is-edited slds-text-color_success customFontChanged';
    subTypeValue = 'ZP06';
    discountTypeValue='Percentage';
    disableStartDate=true;
    // @track recordsToDisplay = [{
    //     Machine: 'Option 1'
    // },{
    //     Machine: 'Option 2'
    // },{
    //     Machine: 'Option 3'
    // }];
    // @wire(getOptionLines, {recordId: '$recordId'})
    // wOptions({error,data}) {
    //     if (data) {
    //         console.log('data'+JSON.stringify(data[0]));
    //         this.recordsToDisplay = data;
    //         this.showTable = true;
    //     } else {
    //         this.error = error;
    //     }
    // }
    connectedCallback() {
        this.isLoaded=false;
        getOptionLines( {recordId: this.recordId} )
        .then((data) => {
            if(data){
                this.initalRecords = new Map(); 
                let recs = [];
                for(let i=0; i<data.length; i++){
                    let asset = {};
                    asset.rowNumber = ''+(i+1);
                    asset.assetLink = '/'+data[i].id;
                    asset = Object.assign(asset, data[i]);    
                    this.initalRecords.set(asset.id, Object.assign({},asset));         
                    recs.push(asset);
                }
                this.allRecords = recs;
                this.isLoaded=true;
            }else{
                this.error = error;
            } 
          
        });
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
        this.startDateValue = event.detail.value;
    }

    handleAllSelectedRows(event) {
        const selectedRows = event.detail;  
        this.selectedAssetOptions = undefined;
        this.cascadeButtonLabel = undefined;   
        if(selectedRows && selectedRows.length > 0){
            this.selectedAssetOptions =  selectedRows;
            this.cascadeButtonLabel = `Cascade to ${this.selectedAssetOptions.length} Options`; 
        }   
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
            let assetOptions = this.selectedAssetOptions;
            let selectedOptionMap = assetOptions.reduce(function(map, obj) {
                map[obj.id] = obj;
                return map;
            }, {});  
            let inValidLineItem=false;
            this.allRecords.forEach(ele => {  
                let modifiedrecord;
                if(ele.id in selectedOptionMap ){
                    if(this.bpoValue){
                        ele.basePriceOverride=this.bpoValue;
                        ele.bpoModified = this.dataChangedClass;
                        if(this.bpoValue>0){
                            ele.netUnitPrice=this.bpoValue;
                            ele.netUnitPriceModified= this.dataChangedClass;
                        }
                        if(!this.typeValue){
                            if(ele.discountPercentage){
                                ele.netUnitPrice= ((ele.basePriceOverride &&ele.basePriceOverride>0) ?(ele.basePriceOverride - ((ele.discountPercentage/100)*ele.basePriceOverride)):(ele.basePrice - ((ele.discountPercentage/100)*ele.basePrice)));
                                ele.netUnitPriceModified= this.dataChangedClass;
                            }
                            else if(ele.discountAmount){
                                ele.netUnitPrice=((ele.basePriceOverride &&ele.basePriceOverride>0)?(ele.basePriceOverride -ele.discountAmount):(ele.basePrice -ele.discountAmount));
                                ele.netUnitPriceModified= this.dataChangedClass;
                            }
                        }
                        
                    }
                    else{
                        ele.basePriceOverride=this.initalRecords.get(ele.id).basePriceOverride;
                        ele.bpoModified = '';
                        ele.netUnitPrice=this.initalRecords.get(ele.id).netUnitPrice;
                        ele.netUnitPriceModified= '';
                    }
                    if(this.typeValue){
                        if(this.discountTypeValue==="Percentage"){
                            ele.percentageModified = this.dataChangedClass;         
                            ele.discountPercentage = this.typeValue ;
                            delete ele['discountAmount'];
                            ele.amountModified='';
                            ele.netUnitPrice= ((ele.basePriceOverride &&ele.basePriceOverride>0) ?(ele.basePriceOverride - ((this.typeValue/100)*ele.basePriceOverride)):(ele.basePrice - ((this.typeValue/100)*ele.basePrice)));
                        }
                        else if(this.discountTypeValue==="Amount"){
                            ele.amountModified = this.dataChangedClass;         
                            ele.discountAmount = this.typeValue ;
                            delete ele['discountPercentage'];
                            ele.percentageModified='';
                            ele.netUnitPrice=((ele.basePriceOverride &&ele.basePriceOverride>0)?(ele.basePriceOverride -this.typeValue):(ele.basePrice -this.typeValue));
                        }
                        
                        ele.netUnitPriceModified= this.dataChangedClass;
                    }
                    else
                    {
                        ele.amountModified='';
                        ele.percentageModified='';
                        ele.subTypeModified = '';
                        ele.discountPercentage = this.initalRecords.get(ele.id).discountPercentage;
                        ele.discountAmount =this.initalRecords.get(ele.id).discountAmount;
                        ele.subType=this.initalRecords.get(ele.id).subType;
                        

                    }
                    console.log('ele.endDate==>'+ele.endDate);
                    if(this.startDateValue){
                        console.log('ele.startDate==>'+this.startDateValue);
                        ele.startDate= this.startDateValue;
                        ele.startDateModified = this.dataChangedClass;
                    }

                    else{
                        ele.startDate=this.initalRecords.get(ele.id).startDate;
                        ele.startDateModified = '';
                        ele.sellingTerm=this.initalRecords.get(ele.id).sellingTerm;
                        ele.sellingTermModified='';
                    }
                    console.log('Working==>');
                    if(this.typeValue && this.subTypeValue){
                        ele.subType=this.subTypeValue;
                        ele.subTypeModified = this.dataChangedClass;
                    }
                }
                console.log('Working1--');
                console.log('ele====>'+JSON.stringify(ele));
                if(ele.netUnitPrice<0){
                    this.showToast(false,`${negativeNetpriceError}`,'error','sticky');
                    inValidLineItem=true;
                }
                if(ele.startDate<ele.originalStartDate || ele.startDate>ele.endDate){
                    this.showToast(false,`${startDateWarning}`,'error','sticky');
                    inValidLineItem=true;
                }
                if(ele.basePriceOverride &&
                ( ele.discountPercentage || ele.discountAmount ) &&
                (ele.percentageModified === this.dataChangedClass ||
                    ele.amountModified === this.dataChangedClass ||
                    ele.bpoModified === this.dataChangedClass ||
                    ele.startDateModified)){
                    this.showToast(false,`Please note that you have provided a discount on top of a BPO.`,'warning','sticky');
                   
                }
                console.log('sellingTermModified123==>'+ele.sellingTermModified);
                console.log('this.dataChangedClass==>'+this.dataChangedClass);
                /*if( ele.percentageModified === this.dataChangedClass ||  ele.amountModified === this.dataChangedClass ||ele.bpoModified === this.dataChangedClass ||ele.startDateModified === this.dataChangedClass || ele.sellingTermModified === this.dataChangedClass){
                    modifiedrecord= Object.assign({}, ele); 
                    ['rowNumber', 'assetLink','percentageModified','amountModified','startDateModified','bpoModified','netUnitPriceModified','subTypeModified','sellingTermModified'].forEach(e => delete modifiedrecord[e]);
                    assetRecords.push(modifiedrecord);
                    
                console.log('modifiedrecord==>'+modifiedrecord);
                console.log('assetRecords===>'+assetRecords);
                //console.log('ele==>'+ele);
                console.log('startDateModified==>'+ele.startDateModified);
                }*/
                console.log('the end');
                modifiedData.push(ele);  
            });   
            reCalculateSellingTermForOptions( {modifiedOptionList: modifiedData} )
            .then((data) => {
                if(data){
                    for(let i=0; i<data.length; i++){
                        let ele = {};
                        let modifiedrecord;
                        ele = Object.assign(ele, data[i]);
                        modifiedSellingTermData.push(ele);
                        if( ele.percentageModified === this.dataChangedClass ||  ele.amountModified === this.dataChangedClass ||ele.bpoModified === this.dataChangedClass ||ele.startDateModified === this.dataChangedClass || ele.sellingTermModified === this.dataChangedClass){
                            modifiedrecord= Object.assign({}, ele); 
                            ['rowNumber', 'assetLink','percentageModified','amountModified','startDateModified','bpoModified','netUnitPriceModified','subTypeModified','sellingTermModified'].forEach(e => delete modifiedrecord[e]);
                            assetRecords.push(modifiedrecord);
                        }
                    }
                    console.log('assetRecords===>'+JSON.stringify(assetRecords));
                    console.log('modifiedSellingTermData===>'+JSON.stringify(modifiedSellingTermData));
                    if(!inValidLineItem){
                        this.allRecords = modifiedSellingTermData; 
                        this.dispatchEvent(
                            new CustomEvent("selectedassets", {
                            bubbles:true,
                            composed:true,
                            detail: assetRecords
                            })
                        );
                        this.template.querySelector('c-apts-lwc-datatable').handleTotalRecordsChange(this.allRecords);  
                        //this.template.querySelector('c-apts-lwc-datatable').setRecordsToDisplay(); 
                        this.disableStartDate=true;
                        this.bpoValue=undefined;
                        this.startDateValue=undefined;
                        this.typeValue=undefined; 
                    }
                    this.isLoaded=true;
                }
            });            
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
    showToast(title,message,variant,mode) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant:variant,
            mode: mode
        });
        this.dispatchEvent(event);
    }
  
        
}