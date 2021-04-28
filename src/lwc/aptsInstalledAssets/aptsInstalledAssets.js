/**********************************************************************
Name: aptsInstalledAssets
Date: 06 July 2020
Author: Sai Sagar
Change Verison History: 
**********************************************************************/

import { LightningElement, track, wire, api } from 'lwc';
import getAssetsRelatedToAccount from '@salesforce/apex/APTS_InstalledAssetsController.getAssetsRelatedToAccount';
import createConversionOrder from '@salesforce/apex/APTS_CreateConversionOrderController.createConversionOrder';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent'
import AddTechnicalService from '@salesforce/label/c.APTS_NewUXAddTechnicalService';
import EndAllAddionalServiceWith0Price from '@salesforce/label/c.APTS_NewUXCancelAdditionalServiceWith0Price';

const columns = [
    { label:'Asset Name',sortable:true, fieldName: 'assetLink', type: 'url', typeAttributes: {label: {fieldName: 'Name'}, tooltip:'Go to detail page', target: '_blank'}},
    { label: 'Type Of Contract', sortable:true, fieldName: 'APTS_Type_Of_Contract__c', type: 'text' },
    { label: 'Start Date', sortable:true, fieldName: 'Apttus_Config2__StartDate__c', type: 'date', typeAttributes:{timeZone:'UTC', year:'numeric', month:'numeric', day:'numeric'}},
    { label: 'End Date', sortable:true, fieldName: 'Apttus_Config2__EndDate__c', type: 'date', typeAttributes:{timeZone:'UTC', year:'numeric', month:'numeric', day:'numeric'}},
    { label: 'Serial Number', fieldName: 'serialNumber', type: 'text', sortable:true }        
];
export default class AptsInstalledAssets extends NavigationMixin(LightningElement) {
    @api recordId;
    @api recordName;
    @track error;
    @track columns = columns;
    @track allRecords; //All opportunities available for data table    
    @track showTable = false; //Used to render table after we get the data from apex controller    
    @track recordsToDisplay = []; //Records to be displayed on the page
    @track rowNumberOffset; //Row number
    @track preSelected = [];
    @track bShowActionModal = false;
    @track showActionButton = false;
    @track selectedAsset ;
    @track isSelectionEnabled=false ;
    @track isStatusLoaded=false ;
    @track selectedActions;
    @track bShowChangeAssetModal = false;
    @track isInvalid = false;
    assetRecords;
    //SORT
    defaultSortDirection = 'asc';
    sortDirection = 'asc';
    sortedBy;   
    orderStatus;
    assetNewDate;
    isStatusScreen;
    bundleAttributes;
    checkCredit;
    @track originalCreditValue;
    casePreFilter;
    selectedInvRmark = '';
    selectedCase = '';

    @wire(getAssetsRelatedToAccount , {recordId: '$recordId'})
    wAssets({error,data}){
        if(data){
            let recs = [];
            for(let i=0; i<data.length; i++){
                let asset = {};
                asset.rowNumber = ''+(i+1);
                asset.assetLink = '/'+data[i].Id;
                asset.serialNumber = data[i].APTS_Physical_Asset__r ? data[i].APTS_Physical_Asset__r.SerialNumber__c: "";
                asset = Object.assign(asset, data[i]); 
                recs.push(asset);
            }
            this.allRecords = recs;
            this.showTable = true;
        }else{
            this.error = error;
        }       
    }

/*     connectedCallback() {
        getAssetsRelatedToAccount( {recordId: this.recordId} )
        .then((data) => {
            if(data){
                let recs = [];
                for(let i=0; i<data.length; i++){
                    let asset = {};
                    asset.rowNumber = ''+(i+1);
                    asset.assetLink = '/'+data[i].Id;
                    asset.UniqueNumber = data[i].APTS_Physical_Asset__r ? data[i].APTS_Physical_Asset__r.UniqueNumber__c : "";
                    asset = Object.assign(asset, data[i]);                
                    recs.push(asset);
                }
                this.assets = recs;
                this.showTable = true;
            }else{
                this.error = error;
            } 
        });
    }   */  
    //Capture the event fired from the paginator component

    handleAllSelectedRows(event) {
        console.log('Inside handleAllSelectedRows--');
        const selectedRows = event.detail;  
        this.selectedAsset = undefined;
        this.showActionButton = false;
        let items = [];
        // As Max Selectin is Set to One take First row in selected rows
        if(selectedRows && selectedRows.length > 0){
            const filterSelected = this.allRecords.filter(({ Id }) => Id === selectedRows[0].Id );
            this.selectedAsset = filterSelected[0];
            this.showActionButton = true;
            this.checkCredit = filterSelected[0].APTS_Credit_Proposal_XC09_Block__c;
            this.originalCreditValue = filterSelected[0].APTS_Credit_Proposal_XC09_Block__c;
            this.casePreFilter = `SalesOrganization__c = '${filterSelected[0].Apttus_Config2__AccountId__r.Sales_Organization__c}'`;
            console.log('--casePerFilter--'+this.casePreFilter);
        }
    }  
    
