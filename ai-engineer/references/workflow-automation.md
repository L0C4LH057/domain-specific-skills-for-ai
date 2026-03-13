# AI Workflow Automation Reference

## What Is AI Workflow Automation?

AI workflow automation combines the decision-making power of LLMs with deterministic process orchestration to automate complex, multi-step tasks that previously required human judgment at every step.

```
Traditional Automation:
  Rule-based → brittle → breaks on edge cases → requires constant maintenance

AI Workflow Automation:
  LLM-guided decisions + deterministic tools → handles edge cases → generalizes
```

**The sweet spot**: Tasks that are too varied for pure rule-based automation, but too repetitive/high-volume for humans to do efficiently.

---

## Workflow Design Patterns

### Pattern 1: Linear Pipeline
Sequential stages, each passing output to the next.
```
Input → Classify → Extract → Transform → Validate → Output

Use when: Steps are always the same; no branching needed
Examples: Document processing, data enrichment, report generation
```

```python
from langchain_core.runnables import RunnableSequence

pipeline = (
    classify_intent           # Stage 1: What type of document is this?
    | extract_entities        # Stage 2: Extract key data points
    | validate_and_format     # Stage 3: Validate and structure
    | generate_report         # Stage 4: Generate output
)
```

### Pattern 2: Conditional Branch
Route to different workflows based on classification.
```
Input → Classifier → [Branch A / Branch B / Branch C] → Merge → Output

Use when: Different input types need different processing
Examples: Customer support routing, document type handling
```

```python
def route_workflow(input: dict) -> str:
    intent = intent_classifier.classify(input["message"])
    routes = {
        "billing":        billing_workflow,
        "technical":      technical_workflow,
        "general":        general_workflow,
        "escalation":     human_escalation,
    }
    return routes.get(intent, general_workflow)
```

### Pattern 3: Map-Reduce
Process items in parallel; aggregate results.
```
Input List → [Item 1, Item 2, ... Item N] → Parallel Processing → Aggregate → Output

Use when: Processing many independent items (documents, records, reviews)
Examples: Bulk email analysis, document batch processing
```

```python
import asyncio

async def process_batch(items: list) -> list:
    tasks = [process_single(item) for item in items]
    results = await asyncio.gather(*tasks)  # Parallel execution
    return aggregate(results)
```

### Pattern 4: Retry + Fallback
Resilient execution with graceful degradation.
```
Try Primary → If fails → Retry (with backoff) → If still fails → Fallback → Log

Use when: LLM calls are unreliable; need production resilience
```

```python
from tenacity import retry, stop_after_attempt, wait_exponential

@retry(stop=stop_after_attempt(3), wait=wait_exponential(min=1, max=10))
async def call_primary_llm(prompt: str) -> str:
    return await primary_llm.ainvoke(prompt)

async def resilient_call(prompt: str) -> str:
    try:
        return await call_primary_llm(prompt)
    except Exception:
        # Fallback to cheaper/different model
        return await fallback_llm.ainvoke(prompt)
```

### Pattern 5: Human-in-the-Loop (HITL)
Pause workflow for human review at critical junctions.
```
Automated Steps → [PAUSE: Human Review Required] → Human Approves/Rejects → Continue/Cancel

Use when: High-stakes decisions, compliance requirements, low confidence outputs
```

```python
# LangGraph HITL pattern
from langgraph.graph import StateGraph, END
from langgraph.checkpoint.memory import MemorySaver

def needs_human_review(state: dict) -> str:
    """Route to human review if confidence is low or amount is large."""
    if state["confidence"] < 0.8 or state["amount"] > 10000:
        return "human_review"
    return "auto_approve"

workflow = StateGraph(State)
workflow.add_conditional_edges("assess", needs_human_review, {
    "human_review": "human_review_node",  # Pause here
    "auto_approve": "execute_node"
})

# Add interrupt BEFORE human_review_node
app = workflow.compile(
    checkpointer=MemorySaver(),
    interrupt_before=["human_review_node"]
)

# After human reviews and approves:
app.invoke(Command(resume={"approved": True}), config=config)
```

