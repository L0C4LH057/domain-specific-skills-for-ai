# Production AI Architecture Reference

## The Production AI System Stack

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  PRESENTATION LAYER                                                         │
│  Web UI / Mobile App / API / Slack Bot / Voice Interface                    │
├─────────────────────────────────────────────────────────────────────────────┤
│  GATEWAY LAYER                                                              │
│  Auth → Rate Limiting → Input Validation → Content Filtering → Routing     │
├─────────────────────────────────────────────────────────────────────────────┤
│  ORCHESTRATION LAYER                                                        │
│  LangGraph / CrewAI / Custom Orchestrator / Workflow Engine                 │
├──────────────────────────────────────┬──────────────────────────────────────┤
│  INTELLIGENCE LAYER                  │  RETRIEVAL LAYER                    │
│  LLM API (Claude/GPT/Gemini/OSS)     │  Vector DB + BM25 + Re-ranker       │
│  Prompt Templates (versioned)         │  Document Store + Metadata Filter   │
│  Tool Definitions                     │  Knowledge Graph (optional)         │
├──────────────────────────────────────┴──────────────────────────────────────┤
│  DATA LAYER                                                                 │
│  Conversation Store | User Profiles | Session State | Audit Logs            │
├─────────────────────────────────────────────────────────────────────────────┤
│  OBSERVABILITY LAYER (cross-cutting)                                        │
│  Tracing | Logging | Metrics | Alerting | Evals | Cost Tracking             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Scaffolding Priorities by System Type

### 1. Simple Q&A / Chatbot
```
Priority order:
1. System prompt quality (defines the entire experience)
2. Context compression (conversation history management)
3. Output format consistency
4. Fallback handling (when model refuses or fails)
5. Logging (you need to see what's happening)
```

### 2. RAG Application
```
Priority order:
1. Chunking strategy (most impactful RAG variable)
2. Embedding model selection
3. Hybrid retrieval (dense + sparse)
4. Re-ranking pipeline
5. Context injection format
6. Groundedness verification layer
7. Indexing pipeline (batch + real-time updates)
```

### 3. Agentic System
```
Priority order:
1. State schema design (what does the agent need to track?)
2. Tool design and error handling
3. Termination conditions (when is the task done?)
4. Human-in-the-loop gates (where must humans approve?)
5. Retry and recovery logic
6. Observability (trace every action)
7. Safety guardrails (what actions are prohibited?)
```

### 4. Multi-Agent System
```
Priority order:
1. Agent specialization (what is each agent's exclusive domain?)
2. Communication protocol (how do agents share info?)
3. Conflict resolution (what if agents disagree?)
4. Shared state management
5. Latency optimization (parallel vs sequential execution)
6. Cost allocation (which tasks go to cheap vs expensive agents?)
```

---

## The AI System Design Checklist

### Before Building
- [ ] Define success criteria with measurable metrics
- [ ] Identify the 10 most common user inputs (build for these first)
- [ ] Identify the 5 most dangerous user inputs (build guardrails)
- [ ] Decide: RAG, fine-tuning, prompting, or combination?
- [ ] Decide: single LLM or multi-model architecture?
- [ ] Estimate token costs at target scale (see token-efficiency.md)
- [ ] Choose observability stack before writing any LLM code

