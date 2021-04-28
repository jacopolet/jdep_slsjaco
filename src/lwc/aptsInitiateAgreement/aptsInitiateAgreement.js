/**
 * @description       : LWC used for showing first page of Agreement New UX
 * @author            : Renuka Ganesan
 * @group             : 
 * @last modified on  : 20-04-2021
 * @last modified by  : Karan Khatri
 * Modifications Log 
 * Ver   Date         Author         Modification
 * 1.0   12-04-2021   Renuka Ganesan   Initial Version
 * 1.1   13-04-2021   Karan Khatri  Added changes for category level(DQ-4112)
**/
import { LightningElement, wire, api, track } from 'lwc';
import getAgreementfields from '@salesforce/apex/APTS_InitiateAgreementController.getAgreementfields';
import getDuration from '@salesforce/apex/APTS_InitiateAgreementController.getDuration';
import setAgreementfields from '@salesforce/apex/APTS_InitiateAgreementController.setAgreementfields';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import { NavigationMixin } from 'lightning/navigation';


export default class AptsInitiateAgreement extends NavigationMixin(LightningElement) {
    @api recordId;
    @api recordName;
    @api accountId;
    @track isLoaded = false;
    allRecords;
    selectedDealType = 'Standard';
    selectedSubType = 'Regular';
    startDate;
    endDate;
    endDateOld;
    startDateOld;
    subTypeOld;
    periodOld;
    routesales = false;
    autorenew = true;
    period;
    disableautorenew = false;
    disableEndDate = true;
    disableDuration = false;
    disableDelivery = false;
    disableOrdering = false;
    priceList;
    oldPriceList;
    routeSalespriceList;
    contact;
    agreementfields;
    delivery;
    ordering;
    durationMap;
    deliveryOptions;
    orderingOptions;
    agreementStages;
    inProgressPathClass='slds-path__item slds-is-current slds-is-active';
    incompletePathClass='slds-path__item slds-is-incomplete';
    completedPathClass='slds-path__item slds-is-complete';
    @track
    deliveryOptionsStaticList = [
        {label: 'LSP', value: 'LSP'},
        {label: 'Indirect channel', value: 'Indirect channel'},
        {label: '3rd party sales', value: '3rd party sales'}
    ];
    @track
    orderingOptionsStaticList = [
        {label: 'Operator', value: 'Operator' },
        {label: 'Online', value: 'Online' },
        {label: 'Sales Support', value: 'Sales Support' },
        {label: 'Indirect channel', value: 'Indirect channel' },
        {label: 'Partner Portal', value: 'Partner Portal' },
        {label: 'Platform Integration', value: 'Platform Integration' },
        {label: '3rd party sales', value: '3rd party sales' }
    ];
    @track notification = {};
    //Added by Karan
    showNewAgreePage;
    showCategoryPage;
    miniCartItemsJSON;
    showConfigurationPage;
    allRecordsJSONString;
    cspGeneralPricelistMap;
    parentPriceListId;
    
    @wire(getAgreementfields , {recordId: '$recordId',accountId: '$accountId'})
    wiredAgreements({error,data}){
        this.showNewAgreePage = true;
        this.showCategoryPage = false;
        this.showConfigurationPage=false;
        this.agreementStages=this.fetchAgreementStages();
        this.cspGeneralPricelistMap = new Map();
        if(data){
            console.log('data'+JSON.stringify(data));
            this.priceList = data.priceListId;
            this.oldPriceList = data.priceListId;
            this.contact = data.conId;
            this.startDate = data.startDate;
            this.endDate = data.endDate;
            this.delivery = data.delivery;
            this.ordering = data.ordering;
            this.period = data.contractPeriod;
            this.routeSalespriceList = data.routeSalesPriceListId;
            this.deliveryOptions = this.deliveryOptionsStaticList;
            this.orderingOptions = this.orderingOptionsStaticList;
            this.allRecords = data;
            this.parentPriceListId=data.parentPriceListId;
            this.cspGeneralPricelistMap=data.generalCSPPriceListIdMap;
            console.log('allRecords'+JSON.stringify(this.allRecords));
            console.log('CSP General PL MAP====>'+JSON.stringify(this.cspGeneralPricelistMap));
        }else{
            this.error = error;
        }  
    }
    handleLoad(event) {
        this.isLoaded=true; 
        const recUi = event.detail;
        console.log('isLoaded=>'+this.isLoaded);
    }

