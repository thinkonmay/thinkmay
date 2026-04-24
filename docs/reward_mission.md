# Thinkmay Mission & Reward System

This document explains the technical architecture and workflow of the Gamified Mission & Reward system implemented in the Thinkmay global database. 

## Overview

The Mission system is designed to reward users for completing specific actions on the platform, such as referring a paying friend or hitting playtime milestones. 

The core philosophy behind this system is **Lazy Evaluation (On-the-Fly Calculation)**. Instead of using complex database triggers to maintain a rolling `progress` state for every single user, the database dynamically calculates the user's progress against active missions *only* when the frontend queries for it.

### Why Lazy Evaluation?
1. **Retroactive Completion**: If a new "Play 120 hours" mission is added today, any user who already has 120+ hours of total playtime will instantly see it as `completed` and can claim it immediately. No database backfilling or synchronization scripts are required.
2. **Zero Race Conditions**: Because progress is derived directly from the source of truth (`subscriptions.total_usage` and `payment_request.verified_at`), there are no issues with race conditions or de-synchronization caused by complex trigger chains.
3. **Easy Extensibility**: Adding a new condition simply means adding a new row to the `missions` dictionary table and a minor case check in the SQL evaluator functions.

---

## Database Schema

The system relies on two new tables located in the `public` schema.

### 1. `missions`
This is a dictionary table that stores the configuration for all active and inactive missions.
- `id`: Primary key.
- `code`: A unique string identifier (e.g., `PLAY_3_HOURS`, `REFER_1_FRIEND`).
- `type`: The category of the mission (e.g., `PLAYTIME_MILESTONE`, `REFERRAL_PAYMENT`).
- `target_value`: The number required to complete the mission (e.g., 3 hours, 1 friend).
- `reward_type`: The kind of reward granted (e.g., `ADD_HOURS`).
- `reward_amount`: The magnitude of the reward (e.g., `5` hours).
- `is_active`: Boolean to easily toggle a mission on or off.

### 2. `user_mission_claims`
A ledger table that acts as a simple boolean flag to track if a user has already claimed the reward for a completed mission.
- `user_email`: The user's identifier.
- `mission_id`: Foreign key linking to the `missions` table.
- `claimed_at`: Timestamp of when the reward was granted.

---

## Remote Procedure Calls (RPCs)

The frontend interacts with the mission system entirely through two secure Supabase RPC functions.

### `get_user_missions_v1(p_email)`
**Purpose**: Render the frontend quest list with accurate progress data.
**Workflow**:
1. Pre-calculates the user's current baseline metrics (total lifetime playtime hours, total number of referred friends who have made a verified payment).
2. Queries all `active` missions from the `missions` table.
3. Compares the user's baseline metrics against the `target_value` of each mission.
4. Returns an array of mission objects, resolving the `status` to either `not_started`, `in_progress`, `completed`, or `claimed` based on whether the progress meets the target and whether a record exists in `user_mission_claims`.

### `claim_mission_v1(p_email, p_mission_code)`
**Purpose**: Securely validate a mission and execute the reward transaction when a user clicks "Claim".
**Workflow**:
1. Looks up the requested mission by `code`.
2. Checks `user_mission_claims` to ensure the user hasn't already claimed it. If they have, it aborts.
3. Dynamically recalculates the exact progress for this specific mission to guarantee they meet the `target_value`. If they don't, it aborts.
4. Inserts a record into `user_mission_claims` to prevent double-claiming.
5. **Applies the Reward**: If the `reward_type` is `ADD_HOURS`, it queries the database for the user's most recent active subscription. It then directly updates `subscriptions.usage_limit`, adding the `reward_amount` to their quota. If no active subscription is found, it aborts the transaction safely.

---

## How to Add New Missions

Because of the extensible design, developers can add new missions rapidly.

**Scenario**: Marketing wants to launch a new mission: "Play 500 Hours" to grant 20 Bonus Hours.
**Action Needed**: Run a single SQL insert statement.
```sql
INSERT INTO public.missions 
(code, type, target_value, reward_type, reward_amount) 
VALUES 
('PLAY_500_HOURS', 'PLAYTIME_MILESTONE', 500, 'ADD_HOURS', 20);
```
The system will instantly calculate progress toward 500 hours for all users the next time `get_user_missions_v1` is called.

**Scenario**: You want a completely new *Type* of mission (e.g., "Join Discord Server").
**Action Needed**:
1. Add the new condition check to the `CASE` statements inside the `get_user_missions_v1` and `claim_mission_v1` SQL functions (e.g., check a boolean flag on the user's profile).
2. Insert the mission row into `public.missions` with the type `JOIN_DISCORD`.
