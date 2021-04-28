import { LightningElement, api, track, wire } from 'lwc';
import { getRecord, updateRecord } from 'lightning/uiRecordApi';
import { getObjectInfo, getPicklistValuesByRecordType  } from 'lightning/uiObjectInfoApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import CASE_OBJECT from '@salesforce/schema/Case';

const QUERY_FIELDS = [
                'Case.RecordTypeId',

                //COMMON FIELDS FOR ALL TYPES
                'Case.Type',
                'Case.InternalSolution__c',
                'Case.RootCauseSolution__c',
                'Case.External_Solution__c',
                'Case.Comments',

                //COMPLAINT
                'Case.ReasonLevel1__c',
                'Case.ReasonLevel2__c',
                'Case.Solution_Type__c',
                'Case.SubType__c',

                //FIELD SERVICE
                'Case.CompletionCode__c'

            ];

export default class TS_CloseCaseKnowledgeArticle extends LightningElement {    
    
    //ID
    @api recordId;
    @api knowledgeObj;

    //ERROR MESSAGE
    @track error;
    validationError = false;

    //PAGE RENDERING
    @track renderComplaint = false;
    @track renderFieldService = false;
    @track renderCustomerCare = false;
    @track renderSpinner = false;
    
    //COMPLAINT
    @track type;
    @track reason1;
    @track reason2;
    @track solutionType;
    @track rootCauseSolution;
    @track subType;

    //FIELD SERVICE
    @track completionCode;
    @track faultLocationCategory;
    @track defectCode;
    @track faultCode;
   
    //ALL RECORD TYPES
    @track internalSolution;
    @track externalSolution;
    @track internalComments;

    //DEPENDENT PICKLIST FOR FIELD SERVICE
    @track controllingValuesFaultLoc = [];
    @track dependentValuesFaultCode = [];
    @track dependentDisabledFaultCode = true;
    @track completionCodeValues = [];
    @track completionCodeDisabled = false;
    @track defectCodeValues = [];
    controlValuesFaultCode;
    totalDependentValuesFaultCode = [];

    //DEPENDENT PICKLIST FOR COMPLAINT
    @track controllingValuesReason1 = [];
    @track dependentValuesReason2 = [];
    @track dependentDisabledReason2 = true;
    @track solutionTypeValues;
    controlValuesReason2;
    totalDependentValuesReason2 = [];


    //OTHER NON TRACK VARIABLES
    recordTypeId;
    recordTypeName;
    case;
    infoCase;
    picklistCase;
    status = 'Closed';
    
    //GET CASE OBJECT SCHEMA
    @wire(getObjectInfo, { objectApiName: CASE_OBJECT })
    infoCase; 

