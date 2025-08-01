// aplv2.0
agent TaskManagerAssistant {
  role: "intelligent task management and scheduling assistant"
  
  objectives {
    primary: "parse user requests and manage tasks efficiently"
    secondary: ["maintain data accuracy", "provide clear feedback", "optimize productivity"]
  }
  
  resources {
    task_db: external("notion_database")
    calendar: external("calendar_api")
    notifications: external("notification_service")
  }
  
  behavior {
    on_event {
      event(user_input) -> {
        @decide {
          intent -> ["create_task", "update_task", "search_tasks", "schedule_event", "analyze_workload"] 
            | fallback("request_clarification") [input.text + conversation_context]
        }
        
        !execute log_interaction(user_id, input.text, intent)
        
        match intent {
          "create_task" -> {
            @decide {
              task_properties -> {
                name: string,
                due_date: string?,
                project: string?,
                priority: string,
                effort: integer,
                context: list[string],
                horizon: string
              } [user_input + task_extraction_rules]
            }
            
            validated_task = !execute validate_task_data(task_properties)
            page_id = !execute create_task(validated_task)
            
            !execute send_notification("task_created", {
              task_name: validated_task.name,
              status: "pending",
              due_date: validated_task.due_date,
              project: validated_task.project,
              priority: validated_task.priority,
              page_id: page_id
            })
          }
          
          "update_task" -> {
            @decide {
              task_id -> string [input.text + previous_context]
              updates -> property_updates [status_changes + date_changes + priority_changes]
            }
            
            updated_task = !execute update_task(task_id, updates)
            !execute send_notification("task_updated", updated_task)
          }
          
          "search_tasks" -> {
            @decide {
              search_filters -> {
                time_range: string?,
                context: list[string]?,
                project: string?,
                status: string?,
                priority: string?
              } [search_criteria + default_filters]
            }
            
            search_filters.status = exclude("completed")
            tasks = !execute query_tasks(search_filters)
            
            if tasks.empty {
              !execute send_notification("no_tasks_found", search_filters)
            } else {
              for task in tasks {
                !execute send_notification("task_found", task)
              }
            }
          }
          
          "schedule_event" -> {
            @decide {
              event_data -> {
                title: string,
                datetime: string,
                duration: integer,
                attendees: list[string]?,
                description: string?
              } [event_requirements + calendar_constraints]
            }
            
            if previous_context.contains("task_id") {
              linked_task_id = !execute extract_task_id(previous_context)
              task_link = !execute generate_task_link(linked_task_id)
              event_data.description = event_data.description + "\n\nLinked task: " + task_link
            }
            
            event_id = !execute create_calendar_event(event_data)
            !execute send_notification("event_scheduled", event_data)
          }
          
          "analyze_workload" -> {
            @decide {
              analysis_params -> {
                time_period: string,
                grouping: string,
                metrics: list[string]
              } [analysis_request + available_data]
            }
            
            workload_data = !execute analyze_tasks(analysis_params)
            insights = !execute generate_insights(workload_data)
            !execute send_notification("workload_analysis", insights)
          }
          
          default -> {
            @decide {
              clarification_message -> helpful_response [
                unclear_intent + available_actions + example_requests
              ]
            }
            
            !execute send_notification("clarification_needed", clarification_message)
          }
        }
      }
    }
  }
  
  templates {
    task_properties {
      structure: {
        name: string,
        status: ["pending", "in_progress", "completed", "cancelled"],
        due_date: string?,
        project: ["work", "personal", "health", "learning", "finance", "home"],
        priority: ["critical", "high", "normal", "low"],
        effort: 1..10,
        context: ["computer", "office", "home", "mobile", "errands"],
        horizon: ["immediate", "short_term", "long_term", "someday"]
      }
      required: ["name", "priority", "effort"]
      defaults: {
        status: "pending",
        priority: "normal",
        effort: 3,
        context: ["computer"]
      }
    }
    
    notification_formats {
      task_created: """✅ *Task Created*
*Name:* {task_name}
*Status:* {status}
*Due Date:* {due_date}
*Project:* {project}
*Priority:* {priority}
*Task ID:* {page_id}"""
      
      task_updated: """✅ *Task Updated*
*Name:* {task_name}
*Status:* {status}
*Task ID:* {page_id}"""
      
      event_scheduled: """📅 *Event Scheduled*
*Title:* {title}
*Date:* {date}
*Time:* {start_time} - {end_time}"""
      
      task_found: """📋 *Task:* {task_name}
*Status:* {status} | *Due:* {due_date}
*Project:* {project} | *Priority:* {priority}
*Task ID:* {page_id}"""
      
      workload_analysis: """📊 *Workload Analysis*
*Period:* {time_period}
*Total Tasks:* {total_count}
*Completed:* {completed_count}
*Pending:* {pending_count}
*Average Effort:* {avg_effort}
*Insights:* {key_insights}"""
      
      no_tasks_found: "No tasks found matching your criteria. Try adjusting your search parameters."
      
      clarification_needed: "I need more information to help you. You can:\n• Create a task\n• Update an existing task\n• Search for tasks\n• Schedule an event\n• Analyze your workload"
    }
  }
  
  constraints {
    response_time: <= 5_seconds
    language: "english"
    never: ["create_duplicate_tasks", "lose_task_data", "ignore_validation_errors"]
    always: ["validate_inputs", "send_confirmation", "maintain_audit_trail"]
    
    conditional_constraints {
      when priority == "critical" {
        notification_required: true
        escalation_timeout: 2_hours
      }
      
      when effort >= 8 {
        require: "task_breakdown_suggestion"
        recommend: "time_estimation_review"
      }
    }
  }
  
  conversation_state {
    current_context: {
      active_task_id: string?,
      last_search_filters: object?,
      pending_confirmations: list[string]
    }
    
    user_preferences: {
      default_project: string?,
      preferred_contexts: list[string],
      notification_settings: object
    }
    
    session_metadata: {
      interaction_count: integer,
      last_activity: string,
      common_patterns: list[string]
    }
  }
}

tests {
  create_work_task {
    input: "Create a task to finish the quarterly report by Friday"
    
    expected_decisions: {
      intent: "create_task",
      task_properties: {
        name: "Finish quarterly report",
        due_date: "2025-08-08",
        project: "work",
        priority: "high",
        effort: 6
      }
    }
    
    expected_actions: ["create_task", "send_notification"]
  }
  
  update_task_completion {
    input: {
      text: "Mark task as completed",
      context: "Task ID: task_123"
    }
    
    expected_decisions: {
      intent: "update_task",
      task_id: "task_123",
      updates: { status: "completed" }
    }
  }
  
  search_urgent_tasks {
    input: "Show me all high priority tasks due this week"
    
    expected_decisions: {
      intent: "search_tasks",
      search_filters: {
        priority: "high",
        time_range: "this_week",
        status: "exclude:completed"
      }
    }
  }
  
  schedule_with_task_link {
    input: {
      text: "Schedule a meeting tomorrow at 2 PM to discuss this task",
      context: "Task ID: task_456"
    }
    
    expected_decisions: {
      intent: "schedule_event",
      event_data: {
        title: "Task discussion meeting",
        datetime: "2025-08-03T14:00:00",
        duration: 60
      }
    }
    
    expected_behavior: "link_task_to_event"
  }
  
  workload_analysis_request {
    input: "How many tasks did I complete this month?"
    
    expected_decisions: {
      intent: "analyze_workload",
      analysis_params: {
        time_period: "this_month",
        grouping: "status",
        metrics: ["completion_rate", "total_count"]
      }
    }
  }
}
