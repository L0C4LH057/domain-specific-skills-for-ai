# Token Efficiency & Management Reference

## Why Token Efficiency Is an Engineering Discipline

Token costs are not a minor line item — at scale they become a primary cost driver:

```
Example calculation:
  10,000 users/day
  × 5 conversations/user
  × 2,000 tokens/conversation average
  = 100,000,000 tokens/day

  At Claude Sonnet pricing (~$3/M input, $15/M output):
  Input-heavy: ~$300/day = $9,000/month
  Output-heavy: ~$1,500/day = $45,000/month

A 50% token reduction = $4,500–$22,500/month saved.
```

Token efficiency is not about being cheap — it's about sustainability and scale.

---

## Token Counting Reference

### Quick Estimation
- 1 token ≈ 0.75 words (English prose)
- 1 token ≈ 4 characters (English)
- 1 page of text ≈ 500–700 tokens
- 1 line of Python ≈ 10–20 tokens
- A typical JSON response ≈ 200–500 tokens
- A long system prompt ≈ 500–3000 tokens

### Accurate Counting
```python
# Anthropic
import anthropic
client = anthropic.Anthropic()

response = client.messages.count_tokens(
    model="claude-sonnet-4-5",
    system="Your system prompt here",
    messages=[{"role": "user", "content": "User message here"}]
)
print(response.input_tokens)

# OpenAI
import tiktoken
enc = tiktoken.encoding_for_model("gpt-4o")
tokens = enc.encode(text)
print(len(tokens))

# Open source (HuggingFace)
from transformers import AutoTokenizer
tokenizer = AutoTokenizer.from_pretrained("meta-llama/Meta-Llama-3-8B")
tokens = tokenizer.encode(text)
```

---

## Pricing Reference (March 2025)

| Model | Input ($/M tokens) | Output ($/M tokens) | Cache Read |
|-------|-------------------|---------------------|------------|
| Claude Opus 4.5 | $15.00 | $75.00 | $1.50 |
| Claude Sonnet 4.5 | $3.00 | $15.00 | $0.30 |
| Claude Haiku 4.5 | $0.80 | $4.00 | $0.08 |
| GPT-4o | $2.50 | $10.00 | $1.25 |
| GPT-4o-mini | $0.15 | $0.60 | $0.075 |
| Gemini 1.5 Pro | $1.25 | $5.00 | — |
| Gemini 1.5 Flash | $0.075 | $0.30 | — |
| Llama 3.1 70B (hosted) | ~$0.35 | ~$0.40 | — |

*Prices change frequently — always verify at provider's pricing page.*

---

## The 10 Token Efficiency Techniques

### Technique 1: System Prompt Auditing
Audit your system prompt for bloat. Common waste patterns:
```
❌ BLOATED:
"Please make sure to always remember to carefully consider the user's question 
and think about what they might be asking before providing a comprehensive and 
detailed response that addresses all aspects of their query..."

✅ TIGHT:
"Answer the user's question directly and completely."
```

Reduce system prompt to the minimum necessary. Every 100 tokens saved × 10,000 calls/day = 1M tokens/day saved.

### Technique 2: Prompt Caching

**Claude Prompt Caching** (up to 90% cost reduction on cached prefix):
```python
response = client.messages.create(
    model="claude-sonnet-4-5",
    max_tokens=1024,
    system=[
        {
            "type": "text",
            "text": "You are a helpful assistant...",  # Short, uncached
        },
        {
            "type": "text",
            "text": very_long_document_or_instructions,  # This gets cached
            "cache_control": {"type": "ephemeral"}
        }
    ],
    messages=messages
)
# First call: charges full input price
# Subsequent calls with same prefix: charges cache_read price (10% of input)
```

