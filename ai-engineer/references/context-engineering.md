# Context Engineering Reference

## What Is Context Engineering?

Context engineering is the discipline of designing, structuring, and managing everything that enters the model's context window to maximize output quality, reliability, and efficiency. It is the most impactful lever available to AI engineers — more impactful than model selection, temperature tuning, or most other parameters.

> Context engineering is to AI systems what architecture is to software systems: the foundation everything else rests on.

---

## The Context Window as Real Estate

Think of the context window as expensive, limited real estate. Every token is a unit of space that must earn its place.

```
┌──────────────────────────────────────────────────────────────────┐
│  CONTEXT WINDOW  (e.g., 200K tokens for Claude)                  │
│                                                                  │
│  [System Prompt]     [Chat History]    [Retrieved Docs]          │
│  ~500–3000 tokens    ~1K–50K tokens    ~2K–100K tokens           │
│                                                                  │
│  [Tools/Functions]   [Current Turn]    [Output Buffer]           │
│  ~500–5000 tokens    ~100–2000 tokens  ~100–8000 tokens          │
│                                                                  │
│  RULE: Signal-to-noise ratio must be HIGH. Irrelevant context   │
│  dilutes model attention and degrades output quality.            │
└──────────────────────────────────────────────────────────────────┘
```

### The Primacy and Recency Effect
LLMs attend strongly to:
- **The very beginning** of the context (system prompt / initial framing)
- **The very end** of the context (the most recent user turn)

Content buried in the middle of very long contexts receives relatively less attention (the "lost in the middle" problem, Liu et al., 2023).

**Practical implication**: Put the most critical instructions at the start of the system prompt AND reinforce key constraints at the point of the user's request.

---

## System Prompt Design Patterns

### Pattern 1: Role + Mission + Constraints
```
You are [specific role], a [adjectives] [function] for [company/product].

Your mission: [1–2 sentences of what the system does]

You MUST:
- [Hard rule 1]
- [Hard rule 2]

You MUST NOT:
- [Hard prohibition 1]
- [Hard prohibition 2]

When you are unsure, [fallback behavior].
```

### Pattern 2: Structured XML Zones (Anthropic-recommended for Claude)
```xml
<system>
  <role>You are Aria, a customer support agent for Acme Corp.</role>
  
  <capabilities>
    You can: answer product questions, process returns, check order status.
    You cannot: issue refunds over $500 without escalation, access payment info.
  </capabilities>
  
  <knowledge>
    [Insert product documentation, FAQs, policy docs here]
  </knowledge>
  
  <output_format>
    Always respond in this structure:
    1. Acknowledge the customer's issue
    2. Provide the answer or next step
    3. Offer follow-up if needed
  </output_format>
</system>
```

**Why XML works well with Claude**: Claude's training includes extensive XML-structured data, so it parses XML-tagged sections with high fidelity. Use tags like `<instructions>`, `<context>`, `<examples>`, `<constraints>`, `<output_format>`.

### Pattern 3: Few-Shot Examples Block
```
EXAMPLES:

Input: [Example user message 1]
Output: [Ideal response 1]

Input: [Example user message 2]
Output: [Ideal response 2]

Input: [Example edge case]
Output: [How to handle it]
```

Place examples AFTER instructions, not before. The model uses instructions to interpret examples, not examples to infer instructions.

### Pattern 4: Chain-of-Thought Activation
```
Before answering, reason through the problem step by step inside <thinking> tags.
Only produce your final answer inside <answer> tags.
Your thinking is private; your answer is what the user sees.
```

For Claude specifically, extended thinking mode can be activated via API for complex reasoning tasks.

---

## Context Loading Strategies

### Static Context
Content that doesn't change per request. Load once in system prompt.
- Company policies
- Persona/role definition
- Output format specifications
- Core domain knowledge

### Dynamic Context
Content that changes per request. Inject at runtime.
- Retrieved documents (RAG)
- User profile / personalization data
- Conversation history (summarized or windowed)
- Current date/time / real-time data
- Tool outputs / function call results

