# Domain AI Integration Playbooks

## How to Use This Reference

Each domain has specific requirements, constraints, and high-value use cases. When integrating AI into a new domain:
1. Read the domain section
2. Apply the architecture recommendations
3. Respect the compliance constraints
4. Target the high-ROI use cases first

---

## Healthcare AI

### High-Value Use Cases
- Clinical documentation (SOAP notes, discharge summaries)
- Medical coding (ICD-10, CPT) assistance
- Patient triage chatbot (symptom collection, NOT diagnosis)
- Drug interaction checking (retrieval from pharmacopeia)
- Radiology/pathology report summarization
- Patient education material generation
- Prior authorization letter drafting
- Clinical trial eligibility matching

### Architecture Recommendations
```
RAG over medical knowledge bases:
  - PubMed abstracts (open access)
  - Clinical guidelines (NICE, WHO, CDC)
  - Hospital formulary (proprietary — self-hosted only)
  - EHR documentation (strictly on-premises)

Model selection:
  - General: Claude Sonnet or GPT-4o (strong medical knowledge)
  - Specialized: Med-PaLM 2 (Google), BioGPT, ClinicalBERT (for NLP tasks)
  - Fine-tuning: Llama fine-tuned on MIMIC-III/IV, PubMed for clinical tasks

Deployment: ON-PREMISES ONLY for anything involving PHI
```

### Compliance Constraints
- **Nigeria**: NDPR (Nigeria Data Protection Regulation) for patient data
- **US**: HIPAA — PHI cannot leave covered entity infrastructure; Business Associate Agreements required with any cloud vendor
- **UK**: NHS Data Security Standards; GDPR
- **Kenya**: Data Protection Act 2019
- **South Africa**: POPIA (Protection of Personal Information Act)

**Critical rule**: AI MUST NOT diagnose. Always include: "This is not medical advice. Consult a qualified healthcare professional."

### Recommended Stack
```python
# Healthcare RAG — on-premises deployment
from langchain_community.vectorstores import Chroma  # Local vector DB
from ollama import Ollama  # Local LLM (no data leaves premises)

llm = Ollama(model="medllama2")  # Or fine-tuned Llama on medical data
vectorstore = Chroma(persist_directory="/secure/data/medical-kb")

# MANDATORY: PHI scrubbing before any LLM call
def process_clinical_note(note: str) -> str:
    scrubbed = pii_scrubber.redact(note, categories=["PHI", "PII"])
    return rag_chain.invoke(scrubbed)
```

---

## Finance & Fintech AI

### High-Value Use Cases
- Automated financial report analysis
- Credit risk assessment support (NOT automated decisions)
- Transaction categorization and enrichment
- Fraud detection alert triage
- Regulatory compliance document Q&A
- Investment research summarization
- Customer financial advice chatbot (KYC-aware)
- Automated reconciliation anomaly detection
- AML (Anti-Money Laundering) narrative generation

### Architecture Recommendations
```
Data sources to index:
  - Annual reports, 10-K/10-Q filings (SEC EDGAR, NSE, JSE)
  - Central bank policy documents
  - Internal credit policies
  - Transaction history (structured data — use SQL tools, not RAG)

Key pattern: Hybrid RAG + Structured Data Tools
  - Unstructured knowledge → RAG (regulatory docs, policies)
  - Structured data → SQL tool calling (transactions, accounts)

Never RAG over transaction data — use SQL/API tools instead.
```

### Critical Constraints
- **Explainability**: Any AI-assisted financial decision MUST be explainable (EU AI Act, Nigerian CBN guidelines)
- **Fair lending**: AI must not discriminate on protected characteristics (US ECOA, FCRA)
- **Data residency**: CBN (Nigeria) mandates financial data stays in Nigeria for licensed institutions
- **Human oversight**: No fully automated high-value financial decisions

### Code Pattern — Financial Document QA
```python
from langchain.agents import create_sql_agent
from langchain_community.agent_toolkits import SQLDatabaseToolkit

# Structured data: SQL agent
db_tool = SQLDatabaseToolkit(db=financial_database, llm=llm)
sql_agent = create_sql_agent(llm, toolkit=db_tool, verbose=True)

# Unstructured: RAG
policy_rag = build_rag_chain(vectorstore=compliance_docs_vectorstore)

# Router: decide which to use
def financial_assistant(query: str) -> str:
    if any(kw in query.lower() for kw in ["transaction", "balance", "account", "amount"]):
        return sql_agent.run(query)
    else:
        return policy_rag.invoke(query)
```

---

## Education / EdTech AI

### High-Value Use Cases
- Personalized tutoring and Socratic Q&A
- Assignment feedback and grading assistance
- Automated quiz and assessment generation
- Curriculum adaptation for learning differences
- Student progress report generation
- Course content summarization
- Language learning conversation practice
- Research assistance and source verification

### Architecture Recommendations
```
Pedagogical prompting pattern (Socratic):
  DO NOT give direct answers. Guide the student to discover the answer.
  
System prompt template:
  "You are a patient tutor. When a student asks a question:
   1. Ask a guiding question to activate their prior knowledge
   2. If they're stuck, give a hint, not the answer
   3. When they get it right, affirm and extend their understanding
   4. Never provide complete answers to homework problems directly"

Adaptive difficulty:
  - Track student performance in session state
  - Adjust question difficulty dynamically
  - Route struggling students to simpler explanations
```

