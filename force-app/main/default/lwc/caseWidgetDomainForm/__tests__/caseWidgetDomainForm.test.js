import { createElement } from 'lwc';
import CaseWidgetDomainForm from 'c/caseWidgetDomainForm';
import saveDomain from '@salesforce/apex/CaseWidgetDomainService.saveDomain';
import validateDomainUniqueness from '@salesforce/apex/CaseWidgetDomainService.validateDomainUniqueness';

jest.mock(
    '@salesforce/apex/CaseWidgetDomainService.saveDomain',
    () => ({ default: jest.fn() }),
    { virtual: true }
);
jest.mock(
    '@salesforce/apex/CaseWidgetDomainService.validateDomainUniqueness',
    () => ({ default: jest.fn() }),
    { virtual: true }
);

const MOCK_DOMAIN_DATA = {
    domain: {
        Id: 'a01',
        Name: 'Test',
        Domain__c: 'test.com',
        Active__c: true,
        Notes__c: ''
    },
    config: {
        Id: 'b01',
        Recaptcha_Site_Key__c: 'site-key',
        Modal_Title__c: 'Report an issue',
        Modal_Description__c: 'Describe the issue',
        Success_Message__c: 'Thank you',
        Loading_Message__c: 'Sending...',
        Auto_Close_Seconds__c: 8,
        Recaptcha_Min_Score__c: 0.5,
        Msg_Email_Required__c: 'Email required',
        Msg_Email_Invalid__c: 'Invalid email',
        Msg_Subject_Required__c: 'Subject required',
        Msg_Description_Required__c: 'Description required'
    },
    hasSecretKey: true,
    caseTypes: [
        { Id: 'c01', Value__c: 'Bug', Label__c: 'Report a bug', Sort_Order__c: 0, Active__c: true }
    ]
};

afterEach(() => {
    while (document.body.firstChild) {
        document.body.removeChild(document.body.firstChild);
    }
    jest.clearAllMocks();
});

describe('caseWidgetDomainForm', () => {
    it('renders in create mode with empty form', () => {
        const el = createElement('c-case-widget-domain-form', { is: CaseWidgetDomainForm });
        document.body.appendChild(el);
        return Promise.resolve().then(() => {
            const header = el.shadowRoot.querySelector('lightning-modal-header');
            expect(header.label).toBe('New Domain');
        });
    });

    it('renders in edit mode with domain data', () => {
        const el = createElement('c-case-widget-domain-form', { is: CaseWidgetDomainForm });
        el.domainData = MOCK_DOMAIN_DATA;
        document.body.appendChild(el);
        return Promise.resolve().then(() => {
            const header = el.shadowRoot.querySelector('lightning-modal-header');
            expect(header.label).toBe('Edit Domain');
        });
    });

    it('shows secret key as password type by default', () => {
        const el = createElement('c-case-widget-domain-form', { is: CaseWidgetDomainForm });
        el.domainData = MOCK_DOMAIN_DATA;
        document.body.appendChild(el);
        return Promise.resolve().then(() => {
            const secretInput = el.shadowRoot.querySelector('lightning-input[data-field="Recaptcha_Secret_Key__c"]');
            expect(secretInput.type).toBe('password');
        });
    });

    it('calls saveDomain on save click with valid form', async () => {
        saveDomain.mockResolvedValue('new-id');
        const el = createElement('c-case-widget-domain-form', { is: CaseWidgetDomainForm });
        el.domainData = MOCK_DOMAIN_DATA;
        document.body.appendChild(el);

        await Promise.resolve();

        const inputs = el.shadowRoot.querySelectorAll('lightning-input, lightning-textarea');
        inputs.forEach(input => {
            jest.spyOn(input, 'reportValidity').mockReturnValue(true);
        });

        const saveBtn = el.shadowRoot.querySelector('lightning-button[label="Save"]');
        saveBtn.dispatchEvent(new CustomEvent('click'));

        await Promise.resolve();
        expect(saveDomain).toHaveBeenCalled();
    });
});