    //GET CASE DATA, INITIALIZE METHODS
    @wire(getRecord, { recordId: '$recordId', fields: QUERY_FIELDS }) 
    wiredCase({ error, data }){
        if(data){
            this.case = data;
            this.setRecordTypeName();
            this.setCaseAttributes();
            this.setCompletionCodeDisabled();
        }
        else if (error){
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Wire Error',
                    message: 'Failed to retrieve case',
                    variant: 'error',
                }),
            );
        }
    }
    
    //GET PICKLIST AVAILABLE FOR RECORD TYPE
    //@wire(getPicklistValuesByRecordType, { objectApiName: CASE_OBJECT, recordTypeId: '$infoCase.data.defaultRecordTypeId'})
    @wire(getPicklistValuesByRecordType, { objectApiName: CASE_OBJECT, recordTypeId: '$recordTypeId'})
    caseObjectPicklistValues({error, data}) {
        if(data) {
            this.picklistCase = data;
            this.setInitialPicklistValues();
            this.dispatchEvent(new CustomEvent('load'));
        }
        else if(error) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Wire error',
                    message: 'Failed to retrieve case picklists',
                    variant: 'error',
                }),
            );
        }
    }

    setInitialPicklistValues(){
        //FOR FIELD SERVICE PICKLIST

        //DEFECT CODE PICKLIST
        this.completionCodeValues = [{label:'--None--', value:'--None--'}];
        this.picklistCase.picklistFieldValues.CompletionCode__c.values.forEach(key => {
            this.completionCodeValues.push({
                label : key.label,
                value: key.value
            })
        });

        //COMPLETION CODE PICKLIST
        this.defectCodeValues = [{label:'--None--', value:'--None--'}];
        this.picklistCase.picklistFieldValues.DefectCodes__c.values.forEach(key => {
            this.defectCodeValues.push({
                label : key.label,
                value: key.value
            })
        });

        //FAULT LOCATION CATEGORY PICKLIST
        let faultLocationCategoryOptions = [{label:'--None--', value:'--None--'}];
        this.picklistCase.picklistFieldValues.FaultLocationCategory__c.values.forEach(key => {
            faultLocationCategoryOptions.push({
                label : key.label,
                value: key.value
            })
        });
        
        this.controllingValuesFaultLoc = faultLocationCategoryOptions;
         //FAULT CODE CONTROL PICKLIST VALUES
        this.controlValuesFaultCode = this.picklistCase.picklistFieldValues.Fault_Code__c.controllerValues;
        //FAULT CODE DEPENDENT PICKLIST VALUES
        this.totalDependentValuesFaultCode = this.picklistCase.picklistFieldValues.Fault_Code__c.values;
        

        //FOR OMPLAINT PICKLIST

        //REASON 1, GETTING THE DEPENDENCY FROM SUBTYPE
        let reason1Options = [{label:'--None--', value:'--None--'}];
        let totalDependentValuesReason1 = this.picklistCase.picklistFieldValues.ReasonLevel1__c.values;
        let controlValuesReason1 = this.picklistCase.picklistFieldValues.ReasonLevel1__c.controllerValues;

        totalDependentValuesReason1.forEach(conValues => {
                if(conValues.validFor[0] === controlValuesReason1[this.subType]) {
                    reason1Options.push({
                        label: conValues.label,
                        value: conValues.value
                    })
                }
            })
         
        this.controllingValuesReason1 = reason1Options;
        //REASON 2 CONTROL PICKLIST VALUES
        this.controlValuesReason2 = this.picklistCase.picklistFieldValues.ReasonLevel2__c.controllerValues;
        //REASON 2 DEPENDENT PICKLIST VALUES
        this.totalDependentValuesReason2 = this.picklistCase.picklistFieldValues.ReasonLevel2__c.values;

        //SOLUTION TYPE
        this.solutionTypeValues = [{label:'--None--', value:'--None--'} ];
        this.picklistCase.picklistFieldValues.Solution_Type__c.values.forEach(key => {
            this.solutionTypeValues.push({
                label : key.label,
                value: key.value
            })
        });

        if(this.reason1){                
            this.setReason2Picklist();
        }

        if(this.faultLocationCategory){                
            this.setFaultCodePicklist();
        }
    }
                
    //EVENT WRAPPER FOR faultLocationCategoryChange
    handleFaultLocationCategoryChange(event){
        this.faultLocationCategory = event.target.value;
        this.setFaultCodePicklist();        
    }

    //HANDLE FAULT CATEGORY CHANGE
    setFaultCodePicklist(){
        let dependValues = [];
        if(this.faultLocationCategory) {
            if(this.faultLocationCategory === '--None--') {
                dependValues = [{label:'--None--', value:'--None--'}];
                this.faultLocationCategory = null;
                this.faultCode = null;
                this.dependentDisabledFaultCode = true;
                return;
            }
            this.dependentDisabledFaultCode = false;
            this.totalDependentValuesFaultCode.forEach(conValues => {
                if(conValues.validFor[0] === this.controlValuesFaultCode[this.faultLocationCategory]) {
                    dependValues.push({
                        label: conValues.label,
                        value: conValues.value
                    })
                }
            })            
            this.dependentValuesFaultCode = dependValues;
        }
    }

    //EVENT WRAPPER FOR REASON 1 CHANGE
    handleReason1Change(event) {
        this.reason1 = event.target.value;
        this.setReason2Picklist();   
    }

    // HANDLE REASON 1  CHANGE
    setReason2Picklist(){
            let dependValues = [];
            if(this.reason1) {
                if(this.reason1 === '--None--') {
                    dependValues = [{label:'--None--', value:'--None--'}];
                    this.reason1 = null;
                    this.reason2 = null;
                    this.dependentDisabledReason2 = true;
                    return;
                }
                this.dependentDisabledReason2 = false;
                this.totalDependentValuesReason2.forEach(conValues => {
                    if(conValues.validFor[0] === this.controlValuesReason2[this.reason1]) {
                        dependValues.push({
                            label: conValues.label,
                            value: conValues.value
                        })
                    }
                }) 
                this.dependentValuesReason2 = dependValues;
            }
        }

    //SET ALL CASE ATTRIBUTES 
    setCaseAttributes(){
        //COMPLAINT
        if(this.recordTypeName != null && this.recordTypeName === 'Complaint'){
            
            this.type = this.case.fields.Type.value;
            this.reason1 = this.case.fields.ReasonLevel1__c.value;
            this.reason2 = this.case.fields.ReasonLevel2__c.value;
            this.solutionType = this.case.fields.Solution_Type__c.value;
            this.internalComments = this.case.fields.Comments.value;
            this.subType = this.case.fields.SubType__c.value;

        }
        //FIELD SERVICE
        else if(this.recordTypeName != null && 
                (this.recordTypeName === 'Field Service Default' ||
                this.recordTypeName === 'Field Service Contract' ||
                this.recordTypeName === 'Field Service Sales')
                ){
            
            this.completionCode = this.case.fields.CompletionCode__c.value;  
        
            if(this.knowledgeObj){
                this.faultLocationCategory = this.knowledgeObj.Fault_Location_Category__c.substr(0,1);
                this.defectCode = this.knowledgeObj.Defect_Code__c.substr(0,3); 
                this.faultCode = this.knowledgeObj.Fault_Code__c.substr(0,3); 
            }
        }
        //ALL RECORD TYPES
        this.rootCauseSolution = this.case.fields.RootCauseSolution__c.value;
        this.internalSolution = this.case.fields.InternalSolution__c.value;
        this.externalSolution = this.case.fields.External_Solution__c.value;
    }

    //INITIALIZE RECORD TYPE
    setRecordTypeName(){
        this.recordTypeId = this.case.fields.RecordTypeId.value;
        const rtids = JSON.stringify(this.infoCase.data.recordTypeInfos);
        const rtObj = JSON.parse(rtids);
        this.recordTypeName = rtObj[this.recordTypeId].name;
        this.toggleRenderOptions();       
    }

    //TOGGLE WHICH FORM TO SHOW
    toggleRenderOptions(){
        if(this.recordTypeName != null && this.recordTypeName === 'Complaint'){
            this.renderComplaint = true;
        }
        else if(this.recordTypeName != null && this.recordTypeName === 'Customer Care'){
            this.renderCustomerCare = true;
        }
        else if(this.recordTypeName != null && 
                (this.recordTypeName === 'Field Service Default' ||
                this.recordTypeName === 'Field Service Contract' ||
                this.recordTypeName === 'Field Service Sales')
                ){
            this.renderFieldService = true;
        }
    }

    //SET COMPLETION CODE TO FIXED VALUE AND DISABLED
    setCompletionCodeDisabled(){
        let recTypes = ['Field Service Contract', 'Field Service Default', 'Field Service Sales'];
        if(recTypes.includes(this.recordTypeName)){
            this.completionCode = '140';
            this.completionCodeDisabled = true;
        }
    }

    //HANDLE ANY FIELD CHANGE
    handleFieldChange(event) {
        //COMPLAINT
        if (event.target.name === 'type') {
            this.type = event.target.value;
        }
        if (event.target.name === 'reason1') {
            this.reason1 = event.target.value;
        }
        if (event.target.name === 'reason2') {
            this.reason2 = event.target.value;
        }
        if (event.target.name === 'solutionType') {
            this.solutionType = event.target.value;
        }
        if (event.target.name === 'rootCauseSolution') {
            this.rootCauseSolution = event.target.value;
        }
             
        //FIELD SERVICE
        if (event.target.name === 'completionCode') {
            this.completionCode = event.target.value;
        }
        if (event.target.name === 'defectCode') {
            this.defectCode = event.target.value;
        }
        if (event.target.name === 'faultCode') {
            this.faultCode = event.target.value;
        }
         
        //ALL FIELDS
        if (event.target.name === 'internalSolutionCare' ||
            event.target.name === 'internalSolutionFS'   ||
            event.target.name === 'internalSolutionComp' ){
            this.internalSolution = event.target.value;
        }

        if (event.target.name === 'externalSolutionCare' ||
            event.target.name === 'externalSolutionFS'   ||
            event.target.name === 'externalSolutionComp' ){
            this.externalSolution = event.target.value;
        }

        if (event.target.name === 'internalCommentsCare' ||
            event.target.name === 'internalCommentsFS'   ||
            event.target.name === 'internalCommentsComp' ){
            this.internalComments = event.target.value;
        }
    }

    validateFields(){
        //COMPLAINT
        if(this.recordTypeName != null && this.recordTypeName === 'Complaint'){
            if( this.reason1 === null ||
                this.solutionType == null ||
                this.externalSolution === null
                ){
                    this.validationError = true;
            }
            else {
                this.validationError = false;
            }

        }

        //CUSTOMER CARE
        else if(this.recordTypeName != null && this.recordTypeName === 'Customer Care'){
            if( this.externalSolution === null ){
                this.validationError = true;                
            }
            else {
                this.validationError = false;
            }
        }

        //FIELD SERVICE
        else if(this.recordTypeName != null && 
                    (this.recordTypeName === 'Field Service Default' ||
                     this.recordTypeName === 'Field Service Contract' ||
                     this.recordTypeName === 'Field Service Sales')
                     ){
                            if( this.completionCode === null ||
                                this.faultLocationCategory === null ||
                                this.faultCode === null ||
                                this.defectCode === null || 
                                this.externalSolution === null
                            ){
                                this.validationError = true;
                            }
                            else {
                                this.validationError = false;
                            }
        }   
    }

    //RECORD SAVING
    updateCase() {

        this.validateFields();

        const fields = {};
            fields['Id'] = this.recordId;
            fields['Status'] = this.status;

            //FIELD SERVICE
            fields['CompletionCode__c'] = this.completionCode;
            fields['FaultLocationCategory__c'] = this.faultLocationCategory;
            fields['DefectCodes__c'] = this.defectCode;
            fields['Fault_Code__c'] = this.faultCode;

            //COMPLAINT
            fields['ReasonLevel1__c'] = this.reason1;
            fields['ReasonLevel2__c'] = this.reason2;
            fields['Solution_Type__c'] = this.solutionType;
            fields['RootCauseSolution__c'] = this.rootCauseSolution;

            //FOR ALL TYPES
            fields['InternalSolution__c'] = this.internalSolution;
            fields['External_Solution__c'] = this.externalSolution;
            fields['Comments'] = this.internalComments;

            //DEFAULT
            fields['Case_Closed_Manually__c'] = true;

        const recordForUpdate = { fields };

        if(this.validationError === false){
            this.renderSpinner = true;
            updateRecord(recordForUpdate)
            .then(() => {
                /*
                this.dispatchEvent(                    
                    new ShowToastEvent({
                        title: 'Record update success',
                        message: 'Successfuly closed the case',
                        variant: 'success',
                    }),                    
                );
                */
                
                //TO REFRESH PARENT LIGHTNING COMPONENT
                this.dispatchEvent(new CustomEvent('close'));
                this.renderSpinner = false;
                
            })
            .catch(error => {
                console.log('ERROR: '+ error);
                
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Unsuccessful',
                        message: error.body.output.errors[0].message,
                        variant: 'error',
                    }),
                );
                this.renderSpinner = false;
            });
        }
        else {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Validation error',
                    message: 'Please fill out all required fields',
                    variant: 'error',
                }),
            );
        }      
    }
}