### Age-Appropriate Guardrails
```python
def apply_age_guardrails(content: str, user_age: int) -> str:
    if user_age < 13:
        guardrail_prompt = "Respond only with age-appropriate content for children under 13."
    elif user_age < 18:
        guardrail_prompt = "Ensure content is appropriate for teenagers."
    else:
        guardrail_prompt = ""
    
    # Add guardrail to system prompt
    return build_system_prompt(base_prompt + guardrail_prompt)
```

### Nigeria-Specific Context
- JAMB curriculum coverage (WAEC, NECO alignment)
- Local language support: Yoruba, Igbo, Hausa summaries for accessibility
- Low-bandwidth mode: Compress responses for 2G/3G connectivity

---

## Legal AI

### High-Value Use Cases
- Contract review and risk identification
- Legal research and case law retrieval
- Document summarization (briefs, pleadings)
- Due diligence document processing
- Compliance gap analysis
- Regulatory change monitoring
- Standard clause extraction and comparison
- Draft generation for standard agreements (NDAs, service agreements)

### Architecture Recommendations
```
RAG over legal corpus:
  - Case law databases (LawPavilion for Nigeria, Westlaw, LexisNexis)
  - Regulatory databases (FIRS circulars, CBN guidelines, SEC rules)
  - Internal precedent library
  - Standard contract templates

Specialized legal models:
  - Harvey AI (proprietary, enterprise legal)
  - SaulLM-7B (open source, legal fine-tuned)
  - Claude with legal-specific system prompts (strong performance)
```

### Critical Constraint
**MANDATORY disclaimer on all legal AI outputs**:
```
LEGAL AI DISCLAIMER:
This analysis is AI-generated and does not constitute legal advice. 
It has not been reviewed by a licensed attorney and may contain errors.
Do not rely on this for legal decisions without consulting qualified legal counsel.
```

---

## E-commerce / Retail AI

### High-Value Use Cases
- Product recommendation engine
- Customer service chatbot (order status, returns, FAQs)
- Product description generation
- Review analysis and response
- Inventory demand forecasting (ML, not just LLM)
- Search relevance improvement
- Price optimization (ML)
- Visual search (multimodal LLM)

### Architecture Patterns
```
Product catalog RAG:
  - Chunk: One chunk per product (product_id, name, description, specs, price)
  - Metadata filters: category, price_range, in_stock, brand
  - Hybrid search: semantic + exact product code match

Customer service pattern:
  - Intent classification (fast, cheap model) → route to handler
  - Order status: Tool call to order management API
  - Return request: Tool call + conditional workflow
  - General FAQ: RAG over support documentation
  - Complex/sensitive: Escalate to human agent

System prompt for customer service:
  "You are [Brand Name] customer support.
   Always be helpful, empathetic, and solution-focused.
   You have access to order management tools.
   For returns, follow this process: [steps]
   If you cannot resolve an issue in 3 turns, offer human escalation."
```

---

## Transportation & Logistics AI

### High-Value Use Cases
- Route optimization with natural language interface
- Driver communication and dispatch assistance
- Freight document processing (bills of lading, customs)
- Predictive maintenance report analysis
- Customer shipment inquiry chatbot
- Regulatory compliance Q&A (FMCSA, ECOWAS transport regulations)
- Incident report generation

### Architecture for Africa-Specific Deployment
```
Considerations for Nigerian/African logistics:
  - Offline capability: Agents often have poor connectivity
  - SMS/USSD interface: Not all drivers use smartphones
  - Local language: Pidgin English, Hausa route instructions
  - WhatsApp integration: Primary business communication channel in Nigeria

WhatsApp Business API integration:
  Twilio / Meta Cloud API → Webhook → LangGraph workflow → Reply
```

---

## Startup AI Integration

### The Startup AI Hierarchy of Needs
```
Level 1 (Immediate ROI):
  - Customer support chatbot (reduce support ticket volume)
  - Lead qualification chatbot (filter inbound leads)
  - Content generation (marketing copy, social media)

Level 2 (Growth):
  - Personalization engine
  - User onboarding automation
  - Churn prediction + intervention

Level 3 (Scale):
  - Internal knowledge base Q&A (reduce onboarding time)
  - Code review assistance
  - Data analysis automation

Start at Level 1. Validate ROI. Then invest in Level 2.
```

### Startup Budget-Conscious Stack
```
Free / Low-cost:
  - LLM: Claude Haiku (cheapest capable model) or GPT-4o-mini
  - Vector DB: Chroma (self-hosted, free) or Pinecone free tier
  - Framework: LangChain (free)
  - Hosting: Railway, Render, or Fly.io (~$5–20/month)
  - Monitoring: LangSmith free tier (up to 5,000 traces/month)
  - Embeddings: text-embedding-3-small ($0.02/1M tokens)

Total cost for MVP: $20–100/month at <1,000 users
```

---

## References

- **"AI in Healthcare: Navigating the Regulatory Landscape"** — FDA AI/ML Action Plan, 2021
- **"Responsible AI in Financial Services"** — FSCA South Africa / FCA UK Guidance
- **"Generative AI in Education: Opportunities and Challenges"** — UNESCO, 2023
- **Nigeria NDPR (Data Protection Regulation)** — NITDA, 2019
- **"The Role of AI in African Agriculture"** — CGIAR, 2023
- **OWASP LLM Application Security** — https://owasp.org/www-project-top-10-for-large-language-model-applications/
- **"Enterprise AI Adoption Patterns"** — McKinsey Global Institute, 2023
- **LawPavilion (Nigerian Legal Database)** — https://lawpavilion.com/
