import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getDomains from '@salesforce/apex/CaseWidgetDomainService.getDomains';
import CaseWidgetDomainForm from 'c/caseWidgetDomainForm';

const STATE = {
    LOADING: 'loading',
    EMPTY: 'empty',
    LIST: 'list',
    ERROR: 'error'
};

export default class CaseWidgetAdmin extends LightningElement {

    @track domains = [];
    @track state = STATE.LOADING;
    @track errorMessage = '';

    // ─── Lifecycle ────────────────────────────────────────────────────────────

    connectedCallback() {
        this.loadDomains();
    }

    // ─── State Getters ────────────────────────────────────────────────────────

    get isLoading() { return this.state === STATE.LOADING; }
    get isError()   { return this.state === STATE.ERROR; }
    get isEmpty()   { return this.state === STATE.EMPTY; }
    get isList()    { return this.state === STATE.LIST; }

    // ─── Data Loading ─────────────────────────────────────────────────────────

    async loadDomains() {
        this.state = STATE.LOADING;
        try {
            this.domains = await getDomains();
            this.state = this.domains.length === 0 ? STATE.EMPTY : STATE.LIST;
        } catch (error) {
            this.errorMessage = error?.body?.message || 'Failed to load domains.';
            this.state = STATE.ERROR;
        }
    }

    // ─── Domain Form (create) ─────────────────────────────────────────────────

    async handleNewDomain() {
        const result = await CaseWidgetDomainForm.open({
            size: 'large',
            domainData: null
        });
        this._handleFormResult(result, 'Domain created successfully.');
    }

    // ─── Domain Form (edit) ───────────────────────────────────────────────────

    async handleEditDomain(event) {
        const domainId = event.detail.domainId;
        const wrapper = this.domains.find(w => w.domain.Id === domainId);
        if (!wrapper) return;

        const result = await CaseWidgetDomainForm.open({
            size: 'large',
            domainData: wrapper
        });
        this._handleFormResult(result, 'Domain updated successfully.');
    }

    // ─── Private ──────────────────────────────────────────────────────────────

    _handleFormResult(result, successMessage) {
        if (result && result.saved) {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Success',
                message: successMessage,
                variant: 'success'
            }));
            this.loadDomains();
        }
    }
}
