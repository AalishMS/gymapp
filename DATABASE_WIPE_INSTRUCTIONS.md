# Supabase Database Wipe Instructions

## Option 1: Manual SQL in Supabase Dashboard (Recommended)

1. Go to your Supabase Dashboard
2. Navigate to SQL Editor  
3. Copy and paste the contents of `database_wipe.sql` 
4. Click "RUN" to execute the script
5. Verify all counts are 0 in the results

## Option 2: Using Supabase CLI (if you have project details)

If you have your Supabase project URL and service role key:

```bash
# Login to Supabase CLI (you'll need to provide your access token)
npx supabase login

# Connect to your project (replace with your project reference)
npx supabase link --project-ref YOUR_PROJECT_REF

# Run the wipe script
npx supabase db push --file database_wipe.sql
```

## Option 3: Environment Variables Method

If you have a `.env` file in your API directory with DATABASE_URL:

```bash
# Navigate to your API directory
cd gymapp_api

# Create .env file with your DATABASE_URL from Supabase
# DATABASE_URL=postgresql://postgres:your-password@your-host.supabase.co:5432/postgres

# Use psql to run the script (if available)
psql $DATABASE_URL -f ../database_wipe.sql
```

## What this wipe will do:

- Delete all session sets
- Delete all session exercises  
- Delete all workout sessions
- Delete all plan exercises
- Delete all workout plans
- Delete all users
- Provide verification counts (should all be 0)

After running this, you'll have a completely clean database ready for fresh registration testing.