    handleNext(event){

        console.log('this.allRecords.selectedDealType'+this.allRecords+'=='+this.contact+'=='+this.endDate+'=='+this.startDate+'=='+this.period+'=='+this.priceList);
        if(this.endDate == '' || this.startDate == '' || this.period == ''
            || this.contact == '' || this.priceList == '' || this.contact == undefined || this.priceList == undefined 
            || this.delivery =='' || this.delivery == undefined || this.ordering == '' || this.ordering == undefined){
                this.showNotification(false, `Please fill in the required Information`, 'Required Information', 'error', `sticky`);
        }else{
            let modifiedList = JSON.parse(JSON.stringify(this.allRecords));
            modifiedList.dealType = this.selectedDealType;
            modifiedList.subType = this.selectedSubType;
            modifiedList.startDate = this.startDate;
            modifiedList.endDate = this.endDate;
            modifiedList.routeSales = this.routesales;
            modifiedList.autoRenew = this.autorenew;
            modifiedList.contractPeriod = this.period;
            modifiedList.priceListId = String(this.priceList);
            modifiedList.conId = String(this.contact);
            modifiedList.delivery = this.delivery;
            modifiedList.ordering = this.ordering;
            modifiedList.oppId = this.recordId;
            modifiedList.accId = this.accountId;
            modifiedList.routeSalesPriceListId = this.routeSalespriceList;
            modifiedList.parentPriceListId=this.parentPriceListId;
            this.allRecords= modifiedList;
            //v1.1 - added by karan - start
            this.showNewAgreePage = false;
            this.showCategoryPage = true;
            this.allRecordsJSONString=JSON.stringify(this.allRecords);
            //v1.1 - added by karan - end
            console.log('allRecords'+JSON.stringify(this.allRecords));
        }
        this.agreementStages.forEach(stage => {
            if(stage.name=='Initiate Agreement'){
                stage.class=this.completedPathClass;
            }
            if(stage.name=='Select Products'){
                stage.class=this.inProgressPathClass;
            }
        });
    }

    
    handleDealType(event){
        console.log(event.detail.value);
        this.selectedDealType=event.detail.value;
    }
    handleSubType(event){
        console.log('SubType changed'+event.detail.value);
        
        this.subTypeOld = this.selectedSubType;
        this.selectedSubType=event.detail.value;
        console.log('SubType changed==>'+this.selectedSubType);
        if(event.detail.value == 'Fixed End Date'){
            this.autorenew=false;
            this.disableautorenew=true;
            console.log('Autorenew'+this.autorenew+'disableAutoRenew'+this.disableautorenew);
            this.disableDuration = true;
            this.disableEndDate = false;
        }else if(event.detail.value != '3+1+1'){
            this.autorenew=true;
            this.disableautorenew=false;
            this.disableDuration = false;
            this.disableEndDate = true;
        }
        if(event.detail.value == '3+1+1'){
            if(this.period != '' && this.period != 60){
                getDuration({startDate: this.startDate, endDate: this.endDate, 
                    duration: this.period, text:'EndDate'})
                .then((data) =>{
                    if(data){
                        this.selectedSubType = this.subTypeOld;
                        console.log('this.selectedSubType==>'+this.selectedSubType);
                        this.showNotification(false, `For 3+1+1 Agreement, Duration between the Agreement end date and Agreement start date is 5 years(60 months)`, '', 'error', `sticky`);
                    }
                })
        }else{
            this.autorenew=true;
            this.disableautorenew=false;
            this.disableDuration = false;
            this.disableEndDate = true;
        }
        }
    }
    handleStartDateChange(event){
        this.startDateOld = this.startDate;
        this.startDate = event.detail.value;
        console.log('this.startDate'+this.startDate);
        if(event.detail.value != undefined && event.detail.value != null && event.detail.value != ''){
            if(this.selectedSubType != 'Fixed End Date'){
                console.log('subType ==> '+this.selectedSubType);
                getDuration({startDate: event.detail.value, endDate: this.endDate, 
                                        duration: this.period, text:'EndDate'})
                .then((data) =>{
                    if(data){
                        console.log('data start date change=>'+JSON.stringify(data));
                        this.endDate = data.endDate;
                        console.log('durationMap=>'+this.period);
                        console.log('new end date=>'+this.endDate);
                    }
                })
            }else if(this.selectedSubType == 'Fixed End Date'){
                console.log('subType ==> '+this.selectedSubType);
                getDuration({startDate: event.detail.value, endDate: this.endDate, 
                                        duration: this.period, text:'Duration'})
                .then((data) =>{
                    if(data){
                        console.log('data start date change=>'+JSON.stringify(data));
                        if(data.contractPeriod > 120 || data.contractPeriod < 1){
                            this.startDate = this.startDateOld;
                            this.showNotification(false, `Agreement Duration cannot be more than 120 or less than 1`, 'Agreement Duration', 'error', `sticky`);
                        }else{
                        this.period = data.contractPeriod;
                        }
                        console.log('durationMap=>'+this.period);
                        console.log('new end date=>'+this.endDate);
                    }
                })
            }        
        }
    }
    handleEndDateChange(event){
        console.log('EndDate'+event.detail.value);
        console.log('this.endDate'+this.endDate);
        this.endDateOld = this.endDate;
        this.endDate=event.detail.value;
        if(event.detail.value != undefined && event.detail.value != null && event.detail.value != ''){
            if(this.selectedSubType == 'Fixed End Date' && event.target.value != undefined){
                console.log('subType ==> '+this.selectedSubType);
                getDuration({startDate: this.startDate, endDate: event.detail.value, 
                                        duration: this.period, text:'Duration'})
                .then((data) =>{
                    if(data){
                        console.log('data start date change=>'+JSON.stringify(data));
                        if(data.contractPeriod > 120 || data.contractPeriod < 1){
                            this.endDate = this.endDateOld;
                            this.showNotification(false, `Agreement Duration cannot be more than 120 or less than 1`, 'Agreement Duration', 'error', `sticky`);
                        }else{
                        this.period = data.contractPeriod;
                        }
                        console.log('Period - durationMap=>'+this.period);
                        console.log('Period - new end date=>'+this.endDate);
                    }
                })
            }
        }
    }
    handleContractPeriod(event){
        console.log('Period'+event.target.value);
        this.periodOld = this.period;
        console.log('this.periodOld==>'+this.periodOld);
        this.period = event.target.value;
        if(event.target.value != undefined && event.target.value != null && event.target.value != ''){
            if(this.selectedSubType != 'Fixed End Date' && event.target.value != undefined){
                console.log('subType ==> '+this.selectedSubType);
                getDuration({startDate: this.startDate, endDate: this.endDate, 
                                        duration: event.target.value, text:'EndDate'})
                .then((data) =>{
                    if(data){
                        if(this.selectedSubType == '3+1+1' && this.period != 60){
                            this.period = '60';
                            this.showNotification(false, `For 3+1+1 Agreement, Duration between the Agreement end date and Agreement start date is 5 years(60 months)`, '', 'error', `sticky`);
                        }else if(this.period > 120 || this.period < 1){
                            console.log('Period > 120');
                            this.period = this.periodOld;
                            this.showNotification(false, `Agreement Duration cannot be more than 120 or less than 1`, 'Agreement Duration', 'error', `sticky`);
                        }else {
                        console.log('data start date change=>'+JSON.stringify(data));
                        this.endDate = data.endDate;
                        console.log('Period - durationMap=>'+this.period);
                        console.log('Period - new end date=>'+this.endDate);
                        }
                    }
                })
            }
        }
    }
    handleContact(event){
        console.log('Contact'+event.detail.value);
        this.contact=event.detail.value;
    }
    handleAutoRenew(event){
        console.log('AutoRenew'+event.detail.checked);
        this.autorenew=event.detail.checked;
    }
    handleRouteSales(event){
        console.log('RouteSales'+event.detail.checked);
        this.routesales = event.detail.checked;
        if(event.detail.checked){
            if(this.routeSalespriceList != undefined && this.routeSalespriceList != null 
                && this.routeSalespriceList != ''){
                this.priceList = this.routeSalespriceList;
            }
            const option = {
                label: 'Routesales',
                value: 'Routesales'
            };
            this.deliveryOptions = [ option ];
            const option1 = {
                label: 'Routesales',
                value: 'Routesales'
            };
            this.orderingOptions = [ option1 ];
            this.delivery = 'Routesales';
            this.ordering = 'Routesales';
            this.disableDelivery = true;
            this.disableOrdering = true;
            console.log('deliveryOptions 1 ==>'+JSON.stringify(this.deliveryOptions));

        }else{
            this.priceList = this.oldPriceList;
            this.delivery = '';
            this.ordering = '';
            this.deliveryOptions = this.deliveryOptionsStaticList;
            this.orderingOptions = this.orderingOptionsStaticList;
            this.disableDelivery = false;
            this.disableOrdering = false;
            console.log('deliveryOptions==>'+JSON.stringify(this.deliveryOptions));
        }
    }
    handlePriceList(event){
        console.log('PriceList'+event.detail.value);
        this.priceList=event.detail.value;
        this.parentPriceListId=undefined;
        for(let key in this.cspGeneralPricelistMap) {
            if(key==event.detail.value){
                console.log('KEY===>'+key);
                console.log('VALUE===>'+this.cspGeneralPricelistMap[key]);
                this.parentPriceListId=this.cspGeneralPricelistMap[key];
            }
        }
    }
    handleDeliver(event){
        console.log('Delivery'+event.detail.value);
        this.delivery=event.detail.value;
    }
    handleOrder(event){
        console.log('Ordering'+event.detail.value);
        this.ordering=event.detail.value;
    }

