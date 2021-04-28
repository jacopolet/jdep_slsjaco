/**********************************************************************
Name: aptsStatus
Date: 07 July 2020
Author: Venky Muppalaneni
Change Verison History: 
**********************************************************************/
import { LightningElement,wire,api ,track} from 'lwc';
import getOrderStatus from '@salesforce/apex/APTS_CreateConversionOrderController.getOrderStatus';
import cancelOrderStatus from '@salesforce/apex/APTS_CreateConversionOrderController.cancelOrderStatus'
import deInstallationOLIStatus from '@salesforce/label/c.APTS_DeInstallationABOStatus'
import { refreshApex } from '@salesforce/apex';

const columns = [    
    { label:'Order Number',sortable:true, fieldName: 'assetLink', type: 'url', typeAttributes: {label: {fieldName: 'name'}, tooltip:'Go to detail page', target: '_blank'}},
	{ label: 'Sub Type', fieldName: 'subType', type: 'text'} ,
	{ label: 'Action', fieldName: 'action', type: 'text'} ,
    { label: 'Created Date', fieldName: 'createdDate', type: 'date'},
    { label: 'Created By', fieldName: 'createdBy', type: 'text'},
	{ label: 'Status', fieldName: 'status', type: 'text',cellAttributes:{class:{fieldName: 'statusModified'}}},
     { label: 'Cancel', fieldName: 'cancelorder', type:'button',onclick:'handleCancel', typeAttributes: {label:'Cancel',disabled:{fieldName:'cancelOrder'},tooltip: 'Cancel the Order',target:'_blank'}},
    { label: 'Indicator', fieldName: 'Status', type: 'text',"cellAttributes": { alignment: 'center',iconName: {fieldName: 'displayIconName'}}} ,
	{ label: 'Error Message',sortable:true,  fieldName: 'errorLink', type: 'url', typeAttributes: {label: {fieldName: 'errorName'}, tooltip:'Go to detail page', target: '_blank'}}
	
]; 


export default class AptsStatus extends LightningElement {
    //@api recordId;
    @track name;
    @track statuss;
    @track listStatus = [];
    columns = columns;
    invoice;
    sapOrder;
    isLoaded;
    allRecords;
    assetId;
    orderData;
    statuss;
    disabledSelections
    @api 
	get recordId() {    
		return this.assetId;  
	}  
	set recordId(value) {    
		this.setAttribute('assetId', value);  
		this.assetId = value;  
	}

	connectedCallback() {        
        this.getOrderData();
    }

    callCancelAction(event){
       this.isLoaded=false;
       //const orderId = event.detail.row.Id;
        const orderNumber = event.detail.name;
        console.log('orderId===>'+orderNumber);
        cancelOrderStatus( {orderId: orderNumber})
        .then(()=>{
            console.log('Entering here==>');
        getOrderStatus( {recordId: this.recordId} )
       .then((data) => {
            if(data){
			   this.doOrderLogic(data);
			   this.template.querySelector('c-apts-lwc-datatable').handleTotalRecordsChange(this.allRecords);
               this.isLoaded=true;
           }else{
               this.error = error;
               } 
       });  
            
        }).catch(error => {
            console.log('Error====>'+JSON.stringify(error));
        })
    }
    getOrderData(){
       //refreshApex(this.orderData);
       this.isLoaded=false;
       getOrderStatus( {recordId: this.recordId} )
       .then((data) => {
           if(data){
			   this.doOrderLogic(data);
           }else{
               this.error = error;
           } 
       });        
    }
	
	doOrderLogic(data){
		       let recs = [];
               this.disabledSelections=false;
               for(let i=0; i<data.length; i++){
                   let asset = {};
                   asset.rowNumber = ''+(i+1);
                   asset.assetLink = '/'+data[i].id;
                    asset.displayIconName='standard:task2';                  
                   this.listStatus=deInstallationOLIStatus.split(',');
                   if((this.listStatus.includes(data[i].status) && data[i].subType ==='De-installation') || (data[i].status!=='Cancelled' && data[i].status!=='Superseded' && data[i].status!=='Completed' && data[i].status!=='Activated' && data[i].subType!=='De-installation') || (data[i].subType==='Installation' && data[i].invoice === undefined && data[i].sapOrder==='XA23')){
                    console.log('Status check=='+data[i].status);    
                    asset.displayIconName='standard:loop';
                        this.disabledSelections=true;
                        if(data[i].errorId){
                            asset.errorLink = '/'+data[i].errorId;
                            asset.displayIconName='standard:first_non_empty';
                        }
                    }                     
                   asset = Object.assign(asset, data[i]);    
                   recs.push(asset);
                   
               }
               this.allRecords = recs; 
               console.log('this.allRecords'+JSON.stringify(this.allRecords));
               this.isLoaded=true;
               this.dispatchEvent(
                new CustomEvent("disableselections", {
                composed:true,
                detail: this.disabledSelections
                })
            );
	}

}