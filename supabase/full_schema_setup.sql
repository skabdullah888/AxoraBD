-- ============================================================
-- COMPLETE SCHEMA SETUP FOR SUPABASE
-- Run this script in your Supabase SQL Editor:
-- https://supabase.com/dashboard/project/dytjcfgxkmkgydgmffzk/sql/new
-- ============================================================

-- 1. ENUMS & EXTENSIONS
DO $$ BEGIN
  CREATE TYPE public.app_role AS ENUM ('admin', 'user');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- 2. TABLES

-- Profiles
CREATE TABLE IF NOT EXISTS public.profiles (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
  username text NOT NULL,
  full_name text,
  email text,
  phone text,
  avatar_url text,
  referral_code text UNIQUE,
  referred_by uuid,
  balance numeric NOT NULL DEFAULT 0,
  trust_score integer NOT NULL DEFAULT 100,
  status text NOT NULL DEFAULT 'inactive',
  is_publisher boolean NOT NULL DEFAULT false,
  publisher_restricted boolean NOT NULL DEFAULT false,
  activated_at timestamptz,
  last_activation_request_at timestamptz,
  signup_ip text,
  last_checkin_at timestamptz,
  checkin_streak integer NOT NULL DEFAULT 0,
  notify_tasks boolean NOT NULL DEFAULT true,
  notify_payments boolean NOT NULL DEFAULT true,
  notify_appeals boolean NOT NULL DEFAULT true,
  withdrawal_method text,
  withdrawal_account text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- User Roles
CREATE TABLE IF NOT EXISTS public.user_roles (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  role public.app_role NOT NULL,
  UNIQUE(user_id, role)
);

-- Tasks
CREATE TABLE IF NOT EXISTS public.tasks (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  publisher_id uuid REFERENCES public.profiles(user_id) ON DELETE SET NULL,
  title text NOT NULL,
  description text,
  instructions text,
  category text DEFAULT 'general',
  reward numeric NOT NULL DEFAULT 0,
  total_slots integer NOT NULL DEFAULT 1,
  completed_slots integer NOT NULL DEFAULT 0,
  status text NOT NULL DEFAULT 'pending',
  deadline timestamptz,
  proof_type text DEFAULT 'image',
  proof_count integer NOT NULL DEFAULT 1,
  proof_examples jsonb DEFAULT '[]'::jsonb,
  proof_fields jsonb NOT NULL DEFAULT '[]'::jsonb,
  banner_url text,
  auto_approve boolean NOT NULL DEFAULT false,
  show_publisher boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now()
);

-- Task Submissions
CREATE TABLE IF NOT EXISTS public.task_submissions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  task_id uuid REFERENCES public.tasks(id) ON DELETE CASCADE,
  user_id uuid REFERENCES public.profiles(user_id) ON DELETE CASCADE,
  status text NOT NULL DEFAULT 'pending',
  note text,
  proof_text text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- Task Submission Proofs
CREATE TABLE IF NOT EXISTS public.task_submission_proofs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  submission_id uuid REFERENCES public.task_submissions(id) ON DELETE CASCADE,
  image_url text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

-- Payments
CREATE TABLE IF NOT EXISTS public.payments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES public.profiles(user_id) ON DELETE CASCADE,
  amount numeric NOT NULL,
  type text NOT NULL,
  status text NOT NULL DEFAULT 'pending',
  method text,
  reference text,
  sender_number text,
  receiver_number text,
  trnx_id text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- Appeals
CREATE TABLE IF NOT EXISTS public.appeals (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  submission_id uuid REFERENCES public.task_submissions(id) ON DELETE CASCADE,
  user_id uuid REFERENCES public.profiles(user_id) ON DELETE CASCADE,
  reason text NOT NULL,
  status text NOT NULL DEFAULT 'pending',
  admin_note text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- Notifications
CREATE TABLE IF NOT EXISTS public.notifications (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
  type text NOT NULL,
  title text NOT NULL,
  message text NOT NULL,
  read boolean NOT NULL DEFAULT false,
  admin_targeted boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now()
);

-- Settings
CREATE TABLE IF NOT EXISTS public.settings (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  activation_fee numeric NOT NULL DEFAULT 0,
  activation_amount numeric NOT NULL DEFAULT 5,
  withdrawal_fee numeric NOT NULL DEFAULT 0,
  minimum_withdrawal numeric NOT NULL DEFAULT 10,
  publisher_task_tax numeric NOT NULL DEFAULT 0,
  referral_bonus numeric NOT NULL DEFAULT 1,
  referral_bonus_type text NOT NULL DEFAULT 'fixed' CHECK (referral_bonus_type IN ('fixed','percent')),
  referral_bonus_percent numeric NOT NULL DEFAULT 0,
  minimum_referrals_for_withdrawal integer NOT NULL DEFAULT 0,
  minimum_tasks_for_withdrawal integer NOT NULL DEFAULT 0,
  withdrawals_enabled boolean NOT NULL DEFAULT true,
  withdrawals_hidden boolean NOT NULL DEFAULT false,
  minimum_task_publish_amount numeric NOT NULL DEFAULT 0,
  minimum_task_total_amount numeric NOT NULL DEFAULT 0,
  duplicate_ip_warning_enabled boolean NOT NULL DEFAULT true,
  duplicate_ip_warning_message text NOT NULL DEFAULT 'We detected that another account was created from the same IP address as yours. Creating multiple accounts violates our terms and may result in suspension.',
  duplicate_ip_warning_title text NOT NULL DEFAULT 'Account warning: duplicate IP detected',
  site_theme text NOT NULL DEFAULT 'default',
  site_logo_url text,
  ads_enabled boolean NOT NULL DEFAULT false,
  ads_client text NOT NULL DEFAULT '',
  ads_slots jsonb NOT NULL DEFAULT '{}'::jsonb,
  ads_provider text NOT NULL DEFAULT 'adsense',
  ads_txt text NOT NULL DEFAULT '',
  ads_verification_meta text NOT NULL DEFAULT '',
  ads_head_script text NOT NULL DEFAULT '',
  ads_extra_scripts jsonb NOT NULL DEFAULT '{}'::jsonb,
  social_facebook text,
  social_youtube text,
  social_instagram text,
  social_twitter text,
  social_telegram text,
  social_whatsapp text,
  social_tiktok text,
  social_linkedin text,
  contact_email text,
  signup_bonus_enabled boolean NOT NULL DEFAULT false,
  signup_bonus_amount numeric NOT NULL DEFAULT 0,
  signup_bonus_max_users integer NOT NULL DEFAULT 0,
  signup_bonus_start_at timestamptz,
  signup_bonus_granted_count integer NOT NULL DEFAULT 0,
  daily_checkin_enabled boolean NOT NULL DEFAULT false,
  daily_checkin_amount numeric NOT NULL DEFAULT 0,
  daily_checkin_streak_days integer NOT NULL DEFAULT 7,
  daily_checkin_streak_bonus numeric NOT NULL DEFAULT 0,
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- Referral Earnings
CREATE TABLE IF NOT EXISTS public.referral_earnings (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  referrer_id uuid NOT NULL,
  referred_id uuid NOT NULL,
  amount numeric NOT NULL DEFAULT 0,
  status text NOT NULL DEFAULT 'pending',
  created_at timestamptz NOT NULL DEFAULT now()
);

-- Payment Methods
CREATE TABLE IF NOT EXISTS public.payment_methods (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  receiver_number text NOT NULL,
  instructions text,
  active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now()
);

-- Notice Board
CREATE TABLE IF NOT EXISTS public.notice_board (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title text NOT NULL,
  body text NOT NULL,
  type text NOT NULL DEFAULT 'info',
  active boolean NOT NULL DEFAULT true,
  created_by uuid,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- Section Videos
CREATE TABLE IF NOT EXISTS public.section_videos (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  section_key text NOT NULL UNIQUE,
  title text NOT NULL DEFAULT '',
  video_url text NOT NULL DEFAULT '',
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- Support Messages
CREATE TABLE IF NOT EXISTS public.support_messages (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  sender text NOT NULL CHECK (sender IN ('user','admin')),
  sender_id uuid,
  message text NOT NULL,
  read_by_admin boolean NOT NULL DEFAULT false,
  read_by_user boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now()
);

-- Security Logs
CREATE TABLE IF NOT EXISTS public.security_logs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid,
  username text,
  action text NOT NULL,
  ip_address text,
  user_agent text,
  suspicious boolean NOT NULL DEFAULT false,
  meta jsonb,
  created_at timestamptz NOT NULL DEFAULT now()
);

-- Email Send Log
CREATE TABLE IF NOT EXISTS public.email_send_log (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  message_id text,
  template_name text NOT NULL,
  recipient_email text NOT NULL,
  status text NOT NULL CHECK (status IN ('pending', 'sent', 'suppressed', 'failed', 'bounced', 'complained', 'dlq')),
  error_message text,
  metadata jsonb,
  created_at timestamptz NOT NULL DEFAULT now()
);

-- Email Send State
CREATE TABLE IF NOT EXISTS public.email_send_state (
  id integer PRIMARY KEY DEFAULT 1 CHECK (id = 1),
  retry_after_until timestamptz,
  batch_size integer NOT NULL DEFAULT 10,
  send_delay_ms integer NOT NULL DEFAULT 200,
  auth_email_ttl_minutes integer NOT NULL DEFAULT 15,
  transactional_email_ttl_minutes integer NOT NULL DEFAULT 60,
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- Suppressed Emails
CREATE TABLE IF NOT EXISTS public.suppressed_emails (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  email text NOT NULL UNIQUE,
  reason text NOT NULL CHECK (reason IN ('unsubscribe', 'bounce', 'complaint')),
  metadata jsonb,
  created_at timestamptz NOT NULL DEFAULT now()
);

-- Email Unsubscribe Tokens
CREATE TABLE IF NOT EXISTS public.email_unsubscribe_tokens (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  token text NOT NULL UNIQUE,
  email text NOT NULL UNIQUE,
  created_at timestamptz NOT NULL DEFAULT now(),
  used_at timestamptz
);

-- Seed default settings if empty
INSERT INTO public.settings (minimum_withdrawal, withdrawal_fee, activation_fee, publisher_task_tax, referral_bonus, activation_amount)
SELECT 10, 0, 0, 5, 1, 5
WHERE NOT EXISTS (SELECT 1 FROM public.settings);

INSERT INTO public.email_send_state (id) VALUES (1) ON CONFLICT DO NOTHING;

INSERT INTO public.payment_methods (name, receiver_number, instructions)
SELECT 'bKash', '01700000000', 'Send money to the number above and submit the transaction ID.'
WHERE NOT EXISTS (SELECT 1 FROM public.payment_methods);

INSERT INTO public.section_videos (section_key, title) VALUES
  ('tasks', 'How to browse & complete tasks'),
  ('submissions', 'How submissions work'),
  ('appeals', 'How to file an appeal'),
  ('wallet', 'How the wallet works'),
  ('deposit', 'How to deposit'),
  ('withdraw', 'How to withdraw'),
  ('publish', 'How to publish a task'),
  ('referrals', 'How referrals work')
ON CONFLICT (section_key) DO NOTHING;

-- 3. FUNCTIONS & HELPERS

CREATE OR REPLACE FUNCTION public.has_role(_user_id uuid, _role public.app_role)
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT EXISTS (SELECT 1 FROM public.user_roles WHERE user_id = _user_id AND role = _role)
$$;
GRANT EXECUTE ON FUNCTION public.has_role(uuid, public.app_role) TO authenticated, anon, service_role;

CREATE OR REPLACE FUNCTION public.get_site_theme()
RETURNS text LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT coalesce(site_theme, 'default') FROM public.settings LIMIT 1;
$$;
GRANT EXECUTE ON FUNCTION public.get_site_theme() TO anon, authenticated;

CREATE OR REPLACE FUNCTION public.gen_referral_code()
RETURNS text LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE c text;
BEGIN
  LOOP
    c := upper(substr(md5(random()::text || clock_timestamp()::text), 1, 8));
    EXIT WHEN NOT EXISTS (SELECT 1 FROM public.profiles WHERE referral_code = c);
  END LOOP;
  RETURN c;
END $$;

CREATE OR REPLACE FUNCTION public.notify_admins(p_title text, p_message text, p_type text)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  INSERT INTO public.notifications (user_id, title, message, type, admin_targeted)
  SELECT ur.user_id, p_title, p_message, p_type, true
  FROM public.user_roles ur WHERE ur.role = 'admin';
END $$;

CREATE OR REPLACE FUNCTION public.get_my_referrals()
RETURNS TABLE(id uuid, username text, status text, created_at timestamptz)
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT id, username, status, created_at
  FROM public.profiles
  WHERE referred_by = auth.uid()
  ORDER BY created_at DESC
$$;
GRANT EXECUTE ON FUNCTION public.get_my_referrals() TO authenticated;

-- Signup Trigger Function
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $function$
DECLARE
  ref_code text;
  ref_by uuid;
  meta_ref text;
  base_username text;
  final_username text;
  suffix int := 0;
  final_phone text;
  fee numeric;
  initial_status text;
  meta_ip text;
  dup_count int;
  dup_enabled boolean;
  dup_title text;
  dup_msg text;
  uname text;
  bonus_enabled boolean;
  bonus_amount numeric;
  bonus_max int;
  bonus_start timestamptz;
  bonus_granted int;
  bonus_to_credit numeric := 0;
  initial_balance numeric := 0;
BEGIN
  IF EXISTS (SELECT 1 FROM public.profiles WHERE user_id = new.id) THEN
    RETURN new;
  END IF;

  ref_code := public.gen_referral_code();
  meta_ref := new.raw_user_meta_data ->> 'referral_code';

  IF meta_ref IS NOT NULL AND length(meta_ref) > 0 THEN
    SELECT user_id INTO ref_by FROM public.profiles WHERE referral_code = upper(meta_ref) LIMIT 1;
  END IF;

  base_username := coalesce(nullif(new.raw_user_meta_data ->> 'username', ''), split_part(new.email, '@', 1));
  final_username := base_username;
  WHILE EXISTS (SELECT 1 FROM public.profiles WHERE lower(username) = lower(final_username)) LOOP
    suffix := suffix + 1;
    final_username := base_username || suffix::text;
  END LOOP;

  final_phone := nullif(new.raw_user_meta_data ->> 'phone', '');
  IF final_phone IS NOT NULL AND EXISTS (SELECT 1 FROM public.profiles WHERE phone = final_phone) THEN
    final_phone := null;
  END IF;

  meta_ip := nullif(new.raw_user_meta_data ->> 'signup_ip', '');

  SELECT coalesce(activation_fee, activation_amount, 0) INTO fee FROM public.settings LIMIT 1;
  IF coalesce(fee, 0) <= 0 THEN
    initial_status := 'active';
  ELSE
    initial_status := 'inactive';
  END IF;

  SELECT coalesce(signup_bonus_enabled,false), coalesce(signup_bonus_amount,0),
         coalesce(signup_bonus_max_users,0), signup_bonus_start_at,
         coalesce(signup_bonus_granted_count,0)
    INTO bonus_enabled, bonus_amount, bonus_max, bonus_start, bonus_granted
    FROM public.settings LIMIT 1 FOR UPDATE;

  IF bonus_enabled AND bonus_amount > 0 AND bonus_max > 0
     AND (bonus_start IS NULL OR now() >= bonus_start)
     AND bonus_granted < bonus_max
  THEN
    bonus_to_credit := bonus_amount;
    initial_balance := bonus_amount;
    UPDATE public.settings SET signup_bonus_granted_count = bonus_granted + 1;
  END IF;

  INSERT INTO public.profiles (user_id, username, email, phone, referral_code, referred_by, status, activated_at, signup_ip, balance)
  VALUES (new.id, final_username, new.email, final_phone, ref_code, ref_by, initial_status,
          CASE WHEN initial_status = 'active' THEN now() ELSE null END, meta_ip, initial_balance);

  IF bonus_to_credit > 0 THEN
    INSERT INTO public.payments (user_id, type, amount, status, reference)
    VALUES (new.id, 'signup_bonus', bonus_to_credit, 'approved', 'signup_bonus');

    INSERT INTO public.notifications (user_id, title, message, type)
    VALUES (new.id, 'Welcome bonus credited',
            'You received ৳' || bonus_to_credit::text || ' signup bonus. Enjoy!',
            'signup_bonus');
  END IF;

  IF meta_ip IS NOT NULL THEN
    SELECT count(*) INTO dup_count FROM public.profiles WHERE signup_ip = meta_ip AND user_id <> new.id;
    IF dup_count > 0 THEN
      SELECT coalesce(duplicate_ip_warning_enabled, true),
             coalesce(duplicate_ip_warning_title, 'Account warning: duplicate IP detected'),
             coalesce(duplicate_ip_warning_message, '')
        INTO dup_enabled, dup_title, dup_msg
        FROM public.settings LIMIT 1;

      IF coalesce(dup_enabled, true) AND length(coalesce(dup_msg, '')) > 0 THEN
        INSERT INTO public.notifications (user_id, title, message, type)
        VALUES (new.id, dup_title, dup_msg, 'warning');
      END IF;

      uname := final_username;
      PERFORM public.notify_admins(
        'Duplicate signup IP detected',
        coalesce(uname, 'A new user') || ' signed up from an IP used by ' || dup_count::text || ' other account(s) (' || meta_ip || ')',
        'duplicate_ip'
      );
    END IF;
  END IF;

  RETURN new;
END;
$function$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Profile privilege protection trigger
CREATE OR REPLACE FUNCTION public.prevent_profile_privilege_escalation()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $function$
BEGIN
  IF public.has_role(auth.uid(), 'admin') THEN RETURN NEW; END IF;
  IF current_setting('role', true) = 'none' OR session_user = 'postgres' THEN
    NULL;
  END IF;
  IF NEW.trust_score IS DISTINCT FROM OLD.trust_score
     OR NEW.publisher_restricted IS DISTINCT FROM OLD.publisher_restricted
     OR NEW.status IS DISTINCT FROM OLD.status
     OR NEW.activated_at IS DISTINCT FROM OLD.activated_at
     OR NEW.referral_code IS DISTINCT FROM OLD.referral_code
     OR NEW.referred_by IS DISTINCT FROM OLD.referred_by
     OR NEW.user_id IS DISTINCT FROM OLD.user_id
     OR NEW.balance IS DISTINCT FROM OLD.balance
     OR NEW.signup_ip IS DISTINCT FROM OLD.signup_ip
     OR NEW.is_publisher IS DISTINCT FROM OLD.is_publisher
  THEN
    RAISE EXCEPTION 'Not allowed to modify privileged profile fields';
  END IF;
  IF (NEW.withdrawal_account IS DISTINCT FROM OLD.withdrawal_account
      OR NEW.withdrawal_method IS DISTINCT FROM OLD.withdrawal_method)
     AND coalesce(current_setting('app.allow_withdrawal_update', true), '') <> '1'
  THEN
    RAISE EXCEPTION 'Withdrawal destination can only be changed via set_withdrawal_destination after re-authentication';
  END IF;
  RETURN NEW;
END $function$;

DROP TRIGGER IF EXISTS trg_prevent_profile_priv_esc ON public.profiles;
CREATE TRIGGER trg_prevent_profile_priv_esc
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW EXECUTE FUNCTION public.prevent_profile_privilege_escalation();

-- Set withdrawal destination RPC
CREATE OR REPLACE FUNCTION public.set_withdrawal_destination(p_method text, p_account text)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $function$
DECLARE
  v_uid uuid := auth.uid();
  v_last timestamptz;
BEGIN
  IF v_uid IS NULL THEN RAISE EXCEPTION 'Not authenticated'; END IF;
  IF p_method IS NULL OR length(trim(p_method)) = 0 THEN RAISE EXCEPTION 'Method required'; END IF;
  IF p_account IS NULL OR length(trim(p_account)) = 0 THEN RAISE EXCEPTION 'Account required'; END IF;

  SELECT last_sign_in_at INTO v_last FROM auth.users WHERE id = v_uid;
  IF v_last IS NULL OR v_last < now() - interval '5 minutes' THEN
    RAISE EXCEPTION 'Please re-enter your password to update withdrawal destination';
  END IF;

  PERFORM set_config('app.allow_withdrawal_update', '1', true);
  UPDATE public.profiles
    SET withdrawal_method = p_method,
        withdrawal_account = trim(p_account),
        updated_at = now()
    WHERE user_id = v_uid;
  PERFORM set_config('app.allow_withdrawal_update', '', true);

  INSERT INTO public.security_logs (user_id, action, meta)
  VALUES (v_uid, 'withdrawal_destination_changed',
    jsonb_build_object('method', p_method, 'account_last4', right(trim(p_account), 4)));
END;
$function$;
GRANT EXECUTE ON FUNCTION public.set_withdrawal_destination(text, text) TO authenticated;

-- Daily checkin RPC
CREATE OR REPLACE FUNCTION public.claim_daily_checkin()
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_uid uuid := auth.uid();
  v_enabled boolean;
  v_amount numeric;
  v_streak_days int;
  v_streak_bonus numeric;
  v_last timestamptz;
  v_streak int;
  v_today date := (now() AT TIME ZONE 'UTC')::date;
  v_last_date date;
  v_new_streak int;
  v_bonus_awarded numeric := 0;
  v_total numeric;
  v_streak_reset boolean := false;
BEGIN
  IF v_uid IS NULL THEN RAISE EXCEPTION 'Not authenticated'; END IF;

  SELECT coalesce(daily_checkin_enabled,false), coalesce(daily_checkin_amount,0),
         coalesce(daily_checkin_streak_days,7), coalesce(daily_checkin_streak_bonus,0)
    INTO v_enabled, v_amount, v_streak_days, v_streak_bonus
    FROM public.settings LIMIT 1;

  IF NOT v_enabled OR v_amount <= 0 THEN
    RAISE EXCEPTION 'Daily check-in is disabled';
  END IF;

  SELECT last_checkin_at, coalesce(checkin_streak,0)
    INTO v_last, v_streak
    FROM public.profiles WHERE user_id = v_uid FOR UPDATE;

  v_last_date := CASE WHEN v_last IS NULL THEN NULL ELSE (v_last AT TIME ZONE 'UTC')::date END;

  IF v_last_date IS NOT NULL AND v_last_date = v_today THEN
    RAISE EXCEPTION 'You have already claimed today. Come back tomorrow!';
  END IF;

  IF v_last_date IS NOT NULL AND v_last_date = v_today - 1 THEN
    v_new_streak := v_streak + 1;
  ELSE
    v_new_streak := 1;
  END IF;

  v_total := v_amount;

  IF v_streak_days > 0 AND v_streak_bonus > 0 AND v_new_streak >= v_streak_days THEN
    v_bonus_awarded := v_streak_bonus;
    v_total := v_total + v_streak_bonus;
    v_new_streak := 0;
    v_streak_reset := true;
  END IF;

  UPDATE public.profiles
    SET balance = coalesce(balance,0) + v_total,
        last_checkin_at = now(),
        checkin_streak = v_new_streak,
        updated_at = now()
    WHERE user_id = v_uid;

  INSERT INTO public.payments (user_id, type, amount, status, reference)
  VALUES (v_uid, 'daily_checkin', v_total, 'approved', 'checkin_' || v_today::text);

  INSERT INTO public.notifications (user_id, title, message, type)
  VALUES (v_uid,
    CASE WHEN v_bonus_awarded > 0 THEN 'Streak bonus unlocked!' ELSE 'Daily check-in claimed' END,
    'You received ৳' || v_total::text ||
      CASE WHEN v_bonus_awarded > 0 THEN ' (includes ৳' || v_bonus_awarded::text || ' streak bonus!)' ELSE '' END,
    'daily_checkin');

  RETURN jsonb_build_object(
    'credited', v_total,
    'base', v_amount,
    'bonus', v_bonus_awarded,
    'streak', v_new_streak,
    'streak_reset', v_streak_reset
  );
END;
$$;
GRANT EXECUTE ON FUNCTION public.claim_daily_checkin() TO authenticated;

-- Publish task RPC
CREATE OR REPLACE FUNCTION public.publish_task_with_charge(
  p_title text, p_description text, p_instructions text, p_category text,
  p_reward numeric, p_total_slots integer, p_proof_type text,
  p_proof_count integer, p_proof_fields jsonb, p_banner_url text
)
RETURNS uuid LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_uid uuid := auth.uid();
  v_tax numeric;
  v_min_total numeric;
  v_subtotal numeric;
  v_total numeric;
  v_balance numeric;
  v_task_id uuid;
  v_status text;
  v_restricted boolean;
BEGIN
  IF v_uid IS NULL THEN RAISE EXCEPTION 'Not authenticated'; END IF;
  IF p_reward <= 0 OR p_total_slots <= 0 THEN RAISE EXCEPTION 'Invalid reward or slots'; END IF;

  SELECT status, coalesce(publisher_restricted, false)
    INTO v_status, v_restricted
    FROM public.profiles WHERE user_id = v_uid;
  IF v_status IS DISTINCT FROM 'active' THEN
    RAISE EXCEPTION 'Account must be active to publish tasks';
  END IF;
  IF v_restricted THEN
    RAISE EXCEPTION 'Publisher access is restricted for this account';
  END IF;

  SELECT coalesce(publisher_task_tax, 0), coalesce(minimum_task_total_amount, 0)
    INTO v_tax, v_min_total FROM public.settings LIMIT 1;

  v_subtotal := p_reward * p_total_slots;

  IF v_min_total > 0 AND v_subtotal < v_min_total THEN
    RAISE EXCEPTION 'Task total (reward × slots) must be at least %', v_min_total;
  END IF;

  v_total := v_subtotal + (v_subtotal * coalesce(v_tax,0) / 100);

  SELECT coalesce(balance, 0) INTO v_balance FROM public.profiles WHERE user_id = v_uid FOR UPDATE;
  IF v_balance IS NULL THEN RAISE EXCEPTION 'Profile not found'; END IF;
  IF v_balance < v_total THEN RAISE EXCEPTION 'Insufficient balance'; END IF;

  INSERT INTO public.tasks (
    publisher_id, title, description, instructions, category,
    reward, total_slots, proof_type, proof_count, proof_fields, banner_url, status
  ) VALUES (
    v_uid, p_title, p_description, p_instructions, p_category,
    p_reward, p_total_slots, p_proof_type, p_proof_count, p_proof_fields, p_banner_url, 'pending'
  ) RETURNING id INTO v_task_id;

  UPDATE public.profiles
  SET balance = balance - v_total, is_publisher = true, updated_at = now()
  WHERE user_id = v_uid;

  INSERT INTO public.payments (user_id, type, amount, status, reference)
  VALUES (v_uid, 'task_publish_hold', v_total, 'approved', v_task_id::text);

  RETURN v_task_id;
END;
$$;
GRANT EXECUTE ON FUNCTION public.publish_task_with_charge(text, text, text, text, numeric, integer, text, integer, jsonb, text) TO authenticated;

-- Publisher review submission RPC
CREATE OR REPLACE FUNCTION public.publisher_review_submission(p_submission_id uuid, p_approve boolean, p_reason text DEFAULT NULL)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_sub record;
  v_task record;
  v_new_completed int;
  v_new_status text;
BEGIN
  SELECT * INTO v_sub FROM public.task_submissions WHERE id = p_submission_id;
  IF v_sub IS NULL THEN RAISE EXCEPTION 'Submission not found'; END IF;
  IF v_sub.status <> 'pending' THEN RAISE EXCEPTION 'Submission already reviewed'; END IF;

  SELECT * INTO v_task FROM public.tasks WHERE id = v_sub.task_id;
  IF v_task IS NULL THEN RAISE EXCEPTION 'Task not found'; END IF;

  IF v_task.publisher_id <> auth.uid() AND NOT public.has_role(auth.uid(), 'admin') THEN
    RAISE EXCEPTION 'Not authorized to review this submission';
  END IF;

  UPDATE public.task_submissions
  SET status = CASE WHEN p_approve THEN 'approved' ELSE 'rejected' END,
      note = CASE WHEN p_approve THEN NULL ELSE p_reason END,
      updated_at = now()
  WHERE id = p_submission_id;

  IF p_approve THEN
    UPDATE public.profiles
    SET balance = balance + coalesce(v_task.reward, 0)
    WHERE user_id = v_sub.user_id;

    v_new_completed := coalesce(v_task.completed_slots, 0) + 1;
    v_new_status := CASE WHEN v_new_completed >= coalesce(v_task.total_slots, 0) THEN 'completed' ELSE 'active' END;
    UPDATE public.tasks
    SET completed_slots = v_new_completed, status = v_new_status
    WHERE id = v_task.id;

    INSERT INTO public.payments (user_id, type, amount, status, reference)
    VALUES (v_sub.user_id, 'task_earning', coalesce(v_task.reward, 0), 'approved', v_task.id::text);
  END IF;
END;
$$;
GRANT EXECUTE ON FUNCTION public.publisher_review_submission(uuid, boolean, text) TO authenticated;

-- Admin reject task with refund RPC
CREATE OR REPLACE FUNCTION public.admin_reject_task_with_refund(p_task_id uuid, p_reason text DEFAULT NULL)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_task record;
  v_hold numeric;
  v_already_refunded numeric;
  v_refund numeric;
  v_used_ratio numeric;
BEGIN
  IF NOT public.has_role(auth.uid(), 'admin') THEN
    RAISE EXCEPTION 'Not authorized';
  END IF;

  SELECT * INTO v_task FROM public.tasks WHERE id = p_task_id FOR UPDATE;
  IF v_task IS NULL THEN RAISE EXCEPTION 'Task not found'; END IF;
  IF v_task.status IN ('rejected','completed') THEN
    RAISE EXCEPTION 'Task cannot be rejected in its current status';
  END IF;

  SELECT coalesce(sum(amount), 0) INTO v_hold
  FROM public.payments
  WHERE reference = p_task_id::text AND type = 'task_publish_hold' AND status = 'approved';

  SELECT coalesce(sum(amount), 0) INTO v_already_refunded
  FROM public.payments
  WHERE reference = p_task_id::text AND type = 'task_publish_refund';

  IF coalesce(v_task.total_slots, 0) > 0 THEN
    v_used_ratio := coalesce(v_task.completed_slots, 0)::numeric / v_task.total_slots::numeric;
  ELSE
    v_used_ratio := 0;
  END IF;

  v_refund := (v_hold * (1 - v_used_ratio)) - v_already_refunded;

  UPDATE public.tasks SET status = 'rejected' WHERE id = p_task_id;

  IF v_refund > 0 AND v_task.publisher_id IS NOT NULL THEN
    UPDATE public.profiles
    SET balance = coalesce(balance, 0) + v_refund, updated_at = now()
    WHERE user_id = v_task.publisher_id;

    INSERT INTO public.payments (user_id, type, amount, status, reference)
    VALUES (v_task.publisher_id, 'task_publish_refund', v_refund, 'approved', p_task_id::text);
  END IF;
END;
$$;
GRANT EXECUTE ON FUNCTION public.admin_reject_task_with_refund(uuid, text) TO authenticated;

-- Publisher cancel task RPC
CREATE OR REPLACE FUNCTION public.publisher_cancel_task(p_task_id uuid)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_uid uuid := auth.uid();
  v_task record;
  v_hold numeric;
  v_already_refunded numeric;
  v_refund numeric := 0;
BEGIN
  IF v_uid IS NULL THEN RAISE EXCEPTION 'Not authenticated'; END IF;

  SELECT * INTO v_task FROM public.tasks WHERE id = p_task_id FOR UPDATE;
  IF v_task IS NULL THEN RAISE EXCEPTION 'Task not found'; END IF;
  IF v_task.publisher_id <> v_uid AND NOT public.has_role(v_uid, 'admin') THEN
    RAISE EXCEPTION 'Not authorized';
  END IF;
  IF v_task.status IN ('completed','rejected','cancelled') THEN
    RAISE EXCEPTION 'Task cannot be cancelled in its current status';
  END IF;

  SELECT coalesce(sum(amount), 0) INTO v_hold
  FROM public.payments
  WHERE reference = p_task_id::text AND type = 'task_publish_hold' AND status = 'approved';

  SELECT coalesce(sum(amount), 0) INTO v_already_refunded
  FROM public.payments
  WHERE reference = p_task_id::text AND type = 'task_publish_refund';

  IF v_task.status = 'pending' THEN
    v_refund := v_hold - v_already_refunded;
  ELSE
    v_refund := 0;
  END IF;

  UPDATE public.tasks SET status = 'cancelled' WHERE id = p_task_id;

  IF v_refund > 0 THEN
    UPDATE public.profiles
    SET balance = coalesce(balance, 0) + v_refund, updated_at = now()
    WHERE user_id = v_task.publisher_id;

    INSERT INTO public.payments (user_id, type, amount, status, reference)
    VALUES (v_task.publisher_id, 'task_publish_refund', v_refund, 'approved', p_task_id::text);
  END IF;

  RETURN jsonb_build_object('refunded', v_refund, 'status', 'cancelled');
END;
$$;
GRANT EXECUTE ON FUNCTION public.publisher_cancel_task(uuid) TO authenticated;

-- 4. ROW LEVEL SECURITY (RLS)

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.task_submissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.task_submission_proofs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.appeals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.referral_earnings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payment_methods ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notice_board ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.section_videos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.support_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.security_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.email_send_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.email_send_state ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.suppressed_emails ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.email_unsubscribe_tokens ENABLE ROW LEVEL SECURITY;

-- Drop existing policies to be cleanly idempotent
DO $$
DECLARE
  pol record;
BEGIN
  FOR pol IN
    SELECT schemaname, tablename, policyname
    FROM pg_policies
    WHERE schemaname = 'public'
  LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I ON %I.%I', pol.policyname, pol.schemaname, pol.tablename);
  END LOOP;
END $$;

-- Admin All Policies
DO $$
DECLARE t text;
BEGIN
  FOREACH t IN ARRAY ARRAY['profiles','tasks','task_submissions','task_submission_proofs','payments','appeals','notifications','settings','security_logs','user_roles','referral_earnings','payment_methods','notice_board','section_videos']
  LOOP
    EXECUTE format('CREATE POLICY "admin_all_%I" ON public.%I FOR ALL TO authenticated USING (public.has_role(auth.uid(), ''admin''::public.app_role)) WITH CHECK (public.has_role(auth.uid(), ''admin''::public.app_role))', t, t);
  END LOOP;
END $$;

-- Profiles Policies
CREATE POLICY "users_select_own_profile" ON public.profiles FOR SELECT TO authenticated USING (auth.uid() = user_id);
CREATE POLICY "users_update_own_profile" ON public.profiles FOR UPDATE TO authenticated USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- Settings Policies
CREATE POLICY "anon_view_settings" ON public.settings FOR SELECT TO anon USING (true);
CREATE POLICY "authenticated_view_settings" ON public.settings FOR SELECT TO authenticated USING (true);

-- Payment Methods Policies
CREATE POLICY "anyone_auth_view_payment_methods" ON public.payment_methods FOR SELECT TO authenticated USING (active = true OR public.has_role(auth.uid(), 'admin'::public.app_role));

-- Notice Board Policies
CREATE POLICY "authenticated_view_active_notices" ON public.notice_board FOR SELECT TO authenticated USING (active = true OR public.has_role(auth.uid(), 'admin'::public.app_role));

-- Section Videos Policies
CREATE POLICY "authenticated_view_section_videos" ON public.section_videos FOR SELECT TO authenticated USING (true);

-- Tasks Policies
CREATE POLICY "anyone_auth_view_active_tasks" ON public.tasks FOR SELECT TO authenticated USING (status = 'active' OR status = 'completed' OR publisher_id = auth.uid());
CREATE POLICY "publisher_insert_own_tasks" ON public.tasks FOR INSERT TO authenticated WITH CHECK (
  publisher_id = auth.uid() AND EXISTS (
    SELECT 1 FROM public.profiles p WHERE p.user_id = auth.uid() AND p.status = 'active' AND coalesce(p.publisher_restricted, false) = false
  )
);
CREATE POLICY "publisher_update_own_tasks" ON public.tasks FOR UPDATE TO authenticated USING (publisher_id = auth.uid());

-- Task Submissions Policies
CREATE POLICY "user_select_own_submissions" ON public.task_submissions FOR SELECT TO authenticated USING (
  user_id = auth.uid() OR EXISTS (SELECT 1 FROM public.tasks t WHERE t.id = task_id AND t.publisher_id = auth.uid())
);
CREATE POLICY "user_insert_own_submissions" ON public.task_submissions FOR INSERT TO authenticated WITH CHECK (user_id = auth.uid());

-- Task Submission Proofs Policies
CREATE POLICY "user_select_own_proofs" ON public.task_submission_proofs FOR SELECT TO authenticated USING (
  EXISTS (
    SELECT 1 FROM public.task_submissions s
    WHERE s.id = submission_id AND (s.user_id = auth.uid() OR EXISTS (SELECT 1 FROM public.tasks t WHERE t.id = s.task_id AND t.publisher_id = auth.uid()))
  )
);
CREATE POLICY "user_insert_own_proofs" ON public.task_submission_proofs FOR INSERT TO authenticated WITH CHECK (
  EXISTS (SELECT 1 FROM public.task_submissions s WHERE s.id = submission_id AND s.user_id = auth.uid())
);

-- Payments Policies
CREATE POLICY "user_select_own_payments" ON public.payments FOR SELECT TO authenticated USING (user_id = auth.uid());
CREATE POLICY "user_insert_own_payments" ON public.payments FOR INSERT TO authenticated WITH CHECK (user_id = auth.uid());

-- Appeals Policies
CREATE POLICY "user_select_own_appeals" ON public.appeals FOR SELECT TO authenticated USING (user_id = auth.uid());
CREATE POLICY "user_insert_own_appeals" ON public.appeals FOR INSERT TO authenticated WITH CHECK (user_id = auth.uid());

-- Notifications Policies
CREATE POLICY "user_select_own_notifications" ON public.notifications FOR SELECT TO authenticated USING (user_id = auth.uid() AND admin_targeted = false);
CREATE POLICY "user_update_own_notifications" ON public.notifications FOR UPDATE TO authenticated USING (user_id = auth.uid() AND admin_targeted = false) WITH CHECK (user_id = auth.uid() AND admin_targeted = false);
CREATE POLICY "user_delete_own_notifications" ON public.notifications FOR DELETE TO authenticated USING (user_id = auth.uid() AND admin_targeted = false);

-- Referral Earnings Policies
CREATE POLICY "user_select_own_referrals" ON public.referral_earnings FOR SELECT TO authenticated USING (referrer_id = auth.uid());

-- Support Messages Policies
CREATE POLICY "Users view own support messages" ON public.support_messages FOR SELECT TO authenticated USING (auth.uid() = user_id OR public.has_role(auth.uid(), 'admin'::public.app_role));
CREATE POLICY "Users send own support messages" ON public.support_messages FOR INSERT TO authenticated WITH CHECK (
  (sender = 'user' AND auth.uid() = user_id AND sender_id = auth.uid()) OR (sender = 'admin' AND public.has_role(auth.uid(), 'admin'::public.app_role) AND sender_id = auth.uid())
);
CREATE POLICY "Mark read updates" ON public.support_messages FOR UPDATE TO authenticated USING (auth.uid() = user_id OR public.has_role(auth.uid(), 'admin'::public.app_role)) WITH CHECK (auth.uid() = user_id OR public.has_role(auth.uid(), 'admin'::public.app_role));

-- Service Role Policies for email tables
CREATE POLICY "Service role can read send log" ON public.email_send_log FOR SELECT USING (auth.role() = 'service_role');
CREATE POLICY "Service role can insert send log" ON public.email_send_log FOR INSERT WITH CHECK (auth.role() = 'service_role');
CREATE POLICY "Service role can update send log" ON public.email_send_log FOR UPDATE USING (auth.role() = 'service_role') WITH CHECK (auth.role() = 'service_role');

CREATE POLICY "Service role can manage send state" ON public.email_send_state FOR ALL USING (auth.role() = 'service_role') WITH CHECK (auth.role() = 'service_role');

CREATE POLICY "Service role can read suppressed emails" ON public.suppressed_emails FOR SELECT USING (auth.role() = 'service_role');
CREATE POLICY "Service role can insert suppressed emails" ON public.suppressed_emails FOR INSERT WITH CHECK (auth.role() = 'service_role');

CREATE POLICY "Service role can read tokens" ON public.email_unsubscribe_tokens FOR SELECT USING (auth.role() = 'service_role');
CREATE POLICY "Service role can insert tokens" ON public.email_unsubscribe_tokens FOR INSERT WITH CHECK (auth.role() = 'service_role');
CREATE POLICY "Service role can mark tokens as used" ON public.email_unsubscribe_tokens FOR UPDATE USING (auth.role() = 'service_role') WITH CHECK (auth.role() = 'service_role');

-- 5. STORAGE BUCKETS
INSERT INTO storage.buckets (id, name, public) VALUES
  ('avatars', 'avatars', true),
  ('proofs', 'proofs', false),
  ('task-banners', 'task-banners', true)
ON CONFLICT (id) DO NOTHING;

DO $$
BEGIN
  -- Avatars storage policies
  DROP POLICY IF EXISTS "avatars_public_read" ON storage.objects;
  CREATE POLICY "avatars_public_read" ON storage.objects FOR SELECT USING (bucket_id = 'avatars');

  DROP POLICY IF EXISTS "avatars_user_insert_own" ON storage.objects;
  CREATE POLICY "avatars_user_insert_own" ON storage.objects FOR INSERT TO authenticated
    WITH CHECK (bucket_id = 'avatars' AND auth.uid()::text = (storage.foldername(name))[1]);

  DROP POLICY IF EXISTS "avatars_user_update_own" ON storage.objects;
  CREATE POLICY "avatars_user_update_own" ON storage.objects FOR UPDATE TO authenticated
    USING (bucket_id = 'avatars' AND auth.uid()::text = (storage.foldername(name))[1]);

  DROP POLICY IF EXISTS "avatars_user_delete_own" ON storage.objects;
  CREATE POLICY "avatars_user_delete_own" ON storage.objects FOR DELETE TO authenticated
    USING (bucket_id = 'avatars' AND auth.uid()::text = (storage.foldername(name))[1]);

  -- Proofs storage policies
  DROP POLICY IF EXISTS "proofs_user_upload" ON storage.objects;
  CREATE POLICY "proofs_user_upload" ON storage.objects FOR INSERT TO authenticated
    WITH CHECK (bucket_id = 'proofs' AND auth.uid()::text = (storage.foldername(name))[1]);

  DROP POLICY IF EXISTS "proofs_owner_or_publisher_or_admin_read" ON storage.objects;
  CREATE POLICY "proofs_owner_or_publisher_or_admin_read" ON storage.objects FOR SELECT TO authenticated
    USING (
      bucket_id = 'proofs' AND (
        public.has_role(auth.uid(), 'admin'::public.app_role)
        OR (auth.uid())::text = (storage.foldername(name))[1]
        OR EXISTS (
          SELECT 1 FROM public.task_submission_proofs p
          JOIN public.task_submissions s ON s.id = p.submission_id
          JOIN public.tasks t ON t.id = s.task_id
          WHERE t.publisher_id = auth.uid()
            AND (p.image_url = objects.name OR p.image_url LIKE '%' || objects.name)
        )
      )
    );

  DROP POLICY IF EXISTS "Publishers and admins can delete proofs" ON storage.objects;
  CREATE POLICY "Publishers and admins can delete proofs" ON storage.objects FOR DELETE TO authenticated
    USING (
      bucket_id = 'proofs' AND (
        public.has_role(auth.uid(), 'admin'::public.app_role)
        OR EXISTS (
          SELECT 1 FROM public.task_submission_proofs p
          JOIN public.task_submissions s ON s.id = p.submission_id
          JOIN public.tasks t ON t.id = s.task_id
          WHERE t.publisher_id = auth.uid()
            AND (p.image_url LIKE '%' || storage.objects.name OR storage.objects.name = p.image_url)
        )
      )
    );

  -- Task banners storage policies
  DROP POLICY IF EXISTS "Anyone can view task banners" ON storage.objects;
  CREATE POLICY "Anyone can view task banners" ON storage.objects FOR SELECT USING (bucket_id = 'task-banners');

  DROP POLICY IF EXISTS "Authenticated can upload task banners" ON storage.objects;
  CREATE POLICY "Authenticated can upload task banners" ON storage.objects FOR INSERT TO authenticated
    WITH CHECK (bucket_id = 'task-banners' AND auth.uid()::text = (storage.foldername(name))[1]);

  DROP POLICY IF EXISTS "Users can delete their own task banners" ON storage.objects;
  CREATE POLICY "Users can delete their own task banners" ON storage.objects FOR DELETE TO authenticated
    USING (bucket_id = 'task-banners' AND auth.uid()::text = (storage.foldername(name))[1]);
EXCEPTION WHEN OTHERS THEN NULL;
END $$;

-- 6. REALTIME REPLICA IDENTITIES & PUBLICATIONS
DO $$
DECLARE tbl text;
BEGIN
  FOREACH tbl IN ARRAY ARRAY['profiles','tasks','task_submissions','payments','appeals','notifications','settings','payment_methods','referral_earnings','notice_board','support_messages']
  LOOP
    BEGIN
      EXECUTE format('ALTER TABLE public.%I REPLICA IDENTITY FULL', tbl);
      EXECUTE format('ALTER PUBLICATION supabase_realtime ADD TABLE public.%I', tbl);
    EXCEPTION WHEN duplicate_object THEN NULL;
              WHEN undefined_object THEN NULL;
              WHEN OTHERS THEN NULL;
    END;
  END LOOP;
END $$;

-- Backfill profile for any existing auth user
INSERT INTO public.profiles (user_id, username, email, phone, referral_code, status)
SELECT
  u.id,
  coalesce(nullif(u.raw_user_meta_data ->> 'username', ''), split_part(u.email, '@', 1)),
  u.email,
  u.raw_user_meta_data ->> 'phone',
  public.gen_referral_code(),
  'active'
FROM auth.users u
WHERE NOT EXISTS (
  SELECT 1 FROM public.profiles p WHERE p.user_id = u.id
);