**Rules for effective caching**:
- Cache breakpoint must be at a stable prefix (doesn't change between calls)
- Minimum cacheable prefix: 1024 tokens (Claude)
- Cache TTL: 5 minutes (resets on each use)
- Best candidates: Large system prompts, reference documents, tool definitions

### Technique 3: Model Routing
Use the cheapest model capable of the task. Don't use Opus for classification.

```python
def route_to_model(task_type: str, complexity: str) -> str:
    routing_map = {
        ("classification", "simple"): "claude-haiku-4-5",
        ("extraction", "simple"):     "claude-haiku-4-5",
        ("qa", "factual"):            "claude-sonnet-4-5",
        ("reasoning", "complex"):     "claude-sonnet-4-5",
        ("analysis", "expert"):       "claude-opus-4-5",
        ("code_review", "complex"):   "claude-opus-4-5",
    }
    return routing_map.get((task_type, complexity), "claude-sonnet-4-5")
```

**Classifier-then-respond pattern**:
1. Run cheap model to classify query complexity/type
2. Route to appropriate model
3. Cost of classification << savings from routing

### Technique 4: Output Length Control
Specify desired output length explicitly:
```
Respond in 2–3 sentences maximum.
Return only the JSON object. No explanation.
Give a one-word answer: YES or NO.
Limit your response to 200 words.
```

Use `max_tokens` parameter for hard limits:
```python
response = client.messages.create(
    model="claude-sonnet-4-5",
    max_tokens=150,  # Hard cap — saves cost; ensure it's not too low for task
    messages=messages
)
```

### Technique 5: Context Window Pruning
Don't inject everything — inject only what's relevant.

```python
def prune_context(retrieved_chunks: list, query: str, max_tokens: int = 4000) -> list:
    """Keep only chunks that exceed relevance threshold, up to token budget."""
    scored_chunks = reranker.score(query, retrieved_chunks)
    scored_chunks.sort(key=lambda x: x.score, reverse=True)
    
    kept = []
    token_count = 0
    for chunk in scored_chunks:
        chunk_tokens = count_tokens(chunk.text)
        if token_count + chunk_tokens > max_tokens:
            break
        if chunk.score > 0.5:  # Relevance threshold
            kept.append(chunk)
            token_count += chunk_tokens
    return kept
```

### Technique 6: Conversation History Compression
Don't pass full history — compress it.

```python
def compress_history(messages: list, max_tokens: int = 2000) -> list:
    if count_tokens(messages) <= max_tokens:
        return messages
    
    # Keep last 4 messages always
    recent = messages[-4:]
    older = messages[:-4]
    
    # Summarize older messages
    summary = llm.invoke(f"Summarize this conversation history in 200 words:\n{format(older)}")
    
    return [
        {"role": "system", "content": f"[Earlier conversation summary: {summary}]"},
        *recent
    ]
```

### Technique 7: Structured Output Efficiency
Request only the fields you need:
```
❌ WASTEFUL: "Analyze this customer review and tell me everything about it"

✅ EFFICIENT: "Extract only:
- sentiment: POSITIVE/NEGATIVE/NEUTRAL  
- main_issue: one sentence
- urgency: HIGH/MEDIUM/LOW

Return as JSON. No other text."
```

### Technique 8: Streaming
Streaming doesn't reduce tokens but improves perceived latency dramatically. Always stream for user-facing interfaces:
```python
with client.messages.stream(
    model="claude-sonnet-4-5",
    max_tokens=1024,
    messages=messages
) as stream:
    for text in stream.text_stream:
        yield text  # Send to client in real-time
```

### Technique 9: Batch Processing
For non-real-time workloads, use batch APIs for 50% cost reduction:
```python
# Anthropic Message Batches API
batch = client.beta.messages.batches.create(
    requests=[
        {"custom_id": f"req-{i}", "params": {"model": "claude-sonnet-4-5", "max_tokens": 500, "messages": [msg]}}
        for i, msg in enumerate(bulk_messages)
    ]
)
# Returns async — poll for results; up to 24h processing time
# 50% cheaper than real-time API
```

### Technique 10: Fine-tuning for Compression
A fine-tuned small model can replace a large prompted model for repetitive tasks:
- Classify intent → Fine-tuned 7B model instead of prompted GPT-4o
- Extract entities → Fine-tuned model at 1/10 the cost
- Style-consistent writing → Fine-tuned model, no long style system prompt needed

---

## Token Budget Allocation Framework

For a typical RAG chatbot, distribute tokens deliberately:

```
Total context window: 128,000 tokens

Allocation:
  System prompt:              2,000 tokens  (1.5%)
  Retrieved context:         60,000 tokens  (47%)
  Conversation history:      50,000 tokens  (39%)
  Current user message:       1,000 tokens  (0.8%)
  Output buffer:             15,000 tokens  (11.7%)

Rule of thumb:
  Never fill > 80% of context window — leave buffer for output and unexpected input length
```

---

## Monitoring Token Usage in Production

```python
# Track per-request token usage
def log_usage(response, request_id: str, user_id: str):
    usage = {
        "request_id": request_id,
        "user_id": user_id,
        "model": response.model,
        "input_tokens": response.usage.input_tokens,
        "output_tokens": response.usage.output_tokens,
        "cache_read_tokens": getattr(response.usage, "cache_read_input_tokens", 0),
        "cache_create_tokens": getattr(response.usage, "cache_creation_input_tokens", 0),
        "estimated_cost": calculate_cost(response),
        "timestamp": datetime.utcnow().isoformat()
    }
    metrics_db.insert(log_entry)
    
    # Alert if cost exceeds threshold
    if log_entry["estimated_cost"] > COST_ALERT_THRESHOLD:
        alert_ops_team(log_entry)
```

**Key metrics to track**:
- Average tokens per request (input + output separately)
- Cache hit rate (should be > 60% for prompt-caching eligible endpoints)
- Cost per user per day
- P95 latency vs token count correlation
- Model distribution (% of requests going to each tier)

---

## References

- **Anthropic Prompt Caching Docs** — https://docs.anthropic.com/en/docs/build-with-claude/prompt-caching
- **OpenAI Prompt Caching** — https://platform.openai.com/docs/guides/prompt-caching
- **Anthropic Message Batches** — https://docs.anthropic.com/en/docs/build-with-claude/message-batches
- **"FlexGen: High-Throughput Generative Inference of Large Language Models"** — Sheng et al., 2023
- **"LLMLingua: Compressing Prompts for Accelerated Inference"** — Jiang et al., Microsoft, 2023
- **Tiktoken (OpenAI tokenizer)** — https://github.com/openai/tiktoken
