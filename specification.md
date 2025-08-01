# Agent Prompting Language (APL) - Complete Language Specification
Version 2.0

August 2, 2025

**Language Classification:** Domain-Specific Language (DSL) for AI Agent Development  
**Target Domain:** Enterprise Production AI Agents  
**Paradigm:** Declarative, State-Machine Based, Decision-Execute Separation

---

## Table of Contents

1. [Language Overview](#language-overview)
2. [Core Syntax and Grammar](#core-syntax-and-grammar)
3. [Type System](#type-system)
4. [Agent Structure](#agent-structure)
5. [Decision System](#decision-system)
6. [Execution System](#execution-system)
7. [State Machines](#state-machines)
8. [Templates](#templates)
9. [Conversation State](#conversation-state)
10. [Module System](#module-system)
11. [Constraint System](#constraint-system)
12. [Testing Framework](#testing-framework)
13. [Runtime Semantics](#runtime-semantics)
14. [Advanced Features](#advanced-features)

---

## Language Overview

### Design Principles

APL is built on five foundational principles that distinguish it from general-purpose programming languages:

**Decision-Execute Separation**: Clear distinction between LLM reasoning (`@decide`) and deterministic system operations (`!execute`). This separation enables formal verification of system behavior while leveraging LLM intelligence.

**Native Capability Leverage**: First-class support for LLM capabilities like task decomposition, summarization, and contextual reasoning, rather than treating them as external black boxes.

**Dynamic Extensibility**: Runtime loading and execution of agent behaviors stored as APL code in modules, enabling continuous evolution without code deployment.

**Ultra-Compact Expressiveness**: Syntax optimized for clarity and brevity, achieving 90% reduction in verbosity compared to natural language prompts while maintaining semantic richness.

**State-Aware Processing**: Native support for complex multi-step processes with persistent state, timeout handling, and error recovery.

### Language Characteristics

- **Declarative**: Describes what the agent should do, not how to do it
- **Strongly Typed**: Explicit type system with compile-time checking
- **Immutable Core**: State changes happen through explicit transitions
- **Composable**: Agents can be composed and extended
- **Testable**: Built-in testing framework with scenario-based verification

---

## Core Syntax and Grammar

### Lexical Structure

```ebnf
// Comments
single_line_comment = "//" { any_character_except_newline } newline
block_comment = "/*" { any_character } "*/"

// Identifiers
identifier = letter { letter | digit | "_" }
letter = "a"..."z" | "A"..."Z"
digit = "0"..."9"

// Literals
string_literal = '"' { string_character } '"'
number_literal = digit { digit } [ "." digit { digit } ]
boolean_literal = "true" | "false"
```

### Grammar Definition

```ebnf
// Top-level constructs
program = { agent_definition | module_definition | test_suite }

// Agent Definition
agent_definition = "agent" identifier "{" agent_body "}"

agent_body = 
    role_definition
    objectives_definition?
    resources_definition?
    states_definition?
    conversation_state_definition?
    templates_definition?
    built_in_capabilities?
    behavior_definition
    constraints_definition?

// Core Language Constructs
role_definition = "role" ":" string_literal

objectives_definition = "objectives" "{" 
    "primary" ":" string_literal
    [ "secondary" ":" "[" string_list "]" ]
"}"

resources_definition = "resources" "{" 
    { resource_binding }
"}"

resource_binding = identifier ":" external_reference | object_literal

external_reference = "external" "(" string_literal ")"

// Decision Blocks
decision_block = "@decide" "{" { decision_statement } "}"

decision_statement = 
    identifier [ "(" parameter_list ")" ] 
    "->" output_specification 
    [ "[" constraint_expression "]" ] 
    [ "|" default_value ]

output_specification = 
    type_expression |
    "[" string_list "]" |
    range_expression |
    identifier

constraint_expression = 
    identifier { ( "+" | "&&" | "||" ) identifier } |
    comparison_expression |
    function_call

// Execution Blocks
execute_statement = "!execute" function_call

function_call = identifier "(" [ argument_list ] ")"

// State Machine Definition
states_definition = "states" "{" 
    [ "initial" ":" string_literal ]
    { state_definition }
"}"

state_definition = identifier "{" state_properties "}"

state_properties = 
    [ "description" ":" string_literal ] 
    [ "allowed_transitions" ":" "[" string_list "]" ]
    [ "timeout" ":" duration_literal ]
    [ "max_retries" ":" number_literal ]
    [ "auto_transition" ":" boolean_literal ]
    [ "final_state" ":" boolean_literal ]
    [ "cleanup_actions" ":" "[" string_list "]" ]

// Behavior Definition
behavior_definition = "behavior" "{" 
    { behavior_block }
"}"

behavior_block = 
    on_enter_state |
    on_exit_state |
    on_event |
    standard_behavior

on_enter_state = "on_enter_state" "{" 
    { state_handler }
"}"

on_exit_state = "on_exit_state" "{" 
    { state_handler }
"}"

on_event = "on_event" "{" 
    { event_handler }
"}"

state_handler = identifier "->" "{" behavior_statements "}"

event_handler = 
    [ "state" "(" identifier ")" "+" ] 
    "event" "(" identifier ")" 
    "->" "{" behavior_statements "}"

behavior_statements = { decision_block | execute_statement | control_structure }

// Control Structures
control_structure = 
    if_statement |
    match_statement |
    while_statement |
    for_statement

if_statement = "if" expression "{" behavior_statements "}" 
               [ "else" "{" behavior_statements "}" ]

match_statement = "match" expression "{" 
    { match_case }
"}"

match_case = ( string_literal | identifier ) "->" "{" behavior_statements "}"

// Templates Definition
templates_definition = "templates" "{" 
    { template_definition }
"}"

template_definition = identifier "{" template_body "}"

template_body = 
    [ "format" ":" ( string_literal | object_literal ) ]
    [ "structure" ":" object_literal ]
    [ "fields" ":" object_literal ]
    [ "required" ":" "[" string_list "]" ]
    [ "validation" ":" object_literal ]

// Module Definitions
module_definition = "module" identifier "{" module_body "}"

module_body = 
    [ "export" { exportable_item } ]
    [ "import" { import_statement } ]
    { module_item }

exportable_item = 
    behavior_definition |
    template_definition |
    function_definition |
    state_definition

// Test Definitions
test_suite = "test_suite" identifier "{" 
    { test_scenario }
"}"

test_scenario = "scenario" string_literal "{" 
    ( test_input | test_sequence )
    test_expectations
"}"

test_input = "input" ":" object_literal

test_sequence = "sequence" ":" "[" string_list "]"

test_expectations = "expect" ":" "{" 
    { expectation_statement }
"}"

// Type System
type_expression = 
    primitive_type |
    collection_type |
    union_type |
    optional_type

primitive_type = 
    "string" | "integer" | "float" | "boolean" | 
    "object" | "any" | "empty"

collection_type = 
    "list" "[" type_expression "]" |
    "map" "[" type_expression "," type_expression "]"

union_type = type_expression "|" type_expression

optional_type = type_expression "?"

range_expression = number_literal ".." number_literal

duration_literal = number_literal "_" time_unit

time_unit = "seconds" | "minutes" | "hours" | "days"
```

---

## Type System

### Primitive Types

APL provides a focused set of primitive types optimized for agent development:

**string**: Unicode text values, primary type for user input and natural language processing
- Examples: `"Hello world"`, `"customer_id"`, `""`
- Operations: concatenation, pattern matching, length checking

**integer**: Whole numbers for counting and indexing
- Examples: `42`, `0`, `-10`
- Range: -2^63 to 2^63-1

**float**: Floating-point numbers for confidence scores and calculations
- Examples: `0.85`, `3.14159`, `-1.5`
- Range: IEEE 754 double precision

**boolean**: Logical values for decision outcomes
- Values: `true`, `false`
- Primary return type for decision statements

**object**: Structured data containers
- Dynamic property access and modification
- JSON-serializable for external system integration

**any**: Universal type for dynamic content
- Used when type cannot be determined at compile time
- Runtime type checking available

**empty**: Explicit absence of value
- Distinct from null/undefined in other languages
- Used to indicate uninitialized state

### Collection Types

**list[T]**: Ordered sequences of homogeneous elements
- Examples: `list[string]`, `list[object]`
- Zero-indexed access with bounds checking
- Immutable by default, modifications create new instances

**map[K,V]**: Key-value associations
- Examples: `map[string, any]`, `map[string, float]`
- Hash-based implementation for O(1) average access
- Keys must be comparable types

### Type Composition

**Union Types**: Multiple allowed types using `|` operator
```apl
customer_status -> ["active", "inactive", "suspended"] | empty
```

**Optional Types**: Nullable values using `?` suffix
```apl
optional_field: string?
```

### Type Inference

APL provides sophisticated type inference to minimize explicit type annotations:

```apl
@decide {
  // Type inferred as string from output specification
  customer_intent -> ["refund", "complaint", "inquiry"]
  
  // Type inferred as float from range
  confidence_score -> 0.0..1.0
  
  // Type inferred as boolean from constraint
  is_valid -> boolean [input_validation_result]
}
```

---

## Agent Structure

### Agent Declaration

Every APL agent follows a consistent structure that separates concerns and enables formal analysis:

```apl
// aplv2.0
agent AgentName {
  role: "descriptive role definition"
  
  objectives {
    primary: "main goal of the agent"
    secondary: ["supporting", "goals", "list"]
  }
  
  resources {
    resource_name: external("system_reference")
    local_data: object_value
  }
  
  states { /* state machine definition */ }
  
  conversation_state { /* persistent state schema */ }
  
  templates { /* response formats and types */ }
  
  built_in_capabilities { /* LLM capability configuration */ }
  
  behavior { /* agent logic */ }
  
  constraints { /* operational constraints */ }
}
```

### Resource Management

Resources represent external systems and data sources that the agent can interact with through function calls:

**External Resources**: Connections to external systems
```apl
resources {
  database: external("postgresql_connection")
  api_service: external("rest_api_client")
  file_storage: external("s3_storage")
}
```

**Local Resources**: Agent-scoped data and configuration
```apl
resources {
  response_templates: {
    "greeting": "Hello {customer_name}, how can I help you today?",
    "closing": "Thank you for contacting us. Have a great day!"
  }
  
  validation_rules: {
    customer_id: "format:numeric, length:8",
    email: "format:email"
  }
}
```

### Conversation State

APL provides first-class support for persistent conversation state that can be managed through simple database operations or maintained in message context:

```apl
conversation_state {
  // Strongly typed state variables
  current_issue_type: string | empty
  collected_data: map[string, any]
  validation_attempts: map[string, integer]
  
  // State with constraints
  conversation_turn: integer [min: 0]
  confidence_level: float [0.0..1.0]
  
  // Optional state
  selected_template: object?
  error_context: string?
}
```

State variables are automatically managed and can be persisted through function calls to external storage systems.

---

## Decision System

### Decision Paradigm

The `@decide` construct is APL's core innovation, representing the boundary between LLM reasoning and deterministic system behavior:

```apl
@decide {
  // Single output decision
  customer_intent -> ["refund", "complaint", "inquiry"] [input.text]
  
  // Multiple output decision
  risk_assessment -> {
    level: ["low", "medium", "high"],
    confidence: 0.0..1.0,
    factors: list[string]
  } [customer_profile + transaction_history]
  
  // Conditional decision with fallback
  next_action -> ["continue", "escalate", "terminate"] 
    | fallback("continue") [context + business_rules]
}
```

### Decision Types

**Classification Decisions**: Choose from predefined categories
```apl
document_type -> ["passport", "license", "utility_bill"] [uploaded_image]
```

**Assessment Decisions**: Evaluate and score on continuous scales
```apl
content_quality -> 1..10 [text_analysis + readability_metrics]
```

**Generation Decisions**: Create new content based on context
```apl
response_message -> generated_text [user_query + conversation_context + tone_guidelines]
```

**Extraction Decisions**: Pull structured data from unstructured input using @decide
```apl
@decide {
  extracted_entities -> {
    transaction_id: string?,
    amount: float?,
    date: string?
  } [user_message + conversation_context]
}
```

### Constraint Expressions

Constraints guide LLM decision-making by providing relevant context and limiting factors:

**Simple Constraints**: Single context variables
```apl
urgency_level -> ["low", "medium", "high"] [customer_tier]
```

**Compound Constraints**: Multiple context factors
```apl
approval_decision -> boolean [risk_score + amount + customer_history + policy_rules]
```

**Conditional Constraints**: Context-dependent factors
```apl
verification_method -> ["automatic", "manual"] 
  [document_quality > 0.8 ? automated_checks : human_review_required]
```

### Fallback Mechanisms

APL provides robust fallback handling for low-confidence decisions:

```apl
@decide {
  // Explicit fallback value
  classification -> ["type_a", "type_b", "type_c"] 
    | fallback("unknown") [confidence > 0.7]
  
  // Conditional fallback
  next_step -> ["process", "review", "reject"] 
    | (confidence < 0.6 ? "manual_review" : "process") [decision_factors]
  
  // Multiple fallback strategies
  action -> ["auto_approve", "request_docs", "reject"] 
    | low_confidence("request_clarification") 
    | timeout("escalate") 
    [risk_assessment + time_constraints]
}
```

---

## Execution System

### Execution Commands

The `!execute` construct handles all deterministic system operations, clearly separating them from LLM reasoning:

```apl
// Function calls to external resources
!execute database.save_record(table_name, record_data)
!execute api_service.post("/webhook", payload)
!execute file_storage.upload(document_path, file_data)

// State transitions
!execute transition_to("new_state")
!execute set_timeout(30_minutes)

// Conversation state management
!execute set_conversation_data("key", value)
!execute save_conversation_state(session_id, current_state)

// Control flow
!execute return_result(final_data)
!execute escalate_to_human(context_data)
```

### System Integration

APL execution commands integrate seamlessly with external systems through function calls:

**Database Operations**:
```apl
!execute database.query("SELECT * FROM customers WHERE id = ?", [customer_id])
!execute database.transaction([
  "INSERT INTO requests (id, type, data) VALUES (?, ?, ?)",
  "UPDATE customer_stats SET request_count = request_count + 1"
])
```

**API Calls**:
```apl
!execute api_service.post("https://api.service.com/v1/notify", {
  customer_id: customer_id,
  message: generated_response,
  priority: urgency_level
})
```

**File Operations**:
```apl
!execute file_storage.write_json("requests/" + request_id + ".json", request_data)
!execute file_storage.upload_to_cloud(document_path, cloud_bucket, cloud_key)
```

### Error Handling in Execution

Execution commands can fail, and APL provides structured error handling:

```apl
try {
  !execute external_api.call(endpoint, data)
} catch (api_error) {
  @decide {
    retry_strategy -> ["immediate", "delayed", "fallback_service"] 
      [error_type + retry_count + time_constraints]
  }
  
  match retry_strategy {
    "immediate" -> !execute external_api.retry(endpoint, data)
    "delayed" -> !execute schedule_retry(5_minutes, endpoint, data)
    "fallback_service" -> !execute backup_api.call(endpoint, data)
  }
}
```

---

## State Machines

### State Machine Architecture

APL state machines provide first-class support for complex multi-step processes with explicit state management:

```apl
states {
  initial: "greeting"
  
  greeting {
    description: "welcome user and determine intent"
    allowed_transitions: ["intent_analysis", "data_collection", "abandoned"]
    timeout: 5_minutes
    max_retries: 3
  }
  
  intent_analysis {
    description: "analyze user intent and route appropriately"
    allowed_transitions: ["data_collection", "clarify_intent", "escalation"]
    timeout: 2_minutes
  }
  
  data_collection {
    description: "gather required information step by step"
    allowed_transitions: ["data_collection", "validation_failed", "data_complete"]
    substates: ["prompting", "validating", "confirming"]
  }
  
  data_complete {
    description: "all data collected successfully"
    allowed_transitions: ["confirmation", "output_generated"]
    final_state: false
  }
  
  confirmation {
    description: "user confirms collected data"
    allowed_transitions: ["output_generated", "data_collection", "restart"]
  }
  
  output_generated {
    description: "final output created"
    final_state: true
    cleanup_actions: ["save_request", "clear_memory", "log_completion"]
  }
  
  // Error states
  validation_failed {
    allowed_transitions: ["data_collection", "escalation"]
    max_retries: 3
    escalation_after: 3_failures
  }
  
  abandoned {
    final_state: true
    cleanup_actions: ["save_partial_progress", "schedule_follow_up"]
  }
}
```

### State Properties

**allowed_transitions**: Explicit list of valid next states
- Enables compile-time verification of state machine completeness
- Prevents invalid state transitions at runtime

**timeout**: Maximum time allowed in state
- Automatic transition to error handling after timeout
- Configurable per-state timeout values

**max_retries**: Retry limits for recoverable failures
- Prevents infinite loops in error states
- Configurable retry strategies

**substates**: Internal state progression within a logical state
- Fine-grained state tracking without explosion of top-level states
- Useful for complex operations with multiple phases

**final_state**: Marks terminal states
- Triggers cleanup actions when reached
- Prevents further transitions

**cleanup_actions**: Operations to perform on state exit
- Resource cleanup and finalization
- Audit logging and metrics

### State Behavior

APL provides three types of state-related behavior handlers:

**on_enter_state**: Executed when entering a state
```apl
on_enter_state {
  greeting -> {
    !execute log_session_start(user_id, timestamp)
    !execute initialize_conversation_context()
    
    @decide {
      greeting_type -> ["new_user", "returning_user", "escalation"] 
        [user_history + session_context]
    }
    
    !execute send_personalized_greeting(greeting_type)
  }
  
  data_collection -> {
    @decide {
      next_field_needed -> field_name [collected_data + required_fields]
      field_prompt -> user_friendly_question [next_field_needed + context]
    }
    
    !execute send_message(field_prompt)
    !execute set_conversation_data("current_field", next_field_needed)
  }
}
```

**on_exit_state**: Executed when leaving a state
```apl
on_exit_state {
  data_collection -> {
    !execute save_collection_progress(conversation_state.collected_data)
    !execute update_field_completion_metrics()
  }
  
  output_generated -> {
    final_request = build_request_output(conversation_state.collected_data)
    !execute save_completed_request(final_request)
    !execute send_confirmation_notification(user_email, final_request.id)
    !execute clear_conversation_memory()
  }
}
```

**on_event**: Responds to events within specific states
```apl
on_event {
  // Universal events (work in any state)
  event(user_input) + input.text.contains("restart") -> {
    !execute clear_conversation_state()
    !execute transition_to("greeting")
  }
  
  event(timeout_reached) -> {
    @decide {
      timeout_action -> ["extend", "abandon", "escalate"] 
        [current_state + user_engagement + business_priority]
    }
    
    match timeout_action {
      "extend" -> !execute extend_timeout(15_minutes)
      "abandon" -> !execute transition_to("abandoned")
      "escalate" -> !execute transition_to("human_handoff")
    }
  }
  
  // State-specific events
  state(data_collection) + event(user_input) -> {
    current_field = conversation_state.current_field
    user_value = input.text.trim()
    
    @decide {
      is_valid -> boolean [user_value + validation_rules[current_field]]
      validation_error -> error_message [user_value + validation_rules[current_field]]
    }
    
    if is_valid {
      !execute set_conversation_data("collected_data." + current_field, user_value)
      !execute send_message("✅ Got it!")
      !execute transition_to("data_collection")  // Continue to next field
    } else {
      !execute send_message("❌ " + validation_error + "\nPlease try again:")
      !execute increment_validation_attempts(current_field)
    }
  }
}
```

---

## Templates

Templates define response formats and structured output types, combining response formatting with type definitions:

```apl
templates {
  // Response templates with dynamic fields
  customer_response {
    format: "Dear {customer_name}, {main_message} Best regards, {agent_name}"
    fields: {
      customer_name: string,
      main_message: string,
      agent_name: string
    }
    validation: {
      main_message: "min_length:10, max_length:500",
      customer_name: "required:true"
    }
  }
  
  // Structured output types
  support_ticket {
    structure: {
      id: string,
      customer_id: string,
      issue_type: ["billing", "technical", "account"],
      priority: 1..5,
      description: string,
      status: ["open", "in_progress", "resolved"],
      created_at: timestamp,
      assigned_to: string?
    }
    required: ["customer_id", "issue_type", "description"]
    defaults: {
      status: "open",
      priority: 3
    }
  }
  
  // API payload templates
  webhook_notification {
    structure: {
      event_type: string,
      timestamp: timestamp,
      data: object,
      metadata: {
        agent_id: string,
        session_id: string,
        version: string
      }
    }
    format: "json"
    validation: {
      event_type: "enum:['ticket_created', 'ticket_updated', 'escalation_triggered']",
      timestamp: "format:iso8601"
    }
  }
  
  // Multi-format templates
  summary_report {
    structure: {
      title: string,
      summary: string,
      details: list[object],
      recommendations: list[string],
      confidence_score: 0.0..1.0
    }
    
    formats: {
      json: "standard_json_output",
      markdown: "# {title}\n\n## Summary\n{summary}\n\n## Details\n{details_formatted}",
      email: "Subject: {title}\n\n{summary}\n\nRecommended actions:\n{recommendations_list}"
    }
  }
}
```

### Template Usage

Templates can be used in decisions and executions:

```apl
@decide {
  // Generate structured data using template
  ticket_data -> support_ticket [customer_issue + conversation_context]
  
  // Generate formatted response using template
  response -> customer_response [resolution_details + customer_info]
  
  // Generate multi-format output
  report -> summary_report [analysis_results + recommendations]
}

// Use templates in execution
!execute send_webhook(webhook_notification.format({
  event_type: "ticket_created",
  data: ticket_data,
  metadata: {
    agent_id: agent.id,
    session_id: session.id,
    version: "2.0"
  }
}))

!execute send_email(customer_response.format({
  customer_name: customer.name,
  main_message: resolution_message,
  agent_name: "Support Team"
}))
```

---

## Conversation State

Conversation state management supports both simple database persistence and in-memory state handling:

```apl
conversation_state {
  // Persistent across conversations
  customer_context: {
    id: string?,
    tier: ["basic", "premium", "enterprise"]?,
    history_summary: string?,
    preferences: map[string, any]
  }
  
  // Session-specific state
  current_workflow: {
    type: string?,
    step: integer,
    collected_data: map[string, any],
    validation_attempts: map[string, integer]
  }
  
  // Interaction tracking
  conversation_metadata: {
    turn_count: integer,
    start_time: timestamp,
    last_update: timestamp,
    confidence_scores: list[float],
    escalation_triggers: list[string]
  }
}
```

### State Management Operations

```apl
behavior {
  on_enter_state {
    greeting -> {
      // Load persistent state from external storage
      stored_state = !execute database.load_conversation_state(session_id)
      
      if stored_state {
        !execute restore_conversation_state(stored_state)
      }
      
      // Initialize session state
      !execute set_conversation_data("conversation_metadata.start_time", now())
      !execute set_conversation_data("conversation_metadata.turn_count", 0)
    }
  }
  
  on_event {
    event(user_input) -> {
      // Update state
      !execute increment_conversation_data("conversation_metadata.turn_count")
      !execute set_conversation_data("conversation_metadata.last_update", now())
      
      // Persist state to external storage
      !execute database.save_conversation_state(session_id, conversation_state)
      
      // State-dependent logic
      if conversation_state.conversation_metadata.turn_count > 20 {
        @decide {
          should_summarize -> boolean [conversation_length + complexity]
        }
        
        if should_summarize {
          @decide {
            conversation_summary -> summary_text [conversation_history]
          }
          
          !execute set_conversation_data("customer_context.history_summary", conversation_summary)
        }
      }
    }
  }
}
```

---

## Module System

Dynamic module loading enables runtime composition of agent behaviors:

```apl
// Module definition
module BillingSupport {
  export templates {
    billing_dispute_form {
      structure: {
        customer_id: string,
        transaction_id: string,
        dispute_amount: float,
        dispute_reason: string,
        supporting_documents: list[string]?
      }
      required: ["customer_id", "transaction_id", "dispute_amount", "dispute_reason"]
    }
  }
  
  export behavior billing_workflow {
    states: {
      verify_customer: {
        allowed_transitions: ["analyze_transaction", "authentication_failed"]
      },
      analyze_transaction: {
        allowed_transitions: ["process_dispute", "escalate_fraud"]
      },
      process_dispute: {
        allowed_transitions: ["dispute_approved", "dispute_denied"]
      }
    }
    
    on_enter_state {
      verify_customer -> {
        @decide {
          customer_data -> billing_dispute_form [user_input + conversation_context]
          is_authenticated -> boolean [customer_data + authentication_service]
        }
        
        if is_authenticated {
          !execute transition_to("analyze_transaction")
        } else {
          !execute transition_to("authentication_failed")
        }
      }
    }
  }
}

// Dynamic module loading
module FraudDetection {
  export functions {
    analyze_transaction_risk(transaction_data: object) -> {
      risk_score: 0.0..1.0,
      risk_factors: list[string],
      recommended_action: ["approve", "review", "deny"]
    }
    
    check_velocity_patterns(customer_id: string) -> {
      unusual_activity: boolean,
      pattern_description: string?
    }
  }
}
```

### Module Usage in Agents

```apl
// aplv2.0
agent EnhancedSupportAgent {
  role: "advanced customer support with specialized capabilities"
  
  imports {
    billing: module("BillingSupport")
    fraud: module("FraudDetection")
    // Runtime loading from external sources
    compliance: module("external:compliance_rules_v2.apl")
  }
  
  behavior {
    on_event {
      event(user_input) -> {
        @decide {
          issue_category -> ["billing", "technical", "account", "fraud"] [user_input]
        }
        
        match issue_category {
          "billing" -> !execute billing.billing_workflow.start()
          "fraud" -> {
            fraud_analysis = !execute fraud.analyze_transaction_risk(transaction_data)
            
            if fraud_analysis.risk_score > 0.8 {
              !execute transition_to("high_risk_escalation")
            }
          }
          "technical" -> !execute standard_technical_flow()
        }
      }
    }
    
    // Runtime module loading based on complexity
    on_enter_state {
      complex_issue -> {
        @decide {
          required_expertise -> expertise_type [issue_details + complexity_assessment]
        }
        
        specialist_module = !execute load_module("vector_db:" + required_expertise)
        !execute activate_specialist_behavior(specialist_module)
      }
    }
  }
}
```

### Module Discovery and Loading

```apl
// Module discovery through external systems
behavior {
  module_discovery {
    // Vector database search for relevant modules
    search_results = !execute vector_search.find_modules({
      query: user_intent + issue_complexity,
      similarity_threshold: 0.75,
      max_results: 5
    })
    
    // Load and validate modules
    for module_ref in search_results {
      if module_ref.confidence > 0.8 {
        loaded_module = !execute load_module(module_ref.source)
        !execute validate_module_compatibility(loaded_module)
      }
    }
  }
}
```

---

## Constraint System

### Constraint Types

APL provides a comprehensive constraint system for governing agent behavior:

**Operational Constraints**: Runtime behavior limits
```apl
constraints {
  max_conversation_time: 30_minutes
  max_validation_attempts: 3
  min_confidence_threshold: 0.7
  required_field_coverage: 100%
  max_memory_usage: 50_mb
}
```

**Never Constraints**: Absolute prohibitions
```apl
never: [
  "bypass_authentication",
  "skip_required_validation", 
  "lose_conversation_context",
  "expose_sensitive_data",
  "exceed_rate_limits"
]
```

**Always Constraints**: Required behaviors
```apl
always: [
  "validate_input_data",
  "maintain_audit_trail",
  "respect_privacy_settings",
  "provide_clear_feedback",
  "log_security_events"
]
```

**Conditional Constraints**: Context-dependent rules
```apl
conditional_constraints {
  when risk_level == "high" {
    require: "human_approval"
    max_auto_processing: 0
    audit_level: "detailed"
    notification_required: true
  }
  
  when customer_tier == "premium" {
    response_time_sla: 30_seconds
    escalation_threshold: 1_failure
    personalization_level: "high"
    priority_queue: true
  }
  
  when data_sensitivity == "pii" {
    encryption_required: true
    access_logging: "comprehensive"
    retention_policy: "30_days"
    approval_required: true
  }
}
```

### State-Specific Constraints

Constraints can be applied to specific states:

```apl
state_constraints {
  identity_verification: {
    max_attempts: 3
    timeout: 30_minutes
    required_documents: ["government_id", "proof_of_address"]
    security_level: "high"
    audit_trail: "complete"
  }
  
  payment_processing: {
    encryption_required: true
    audit_trail_mandatory: true
    dual_approval_threshold: 10000.00
    fraud_check_required: true
  }
  
  data_collection: {
    privacy_compliance: "gdpr"
    consent_verification: true
    data_minimization: true
    purpose_limitation: true
  }
}
```

---

## Testing Framework

### Test Suite Structure

APL includes testing through examples that serve as both documentation and validation:

```apl
examples {
  // Basic functionality examples
  customer_billing_dispute {
    input: { 
      query: "I was charged $75.50 for transaction TXN987654321 but I never authorized this"
    }
    
    expected_decisions: {
      issue_category: "billing",
      issue_type: "dispute",
      extracted_amount: 75.50,
      extracted_transaction: "TXN987654321",
      urgency_level: >= 7
    }
    
    expected_flow: [
      "greeting" -> "intent_analysis" -> "billing_verification" -> "dispute_resolution"
    ]
    
    expected_outputs: {
      resolution_type: "refund_initiated",
      confidence_score: >= 0.8,
      completion_time: <= 10_minutes
    }
  }
  
  // Complex workflow examples
  escalation_scenario {
    input: "This is the third time I'm calling about this issue and nobody helps!"
    
    expected_decisions: {
      frustration_level: >= 8,
      escalation_needed: true,
      priority: "immediate",
      customer_sentiment: "negative"
    }
    
    expected_flow: [
      "greeting" -> "frustration_detection" -> "immediate_escalation"
    ]
    
    expected_actions: [
      "log_escalation_trigger",
      "notify_supervisor", 
      "create_priority_ticket"
    ]
  }
  
  // Edge case examples
  unclear_request {
    input: "um, hi, I think maybe something might be wrong?"
    
    expected_decisions: {
      clarity_level: "very_low",
      confidence: <= 0.4,
      follow_up_needed: true
    }
    
    expected_behavior: "ask_clarifying_questions"
    
    clarification_sequence: [
      "Can you tell me more about what specific issue you're experiencing?",
      "Is this related to your account, a recent transaction, or something else?"
    ]
  }
  
  // Error handling examples
  system_failure_recovery {
    scenario: "database_unavailable"
    
    expected_behavior: {
      fallback_mode: "local_cache",
      user_notification: "experiencing_temporary_delays",
      retry_strategy: "exponential_backoff",
      escalation_after: 3_attempts
    }
  }
}

// Structured test scenarios for complex flows
test_scenarios {
  complete_billing_flow {
    sequence: [
      user: "I have a billing question",
      expect_agent: "identify_billing_category",
      user: "I was charged twice for my subscription", 
      expect_agent: "extract_subscription_details",
      user: "It's the premium plan for $29.99",
      expect_agent: "verify_duplicate_charge",
      expect_resolution: "duplicate_charge_refunded"
    ]
    
    success_criteria: {
      issue_resolved: true,
      customer_satisfaction: >= 4.0,
      data_accuracy: 100%,
      completion_time: <= 8_minutes
    }
  }
  
  multi_issue_handling {
    sequence: [
      user: "I can't log in AND I was charged wrong",
      expect_agent: "identify_multiple_issues",
      expect_flow: "prioritize_issues",
      expect_behavior: "address_login_first",
      final_state: "both_issues_resolved"
    ]
  }
}
```

### Test-Driven Development

Examples can guide agent development and serve as regression tests:

```apl
// Development examples that define expected behavior
development_examples {
  new_feature_request {
    description: "Handle subscription cancellation requests"
    
    input: "I want to cancel my subscription"
    
    desired_behavior: {
      @decide {
        cancellation_intent -> boolean [user_input]
        retention_opportunity -> boolean [customer_value + satisfaction_history]
        cancellation_reason -> reason_category [user_input + follow_up_questions]
      }
      
      if retention_opportunity {
        !execute offer_retention_incentives(customer_profile)
      } else {
        !execute process_cancellation(subscription_id)
      }
    }
    
    success_metrics: {
      intent_accuracy: >= 0.9,
      retention_rate: >= 0.3,
      process_completion: <= 5_minutes
    }
  }
}
```
---

## Advanced Features

### Meta-Programming

APL supports limited meta-programming capabilities for advanced use cases:

**Dynamic Agent Generation**: Runtime creation of agent behaviors
```apl
agent_factory {
  create_specialized_agent(domain: string, requirements: object) -> agent {
    base_template = !execute load_agent_template("generic_support")
    
    @decide {
      specialized_behavior -> agent_modifications [domain + requirements + best_practices]
      required_modules -> module_list [domain + complexity + available_modules]
    }
    
    enhanced_agent = !execute modify_agent(base_template, specialized_behavior)
    
    for module_name in required_modules {
      specialist_module = !execute load_module(module_name)
      !execute integrate_module(enhanced_agent, specialist_module)
    }
    
    return enhanced_agent
  }
}
```

### Advanced Decision Types

**Multi-Modal Decisions**: Decisions incorporating multiple input types
```apl
@decide {
  document_analysis -> {
    text_content: extracted_text,
    image_analysis: document_structure,
    authenticity_score: 0.0..1.0,
    confidence_factors: list[string]
  } [uploaded_image + ocr_results + fraud_detection_patterns]
}
```

**Temporal Decisions**: Time-aware decision making
```apl
@decide {
  escalation_urgency -> ["immediate", "within_hour", "next_business_day"] 
    [issue_severity + time_of_day + customer_tier + historical_patterns + sla_requirements]
    
  // Time-based constraints with business logic
  processing_strategy -> ["automated", "assisted", "manual_review"]
    [current_time in business_hours + complexity + staff_availability + workload]
}
```
---

This comprehensive specification provides the complete foundation for building sophisticated AI agents using APL, incorporating your requested changes while maintaining the language's depth and capability.
