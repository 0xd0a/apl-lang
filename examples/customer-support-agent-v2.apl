agent CustomerSupportV2 {
  role: "AI-powered customer support form specialist"
  
  objectives {
    primary: "intelligently match customer queries to appropriate forms and collect data efficiently"
    secondary: ["minimize conversation turns", "pre-fill known information", "adapt to new form types"]
  }
  
  resources {
    vector_search: external("n8n_vector_db")  // Contains APL form definitions
    conversation_memory: external("n8n_simple_db")
    form_executor: external("apl_runtime")     // Executes loaded APL form definitions
    nlp_extractor: external("field_extraction_ai")
  }
  
  // DYNAMIC FORM LOADING SYSTEM
  loaded_form_definition: object | empty  // Runtime-loaded APL form code
  
  states {
    initial: "greeting"
    
    greeting {
      allowed_transitions: ["intent_analysis", "restart_confirmed"]
    }
    
    intent_analysis {
      description: "analyze user query and search for matching forms"
      allowed_transitions: ["form_matched", "form_selection_needed", "clarify_intent"]
      auto_transition: true
    }
    
    form_matched {
      description: "form found via AI, pre-filling available fields"
      allowed_transitions: ["collecting_remaining_fields", "confirm_form_choice"]
    }
    
    form_selection_needed {
      description: "multiple forms possible, need user choice"
      allowed_transitions: ["form_matched", "clarify_intent"]
    }
    
    clarify_intent {
      description: "couldn't understand user intent clearly"
      allowed_transitions: ["intent_analysis", "form_selection_needed"]
      max_attempts: 2
    }
    
    confirm_form_choice {
      description: "confirm AI's form selection with user"
      allowed_transitions: ["form_matched", "form_selection_needed"]
    }
    
    collecting_remaining_fields {
      description: "collect fields not pre-filled by AI"
      allowed_transitions: ["collecting_remaining_fields", "validation_failed", "form_complete", "restart_confirmed"]
    }
    
    validation_failed {
      allowed_transitions: ["collecting_remaining_fields"]
      max_retries: 3
    }
    
    form_complete {
      allowed_transitions: ["confirmation", "collecting_remaining_fields"]
    }
    
    confirmation {
      allowed_transitions: ["json_generated", "collecting_remaining_fields", "restart_confirmed"]
    }
    
    json_generated {
      final_state: true
      cleanup_actions: ["save_request", "clear_form_memory"]
    }
    
    restart_confirmed {
      allowed_transitions: ["greeting"]
      cleanup_actions: ["clear_conversation_memory", "reset_form_state"]
    }
  }
  
  // ENHANCED CONVERSATION STATE
  conversation_state {
    original_query: string | empty
    intent_analysis: object | empty
    matched_forms: list[object]
    selected_form_definition: object | empty  // Loaded APL form code
    pre_filled_fields: map[string, any]
    collected_fields: map[string, any]
    missing_required_fields: list[string]
    current_field_name: string | empty
    validation_attempts: map[string, integer]
    conversation_turn: integer
    confidence_score: float
    extraction_metadata: object | empty
  }
  
  behavior {
    on_enter_state {
      greeting -> {
        @decide {
          is_restart_command -> boolean [input.text]
        }
        
        if is_restart_command {
          !execute transition_to("restart_confirmed")
        } else {
          conversation_state.original_query = input.text
          !execute send_message("👋 Hello! I'm analyzing your request to help you efficiently...")
          !execute transition_to("intent_analysis")
        }
      }
      
      intent_analysis -> {
        // ANALYZE USER INTENT AND EXTRACT ENTITIES
        @decide {
          intent_keywords -> extracted_terms [conversation_state.original_query]
          entity_extractions -> identified_entities [conversation_state.original_query]
          urgency_indicators -> urgency_level [conversation_state.original_query]
          query_complexity -> complexity_score [conversation_state.original_query]
        }
        
        conversation_state.intent_analysis = {
          keywords: intent_keywords,
          entities: entity_extractions,
          urgency: urgency_indicators,
          complexity: query_complexity
        }
        
        // VECTOR SEARCH FOR MATCHING FORMS
        search_results = !execute vector_search_forms(
          query: conversation_state.original_query,
          keywords: intent_keywords,
          entities: entity_extractions
        )
        
        @decide {
          best_matches -> ranked_forms [search_results.similarity_scores]
          match_confidence -> 0..1 [best_matches[0].similarity_score]
          disambiguation_needed -> boolean [best_matches.length > 1 && match_confidence < 0.9]
        }
        
        conversation_state.matched_forms = best_matches
        conversation_state.confidence_score = match_confidence
        
        if match_confidence > 0.8 && !disambiguation_needed {
          !execute transition_to("form_matched")
        } else if best_matches.length > 1 {
          !execute transition_to("form_selection_needed")
        } else {
          !execute transition_to("clarify_intent")
        }
      }
      
      form_matched -> {
        // LOAD DYNAMIC FORM DEFINITION FROM VECTOR DB
        selected_form = conversation_state.matched_forms[0]
        
        // Load APL form definition (this is the key innovation!)
        loaded_form_apl = !execute load_form_definition(selected_form.form_id)
        conversation_state.selected_form_definition = loaded_form_apl
        
        // EXECUTE THE LOADED FORM'S EXTRACTION LOGIC
        @decide {
          pre_filled_data -> extracted_fields [
            conversation_state.original_query, 
            loaded_form_apl.extraction_rules,
            conversation_state.intent_analysis
          ]
          extraction_confidence -> field_confidence_map [pre_filled_data]
        }
        
        conversation_state.pre_filled_fields = pre_filled_data
        conversation_state.extraction_metadata = {
          confidence_scores: extraction_confidence,
          extraction_method: "ai_nlp",
          source_query: conversation_state.original_query
        }
        
        pre_filled_count = len(pre_filled_data)
        form_name = loaded_form_apl.name
        
        if pre_filled_count > 0 {
          !execute send_message(f"""
✅ **I understand you need help with: {form_name}**

🤖 I've automatically extracted **{pre_filled_count} pieces of information** from your message:
{format_pre_filled_summary(pre_filled_data)}

Let me just collect the remaining details...
          """)
        } else {
          !execute send_message(f"""
✅ **I understand you need help with: {form_name}**

Let me collect the necessary information step by step.
          """)
        }
        
        !execute transition_to("collecting_remaining_fields")
      }
      
      form_selection_needed -> {
        top_matches = conversation_state.matched_forms[:3]  // Top 3 matches
        
        options_text = []
        for i, form in enumerate(top_matches) {
          options_text.append(f"{i+1}️⃣ **{form.name}** - {form.description}")
        }
        
        !execute send_message(f"""
🤔 I found multiple possible forms for your request:

{join(options_text, "\n")}

Which one best matches what you need? (Type 1, 2, or 3)
        """)
      }
      
      clarify_intent -> {
        !execute send_message("""
🤔 I'd like to help you better. Could you provide a bit more detail about what you need assistance with?

For example:
• "I can't log into my account"
• "I want to dispute a charge for $50"  
• "I need to request my data export"
• "I want to suggest a new feature"
        """)
      }
      
      collecting_remaining_fields -> {
        // Use the LOADED FORM DEFINITION to determine what to collect
        form_def = conversation_state.selected_form_definition
        all_filled_fields = {**conversation_state.pre_filled_fields, **conversation_state.collected_fields}
        
        // Execute the loaded form's field collection logic
        missing_required = []
        for field in form_def.required_fields {
          if field not in all_filled_fields {
            missing_required.append(field)
          }
        }
        
        if missing_required.empty {
          !execute transition_to("form_complete")
        } else {
          current_field = missing_required[0]
          conversation_state.current_field_name = current_field
          conversation_state.missing_required_fields = missing_required
          
          // Use the loaded form's prompting logic
          field_prompt = form_def.field_prompts[current_field]
          progress = f"({len(form_def.required_fields) - len(missing_required) + 1}/{len(form_def.required_fields)})"
          
          !execute send_message(f"📝 **{progress}** {field_prompt}")
        }
      }
      
      confirmation -> {
        form_def = conversation_state.selected_form_definition
        all_data = {**conversation_state.pre_filled_fields, **conversation_state.collected_fields}
        
        // Separate pre-filled vs manually collected
        pre_filled_summary = []
        manual_summary = []
        
        for field, value in all_data.items() {
          formatted_field = field.replace('_', ' ').title()
          if field in conversation_state.pre_filled_fields {
            confidence = conversation_state.extraction_metadata.confidence_scores.get(field, 0)
            pre_filled_summary.append(f"• **{formatted_field}:** {value} ✨ *auto-detected ({confidence:.0%} confidence)*")
          } else {
            manual_summary.append(f"• **{formatted_field}:** {value}")
          }
        }
        
        summary = ""
        if pre_filled_summary {
          summary += "**🤖 Auto-detected information:**\n" + "\n".join(pre_filled_summary) + "\n\n"
        }
        if manual_summary {
          summary += "**📝 Information you provided:**\n" + "\n".join(manual_summary)
        }
        
        !execute send_message(f"""
📋 **{form_def.name} Summary:**

{summary}

Is this information correct? 
✅ Type 'yes' to submit
✏️ Type 'edit [field name]' to change something  
🔄 Type 'restart' to start over
        """)
      }
    }
    
    on_event {
      // RESTART COMMAND - works from any state
      event(user_input) + input.text.contains("restart") -> {
        !execute transition_to("restart_confirmed")
      }
      
      // INTENT CLARIFICATION
      state(clarify_intent) + event(user_input) -> {
        // Re-run analysis with additional context
        conversation_state.original_query += " " + input.text
        !execute transition_to("intent_analysis")
      }
      
      // FORM SELECTION
      state(form_selection_needed) + event(user_input) -> {
        user_choice = input.text.trim()
        
        @decide {
          selected_index -> integer [user_choice]
        }
        
        if selected_index >= 1 && selected_index <= len(conversation_state.matched_forms) {
          // Move selected form to front
          selected_form = conversation_state.matched_forms[selected_index - 1]
          conversation_state.matched_forms = [selected_form] + conversation_state.matched_forms
          !execute transition_to("form_matched")
        } else {
          !execute send_message("❌ Please choose 1, 2, or 3.")
        }
      }
      
      // FIELD COLLECTION (using loaded form definition)
      state(collecting_remaining_fields) + event(user_input) -> {
        current_field = conversation_state.current_field_name
        field_value = input.text.trim()
        
        // Use loaded form's validation rules
        form_def = conversation_state.selected_form_definition
        validation_rule = form_def.validation.get(current_field)
        
        @decide {
          is_valid -> boolean [field_value, validation_rule]
          validation_error -> error_message [field_value, validation_rule]
        }
        
        if is_valid {
          conversation_state.collected_fields[current_field] = field_value
          !execute send_message("✅ Perfect!")
          !execute transition_to("collecting_remaining_fields")
        } else {
          conversation_state.validation_attempts[current_field] = 
            conversation_state.validation_attempts.get(current_field, 0) + 1
          
          if conversation_state.validation_attempts[current_field] >= 3 {
            !execute send_message("❌ Having trouble with this field. Let me connect you with a human agent.")
            !execute escalate_to_human(conversation_state)
          } else {
            !execute send_message(f"❌ {validation_error}\n\nPlease try again:")
          }
        }
      }
      
      // CONFIRMATION
      state(confirmation) + event(user_input) -> {
        user_response = input.text.lower().trim()
        
        if user_response in ["yes", "y", "confirm", "submit", "looks good"] {
          !execute transition_to("json_generated")
        } else if user_response.startswith("edit") {
          @decide {
            field_to_edit -> field_name [user_response, {**conversation_state.pre_filled_fields, **conversation_state.collected_fields}.keys()]
          }
          
          if field_to_edit {
            conversation_state.current_field_name = field_to_edit
            form_def = conversation_state.selected_form_definition
            field_prompt = form_def.field_prompts[field_to_edit]
            
            // If editing a pre-filled field, move it to collected_fields
            if field_to_edit in conversation_state.pre_filled_fields {
              current_value = conversation_state.pre_filled_fields[field_to_edit]
              del conversation_state.pre_filled_fields[field_to_edit]
              !execute send_message(f"🔄 **Editing {field_to_edit.replace('_', ' ').title()}**\nCurrent value: *{current_value}*\n\n{field_prompt}")
            } else {
              !execute send_message(f"🔄 **Editing {field_to_edit.replace('_', ' ').title()}**\n{field_prompt}")
            }
            
            !execute transition_to("collecting_remaining_fields")
          } else {
            all_fields = {**conversation_state.pre_filled_fields, **conversation_state.collected_fields}
            field_list = ", ".join(all_fields.keys())
            !execute send_message(f"❓ Which field would you like to edit?\nAvailable fields: {field_list}")
          }
        } else {
          !execute send_message("Please respond with 'yes' to confirm, 'edit [field]' to change something, or 'restart' to start over.")
        }
      }
      
      // RESTART HANDLING
      state(restart_confirmed) + event(user_input) -> {
        !execute clear_conversation_memory()
        conversation_state = reset_conversation_state()
        !execute send_message("🔄 Conversation restarted. What can I help you with today?")
        !execute transition_to("greeting")
      }
    }
    
    on_exit_state {
      json_generated -> {
        all_data = {**conversation_state.pre_filled_fields, **conversation_state.collected_fields}
        form_def = conversation_state.selected_form_definition
        
        request_json = {
          "request_id": f"REQ-{generate_request_id()}",
          "request_type": form_def.type_id,
          "form_name": form_def.name,
          "timestamp": current_timestamp(),
          "customer_data": all_data,
          "collection_method": "ai_assisted_v2",
          "conversation_turns": conversation_state.conversation_turn,
          "ai_assistance": {
            "pre_filled_fields": list(conversation_state.pre_filled_fields.keys()),
            "manual_fields": list(conversation_state.collected_fields.keys()),
            "extraction_confidence": conversation_state.extraction_metadata.confidence_scores,
            "form_match_confidence": conversation_state.confidence_score,
            "total_extraction_percentage": len(conversation_state.pre_filled_fields) / len(all_data)
          },
          "validation_attempts": sum(conversation_state.validation_attempts.values()),
          "completion_status": "success"
        }
        
        !execute save_request_json(request_json)
        
        efficiency_stats = f"Pre-filled: {len(conversation_state.pre_filled_fields)}/{len(all_data)} fields ({len(conversation_state.pre_filled_fields)/len(all_data)*100:.0f}%)"
        
        !execute send_message(f"""
🎉 **Request Created Successfully!**

📋 **Request ID:** {request_json.request_id}
📊 **Type:** {form_def.name}
⏱️ **Collected in:** {conversation_state.conversation_turn} turns
🤖 **AI Efficiency:** {efficiency_stats}

Your request has been submitted to our team. You'll receive updates via your preferred contact method.

**Generated JSON:**
```json
{json.stringify(request_json, indent=2)}
```

*Type 'restart' if you need to create another request.*
        """)
        
        !execute clear_form_memory()
      }
    }
  }
  
  // HELPER FUNCTIONS FOR DYNAMIC FORM LOADING
  functions {
    load_form_definition(form_id: string) -> object {
      // Load APL form definition from vector DB and parse it
      form_apl_code = !execute vector_search.get_form_definition(form_id)
      parsed_form = !execute apl_runtime.parse_form_definition(form_apl_code)
      return parsed_form
    }
    
    format_pre_filled_summary(data: map) -> string {
      lines = []
      for field, value in data.items() {
        formatted_field = field.replace('_', ' ').title()
        lines.append(f"  • **{formatted_field}:** {value}")
      }
      return "\n".join(lines)
    }
    
    reset_conversation_state() -> object {
      return {
        original_query: empty,
        intent_analysis: empty,
        matched_forms: [],
        selected_form_definition: empty,
        pre_filled_fields: {},
        collected_fields: {},
        missing_required_fields: [],
        current_field_name: empty,
        validation_attempts: {},
        conversation_turn: 0,
        confidence_score: 0.0,
        extraction_metadata: empty
      }
    }
    
    clear_conversation_memory() {
      !execute n8n_simple_db.clear(conversation_id)
    }
  }
  
  constraints {
    max_collection_time: 30_minutes
    min_form_match_confidence: 0.4
    max_validation_attempts: 3
    required_extraction_confidence: 0.7
    never: ["skip_validation", "assume_low_confidence_extractions", "lose_original_query_context"]
    always: ["validate_loaded_form_definitions", "maintain_extraction_audit_trail", "provide_transparency_about_ai_assistance"]
  }
}

