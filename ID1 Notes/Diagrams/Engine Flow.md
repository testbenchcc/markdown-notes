```mermaid
flowchart LR
  %% Primary engine modes
  STOP([Stop])
  MAN([Manual])
  AUTO([Auto])
  SOURCE{ANY SOURCE?}

  DEMAND{DEMAND?}
  FILL{FILL REQUEST?}
  TRANSFER
  ANYSD{ANY SD ALARM?}
  INTERVAL{INTERVAL}


  subgraph "ENGINE STATES"
    TRANSFER
    RECIRCULATE
    SUPPLYING
    STANDBY
  end


  %% Allowed transitions (per your rundown)
  STOP --> MAN
  MAN -. RUN / Maint .-> MAN
  MAN --> AUTO
  AUTO -- CONFIRM --> MAN
  AUTO -- CONFIRM --> STOP

  %% Forbidden transitions (shown as comments for clarity)
  %% STOP -x-> AUTO   // not allowed
  %% MAN  -x-> STOP   // not allowed per spec you gave


  AUTO --> ANYSD -- FALSE --> SOURCE
  SOURCE -- TRUE --> DEMAND
  SOURCE -- FALSE --> STANDBY

  DEMAND -- TRUE --> SUPPLYING
  DEMAND -- FALSE --> FILL
  FILL -- TRUE --> TRANSFER
  FILL -- FALSE --> INTERVAL


  ANYSD -- TRUE --> STOP


  INTERVAL -- TRUE --> RECIRCULATE
  INTERVAL -- FALSE --> STANDBY  
  RECIRCULATE -- DURATION --> RECIRCULATE
```

