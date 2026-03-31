import { api, track } from 'lwc';
import LightningModal from 'lightning/modal';
import saveDomain from '@salesforce/apex/CaseWidgetDomainService.saveDomain';
import validateDomainUniqueness from '@salesforce/apex/CaseWidgetDomainService.validateDomainUniqueness';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

const DEFAULT_CONFIG = {
    Recaptcha_Site_Key__c: '',
    Recaptcha_Secret_Key__c: '',
    Modal_Title__c: 'Report an issue',
    Modal_Description__c: '',
    Success_Message__c: 'Thank you for your message.',
    Loading_Message__c: 'Sending your request...',
    Auto_Close_Seconds__c: 8,
    Recaptcha_Min_Score__c: 0.50,
    Msg_Email_Required__c: 'Email is required',
    Msg_Email_Invalid__c: 'Enter a valid email',
    Msg_Subject_Required__c: 'Subject is required',
    Msg_Description_Required__c: 'Description is required'
};

export default class CaseWidgetDomainForm extends LightningModal {

    @api domainData; // DomainWrapper from getDomains — null for create

    @track domain = { Name: '', Domain__c: '', Active__c: true, Notes__c: '' };
    @track config = { ...DEFAULT_CONFIG };
    @track caseTypes = [];
    @track domainError = '';
    @track isSaving = false;
    @track secretKeyVisible = false;
    @track secretKeyRequired = true;

    // ─── Lifecycle ────────────────────────────────────────────────────────────

    connectedCallback() {
        if (this.domainData) {
            this.domain = { ...this.domainData.domain };
            if (this.domainData.config) {
                // Never populate the secret key in the form — show placeholder instead
                const cfg = { ...this.domainData.config };
                cfg.Recaptcha_Secret_Key__c = '';
                this.config = cfg;
                // If a secret key exists, not required to re-enter
                this.secretKeyRequired = !this.domainData.hasSecretKey;
            }
            this.caseTypes = this.domainData.caseTypes ? [...this.domainData.caseTypes] : [];
        }
    }

    // ─── Getters ──────────────────────────────────────────────────────────────

    get modalTitle() {
        return this.domainData ? 'Edit Domain' : 'New Domain';
    }

    get secretKeyInputType() {
        return this.secretKeyVisible ? 'text' : 'password';
    }

    get secretKeyIcon() {
        return this.secretKeyVisible ? 'utility:hide' : 'utility:preview';
    }

    get secretKeyPlaceholder() {
        return this.domainData && this.domainData.hasSecretKey
            ? '●●●●●●●●●●●●●●●● (configured)'
            : '';
    }

    // ─── Field Change Handlers ────────────────────────────────────────────────

    handleChange(event) {
        const field = event.currentTarget.dataset.field;
        const obj = event.currentTarget.dataset.obj;
        const value = event.target.value;
        if (obj === 'domain') {
            this.domain = { ...this.domain, [field]: value };
        } else if (obj === 'config') {
            this.config = { ...this.config, [field]: value };
        }
    }

    handleActiveToggle(event) {
        this.domain = { ...this.domain, Active__c: event.target.checked };
    }

    handleCaseTypesChange(event) {
        this.caseTypes = event.detail.caseTypes;
    }

    handleToggleSecretKey() {
        this.secretKeyVisible = !this.secretKeyVisible;
    }

    // ─── Domain Uniqueness Validation ─────────────────────────────────────────

    async handleDomainBlur() {
        const domainValue = this.domain.Domain__c;
        if (!domainValue || !domainValue.trim()) return;

        try {
            const isUnique = await validateDomainUniqueness({
                domain: domainValue,
                domainId: this.domain.Id || null
            });
            this.domainError = isUnique ? '' : 'This domain is already registered.';
        } catch {
            // Non-blocking — server error during validation
        }
    }

    // ─── Save ─────────────────────────────────────────────────────────────────

    async handleSave() {
        // 1. Validate all lightning-input fields
        const inputs = [...this.template.querySelectorAll('lightning-input, lightning-textarea')];
        const allValid = inputs.reduce((acc, input) => input.reportValidity() && acc, true);
        if (!allValid) return;

        // 2. Check domain uniqueness error
        if (this.domainError) return;

        // 3. Validate case types subcomponent
        const caseTypeEditor = this.template.querySelector('c-case-widget-case-type-editor');
        if (caseTypeEditor) {
            const caseTypesValidation = caseTypeEditor.validate();
            if (!caseTypesValidation.valid) return;
            this.caseTypes = caseTypeEditor.getValue();
        }

        this.isSaving = true;
        try {
            const domainId = await saveDomain({
                domainJson: JSON.stringify(this.domain),
                configJson: JSON.stringify(this.config),
                caseTypesJson: JSON.stringify(this.caseTypes)
            });
            this.close({ saved: true, domainId });
        } catch (error) {
            const message = error.body?.message || 'An unexpected error occurred.';
            this.dispatchEvent(new ShowToastEvent({
                title: 'Error saving domain',
                message,
                variant: 'error'
            }));
        } finally {
            this.isSaving = false;
        }
    }

    handleCancel() {
        this.close({ saved: false });
    }
}
