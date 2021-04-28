import {LightningElement, api, track} from 'lwc';
import getLookupResults from '@salesforce/apex/APTS_CustomLookupController.getLookupResults';

export default class AptsLwcCustomLookup extends LightningElement {
    @api objectName;
    @api numOfChars = 3;
    @api iconName;
    @api displayFieldName = "Name";
    @api lookupLabel;
    @track prepopulateRecordId;

    @api extraFields;
    @api extraFilters;
    @api customStyle;
    @api label;
    @api limit = 50;
    @track message = "";
    @track recordsList = [];
    @track selectedRecord = {};

    @track searchKeyword;

    @track showSpinner;

    @api
    get prepopulateId() {
        return this.prepopulateRecordId;
    }
    set prepopulateId(value) {
        this.prepopulateRecordId = value;
        this.getResults(null);
    }

    get recordsNotFound() {
        return this.showSpinner == false && this.recordsList.length == 0;
    }

    get isRecordSelected() {
        return this.selectedRecord != null && Object.keys(this.selectedRecord).length > 0;
    }

    get placeholderString() {
        return "Search ...";
    }

    get getStyle() {
        return "z-index:9002;top:initial;left:initial;transform:initial;" + this.customStyle;
    }

    toggleResultsDiv(event) {
        let domEl = this.template.querySelector('.slds-combobox');
        let openClassCondition = event.type != 'blur' && (this.searchKeyword != null && this.searchKeyword.length >= this.numOfChars);
        let classToAdd = openClassCondition ? 'slds-is-open' : 'slds-is-close';
        let classToRemove = openClassCondition ? 'slds-is-close' : 'slds-is-open';

        if (!domEl.classList.contains(classToAdd)) {
            domEl.classList.add(classToAdd);
            domEl.classList.remove(classToRemove);
        }
    }

    getResults(event) {
        if (event) {
            this.searchKeyword = event.target.value;
            this.toggleResultsDiv(event);
        }
        if (this.prepopulateRecordId || (this.searchKeyword && this.searchKeyword.length >= this.numOfChars)) {
            this.showSpinner = true;
            this.displayFieldName = this.objectName == 'Case' ? 'CaseNumber' : 'Name';
            let fieldName =  this.displayFieldName;
            let setSelectedRecord = this.prepopulateRecordId != null;
            getLookupResults({displayFieldName: this.displayFieldName,
                              objectName: this.objectName,
                              extraFilters: this.extraFilters,
                              extraFields: this.extraFields,
                              searchKeyword: this.searchKeyword,
                              prepopulateId: this.prepopulateRecordId})
                .then(result => {
                    let searchKeywordLower = this.searchKeyword && this.objectName == 'Case' ? this.searchKeyword : this.searchKeyword ? this.searchKeyword.toLowerCase() : null;
                    let extraFieldsArray = this.extraFields != null ? this.extraFields.split(",") : [];
                    let extraFieldsMaxLength = Math.min(3, extraFieldsArray.length);

                    result.forEach(function(record) {
                        record.label = record[fieldName];
                        if (searchKeywordLower != null) {
                            let indexOfSubstring = record.label.toLowerCase().indexOf(searchKeywordLower);
                            if (indexOfSubstring !== -1) {
                                record.formattedLabel = record.label.substring(0, indexOfSubstring)
                                    + '<b>' + record.label.substring(indexOfSubstring, indexOfSubstring + searchKeywordLower.length) + '</b>'
                                    + record.label.substring(indexOfSubstring + searchKeywordLower.length);
                            } else {
                                record.formattedLabel = record.label;
                            }
                        }
                        let valuesArr = [];
                        for (let i=0; i<extraFieldsMaxLength; i++) {
                            let extraFieldName = extraFieldsArray[i].trim();
                            let extraFieldNames = (typeof extraFieldName !== "undefined") ? extraFieldName.split('.') : [];

                            let crossObjectFieldValue = record;
                            while (extraFieldNames.length != 0) {
                                crossObjectFieldValue = crossObjectFieldValue[extraFieldNames.splice(0,1)];
                            }
                            if (typeof crossObjectFieldValue !== "undefined") valuesArr.push(crossObjectFieldValue);
                        }
                        if (valuesArr.length !== 0) {
                            record.additionalValues = valuesArr.join(' • ');
                        }
                    });
                    this.recordsList = result;
                    this.showSpinner = false;
                    if (setSelectedRecord) {
                        this.selectedRecord = this.recordsList[0];
                    }
                    console.log(result);
                })
                .catch(error => {
                    this.showSpinner = false;
                    console.log(error);
                });
        } else {
            this.recordsList = [];
        }
    }

    selectRecord(event) {
        console.log('aptsLwcCustomLookup--'+event.detail);
        this.selectedRecord = event.detail;
    }

    removeSelectedRecord() {
        this.selectedRecord = {};
        this.recordsList = [];
        this.prepopulateRecordId = null;
        this.searchKeyword = null;
        const selectedRecordEvent = new CustomEvent("removeselected", {
          detail: "Remove Selected"
        });
        this.dispatchEvent(selectedRecordEvent);        
    }
}