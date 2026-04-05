-- SUPABASE DATABASE WIPE SCRIPT
-- Run this SQL in your Supabase Dashboard > SQL Editor
-- This will delete all users and their associated data

-- WARNING: This will permanently delete ALL data
-- Make sure you're running this on the correct database

-- Step 1: Delete all data in dependency order (foreign key constraints)
-- Start with dependent tables first, then parent tables

-- Delete session sets (depends on session_exercises)
DELETE FROM session_sets;

-- Delete session exercises (depends on workout_sessions)  
DELETE FROM session_exercises;

-- Delete workout sessions (depends on users and workout_plans)
DELETE FROM workout_sessions;

-- Delete plan exercises (depends on workout_plans)
DELETE FROM plan_exercises;

-- Delete workout plans (depends on users)
DELETE FROM workout_plans;

-- Finally, delete all users
DELETE FROM users;

-- Step 2: Reset any sequences if needed (optional)
-- This ensures new UUIDs start fresh if using sequences

-- Step 3: Verify all data is deleted
SELECT 'users' as table_name, COUNT(*) as remaining_records FROM users
UNION ALL
SELECT 'workout_plans' as table_name, COUNT(*) as remaining_records FROM workout_plans  
UNION ALL
SELECT 'plan_exercises' as table_name, COUNT(*) as remaining_records FROM plan_exercises
UNION ALL
SELECT 'workout_sessions' as table_name, COUNT(*) as remaining_records FROM workout_sessions
UNION ALL
SELECT 'session_exercises' as table_name, COUNT(*) as remaining_records FROM session_exercises
UNION ALL
SELECT 'session_sets' as table_name, COUNT(*) as remaining_records FROM session_sets;

-- All counts should be 0 after running the DELETE statements above