    navigateToAccount(){
        // Generate a URL to a User record page
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.recordId,
                actionName: 'view',
            },
        })   
    }    

    openModal() {    
        // to open modal window set 'bShowActionModal' tarck value as true
        this.bShowActionModal = true;
        this.selectedActions = undefined;
        this.resetConverionOrderSeletion();
    }
 
    closeModal() {    
        // to close modal window set 'bShowActionModal' tarck value as false
        this.bShowActionModal = false;
        this.resetConverionOrderSeletion();
    }    

    onActionSelect(event) {    
        this.selectedActions = event.detail;
        this.selectedActions = this.selectedActions.length > 0? this.selectedActions: undefined;
    }   

    onSelectionChange(event) {    
        this.isSelectionEnabled = event.detail;
        this.isStatusLoaded=true;
    }
    
    openChangeAssetModal() {
        this.bShowChangeAssetModal = true;
        this.bShowActionModal = false;
        this.resetConverionOrderSeletion();
    }

    resetConverionOrderSeletion(){
        this.isStatusScreen=false;
        this.assetRecords = undefined;
        this.checkCredit = this.originalCreditValue;
        this.selectedCase = '';
        this.selectedInvRmark = '';
    }

    closeChangeAssetModal() {
        this.bShowChangeAssetModal = false;
    }    
    handleSelectedAssets(event)
    {
        this.assetRecords=event.detail;
       
    } 
    handleTermination(event)
    {
        this.assetNewDate=event.detail;
        this.createOrder(null);
        
    }
    handleBundleAttributes(event){
        console.log('BUNDLE EVENT ATTRIBUTES====>'+JSON.stringify(event.detail));
        this.bundleAttributes=event.detail;
    }
    handleCreditCheck(event)
    {
        this.checkCredit = event.detail.checked;
    }
    handleInvRemark(event){
        console.log('parent comp---'+event.detail);
        this.selectedInvRmark = event.detail;
    }
    handleCaseChange(event){
        console.log('parent comp---'+event.detail);
        let res = JSON.stringify(event.detail);
		console.log('--res--'+res);
        if(!res.includes('Remove Selected')){
            this.selectedCase = event.detail;
        }else{
            this.selectedCase = '';
        }
    }
    createOrder(event) {
        console.log('this.selectedAsset.Id====>'+this.selectedAsset.Id);
        console.log('this.selectedAction====>'+this.selectedActions[0]);
        console.log('Asset records====>'+JSON.stringify(this.assetRecords));
        console.log('new date====>'+this.assetNewDate);
        console.log('BUNDLE ATTRIBUTES====>'+this.bundleAttributes);
        this.isInvalid=false; 
        if(this.selectedActions[0]=='Add/Remove Options'){
            console.log('selectedActions====>'+this.selectedActions);
            var hasServiceFee=false;
            var hasActiveServiceFee=false;
            var sumOfActiveAdditonalServices=0;
            var hasActiveAdditionalServiceFee=false;
            for(let i=0; i<this.assetRecords.length; i++){
                if(this.assetRecords[i].optionGroupText=='Technical Service'&&this.assetRecords[i].linestatus!='Cancelled'){
                    hasServiceFee = true;
                    /*if(this.assetRecords[i].assetName!='NO COVERAGE'){
                        hasActiveServiceFee=true;
                    }*/
                }
                /*if(this.assetRecords[i].chargeType=='Additional Service Fee' && this.assetRecords[i].linestatus!='Cancelled'){
                    sumOfActiveAdditonalServices+=this.assetRecords[i].netUnitPrice;
                    hasActiveAdditionalServiceFee=true;
                }*/
             }
             /*console.log('hasServiceFee====>'+hasServiceFee);
             console.log('hasActiveServiceFee====>'+hasActiveServiceFee);
             console.log('hasActiveAdditionalServiceFee====>'+hasActiveAdditionalServiceFee);
             console.log('sumOfActiveAdditonalServices====>'+sumOfActiveAdditonalServices);
             if(hasActiveServiceFee==false && sumOfActiveAdditonalServices==0 && hasActiveAdditionalServiceFee==true){
                this.showToast('false',`${EndAllAddionalServiceWith0Price}`, 'error','sticky');  
                this.isInvalid=true;
             }*/
            if(hasServiceFee==false){
                this.showToast('false',`${AddTechnicalService}`, 'error','sticky');
                this.isInvalid=true;
            }
        }

        if(this.isInvalid==false){
            this.orderStatus = true;
            createConversionOrder({primaryL1AssetId: this.selectedAsset.Id, subSubType: this.selectedActions[0],
                                    orderInput: JSON.stringify(this.assetRecords),assetNewDate:this.assetNewDate,
                                    bundleLevelAttributes:JSON.stringify(this.bundleAttributes),
                                    creditBlock: this.checkCredit, invoiceRemark: this.selectedInvRmark, 
                                    orderCase: this.selectedCase} )
            .then((data) => {
                if(data){
                    console.log('data====>'+JSON.stringify(data));
                    if(data.isSuccess){
                        this.showToast( 'Success','Order Created Succesfully', 'success');
                        this.selectedActions = ['Status'];
                        this.resetConverionOrderSeletion();
                        this.isStatusScreen=true;
                    }                
                }
                this.orderStatus = false;            
            })
        
            .catch(()=>{ this.orderStatus = false;})
        }
    }

    showToast(title,message,variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant:variant
        });
        this.dispatchEvent(event);
    }
 
}