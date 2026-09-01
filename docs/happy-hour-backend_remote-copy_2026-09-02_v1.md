<!-- Read-only copy of bloodyanalytics02:~/docs/features/happy-hour-backend.md (dev team doc, last commit 2025-12-23). Pulled 2026-09-02 for the Happy Hour A/B work. STALE where noted in .agent/capsules/happy-hour-ab-test.md: the BonusDeposit processor was confirmed implemented 2026-08-26. -->

# Happy Hour - Backend Documentation

## Overview

The Happy Hour system is a gamification feature that allows BloodyCase to run timed promotional events where users can complete specific conditions (e.g., open cases, make deposits) to earn the right to spin a prize wheel. The system uses cron-based scheduling to automatically create, start, and end happy hour events with configurable conditions and prize pools.

## Technology Stack

| Technology | Purpose | Version |
|------------|---------|---------|
| **Go** | Primary language | 1.24.3 |
| **gRPC/Connect** | API protocol | connectrpc.com/connect v1.18.1 |
| **GORM** | Database ORM | - |
| **PostgreSQL** | Primary database | - |
| **NATS** | Event streaming | v1.43.0 |
| **AWS Lambda** | Serverless functions | - |
| **AWS EventBridge Scheduler** | Cron scheduling | - |
| **AWS SQS** | Lambda triggers | - |
| **Robfig Cron** | Cron expression parsing | v1.2.0 |

## Service Architecture

### Main Components

```
┌─────────────────────────────────────────────────────────────┐
│                         Main Service                         │
│  - gRPC API Server (Public + Admin)                         │
│  - NATS Consumers (CaseOpened, Deposit)                     │
│  - Happy Hour Service (eligibility, progress tracking)      │
│  - Prize Service (spin wheel, reward distribution)          │
└─────────────────────────────────────────────────────────────┘
                              │
           ┌──────────────────┼──────────────────┐
           ▼                  ▼                  ▼
    ┌─────────────┐   ┌─────────────┐   ┌─────────────┐
    │   Create    │   │    Start    │   │    Close    │
    │   Lambda    │   │   Lambda    │   │   Lambda    │
    └─────────────┘   └─────────────┘   └─────────────┘
           ▲                  ▲                  ▲
           │                  │                  │
    ┌─────────────┐   ┌─────────────┐   ┌─────────────┐
    │ EventBridge │   │ EventBridge │   │ EventBridge │
    │  Scheduler  │   │  Scheduler  │   │  Scheduler  │
    └─────────────┘   └─────────────┘   └─────────────┘
```

### Deployment Model

The service runs in **two modes**:

1. **Main Service** (ECS/EC2):
   - Serves gRPC API requests
   - Consumes NATS events
   - Tracks player progress in real-time

2. **Lambda Functions** (AWS Lambda):
   - `CreateHappyHourFunction`: Creates new happy hour instances from planners
   - `StartHappyHourFunction`: Activates happy hours at scheduled time
   - `CloseHappyHourFunction`: Finalizes happy hours and schedules next cycle

## Happy Hour Mechanics

### Lifecycle States

| Status | Value | Description |
|--------|-------|-------------|
| `Unspecified` | 0 | Invalid/default state |
| `Scheduled` | 1 | Created but not yet active |
| `Active` | 2 | Currently running, users can participate |
| `Finished` | 3 | Ended and finalized |

### Planner System

A **Planner** is a template that defines recurring happy hour events:

