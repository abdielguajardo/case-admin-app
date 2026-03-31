import { createElement } from 'lwc';
import CaseWidgetCaseTypeEditor from 'c/caseWidgetCaseTypeEditor';

const MOCK_TYPES = [
    { Id: 'a01', Value__c: 'Bug', Label__c: 'Report a bug', Sort_Order__c: 0, Active__c: true },
    { Id: 'a02', Value__c: 'Question', Label__c: 'I have a question', Sort_Order__c: 1, Active__c: true }
];

function createElement_() {
    const el = createElement('c-case-widget-case-type-editor', {
        is: CaseWidgetCaseTypeEditor
    });
    document.body.appendChild(el);
    return el;
}

afterEach(() => {
    while (document.body.firstChild) {
        document.body.removeChild(document.body.firstChild);
    }
});

describe('caseWidgetCaseTypeEditor', () => {
    it('renders case types passed via @api', () => {
        const el = createElement_();
        el.caseTypes = MOCK_TYPES;
        return Promise.resolve().then(() => {
            const rows = el.shadowRoot.querySelectorAll('.type-row');
            expect(rows.length).toBe(2);
        });
    });

    it('shows empty message when no types', () => {
        const el = createElement_();
        el.caseTypes = [];
        return Promise.resolve().then(() => {
            const empty = el.shadowRoot.querySelector('p.slds-text-color_weak');
            expect(empty).not.toBeNull();
        });
    });

    it('shows add form on button click', () => {
        const el = createElement_();
        el.caseTypes = [];
        return Promise.resolve().then(() => {
            const btn = el.shadowRoot.querySelector('lightning-button');
            btn.dispatchEvent(new CustomEvent('click'));
            return Promise.resolve();
        }).then(() => {
            const addForm = el.shadowRoot.querySelector('.add-form');
            expect(addForm).not.toBeNull();
        });
    });

    it('getValue returns correct structure', () => {
        const el = createElement_();
        el.caseTypes = MOCK_TYPES;
        return Promise.resolve().then(() => {
            const value = el.getValue();
            expect(value.length).toBe(2);
            expect(value[0].Sort_Order__c).toBe(0);
            expect(value[1].Sort_Order__c).toBe(1);
        });
    });

    it('validate returns invalid when no active types', () => {
        const el = createElement_();
        el.caseTypes = [
            { Id: 'a01', Value__c: 'Bug', Label__c: 'Report a bug', Sort_Order__c: 0, Active__c: false }
        ];
        return Promise.resolve().then(() => {
            const result = el.validate();
            expect(result.valid).toBe(false);
        });
    });

    it('validate returns valid when at least one active type', () => {
        const el = createElement_();
        el.caseTypes = MOCK_TYPES;
        return Promise.resolve().then(() => {
            const result = el.validate();
            expect(result.valid).toBe(true);
        });
    });
});
