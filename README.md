# Agent Prompting Language (APL)

**A declarative domain-specific language for building production AI agents**

## Overview

APL (Agent Prompting Language) is a language proposal for creating sophisticated AI agents with clear separation between LLM reasoning and deterministic system operations. It emphasizes ultra-compact expressiveness, state-aware processing, and dynamic module composition.

## Language Features

- **Decision-Execute Separation**: Clear distinction between `@decide` (LLM reasoning) and `!execute` (system operations)
- **State Machine Support**: Native support for complex multi-step workflows
- **Dynamic Module Loading**: Runtime composition of agent behaviors
- **Template System**: Structured response formats and type definitions
- **Built-in Testing**: Examples serve as both documentation and validation

## Language Status

🚧 **This is a language proposal and specification.** 

APL is currently in the design and specification phase. The language syntax, semantics, and features described in this repository represent a proposed approach to AI agent development. Implementation of interpreters, compilers, or runtime environments is ongoing.

## Repository Structure

- [`specification.md`](specification.md) - Complete language specification
- [`examples/`](examples/) - Example APL programs demonstrating language features
- [`LICENSE`](LICENSE) - License terms for using and modifying this specification

## Quick Example

```apl
// aplv2.0
agent CustomerSupportAgent {
  role: "helpful customer support representative"
  
  states {
    initial: "greeting"
    greeting { allowed_transitions: ["issue_identification"] }
    issue_identification { allowed_transitions: ["resolution", "escalation"] }
    resolution { final_state: true }
  }
  
  behavior {
    on_event {
      event(user_input) -> {
        @decide {
          user_intent -> ["question", "complaint", "request"] [input.text]
          urgency -> 1..10 [content + customer_history]
        }
        
        if urgency > 7 {
          !execute transition_to("escalation")
        } else {
          !execute provide_standard_response(user_intent)
        }
      }
    }
  }
}
```

## Examples

See the [`examples/`](examples/) directory for complete APL programs including:

- Customer support agents with state management
- Form handling and data collection workflows  
- Multi-module agent compositions
- Error handling and recovery patterns

## Contributing

This is an open language proposal. Contributions, suggestions, and discussions about the language design are welcome through issues and pull requests.

## Use Cases

APL is designed for:
- Customer service automation
- Form processing and data collection
- Multi-step business workflows
- Interactive troubleshooting systems
- Dynamic agent behavior composition

## License

This specification is available under the [MIT License with Attribution](LICENSE). You are free to use, modify, and distribute this specification with proper citation.

---

*APL v2.0 Language Specification*