### Pattern 6: Streaming Pipeline
Process and respond incrementally, don't wait for full completion.
```
Input → Start processing → Stream partial results → Complete → Final result

Use when: Long-running tasks; real-time user feedback needed
Examples: Long document analysis, research workflows, code generation
```

```python
async def streaming_analysis(document: str):
    """Stream analysis results as they're generated."""
    async for chunk in analysis_chain.astream({"document": document}):
        yield chunk  # Send to client immediately

# FastAPI streaming endpoint
from fastapi.responses import StreamingResponse

@app.post("/analyze")
async def analyze_document(request: AnalysisRequest):
    return StreamingResponse(
        streaming_analysis(request.document),
        media_type="text/event-stream"
    )
```

---

## Automation Trigger Patterns

### Event-Driven Automation
```python
# Webhook-triggered workflow
@app.post("/webhook/email")
async def handle_incoming_email(email: EmailEvent):
    # Trigger AI workflow on incoming email
    task = {
        "sender": email.from_address,
        "subject": email.subject,
        "body": email.body,
        "attachments": email.attachments
    }
    result = await email_processing_workflow.ainvoke(task)
    await send_auto_reply(email.from_address, result["draft_reply"])
    await create_crm_task(result["extracted_action_items"])
```

### Scheduled Automation
```python
from apscheduler.schedulers.asyncio import AsyncIOScheduler

scheduler = AsyncIOScheduler()

@scheduler.scheduled_job('cron', hour=8, minute=0)  # Every day at 8 AM
async def daily_report_generation():
    data = await fetch_yesterday_metrics()
    report = await report_generation_workflow.ainvoke(data)
    await send_to_stakeholders(report)

@scheduler.scheduled_job('interval', hours=1)
async def monitor_and_alert():
    metrics = await get_system_metrics()
    analysis = await anomaly_detection_workflow.ainvoke(metrics)
    if analysis["anomalies_detected"]:
        await send_alert(analysis["alert_message"])
```

### Queue-Based Processing
```python
import asyncio
from asyncio import Queue

async def worker(queue: Queue, worker_id: int):
    while True:
        task = await queue.get()
        try:
            result = await ai_workflow.ainvoke(task)
            await store_result(result)
        except Exception as e:
            await handle_error(task, e)
        finally:
            queue.task_done()

async def process_batch_queue(tasks: list, num_workers: int = 5):
    queue = Queue()
    for task in tasks:
        await queue.put(task)
    
    workers = [asyncio.create_task(worker(queue, i)) for i in range(num_workers)]
    await queue.join()
    for w in workers:
        w.cancel()
```

---

## Production Workflow Best Practices

### Idempotency
Every workflow step must be safely re-executable (in case of failures):
```python
async def process_document(doc_id: str) -> dict:
    # Check if already processed
    existing = await db.get_result(doc_id)
    if existing:
        return existing  # Return cached result, don't reprocess
    
    result = await heavy_ai_workflow.ainvoke({"doc_id": doc_id})
    await db.store_result(doc_id, result)  # Cache result
    return result
```

### Dead Letter Queue
Handle permanently failed tasks:
```python
async def robust_workflow(task: dict, max_retries: int = 3):
    for attempt in range(max_retries):
        try:
            return await ai_workflow.ainvoke(task)
        except Exception as e:
            if attempt == max_retries - 1:
                # Send to dead letter queue for manual review
                await dead_letter_queue.put({
                    "task": task,
                    "error": str(e),
                    "timestamp": datetime.utcnow().isoformat()
                })
                raise
            await asyncio.sleep(2 ** attempt)  # Exponential backoff
```

