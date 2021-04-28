import { LightningElement, api, wire, track } from 'lwc';

//call apex class
import getAgreement from '@salesforce/apex/SM_DataAccessObjectLWC.getAgreementList';
import TS_Case_ServiceWindow_Weekday from '@salesforce/label/c.TS_Case_ServiceWindow_Weekday';

const columns = [
    
    { label:'Action',sortable:true, fieldName: 'amendLink', type: 'url', typeAttributes: {label: 'Amend', tooltip:'Go to detail page', target: '_self'},initialWidth: 100},
    { label:'Agreement Name',sortable:true, fieldName: 'agreementLink', type: 'url', typeAttributes: {label: {fieldName: 'agreementName'}, tooltip:'Go to detail page', target: '_blank'},initialWidth: 200},
    { label: 'Agreement Number', fieldName: 'agreementNumber', type:'text', initialWidth: 200},
    { label: 'Status Category', fieldName: 'statusCategory', type:'text', initialWidth: 200},
    { label: 'Status', fieldName: 'status', type:'text', initialWidth: 200},
    { label: 'Agreement End Date', fieldName: 'agreementEndDate', initialWidth: 200, type: 'date'},
    { label: 'Created Date', fieldName: 'agreementCreatedDate', initialWidth: 200, type: 'date' }
   
];

export default class AgreementListOpportunity extends LightningElement {
    @api recordId;
    @track agreeList;
    @track error;
    @track showDataTable;
    @track showMessage;
    columns = columns;
    initalRecords;

    @wire(getAgreement, {oppId: '$recordId'})
    agreementList({error, data}){
        this.showDataTable=false;
        this.showMessage=false;
        if(data){
            console.log('Data=====>'+JSON.stringify(data));
            this.initalRecords = new Map(); 
            let recs = [];
            for(let i=0; i<data.length; i++){
                let asset = {};
                asset = Object.assign(asset, data[i]);    
                this.initalRecords.set(asset.id, Object.assign({},asset));         
                recs.push(asset);
            }
            this.agreeList = recs;
            console.log('Data==2==>'+JSON.stringify(this.agreeList));
            this.showDataTable=true;
            if(this.agreeList.length === 0){
                this.showDataTable = false;
                this.showMessage = true;
            } else {
                this.showDataTable = true;
                this.showMessage = false;
            }
        }else if(error){
            this.error = error;
            this.showMessage=true;
        }
    };
    
}