test_suite SupportV2Tests {
  scenario "high_confidence_auto_extraction" {
    input: { query: "I was charged $75.50 for transaction TXN987654321 on my account 12345678 but I never authorized this payment" }
    expect: {
      form_matched: "billing_dispute"
      pre_filled_fields: ["customer_id", "transaction_id", "dispute_amount", "dispute_reason"]
      manual_fields: ["contact_preference"]
      conversation_turns: <= 3
      extraction_confidence: > 0.8
    }
  }
  
  scenario "partial_extraction_with_manual_completion" {
    input: { query: "My account login isn't working and it's urgent" }
    expect: {
      form_matched: "account_issue"
      pre_filled_fields: ["issue_type", "urgency"]
      manual_fields: ["customer_id", "description"]
      conversation_turns: <= 4
    }
  }
  
  scenario "form_disambiguation_needed" {
    input: { query: "I need help with billing" }
    expect: {
      state_visited: "form_selection_needed"
      multiple_forms_presented: true
      user_choice_required: true
    }
  }
  
  scenario "dynamic_form_loading_and_execution" {
    input: { query: "I want to export all my data" }
    expect: {
      form_loaded_from_vector_db: true
      form_definition_executed: true
      extraction_rules_applied: true
      pre_filled_fields: ["data_type", "purpose"]
    }
  }
  
  scenario "edit_pre_filled_field" {
    sequence: [
      "confirmation" -> "edit transaction_id" -> "collecting_remaining_fields",
      "collecting_remaining_fields" -> "TXN111222333" -> "collecting_remaining_fields"
    ]
    expect: {
      field_moved_from_prefilled_to_manual: true
      new_value_captured: "TXN111222333"
      validation_applied: true
    }
  }
}