    get dealType(){
            return [
                { label: 'Standard Deal', value: 'Standard' }
            ];
    }
    get subType(){
        return [
            { label: 'Fixed-Term-Fixed Costs', value: 'Fixed-Term-Fixed Costs' },
            { label: 'Fixed Term-Ingredients', value: 'Fixed Term-Ingredients' },
            { label: 'Fixed Term-Both Fixed Costs and Ingredients', value: 'Fixed Term-Both Fixed Costs and Ingredients' },
            { label: 'Fixed End Date', value: 'Fixed End Date' },
            { label: '3+1+1', value: '3+1+1' },
            { label: 'Regular', value: 'Regular' }
        ];
    }
    showNotification(isCustom, message, title, variant, mode) {
        if(isCustom){
            this.notification.show = true;
            this.notification.message = `${message}`;
            this.notification.title = `${title}`;
            if(variant === 'warning'){
                this.notification.style = `slds-notify slds-notify_toast slds-theme_warning`;
            }
            if(variant === 'error'){
                this.notification.style = `slds-notify slds-notify_toast slds-theme_error`;
            }
            if(variant === 'success'){
                this.notification.style = `slds-notify slds-notify_toast slds-theme_success`;
            } 
        } else{
            const evt = new ShowToastEvent({
                title: title,
                message: message,
                variant: variant,
                mode: mode
            });
            this.dispatchEvent(evt);
        }               
    } 
    