### Workflow Observability
```python
import structlog

logger = structlog.get_logger()

async def traced_workflow_step(step_name: str, input: dict) -> dict:
    log = logger.bind(
        workflow_id=input["workflow_id"],
        step=step_name,
        input_preview=str(input)[:200]
    )
    log.info("step_started")
    
    start = time.perf_counter()
    try:
        result = await workflow_step.ainvoke(input)
        log.info("step_completed", 
                 duration_ms=(time.perf_counter() - start) * 1000,
                 output_preview=str(result)[:200])
        return result
    except Exception as e:
        log.error("step_failed", error=str(e), duration_ms=(time.perf_counter() - start) * 1000)
        raise
```

---

## Integration Patterns

### REST API Integration
```python
from langchain.tools import tool
import httpx

@tool
async def call_crm_api(customer_id: str, action: str, data: dict = {}) -> dict:
    """
    Interact with the CRM API.
    Actions: get_customer, update_customer, create_task, get_history
    """
    async with httpx.AsyncClient() as client:
        response = await client.post(
            f"{CRM_BASE_URL}/{action}",
            json={"customer_id": customer_id, **data},
            headers={"Authorization": f"Bearer {CRM_API_KEY}"},
            timeout=10.0
        )
        response.raise_for_status()
        return response.json()
```

### Database Integration
```python
from langchain_community.tools import QuerySQLDataBaseTool
from langchain_community.utilities import SQLDatabase

db = SQLDatabase.from_uri(DATABASE_URL)
sql_tool = QuerySQLDataBaseTool(db=db)

# Agent can now query database with natural language → SQL
agent_with_db = create_react_agent(llm, tools=[sql_tool])
result = agent_with_db.invoke({
    "input": "How many customers signed up in Lagos last month?"
})
```

### WhatsApp / Messaging Integration (Africa-specific)
```python
from fastapi import FastAPI, Request
import httpx

app = FastAPI()

@app.post("/whatsapp/webhook")
async def whatsapp_webhook(request: Request):
    data = await request.json()
    
    # Extract message
    message = data["entry"][0]["changes"][0]["value"]["messages"][0]
    from_number = message["from"]
    text = message["text"]["body"]
    
    # Run AI workflow
    response = await customer_service_agent.ainvoke({
        "user_id": from_number,
        "message": text,
        "channel": "whatsapp"
    })
    
    # Reply via WhatsApp API
    async with httpx.AsyncClient() as client:
        await client.post(
            f"https://graph.facebook.com/v18.0/{PHONE_NUMBER_ID}/messages",
            json={
                "messaging_product": "whatsapp",
                "to": from_number,
                "text": {"body": response["reply"]}
            },
            headers={"Authorization": f"Bearer {WHATSAPP_TOKEN}"}
        )
    return {"status": "ok"}
```

---

## Workflow Testing

```python
import pytest

@pytest.mark.asyncio
async def test_document_processing_workflow():
    # Arrange
    test_doc = {"content": "Invoice #12345, Amount: ₦500,000, Due: 2025-03-31"}
    
    # Act
    result = await document_workflow.ainvoke(test_doc)
    
    # Assert
    assert result["doc_type"] == "invoice"
    assert result["extracted"]["invoice_number"] == "12345"
    assert result["extracted"]["amount"] == 500000
    assert result["extracted"]["currency"] == "NGN"

@pytest.mark.asyncio
async def test_workflow_handles_failure_gracefully():
    # Test that workflow doesn't crash on bad input
    result = await document_workflow.ainvoke({"content": ""})
    assert result["status"] == "error"
    assert "error_message" in result
```

---

## References

- **LangGraph Documentation** — https://langchain-ai.github.io/langgraph/
- **"Temporal Workflows for Durable Execution"** — Temporal.io docs
- **"Prefect: Modern Dataflow Automation"** — https://docs.prefect.io/
- **n8n AI Workflow Platform** — https://n8n.io/
- **"Building Event-Driven Applications with LLMs"** — InfoQ, 2024
- **APScheduler Documentation** — https://apscheduler.readthedocs.io/
- **FastAPI Documentation** — https://fastapi.tiangolo.com/
- **"The Practical Guide to LLM Agents"** — Simon Willison's Weblog, 2024
- **WhatsApp Business API** — https://developers.facebook.com/docs/whatsapp/