### During Building
- [ ] Version control every prompt change
- [ ] Write evals before writing prompts (TDD for AI)
- [ ] Test with adversarial inputs from day 1
- [ ] Mock LLM API calls in unit tests (don't hit real API in CI)
- [ ] Log every LLM request/response in development

### Before Shipping
- [ ] Eval suite passes at threshold (define the threshold!)
- [ ] Latency p95 < acceptable limit (usually 3–5s for user-facing)
- [ ] Cost per request within budget
- [ ] Graceful degradation when LLM API is down
- [ ] Rate limiting in place (prevent prompt injection DoS)
- [ ] PII detection / scrubbing if handling sensitive data
- [ ] Content filter for outputs (especially for public-facing apps)

---

## Observability Stack

### LangSmith (LangChain's tracing platform)
```python
import os
os.environ["LANGCHAIN_TRACING_V2"] = "true"
os.environ["LANGCHAIN_API_KEY"] = "your-api-key"
os.environ["LANGCHAIN_PROJECT"] = "my-project"

# All LangChain/LangGraph calls now auto-traced
# View traces at smith.langchain.com
```

### Helicone (Multi-provider proxy with analytics)
```python
import anthropic

client = anthropic.Anthropic(
    base_url="https://anthropic.helicone.ai",
    default_headers={
        "Helicone-Auth": f"Bearer {helicone_api_key}",
        "Helicone-User-Id": user_id,  # Track per-user costs
        "Helicone-Session-Id": session_id,
    }
)
# Full cost analytics, latency charts, prompt versioning at helicone.ai
```

### Custom OpenTelemetry Integration
```python
from opentelemetry import trace
from opentelemetry.sdk.trace import TracerProvider

tracer = trace.get_tracer(__name__)

def call_llm_with_tracing(prompt: str, **kwargs):
    with tracer.start_as_current_span("llm_call") as span:
        span.set_attribute("model", kwargs.get("model"))
        span.set_attribute("input_preview", prompt[:200])
        
        response = llm.invoke(prompt, **kwargs)
        
        span.set_attribute("input_tokens", response.usage.input_tokens)
        span.set_attribute("output_tokens", response.usage.output_tokens)
        span.set_attribute("cost_usd", calculate_cost(response))
        
        return response
```

### Key Metrics to Monitor
```
System Health:
  - request_rate (req/min)
  - error_rate (% errors)
  - p50/p95/p99 latency
  - LLM API uptime

AI Quality:
  - eval_score (weekly automated evals)
  - user_thumbs_up_rate
  - hallucination_rate (if measured)
  - retrieval_precision (for RAG)

Cost:
  - cost_per_request
  - cost_per_user_per_day
  - cache_hit_rate
  - tokens_per_request (input + output)
```

---

## Deployment Patterns

### Pattern 1: Serverless (AWS Lambda / GCP Cloud Functions)
Best for: Low-traffic, bursty workloads; simple chatbots; cost-sensitive
```python
# handler.py (AWS Lambda)
def lambda_handler(event, context):
    user_message = event["body"]["message"]
    response = ai_pipeline.run(user_message)
    return {"statusCode": 200, "body": response}
```
Considerations: Cold start latency (3–5s); no persistent state; 15min max execution time

### Pattern 2: Container (Docker + Kubernetes)
Best for: Production scale; stateful agents; complex pipelines
```dockerfile
FROM python:3.11-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY . .
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000", "--workers", "4"]
```

### Pattern 3: Edge Deployment
Best for: Low-latency requirements; offline capability; privacy-sensitive
- Use small quantized models (Llama 3.2 1B/3B, Phi-3 mini)
- Frameworks: Ollama, llama.cpp, MLC-LLM, ONNX Runtime
- Hardware: Apple Silicon (MLX), NVIDIA Jetson, Qualcomm AI

### Pattern 4: Hybrid (Edge + Cloud)
- Route simple queries to on-device model
- Route complex queries to cloud model
- Use classifier to determine routing
- Best: privacy + cost + capability trade-off

---

## Security Architecture

### Input Sanitization
```python
def sanitize_user_input(user_input: str) -> str:
    """Prevent prompt injection and enforce input constraints."""
    # Length limit
    if len(user_input) > 10000:
        raise ValueError("Input too long")
    
    # Detect obvious injection attempts
    injection_patterns = [
        "ignore previous instructions",
        "system prompt",
        "disregard your",
        "you are now",
    ]
    lower_input = user_input.lower()
    for pattern in injection_patterns:
        if pattern in lower_input:
            return "[INPUT FLAGGED: Potential prompt injection detected]"
    
    return user_input

def build_safe_prompt(system: str, user_input: str) -> list:
    """Always separate system and user content structurally."""
    return [
        {"role": "system", "content": system},
        {"role": "user", "content": f"<user_input>{sanitize_user_input(user_input)}</user_input>"}
    ]
```

### PII Handling
```python
import presidio_analyzer

analyzer = presidio_analyzer.AnalyzerEngine()

def detect_and_redact_pii(text: str) -> tuple[str, list]:
    results = analyzer.analyze(text=text, language="en")
    redacted = presidio_anonymizer.AnonymizerEngine().anonymize(text=text, analyzer_results=results)
    return redacted.text, results  # Return redacted text + what was found

# Before sending to LLM:
safe_input, pii_found = detect_and_redact_pii(user_message)
if pii_found:
    log_pii_detection(user_id, pii_found)  # Alert / audit
```

### Output Guardrails
```python
from anthropic import Anthropic

def apply_output_guardrails(ai_response: str, context: dict) -> str:
    """Layer of safety checks on generated output."""
    
    # 1. Content policy check (using a classifier model)
    safety_check = safety_classifier.classify(ai_response)
    if safety_check["is_harmful"]:
        return SAFE_FALLBACK_RESPONSE
    
    # 2. Hallucination check for RAG responses
    if context.get("retrieved_docs"):
        grounded = groundedness_checker.check(ai_response, context["retrieved_docs"])
        if grounded["score"] < 0.7:
            return f"{ai_response}\n\n⚠️ Note: Parts of this answer could not be verified against available sources."
    
    # 3. Confidentiality check (don't leak system prompt content)
    if "system prompt" in ai_response.lower() or "instructions" in ai_response.lower():
        ai_response = redact_system_prompt_leakage(ai_response)
    
    return ai_response
```

---

## Evaluation Framework (Full)

```python
# evals/eval_suite.py
from braintrust import Eval

def run_eval_suite(pipeline, eval_dataset):
    return Eval(
        name="production-eval",
        data=eval_dataset,
        task=lambda input: pipeline.run(input["question"]),
        scores=[
            # Exact match for factual tasks
            lambda output, expected: output.strip() == expected.strip(),
            
            # LLM-as-judge for quality
            LLMJudge(
                prompt="Rate the quality of this answer 0-1: {output}",
                model="claude-haiku-4-5"
            ),
            
            # Custom metrics
            GroundednessScore(context=input["retrieved_docs"]),
            LatencyScore(threshold_ms=3000),
        ]
    )
```

---

## References

- **"MLOps: Machine Learning Operations"** — Practical MLOps, O'Reilly, 2022
- **LangSmith Docs** — https://docs.smith.langchain.com/
- **Helicone Docs** — https://docs.helicone.ai/
- **Braintrust Evals** — https://www.braintrust.dev/
- **"OWASP Top 10 for LLM Applications"** — OWASP Foundation, 2023 — https://owasp.org/www-project-top-10-for-large-language-model-applications/
- **"Patterns for Building LLM-Based Systems & Products"** — Eugene Yan, 2023 — https://eugeneyan.com/writing/llm-patterns/
- **"Building Production LLM Apps"** — Hamel Husain, 2024
- **Presidio (PII Detection)** — Microsoft — https://github.com/microsoft/presidio
- **"Hidden Technical Debt in Machine Learning Systems"** — Sculley et al., Google, 2015