    hideNotification() {
        this.notification.show = false;
    } 
    //v1.1 - added by karan - start
    handleMiniCartItems(event){
        console.log('miniCartItems==PARENT BUNDLE==>'+JSON.stringify(event.detail));
        this.miniCartItemsJSON=JSON.stringify(event.detail);
    } 


    handleGoToNewAgreementPage(event){
        console.log('first Page flag====>'+event.detail);
        if(event.detail==true){
            this.showCategoryPage=false;
            this.showNewAgreePage=true;
            this.showConfigurationPage=false;
        }
        this.agreementStages.forEach(stage => {
            if(stage.name=='Initiate Agreement'){
                stage.class=this.inProgressPathClass;
            }
            if(stage.name=='Select Products'){
                stage.class=this.incompletePathClass;
            }
        });
    }

    handleGoToProductConfigPage(event){
        console.log('second Page flag==NEXT PAGE==>'+event.detail);
        if(event.detail==true){
            this.showCategoryPage=false;
            this.showConfigurationPage=true;
        }
        this.agreementStages.forEach(stage => {
            if(stage.name=='Initiate Agreement'){
                stage.class=this.completedPathClass;
            }
            if(stage.name=='Select Products'){
                stage.class=this.completedPathClass;
            }
            if(stage.name=='Configure Bundles'){
                stage.class=this.inProgressPathClass;
            }
        });
    }  
    handleGoToCatalogPage(event){
        if(event.detail==true){
            this.showCategoryPage=true;
            this.showNewAgreePage=false;
            this.showConfigurationPage=false;
        }
        this.agreementStages.forEach(stage => {
            if(stage.name=='Initiate Agreement'){
                stage.class=this.completedPathClass;
            }
            if(stage.name=='Select Products'){
                stage.class=this.inProgressPathClass;
            }
            if(stage.name=='Configure Bundles'){
                stage.class=this.incompletePathClass;
            }
        });
    } 
    fetchAgreementStages() {
        return [
            { name: 'Initiate Agreement', class: this.inProgressPathClass},
            { name: 'Select Products', class: this.incompletePathClass},
            { name: 'Configure Bundles', class: this.incompletePathClass },
            { name: 'Price Machines', class: this.incompletePathClass},
            { name: 'Price Ingredients', class:this.incompletePathClass},
            { name: 'Billing Details', class:this.incompletePathClass},
            { name: 'Summary', class:this.incompletePathClass},
            { name: 'Approvals', class:this.incompletePathClass},
            { name: 'Signatures', class:this.incompletePathClass },
        ];
    }
    //v1.1 - added by karan - start
}