**Source:** `pkg/database/planner.go` ([GitHub](https://github.com/bloodyorg/happy-hour/blob/master/pkg/database/planner.go))

```go
type Planner struct {
    ID              uuid.UUID    // Unique planner ID
    IsCyclical      bool         // If true, reschedules after completion
    IsActive        bool         // If false, stops scheduling
    Conditions      []*Condition // Eligibility requirements
    Prizes          []*Prize     // Prize pool configuration
    Cron            string       // Cron expression (e.g., "0 12 * * *")
    DurationMinutes int32        // How long the event runs
}
```

**Flow:**
1. Admin creates planner with cron schedule
2. Scheduler creates first `HappyHour` instance at cron time
3. When event ends, if `IsCyclical=true`, schedules next instance

**Code Reference:** `pkg/happy_hour/service.go:44-90` ([GitHub](https://github.com/bloodyorg/happy-hour/blob/master/pkg/happy_hour/service.go#L44-L90))

### Event Lifecycle

```
Admin Creates Planner
    ↓
EventBridge scheduled at cron.Next(now)
    ↓
CreateHappyHourFunction triggered
    ↓
Creates HappyHour (status=Scheduled)
    ↓
Schedules StartLambda + CloseLambda
    ↓
StartHappyHourFunction triggered at StartsAt
    ↓
Status → Active
    ↓
NATS event published: happy_hour.happy_hour_started
    ↓
[Event runs for DurationMinutes]
    ↓
CloseHappyHourFunction triggered at EndsAt
    ↓
Status → Finished
    ↓
NATS event published: happy_hour.happy_hour_finished
    ↓
If IsCyclical, schedule next CreateLambda
```

**Create Logic:** `pkg/happy_hour/lifecycle.go:36-99` ([GitHub](https://github.com/bloodyorg/happy-hour/blob/master/pkg/happy_hour/lifecycle.go#L36-L99))
**Start Logic:** `pkg/happy_hour/lifecycle.go:101-136` ([GitHub](https://github.com/bloodyorg/happy-hour/blob/master/pkg/happy_hour/lifecycle.go#L101-L136))
**Close Logic:** `pkg/happy_hour/lifecycle.go:138-202` ([GitHub](https://github.com/bloodyorg/happy-hour/blob/master/pkg/happy_hour/lifecycle.go#L138-L202))

### Condition System

Players must complete conditions to become eligible to spin:

**Source:** `pkg/database/planner.go:15-29` ([GitHub](https://github.com/bloodyorg/happy-hour/blob/master/pkg/database/planner.go#L15-L29))

| Type | Value | Description | Fields |
|------|-------|-------------|--------|
| `NoCondition` | 1 | Always eligible | - |
| `OpenCase` | 2 | Open N cases | `Count`, `SpecificCaseIDs` (optional) |
| `MakeDeposit` | 3 | Deposit N amount | `Count` (amount in cents) |
| `NotParticipated24Hours` | 4 | Last spin >24h ago | - |

**Condition Schema:**
```go
type Condition struct {
    Type            ConditionType
    Count           int32    // Required count/amount
    SpecificCaseIDs []int32  // Optional case filter for OpenCase
}
```

**Examples:**
- Open 3 cases: `{Type: 2, Count: 3, SpecificCaseIDs: []}`
- Open 2 specific cases: `{Type: 2, Count: 2, SpecificCaseIDs: [101, 202]}`
- Deposit $10: `{Type: 3, Count: 1000}`
- No conditions: `{Type: 1, Count: 0}`

### Progress Tracking

When a player's action occurs, the system:

1. **NATS Consumer** receives event (`CaseOpenedEvent` or `DepositEvent`)
2. **ProcessClientProgress** is called:
   - Gets or creates `Client` record
   - Gets or creates `ClientHappyHour` for current active event
   - Creates `ClientProgressRequirement` array from event conditions
   - Finds matching processor for condition type
   - Processor updates `Value` and `IsCompleted` fields
   - If all conditions completed: sets `CanSpin=true`

**Source:** `pkg/happy_hour/service.go:246-374` ([GitHub](https://github.com/bloodyorg/happy-hour/blob/master/pkg/happy_hour/service.go#L246-L374))

**Processors:**
- `NoConditionProcessor`: Always marks completed ([source](https://github.com/bloodyorg/happy-hour/blob/master/pkg/conditions/processor_no_conditions.go))
- `OpenCaseProcessor`: Increments on case opened, supports specific case IDs ([source](https://github.com/bloodyorg/happy-hour/blob/master/pkg/conditions/processor_open_case.go))
- `MakeDepositProcessor`: Accumulates deposit amount during event window ([source](https://github.com/bloodyorg/happy-hour/blob/master/pkg/conditions/processor_make_deposit.go))
- `LastParticipatedProcessor`: Checks 24h cooldown from last win ([source](https://github.com/bloodyorg/happy-hour/blob/master/pkg/conditions/processor_last_participated.go))

**Processor Interface:**
```go
type Processor interface {
    Type() database.ConditionType
    Process(ctx context.Context, req *ProcessRequest) (bool, error)
}
```

Each processor is registered at service initialization and mapped to its condition type for dynamic dispatch during progress tracking.

### Prize System

Prize pool is configured per planner with weighted random selection:

**Source:** `pkg/database/planner.go:31-46` ([GitHub](https://github.com/bloodyorg/happy-hour/blob/master/pkg/database/planner.go#L31-L46))

| Type | Value | Description | Fields |
|------|-------|-------------|--------|
| `PromoCode` | 1 | Case promo code | `CaseID`, `Amount` (uses count) |
| `FreeTicket` | 2 | Case battle ticket | `CaseID`, `Amount` |
| `EventCoins` | 3 | Event currency | `Amount` |
| `BonusDeposit` | 4 | Deposit bonus % | `Amount` (percentage) |

**Prize Schema:**
```go
type Prize struct {
    Type   PrizeType
    Weight int32  // Relative probability (not used in current impl)
    Amount int32  // Prize amount/count
    CaseID int32  // Required for PromoCode/FreeTicket
}
```

**Current Implementation:** Simple random selection (no weight consideration)
```go
randomPrize := hh.Prizes[rand.Intn(len(hh.Prizes))]
```

**Note:** The `Weight` field exists in the schema but is not currently used in prize selection logic. All prizes have equal probability.

**Source:** `pkg/prizes/service.go:68` ([GitHub](https://github.com/bloodyorg/happy-hour/blob/master/pkg/prizes/service.go#L68))

### Spin Flow

1. Client calls `Spin(happy_hour_id)`
2. System checks:
   - `ClientHappyHour` exists
   - `CanSpin == true`
   - `PrizeWon == null` (TODO: currently disabled for testing)
3. Random prize selected from pool
4. Prize processor distributes reward:
   - **PromoCode**: Calls `cases_internal.GeneratePromoCode`
   - **FreeTicket**: Calls `accounting_internal.AddFreeTicket`
   - **EventCoins**: Calls `stats_events_internal.AddEventCurrencyToClient`
   - **BonusDeposit**: (Not yet implemented)
5. Updates `ClientHappyHour`:
   - `PrizeWon = selectedPrize`
   - `PrizeSentAt = now()`

**Source:** `pkg/prizes/service.go:39-107` ([GitHub](https://github.com/bloodyorg/happy-hour/blob/master/pkg/prizes/service.go#L39-L107))

### Prize Processors

Similar to condition processors, prize distribution uses a processor pattern:

**Processor Interface:**
```go
type Processor interface {
    Type() database.PrizeType
    Process(ctx context.Context, req *ProcessRequest) (*ProcessResponse, error)
}
```

**Available Processors:**
- `PromoCodeProcessor`: Generates 7-day promo codes via Case Service ([source](https://github.com/bloodyorg/happy-hour/blob/master/pkg/prizes/process_promocode.go))
- `FreeTicketProcessor`: Credits free tickets via Accounting Service ([source](https://github.com/bloodyorg/happy-hour/blob/master/pkg/prizes/process_free_ticket.go))
- `EventCoinsProcessor`: Adds event currency via Stats Service ([source](https://github.com/bloodyorg/happy-hour/blob/master/pkg/prizes/process_event_coins.go))

Each processor handles the external service call and returns metadata (e.g., promo code details) to be included in the spin response.

## gRPC API Endpoints

### Public API

**Service:** `bloody.happy_hour.public_api.v1.HappyHourPublicAPIService`

#### GetCurrentHappyHour

Gets the currently active happy hour event.

**Request:** Empty
**Response:**
```protobuf
message GetCurrentHappyHourResponse {
  HappyHour happy_hour = 1; // null if no active event
}
```

**Handler:** `cmd/apis/public_api/happy_hour.go:9-23` ([GitHub](https://github.com/bloodyorg/happy-hour/blob/master/cmd/apis/public_api/happy_hour.go#L9-L23))

#### GetClientHappyHour

Gets client's progress in current happy hour.

**Request:**
```protobuf
message GetClientHappyHourRequest {
  string happy_hour_id = 1;
}
```

**Response:**
```protobuf
message GetClientHappyHourResponse {
  ClientHappyHour client_happy_hour = 1;
}
```

**Handler:** `cmd/apis/public_api/client_happy_hour.go` ([GitHub](https://github.com/bloodyorg/happy-hour/blob/master/cmd/apis/public_api/client_happy_hour.go))

#### CanSpin

Checks if client can spin (processes progress first).

**Request:**
```protobuf
message CanSpinRequest {
  string happy_hour_id = 1;
}
```

**Response:**
```protobuf
message CanSpinResponse {
  bool can_spin = 1;
}
```

**Handler:** `cmd/apis/public_api/prizes.go:15-36` ([GitHub](https://github.com/bloodyorg/happy-hour/blob/master/cmd/apis/public_api/prizes.go#L15-L36))

#### Spin

Spins the prize wheel and awards prize.

**Request:**
```protobuf
message SpinRequest {
  string happy_hour_id = 1;
}
```

**Response:**
```protobuf
message SpinResponse {
  PrizeType type = 1;
  int32 amount = 2;
  PromoCodeReward promo_code_reward = 3; // Only for PromoCode type

  message PromoCodeReward {
    string code = 1;
    Case case = 2;
  }
}
```

**Handler:** `cmd/apis/public_api/prizes.go:38-71` ([GitHub](https://github.com/bloodyorg/happy-hour/blob/master/cmd/apis/public_api/prizes.go#L38-L71))

### Admin API

**Service:** `bloody.happy_hour.admin_api.v1.HappyHourAdminAPIService`

#### CreatePlanner

Creates a new happy hour planner.

**Request:**
```protobuf
message CreatePlannerRequest {
  bool is_cyclical = 1;
  bool is_active = 2;
  string cron = 3;              // e.g., "0 12 * * *"
  int32 duration_minutes = 4;
  repeated Condition conditions = 5;
  repeated Prize prizes = 6;
}
```

**Response:**
```protobuf
message CreatePlannerResponse {
  string planner_id = 1; // UUID
}
```

**Handler:** `cmd/apis/admin_api/planner.go:13-47` ([GitHub](https://github.com/bloodyorg/happy-hour/blob/master/cmd/apis/admin_api/planner.go#L13-L47))

#### EditPlanner

Updates existing planner configuration.

**Request:**
```protobuf
message EditPlannerRequest {
  string planner_id = 1;
  bool is_cyclical = 2;
  bool is_active = 3;
  string cron = 4;
  int32 duration_minutes = 5;
  repeated Condition conditions = 6;
  repeated Prize prizes = 7;
}
```

**Response:**
```protobuf
message EditPlannerResponse {
  string planner_id = 1;
}
```

**Handler:** `cmd/apis/admin_api/planner.go:49-84` ([GitHub](https://github.com/bloodyorg/happy-hour/blob/master/cmd/apis/admin_api/planner.go#L49-L84))

#### GetPlanners

Lists planners by IDs.

**Request:**
```protobuf
message GetPlannersRequest {
  repeated string ids = 1; // Empty = all planners
}
```

**Response:**
```protobuf
message GetPlannersResponse {
  repeated Planner planners = 1;
}
```

**Handler:** `cmd/apis/admin_api/planner.go:86-109` ([GitHub](https://github.com/bloodyorg/happy-hour/blob/master/cmd/apis/admin_api/planner.go#L86-L109))

## Database Schema

### Table: `planners`

Defines recurring happy hour templates.

```sql
CREATE TABLE IF NOT EXISTS planners (
    id               UUID PRIMARY KEY,
    is_cyclical      BOOLEAN DEFAULT false,
    is_active        BOOLEAN DEFAULT false,
    conditions       JSONB,
    prizes           JSONB,
    cron             VARCHAR(255),
    duration_minutes INTEGER DEFAULT 0,
    created_at       TIMESTAMP NOT NULL DEFAULT NOW()
);
```

**JSONB Schemas:**

`conditions`:
```json
[
  {
    "type": 2,
    "count": 3,
    "specific_case_ids": [101, 202]
  }
]
```

`prizes`:
```json
[
  {
    "type": 3,
    "weight": 50,
    "amount": 100,
    "case_id": 0
  }
]
```

**Migration:** `pkg/database/migrations.go:66-82` ([GitHub](https://github.com/bloodyorg/happy-hour/blob/master/pkg/database/migrations.go#L66-L82))

### Table: `happy_hours`

Individual happy hour event instances.

```sql
CREATE TABLE IF NOT EXISTS happy_hours (
    id           UUID PRIMARY KEY,
    planner_id   UUID NOT NULL,
    created_at   TIMESTAMP NOT NULL DEFAULT NOW(),
    finalized_at TIMESTAMP,
    starts_at    TIMESTAMP NOT NULL,
    ends_at      TIMESTAMP NOT NULL,
    conditions   JSONB,
    prizes       JSONB DEFAULT NULL,
    status       INTEGER NOT NULL DEFAULT 0
);
```

**Status Values:**
- `0`: Unspecified
- `1`: Scheduled
- `2`: Active
- `3`: Finished

**Migration:** `pkg/database/migrations.go:47-63` ([GitHub](https://github.com/bloodyorg/happy-hour/blob/master/pkg/database/migrations.go#L47-L63))

### Table: `clients`

Player statistics and tracking.

```sql
CREATE TABLE IF NOT EXISTS clients (
    id                  INTEGER PRIMARY KEY,
    client_uuid         UUID NOT NULL,
    total_won           INTEGER DEFAULT 0,
    created_at          TIMESTAMP,
    last_win_at         TIMESTAMP,
    last_happy_hour_id  VARCHAR(36)
);
```

**Fields:**
- `total_won`: Number of times player has won (completed conditions)
- `last_win_at`: Last time player completed conditions
- `last_happy_hour_id`: Last event player participated in

**Migration:** `pkg/database/migrations.go:11-24` ([GitHub](https://github.com/bloodyorg/happy-hour/blob/master/pkg/database/migrations.go#L11-L24))

### Table: `client_happy_hours`

Player progress in specific happy hour events.

```sql
CREATE TABLE IF NOT EXISTS client_happy_hours (
    id                   UUID PRIMARY KEY,
    client_id            INTEGER NOT NULL,
    happy_hour_id        UUID NOT NULL,
    created_at           TIMESTAMP,
    completed_at         TIMESTAMP,
    progress_requirement JSONB,
    prize_won            JSONB,
    prize_sent_at        TIMESTAMP,
    can_spin             BOOLEAN DEFAULT false
);
```

**JSONB Schemas:**

`progress_requirement`:
```json
[
  {
    "type": 2,
    "value": 2,
    "is_completed": false,
    "condition": {
      "type": 2,
      "count": 3,
      "specific_case_ids": []
    }
  }
]
```

`prize_won`:
```json
{
  "type": 3,
  "weight": 50,
  "amount": 100,
  "case_id": 0
}
```

**Migration:** `pkg/database/migrations.go:27-44` ([GitHub](https://github.com/bloodyorg/happy-hour/blob/master/pkg/database/migrations.go#L27-L44))

## External Integrations

### NATS Event Consumers

**OpenCase Consumer:**
- **Subject:** Cases service event stream
- **Event Type:** `bloody.case.v1.CaseOpenedEvent`
- **Processor:** `OpenCaseProcessor`
- **Action:** Increments case open count, checks specific case IDs

**Source:** `cmd/consumers/consumer_open_case.go` ([GitHub](https://github.com/bloodyorg/happy-hour/blob/master/cmd/consumers/consumer_open_case.go))

**MakeDeposit Consumer:**
- **Subject:** Deposit event stream
- **Event Type:** `DepositEvent`
- **Processor:** `MakeDepositProcessor`
- **Action:** Accumulates deposit amount (must be during event window)

**Source:** `cmd/consumers/consumer_make_deposit.go` ([GitHub](https://github.com/bloodyorg/happy-hour/blob/master/cmd/consumers/consumer_make_deposit.go))

### NATS Event Publishers

**HappyHourStarted:**
- **Subject:** `happy-hour`
- **Event:** `happy_hour.happy_hour_started`
- **Payload:** `bloody.happy_hour.v1.HappyHour` (protobuf)
- **Trigger:** When happy hour becomes active

**HappyHourFinished:**
- **Subject:** `happy-hour.{happy_hour_id}`
- **Event:** `happy_hour.happy_hour_finished`
- **Payload:** `bloody.happy_hour.v1.HappyHour` (protobuf)
- **Trigger:** When happy hour ends

**Source:** `pkg/happy_hour/lifecycle.go:126-133, 171-178` ([GitHub](https://github.com/bloodyorg/happy-hour/blob/master/pkg/happy_hour/lifecycle.go#L126-L133))

### gRPC Client Integrations

| Service | Purpose | Used In |
|---------|---------|---------|
| `accounting_internal` | Add free case tickets | FreeTicketProcessor |
| `cases_internal` | Generate promo codes | PromoCodeProcessor |
| `stats_events_internal` | Add event coins | EventCoinsProcessor |

**Client Setup:** `main.go:47-50` ([GitHub](https://github.com/bloodyorg/happy-hour/blob/master/main.go#L47-L50))

## AWS Infrastructure

### EventBridge Schedulers

Three separate scheduler groups manage lifecycle:

**CreateScheduler:**
- **Trigger:** Cron expression from planner
- **Target:** `CreateHappyHourFunction` SQS queue
- **Payload:** `{planner_id: "uuid"}`
- **Created:** When planner is created/activated

**StartScheduler:**
- **Trigger:** `happy_hour.starts_at` timestamp
- **Target:** `StartHappyHourFunction` SQS queue
- **Payload:** `{happy_hour_id: "uuid", planned_scheduler_at: "timestamp"}`
- **Created:** When happy hour instance is created

**CloseScheduler:**
- **Trigger:** `happy_hour.ends_at` timestamp
- **Target:** `CloseHappyHourFunction` SQS queue
- **Payload:** `{happy_hour_id: "uuid", planned_scheduler_at: "timestamp"}`
- **Created:** When happy hour instance is created

**Scheduler Implementations:**
- `pkg/happy_hour/scheduler_create.go` ([GitHub](https://github.com/bloodyorg/happy-hour/blob/master/pkg/happy_hour/scheduler_create.go))
- `pkg/happy_hour/scheduler_start.go` ([GitHub](https://github.com/bloodyorg/happy-hour/blob/master/pkg/happy_hour/scheduler_start.go))
- `pkg/happy_hour/scheduler_end.go` ([GitHub](https://github.com/bloodyorg/happy-hour/blob/master/pkg/happy_hour/scheduler_end.go))

### Lambda Functions

**CreateHappyHourFunction:**
- **Trigger:** SQS (EventBridge Scheduler)
- **Timeout:** 180s
- **VPC:** Enabled (database access)
- **Template:** `template.yaml:121-165` ([GitHub](https://github.com/bloodyorg/happy-hour/blob/master/template.yaml#L121-L165))

**StartHappyHourFunction:**
- **Trigger:** SQS (EventBridge Scheduler)
- **Timeout:** 180s
- **VPC:** Enabled (database + NATS)
- **Template:** `template.yaml:79-119` ([GitHub](https://github.com/bloodyorg/happy-hour/blob/master/template.yaml#L79-L119))

**CloseHappyHourFunction:**
- **Trigger:** SQS (EventBridge Scheduler)
- **Timeout:** 180s
- **VPC:** Enabled (database + NATS + scheduler)
- **Template:** `template.yaml:31-77` ([GitHub](https://github.com/bloodyorg/happy-hour/blob/master/template.yaml#L31-L77))

## Key Business Logic

### Eligibility Rules

1. **Active Event Required:**
   - Only one happy hour can be active at a time
   - Status must be `Active` (2)

2. **Condition Completion:**
   - ALL conditions must be completed (`IsCompleted=true`)
   - Progress is cumulative during event window
   - Deposit conditions check timestamp is within `[starts_at, ends_at]`

3. **Spin Once Rule:**
   - Currently disabled for testing (`prizes/service.go:51-53` commented out)
   - When enabled: `PrizeWon != null` prevents re-spin
   - TODO: Re-enable after testing phase

4. **24h Cooldown (Optional):**
   - If `NotParticipated24Hours` condition exists
   - Checks `client.last_win_at < now() - 24h`

**Source:** `pkg/conditions/processor_last_participated.go` ([GitHub](https://github.com/bloodyorg/happy-hour/blob/master/pkg/conditions/processor_last_participated.go))

### Cron Scheduling Logic

When planner is created/updated:
1. Parse cron expression: `cron.Parse(cron_string)`
2. Calculate next execution: `cronParsed.Next(time.Now().UTC())`
3. Create EventBridge schedule for `CreateLambda`
4. Lambda creates `HappyHour` instance
5. Schedules `StartLambda` and `CloseLambda` with absolute timestamps

**Important:** Cron calculation happens only at planner activation/update time. Individual events use absolute timestamps.

**Source:** `pkg/happy_hour/service.go:76-84` ([GitHub](https://github.com/bloodyorg/happy-hour/blob/master/pkg/happy_hour/service.go#L76-L84))

### Cyclical Rescheduling

When `CloseHappyHourFunction` runs:
1. Marks event as `Finished`
2. Publishes `happy_hour_finished` event
3. Loads planner from `happy_hour.planner_id`
4. If `planner.is_active && planner.is_cyclical`:
   - Calculates next run: `cron.Parse(planner.cron).Next(now)`
   - Schedules `CreateLambda` at calculated time

**Source:** `pkg/happy_hour/lifecycle.go:180-199` ([GitHub](https://github.com/bloodyorg/happy-hour/blob/master/pkg/happy_hour/lifecycle.go#L180-L199))

### One-Time Events

For non-cyclical planners:
1. When `CreateLambda` runs, sets `planner.is_active = false`
2. This prevents future scheduling
3. Event runs once and completes

**Source:** `pkg/happy_hour/lifecycle.go:54-60` ([GitHub](https://github.com/bloodyorg/happy-hour/blob/master/pkg/happy_hour/lifecycle.go#L54-L60))

## Error Codes

Custom error codes defined in `pkg/codes/error_codes.go`:

| Code | Constant | Meaning |
|------|----------|---------|
| `1001` | `ErrorClientAlreadySpin` | Client already spun (prize_won exists) |
| `1002` | `ErrorConeCantSpin` | Client cannot spin (conditions not met) |

**Source:** `pkg/codes/error_codes.go` ([GitHub](https://github.com/bloodyorg/happy-hour/blob/master/pkg/codes/error_codes.go))

## Configuration

### Environment Variables

**Database:**
- `Db_Host`, `Db_Port`, `Db_User`, `Db_Password`: Master DB
- `ReadonlyDb_Host`, `ReadonlyDb_Port`, `ReadonlyDb_User`, `ReadonlyDb_Password`: Readonly replica

**NATS:**
- `Nats_Uri`: Backend event bus
- `NatsFrontEnd_Uri`: Frontend event bus (for publishing happy hour events)

**AWS:**
- `HappyHour_SchedulerGroupName`: EventBridge scheduler group
- `HappyHour_CreateSQSQueueArn`: Create lambda queue ARN
- `HappyHour_CreateSQSRoleArn`: IAM role for scheduler
- `HappyHour_StartSQSQueueArn`: Start lambda queue ARN
- `HappyHour_StartSQSRoleArn`: IAM role for scheduler
- `HappyHour_CloseSQSQueueArn`: Close lambda queue ARN
- `HappyHour_CloseSQSRoleArn`: IAM role for scheduler

**Source:** `configuration/config.go` ([GitHub](https://github.com/bloodyorg/happy-hour/blob/master/configuration/config.go))

## Implementation Notes

### Important Caveats

1. **Prize Weight Not Implemented:**
   - The `weight` field exists in prize schema but is currently ignored
   - All prizes have equal probability regardless of weight value
   - Future implementation would require weighted random selection algorithm

2. **Spin-Once Protection Disabled:**
   - Currently commented out for testing purposes (`prizes/service.go:51-53`)
   - Production deployment should re-enable to prevent multiple prize claims
   - Check: `if clientHH.PrizeWon != nil { return ErrClientAlreadyWon }`

3. **MakeDeposit Timing:**
   - Only deposits made AFTER event creation (`happy_hour.created_at`) count
   - Deposits must occur before `happy_hour.ends_at`
   - Pre-event deposits do not retroactively qualify

4. **OpenCase Specific Cases:**
   - If `SpecificCaseIDs` is empty, any case counts
   - If `SpecificCaseIDs` has values, only those cases increment progress
   - Case opening events are processed asynchronously via NATS

5. **Database Transactions:**
   - Progress tracking uses `DbTypeMaster` (write DB)
   - Read operations use `DbTypeReadonly` where possible
   - Progress updates are atomic per event but not globally locked

6. **EventBridge Scheduler Limits:**
   - AWS EventBridge has quotas on schedule count and rate
   - Each planner creates up to 3 schedules (create, start, end)
   - Consider cleanup of old schedules in production

### Performance Considerations

- **NATS Consumer Backpressure:** High case opening volume may cause lag in progress updates
- **Database Queries:** `GetActiveHappyHour` query uses `status` filter and `ORDER BY created_at DESC`
- **JSON Serialization:** GORM serializes conditions/prizes as JSONB on every save
- **EventBridge Precision:** Scheduler triggers may have up to 15-second delay

### Testing Recommendations

1. Use isolated planner IDs for test events
2. Set short `duration_minutes` (e.g., 5 minutes) for testing
3. Mock external gRPC services (accounting, cases, stats)
4. Test cron edge cases (leap years, DST transitions)
5. Verify EventBridge scheduler creation/deletion

## Related Documentation

- [Cases Service](./cases.md) - Integration for OpenCase condition
- [Accounting Service](./accounting.md) - Integration for FreeTicket prizes
- [Stats Events Service](./stats-events.md) - Integration for EventCoins prizes
- [Platform Events](../platform/events.md) - NATS event specifications

## Changelog

| Date | Change | Author |
|------|--------|--------|
| 2025-12-23 | Enhanced with processor patterns, implementation notes, performance considerations | Tech Writer |
| 2025-12-23 | Initial backend documentation | Tech Writer |