### Context Injection Template
```python
def build_context(user_query: str, retrieved_docs: list, user_history: list) -> str:
    return f"""
<retrieved_context>
{format_docs(retrieved_docs)}
</retrieved_context>

<conversation_history>
{format_history(user_history[-10:])}  # Last 10 turns max
</conversation_history>

<current_request>
{user_query}
</current_request>
"""
```

---

## Conversation History Management

### The Problem
Conversation history grows unbounded. If you include full history, you waste tokens. If you truncate arbitrarily, you lose critical context.

### Strategies

**1. Sliding Window**
Keep last N turns. Simple. Loses older context.
```python
history = conversation[-20:]  # Last 20 messages
```

**2. Summarization**
Periodically compress older turns into a running summary.
```python
if len(conversation) > 30:
    summary = llm.summarize(conversation[:-10])  # Summarize all but last 10
    history = [{"role": "system", "content": f"Earlier context: {summary}"}] + conversation[-10:]
```

**3. Selective Retention**
Use an LLM or classifier to identify which past turns are relevant to the current query.

**4. Entity Memory**
Extract and maintain a structured record of key entities (user name, preferences, past decisions) rather than raw history.

```python
entity_memory = {
    "user_name": "Bn Adam",
    "project": "lekturer",
    "preferences": ["detailed explanations", "Windows environment"],
    "past_decisions": ["chose Docker Compose", "using PostgreSQL"]
}
```

---

## Context Compression Techniques

### Technique 1: Extractive Summarization
Ask the model to extract only the relevant parts of a long document for a specific question.
```
Given the following document and the user's question, extract ONLY the sentences and 
paragraphs directly relevant to answering the question. Discard all other content.

Question: {question}
Document: {document}
```

### Technique 2: Hierarchical Summarization
For very long documents, summarize in chunks, then summarize the summaries.
```
Level 1: Summarize each section (500 words → 50 words)
Level 2: Summarize the section summaries (10 × 50 words → 100 words)
Level 3: Use the final 100-word summary as context
```

### Technique 3: Structured Extraction
Convert unstructured text to structured data before injecting.
```python
# Instead of dumping a 5000-token customer record as prose:
# Extract only relevant fields as JSON
customer_context = {
    "plan": "Enterprise",
    "open_tickets": 2,
    "last_purchase": "2024-11-15",
    "risk_flag": False
}
```

### Technique 4: Prompt Caching
For Claude and GPT-4o, repeated prefixes can be cached to reduce latency and cost.
- Claude: Cache breakpoints at end of system prompt, after tools list, or at turn boundaries
- GPT-4o: Automatic caching for prompts >1024 tokens with identical prefixes
- Savings: Up to 90% cost reduction on cached tokens (Claude); ~50% (OpenAI)

---

## The CONTEXT Checklist (Before Shipping)

- [ ] **C** — Is every sentence in the system prompt necessary? Cut what adds no value.
- [ ] **O** — Is the ordering optimal? Critical instructions first and last.
- [ ] **N** — Are negative examples included? Show what NOT to do for edge cases.
- [ ] **T** — Are instructions testable? If you can't verify compliance, rewrite.
- [ ] **E** — Are examples provided for complex format requirements?
- [ ] **X** — Are XML/structural tags used to separate zones clearly?
- [ ] **T** — Is the token budget accounted for? Will this fit with retrieval added?

---

## References & Papers

- **"Lost in the Middle"** — Liu et al., 2023 — demonstrated primacy/recency attention bias in LLMs
- **Anthropic Prompt Engineering Guide** — https://docs.anthropic.com/en/docs/build-with-claude/prompt-engineering/overview
- **OpenAI Prompt Engineering Guide** — https://platform.openai.com/docs/guides/prompt-engineering
- **"Large Language Models Are Human-Level Prompt Engineers"** — Zhou et al., 2022 (APE paper)
- **Constitutional AI** — Bai et al., Anthropic 2022 — foundational for system-level behavioral constraints
- **Prompt Injection Attacks** — Perez & Ribeiro, 2022 — critical for production security design
