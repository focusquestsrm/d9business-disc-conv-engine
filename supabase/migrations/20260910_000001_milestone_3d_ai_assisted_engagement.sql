BEGIN;

CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE IF NOT EXISTS public.ai_engagement_suggestions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid,
  prospect_id uuid,
  engagement_thread_id uuid,
  connection_id uuid,
  platform text NOT NULL CHECK (platform IN ('instagram', 'facebook', 'linkedin', 'email')),
  channel text NOT NULL CHECK (channel IN ('comment', 'direct_message', 'email', 'follow_up', 'staff_response')),
  suggestion_type text NOT NULL CHECK (suggestion_type IN ('comment', 'direct_message', 'email', 'follow_up', 'staff_response')),
  subject_line text,
  content text NOT NULL,
  status text NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'generated', 'needs_review', 'approved', 'rejected', 'expired', 'blocked', 'pending_delivery', 'delivered', 'delivery_failed', 'cancelled')),
  generation_source text NOT NULL DEFAULT 'template' CHECK (generation_source IN ('template', 'staff', 'simulated_ai', 'provider_ai', 'hybrid')),
  personalization_fields jsonb NOT NULL DEFAULT '{}'::jsonb,
  source_context jsonb NOT NULL DEFAULT '{}'::jsonb,
  model_provider text,
  model_name text,
  prompt_template_id uuid,
  prompt_version text NOT NULL DEFAULT 'v1',
  confidence_score numeric(4,3),
  uncertainty_reasons jsonb NOT NULL DEFAULT '[]'::jsonb,
  safety_labels jsonb NOT NULL DEFAULT '[]'::jsonb,
  sensitivity_level text NOT NULL DEFAULT 'low' CHECK (sensitivity_level IN ('low', 'medium', 'high')),
  created_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  generated_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  expires_at timestamptz
);

CREATE TABLE IF NOT EXISTS public.ai_engagement_approvals (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid,
  suggestion_id uuid NOT NULL REFERENCES public.ai_engagement_suggestions(id) ON DELETE CASCADE,
  decision text NOT NULL CHECK (decision IN ('approved', 'rejected', 'changes_requested', 'cancelled')),
  decided_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  decided_at timestamptz NOT NULL DEFAULT now(),
  edited_content_snapshot text,
  decision_reason text,
  eligibility_snapshot jsonb NOT NULL DEFAULT '{}'::jsonb,
  frequency_snapshot jsonb NOT NULL DEFAULT '{}'::jsonb,
  provider_capability_snapshot jsonb NOT NULL DEFAULT '{}'::jsonb,
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb
);

CREATE TABLE IF NOT EXISTS public.engagement_outreach_attempts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid,
  suggestion_id uuid,
  prospect_id uuid NOT NULL,
  thread_id uuid,
  connection_id uuid,
  platform text NOT NULL CHECK (platform IN ('instagram', 'facebook', 'linkedin', 'email')),
  channel text NOT NULL CHECK (channel IN ('comment', 'direct_message', 'email', 'follow_up', 'staff_response')),
  attempt_type text NOT NULL CHECK (attempt_type IN ('draft', 'approval', 'manual', 'provider', 'follow_up')),
  status text NOT NULL CHECK (status IN ('proposed', 'blocked', 'approved_pending_delivery', 'manually_sent', 'provider_accepted', 'delivered', 'failed', 'cancelled')),
  attempted_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  attempted_at timestamptz NOT NULL DEFAULT now(),
  provider_message_id text,
  provider_status text,
  eligibility_result text NOT NULL DEFAULT 'pending',
  block_reason text,
  failure_reason text,
  content_snapshot text,
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.engagement_follow_up_reminders (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid,
  prospect_id uuid,
  thread_id uuid,
  suggestion_id uuid,
  outreach_attempt_id uuid,
  due_at timestamptz NOT NULL,
  reminder_type text NOT NULL CHECK (reminder_type IN ('follow_up', 'reply_wait', 'consent_review', 'manual_review', 'approval_filter')),
  priority text NOT NULL DEFAULT 'normal' CHECK (priority IN ('low', 'normal', 'high', 'urgent')),
  status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'due', 'snoozed', 'completed', 'cancelled')),
  assigned_to uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  reason text,
  created_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  completed_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  completed_at timestamptz,
  snoozed_until timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.engagement_outcome_classifications (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid,
  prospect_id uuid,
  thread_id uuid NOT NULL,
  message_id uuid,
  outcome text NOT NULL CHECK (outcome IN ('positive_interest', 'information_requested', 'verification_question', 'follow_up_needed', 'not_interested', 'opt_out_request', 'wrong_person', 'out_of_office', 'delivery_failure', 'complaint', 'sensitive', 'unclear', 'other')),
  confidence_score numeric(4,3) NOT NULL DEFAULT 0,
  classification_source text NOT NULL DEFAULT 'manual',
  sensitivity_level text NOT NULL DEFAULT 'low' CHECK (sensitivity_level IN ('low', 'medium', 'high')),
  uncertainty_reasons jsonb NOT NULL DEFAULT '[]'::jsonb,
  evidence_summary text,
  requires_staff_review boolean NOT NULL DEFAULT false,
  reviewed_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  reviewed_at timestamptz,
  final_outcome text,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.engagement_escalations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid,
  prospect_id uuid,
  thread_id uuid NOT NULL,
  message_id uuid,
  classification_id uuid,
  escalation_type text NOT NULL CHECK (escalation_type IN ('sensitive_content', 'low_confidence', 'consent_uncertain', 'identity_uncertain', 'legal_or_compliance', 'complaint', 'threat_or_safety', 'discrimination_or_harassment', 'financial_request', 'medical_or_personal_crisis', 'platform_restriction', 'manual_review')),
  severity text NOT NULL DEFAULT 'medium' CHECK (severity IN ('low', 'medium', 'high', 'critical')),
  reason text NOT NULL,
  status text NOT NULL DEFAULT 'open' CHECK (status IN ('open', 'queued', 'in_progress', 'resolved', 'cancelled')),
  assigned_to uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  work_queue_item_id uuid,
  created_at timestamptz NOT NULL DEFAULT now(),
  resolved_at timestamptz,
  resolved_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  resolution_notes text
);

CREATE TABLE IF NOT EXISTS public.engagement_frequency_rules (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid,
  channel text,
  platform text,
  purpose text NOT NULL,
  max_attempts integer NOT NULL DEFAULT 3,
  window_interval integer NOT NULL DEFAULT 30,
  cooldown_interval integer NOT NULL DEFAULT 24,
  active boolean NOT NULL DEFAULT true,
  created_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.ai_prompt_templates (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  use_case text NOT NULL,
  channel text NOT NULL,
  platform text,
  system_instruction text NOT NULL,
  template_content text NOT NULL,
  version text NOT NULL DEFAULT 'v1',
  active boolean NOT NULL DEFAULT true,
  approved_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  approved_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_ai_engagement_suggestions_status
  ON public.ai_engagement_suggestions (tenant_id, status, generated_at DESC);

CREATE INDEX IF NOT EXISTS idx_ai_engagement_approvals_suggestion
  ON public.ai_engagement_approvals (suggestion_id, decided_at DESC);

CREATE INDEX IF NOT EXISTS idx_engagement_outreach_attempts_prospect
  ON public.engagement_outreach_attempts (tenant_id, prospect_id, attempted_at DESC);

CREATE INDEX IF NOT EXISTS idx_engagement_follow_up_reminders_due
  ON public.engagement_follow_up_reminders (tenant_id, due_at, status);

CREATE INDEX IF NOT EXISTS idx_engagement_escalations_status
  ON public.engagement_escalations (tenant_id, status, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_engagement_frequency_rules_active
  ON public.engagement_frequency_rules (tenant_id, active, purpose, channel, platform);

ALTER TABLE public.ai_engagement_suggestions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ai_engagement_approvals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.engagement_outreach_attempts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.engagement_follow_up_reminders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.engagement_outcome_classifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.engagement_escalations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.engagement_frequency_rules ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ai_prompt_templates ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Authenticated users can read AI engagement suggestions" ON public.ai_engagement_suggestions;
CREATE POLICY "Authenticated users can read AI engagement suggestions"
  ON public.ai_engagement_suggestions FOR SELECT
  USING (auth.uid() IS NOT NULL);

DROP POLICY IF EXISTS "Authenticated users can insert AI engagement suggestions" ON public.ai_engagement_suggestions;
CREATE POLICY "Authenticated users can insert AI engagement suggestions"
  ON public.ai_engagement_suggestions FOR INSERT
  WITH CHECK (auth.uid() IS NOT NULL);

DROP POLICY IF EXISTS "Authenticated users can update AI engagement suggestions" ON public.ai_engagement_suggestions;
CREATE POLICY "Authenticated users can update AI engagement suggestions"
  ON public.ai_engagement_suggestions FOR UPDATE
  USING (auth.uid() IS NOT NULL)
  WITH CHECK (auth.uid() IS NOT NULL);

CREATE OR REPLACE FUNCTION public.set_ai_engagement_updated_at()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS ai_engagement_suggestions_set_updated_at ON public.ai_engagement_suggestions;
CREATE TRIGGER ai_engagement_suggestions_set_updated_at
BEFORE UPDATE ON public.ai_engagement_suggestions
FOR EACH ROW EXECUTE FUNCTION public.set_ai_engagement_updated_at();

DROP TRIGGER IF EXISTS engagement_follow_up_reminders_set_updated_at ON public.engagement_follow_up_reminders;
CREATE TRIGGER engagement_follow_up_reminders_set_updated_at
BEFORE UPDATE ON public.engagement_follow_up_reminders
FOR EACH ROW EXECUTE FUNCTION public.set_ai_engagement_updated_at();

DROP TRIGGER IF EXISTS engagement_frequency_rules_set_updated_at ON public.engagement_frequency_rules;
CREATE TRIGGER engagement_frequency_rules_set_updated_at
BEFORE UPDATE ON public.engagement_frequency_rules
FOR EACH ROW EXECUTE FUNCTION public.set_ai_engagement_updated_at();

CREATE OR REPLACE FUNCTION public.create_ai_engagement_suggestion(
  p_tenant_id uuid,
  p_prospect_id uuid,
  p_engagement_thread_id uuid DEFAULT NULL,
  p_connection_id uuid DEFAULT NULL,
  p_platform text,
  p_channel text,
  p_suggestion_type text,
  p_subject_line text DEFAULT NULL,
  p_content text,
  p_status text DEFAULT 'generated',
  p_generation_source text DEFAULT 'template',
  p_personalization_fields jsonb DEFAULT '{}'::jsonb,
  p_source_context jsonb DEFAULT '{}'::jsonb,
  p_model_provider text DEFAULT NULL,
  p_model_name text DEFAULT NULL,
  p_prompt_template_id uuid DEFAULT NULL,
  p_prompt_version text DEFAULT 'v1',
  p_confidence_score numeric DEFAULT 0.5,
  p_uncertainty_reasons jsonb DEFAULT '[]'::jsonb,
  p_safety_labels jsonb DEFAULT '[]'::jsonb,
  p_sensitivity_level text DEFAULT 'low',
  p_created_by uuid DEFAULT NULL
)
RETURNS public.ai_engagement_suggestions
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_row public.ai_engagement_suggestions;
BEGIN
  INSERT INTO public.ai_engagement_suggestions (
    tenant_id, prospect_id, engagement_thread_id, connection_id, platform, channel, suggestion_type,
    subject_line, content, status, generation_source, personalization_fields, source_context,
    model_provider, model_name, prompt_template_id, prompt_version, confidence_score,
    uncertainty_reasons, safety_labels, sensitivity_level, created_by, generated_at, updated_at
  ) VALUES (
    p_tenant_id, p_prospect_id, p_engagement_thread_id, p_connection_id, p_platform, p_channel, p_suggestion_type,
    p_subject_line, p_content, p_status, p_generation_source, COALESCE(p_personalization_fields, '{}'::jsonb), COALESCE(p_source_context, '{}'::jsonb),
    p_model_provider, p_model_name, p_prompt_template_id, p_prompt_version, p_confidence_score,
    COALESCE(p_uncertainty_reasons, '[]'::jsonb), COALESCE(p_safety_labels, '[]'::jsonb), p_sensitivity_level, p_created_by, NOW(), NOW()
  ) RETURNING * INTO v_row;

  RETURN v_row;
END;
$$;

CREATE OR REPLACE FUNCTION public.generate_ai_engagement_suggestion(
  p_tenant_id uuid,
  p_prospect_id uuid,
  p_platform text,
  p_channel text,
  p_suggestion_type text,
  p_business_name text DEFAULT NULL,
  p_prospect_name text DEFAULT NULL,
  p_handle text DEFAULT NULL,
  p_content text DEFAULT NULL,
  p_created_by uuid DEFAULT NULL
)
RETURNS public.ai_engagement_suggestions
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_content text;
  v_row public.ai_engagement_suggestions;
BEGIN
  v_content := COALESCE(p_content, 'Thanks for your interest. We would welcome the opportunity to continue the conversation.');

  INSERT INTO public.ai_engagement_suggestions (
    tenant_id, prospect_id, platform, channel, suggestion_type, content, status, generation_source,
    personalization_fields, source_context, confidence_score, uncertainty_reasons, safety_labels,
    sensitivity_level, created_by, generated_at, updated_at
  ) VALUES (
    p_tenant_id, p_prospect_id, p_platform, p_channel, p_suggestion_type, v_content, 'generated', 'template',
    jsonb_build_object('prospect_name', p_prospect_name, 'business_name', p_business_name, 'handle', p_handle),
    jsonb_build_object('source', 'simulated_ai_template'), 0.75, '[]'::jsonb, '[]'::jsonb,
    'low', p_created_by, NOW(), NOW()
  ) RETURNING * INTO v_row;

  RETURN v_row;
END;
$$;

CREATE OR REPLACE FUNCTION public.update_ai_engagement_draft(
  p_suggestion_id uuid,
  p_content text DEFAULT NULL,
  p_subject_line text DEFAULT NULL,
  p_status text DEFAULT 'draft',
  p_personalization_fields jsonb DEFAULT '{}'::jsonb,
  p_source_context jsonb DEFAULT '{}'::jsonb,
  p_confidence_score numeric DEFAULT NULL
)
RETURNS public.ai_engagement_suggestions
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_row public.ai_engagement_suggestions;
BEGIN
  UPDATE public.ai_engagement_suggestions
  SET content = COALESCE(p_content, content),
      subject_line = COALESCE(p_subject_line, subject_line),
      status = COALESCE(p_status, status),
      personalization_fields = COALESCE(p_personalization_fields, personalization_fields),
      source_context = COALESCE(p_source_context, source_context),
      confidence_score = COALESCE(p_confidence_score, confidence_score),
      updated_at = NOW()
  WHERE id = p_suggestion_id
  RETURNING * INTO v_row;

  RETURN v_row;
END;
$$;

CREATE OR REPLACE FUNCTION public.submit_ai_suggestion_for_review(
  p_suggestion_id uuid,
  p_reviewed_by uuid DEFAULT NULL
)
RETURNS public.ai_engagement_suggestions
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_row public.ai_engagement_suggestions;
BEGIN
  UPDATE public.ai_engagement_suggestions
  SET status = 'needs_review',
      updated_at = NOW(),
      created_by = COALESCE(created_by, p_reviewed_by)
  WHERE id = p_suggestion_id
  RETURNING * INTO v_row;

  RETURN v_row;
END;
$$;

CREATE OR REPLACE FUNCTION public.approve_ai_engagement_suggestion(
  p_suggestion_id uuid,
  p_decided_by uuid,
  p_decision_reason text DEFAULT 'Approved by staff review.',
  p_edited_content_snapshot text DEFAULT NULL,
  p_eligibility_snapshot jsonb DEFAULT '{}'::jsonb,
  p_frequency_snapshot jsonb DEFAULT '{}'::jsonb,
  p_provider_capability_snapshot jsonb DEFAULT '{}'::jsonb
)
RETURNS public.ai_engagement_suggestions
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_row public.ai_engagement_suggestions;
BEGIN
  UPDATE public.ai_engagement_suggestions
  SET status = 'approved',
      updated_at = NOW()
  WHERE id = p_suggestion_id
  RETURNING * INTO v_row;

  INSERT INTO public.ai_engagement_approvals (
    tenant_id, suggestion_id, decision, decided_by, decided_at, edited_content_snapshot,
    decision_reason, eligibility_snapshot, frequency_snapshot, provider_capability_snapshot
  )
  SELECT tenant_id, p_suggestion_id, 'approved', p_decided_by, NOW(), p_edited_content_snapshot,
         p_decision_reason, COALESCE(p_eligibility_snapshot, '{}'::jsonb), COALESCE(p_frequency_snapshot, '{}'::jsonb), COALESCE(p_provider_capability_snapshot, '{}'::jsonb)
  FROM public.ai_engagement_suggestions
  WHERE id = p_suggestion_id;

  RETURN v_row;
END;
$$;

CREATE OR REPLACE FUNCTION public.reject_ai_engagement_suggestion(
  p_suggestion_id uuid,
  p_decided_by uuid,
  p_reason text DEFAULT NULL
)
RETURNS public.ai_engagement_suggestions
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_row public.ai_engagement_suggestions;
BEGIN
  UPDATE public.ai_engagement_suggestions
  SET status = 'rejected',
      updated_at = NOW()
  WHERE id = p_suggestion_id
  RETURNING * INTO v_row;

  INSERT INTO public.ai_engagement_approvals (tenant_id, suggestion_id, decision, decided_by, decided_at, decision_reason)
  SELECT tenant_id, p_suggestion_id, 'rejected', p_decided_by, NOW(), p_reason
  FROM public.ai_engagement_suggestions
  WHERE id = p_suggestion_id;

  RETURN v_row;
END;
$$;

CREATE OR REPLACE FUNCTION public.cancel_ai_engagement_suggestion(
  p_suggestion_id uuid,
  p_cancelled_by uuid DEFAULT NULL,
  p_reason text DEFAULT 'Cancelled by staff.'
)
RETURNS public.ai_engagement_suggestions
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_row public.ai_engagement_suggestions;
BEGIN
  UPDATE public.ai_engagement_suggestions
  SET status = 'cancelled',
      updated_at = NOW()
  WHERE id = p_suggestion_id
  RETURNING * INTO v_row;

  INSERT INTO public.ai_engagement_approvals (tenant_id, suggestion_id, decision, decided_by, decided_at, decision_reason)
  SELECT tenant_id, p_suggestion_id, 'cancelled', p_cancelled_by, NOW(), p_reason
  FROM public.ai_engagement_suggestions
  WHERE id = p_suggestion_id;

  RETURN v_row;
END;
$$;

CREATE OR REPLACE FUNCTION public.evaluate_engagement_send_eligibility(
  p_prospect_id uuid,
  p_connection_id uuid DEFAULT NULL,
  p_thread_id uuid DEFAULT NULL,
  p_platform text,
  p_channel text,
  p_purpose text DEFAULT 'general_communication',
  p_consent_allowed boolean DEFAULT true,
  p_suppression_blocked boolean DEFAULT false,
  p_sensitive_response_hold boolean DEFAULT false,
  p_provider_connected boolean DEFAULT false,
  p_provider_activity_permitted boolean DEFAULT true,
  p_frequency_ok boolean DEFAULT true,
  p_frequency_reason text DEFAULT NULL,
  p_cooldown_active boolean DEFAULT false,
  p_prospect_match_required boolean DEFAULT false,
  p_prospect_matched boolean DEFAULT true,
  p_requires_human_approval boolean DEFAULT true,
  p_human_approval_granted boolean DEFAULT false
)
RETURNS TABLE (
  allowed boolean,
  reason text,
  code text
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
BEGIN
  IF p_suppression_blocked THEN
    RETURN QUERY SELECT false, 'Global or channel suppressions are active.', 'global_opt_out';
  ELSIF p_consent_allowed = false THEN
    RETURN QUERY SELECT false, 'Consent is missing, denied, expired, or withdrawn.', 'consent_missing';
  ELSIF p_sensitive_response_hold THEN
    RETURN QUERY SELECT false, 'Sensitive response hold prevents outreach.', 'sensitive_response_hold';
  ELSIF p_provider_connected = false THEN
    RETURN QUERY SELECT false, 'Provider is not connected.', 'provider_not_connected';
  ELSIF p_provider_activity_permitted = false THEN
    RETURN QUERY SELECT false, 'Provider activity is not permitted for this connection.', 'provider_activity_not_permitted';
  ELSIF p_frequency_ok = false THEN
    RETURN QUERY SELECT false, COALESCE(p_frequency_reason, 'Frequency limit reached.'), CASE WHEN p_cooldown_active THEN 'cooldown_active' ELSE 'frequency_limit_reached' END;
  ELSIF p_prospect_match_required AND p_prospect_matched = false THEN
    RETURN QUERY SELECT false, 'Prospect match is required before outreach proceeds.', 'prospect_match_required';
  ELSIF p_requires_human_approval AND p_human_approval_granted = false THEN
    RETURN QUERY SELECT false, 'Human approval is required before this outreach can be sent.', 'human_approval_required';
  ELSE
    RETURN QUERY SELECT true, 'Eligible for approved outreach.', 'eligible';
  END IF;
END;
$$;

CREATE OR REPLACE FUNCTION public.record_engagement_outreach_attempt(
  p_tenant_id uuid,
  p_suggestion_id uuid DEFAULT NULL,
  p_prospect_id uuid,
  p_thread_id uuid DEFAULT NULL,
  p_connection_id uuid DEFAULT NULL,
  p_platform text,
  p_channel text,
  p_attempt_type text DEFAULT 'approval',
  p_status text DEFAULT 'proposed',
  p_attempted_by uuid DEFAULT NULL,
  p_provider_message_id text DEFAULT NULL,
  p_provider_status text DEFAULT NULL,
  p_eligibility_result text DEFAULT 'pending',
  p_block_reason text DEFAULT NULL,
  p_failure_reason text DEFAULT NULL,
  p_content_snapshot text DEFAULT NULL,
  p_metadata jsonb DEFAULT '{}'::jsonb
)
RETURNS public.engagement_outreach_attempts
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_row public.engagement_outreach_attempts;
BEGIN
  INSERT INTO public.engagement_outreach_attempts (
    tenant_id, suggestion_id, prospect_id, thread_id, connection_id, platform, channel,
    attempt_type, status, attempted_by, provider_message_id, provider_status,
    eligibility_result, block_reason, failure_reason, content_snapshot, metadata, created_at
  ) VALUES (
    p_tenant_id, p_suggestion_id, p_prospect_id, p_thread_id, p_connection_id, p_platform, p_channel,
    p_attempt_type, p_status, p_attempted_by, p_provider_message_id, p_provider_status,
    p_eligibility_result, p_block_reason, p_failure_reason, p_content_snapshot, COALESCE(p_metadata, '{}'::jsonb), NOW()
  ) RETURNING * INTO v_row;

  RETURN v_row;
END;
$$;

CREATE OR REPLACE FUNCTION public.record_manual_engagement_delivery(
  p_tenant_id uuid,
  p_suggestion_id uuid,
  p_prospect_id uuid,
  p_thread_id uuid DEFAULT NULL,
  p_connection_id uuid DEFAULT NULL,
  p_platform text,
  p_channel text,
  p_attempted_by uuid DEFAULT NULL,
  p_content_snapshot text DEFAULT NULL
)
RETURNS public.engagement_outreach_attempts
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_row public.engagement_outreach_attempts;
BEGIN
  INSERT INTO public.engagement_outreach_attempts (
    tenant_id, suggestion_id, prospect_id, thread_id, connection_id, platform, channel,
    attempt_type, status, attempted_by, content_snapshot, eligibility_result, created_at
  ) VALUES (
    p_tenant_id, p_suggestion_id, p_prospect_id, p_thread_id, p_connection_id, p_platform, p_channel,
    'manual', 'manually_sent', p_attempted_by, p_content_snapshot, 'eligible', NOW()
  ) RETURNING * INTO v_row;

  RETURN v_row;
END;
$$;

CREATE OR REPLACE FUNCTION public.classify_engagement_outcome(
  p_tenant_id uuid,
  p_prospect_id uuid,
  p_thread_id uuid,
  p_message_id uuid DEFAULT NULL,
  p_outcome text,
  p_confidence_score numeric DEFAULT 0,
  p_classification_source text DEFAULT 'manual',
  p_sensitivity_level text DEFAULT 'low',
  p_uncertainty_reasons jsonb DEFAULT '[]'::jsonb,
  p_evidence_summary text DEFAULT NULL,
  p_requires_staff_review boolean DEFAULT false,
  p_reviewed_by uuid DEFAULT NULL
)
RETURNS public.engagement_outcome_classifications
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_row public.engagement_outcome_classifications;
BEGIN
  INSERT INTO public.engagement_outcome_classifications (
    tenant_id, prospect_id, thread_id, message_id, outcome, confidence_score,
    classification_source, sensitivity_level, uncertainty_reasons, evidence_summary,
    requires_staff_review, reviewed_by, reviewed_at, created_at
  ) VALUES (
    p_tenant_id, p_prospect_id, p_thread_id, p_message_id, p_outcome, p_confidence_score,
    p_classification_source, p_sensitivity_level, COALESCE(p_uncertainty_reasons, '[]'::jsonb),
    p_evidence_summary, p_requires_staff_review, p_reviewed_by, NOW(), NOW()
  ) RETURNING * INTO v_row;

  RETURN v_row;
END;
$$;

CREATE OR REPLACE FUNCTION public.review_engagement_outcome(
  p_classification_id uuid,
  p_final_outcome text,
  p_reviewed_by uuid DEFAULT NULL
)
RETURNS public.engagement_outcome_classifications
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_row public.engagement_outcome_classifications;
BEGIN
  UPDATE public.engagement_outcome_classifications
  SET final_outcome = p_final_outcome,
      reviewed_by = p_reviewed_by,
      reviewed_at = NOW()
  WHERE id = p_classification_id
  RETURNING * INTO v_row;

  RETURN v_row;
END;
$$;

CREATE OR REPLACE FUNCTION public.create_engagement_follow_up(
  p_tenant_id uuid,
  p_prospect_id uuid,
  p_thread_id uuid DEFAULT NULL,
  p_suggestion_id uuid DEFAULT NULL,
  p_outreach_attempt_id uuid DEFAULT NULL,
  p_due_at timestamptz,
  p_reminder_type text,
  p_priority text DEFAULT 'normal',
  p_status text DEFAULT 'pending',
  p_assigned_to uuid DEFAULT NULL,
  p_reason text DEFAULT NULL,
  p_created_by uuid DEFAULT NULL
)
RETURNS public.engagement_follow_up_reminders
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_row public.engagement_follow_up_reminders;
BEGIN
  INSERT INTO public.engagement_follow_up_reminders (
    tenant_id, prospect_id, thread_id, suggestion_id, outreach_attempt_id, due_at,
    reminder_type, priority, status, assigned_to, reason, created_by, created_at, updated_at
  ) VALUES (
    p_tenant_id, p_prospect_id, p_thread_id, p_suggestion_id, p_outreach_attempt_id, p_due_at,
    p_reminder_type, p_priority, p_status, p_assigned_to, p_reason, p_created_by, NOW(), NOW()
  ) RETURNING * INTO v_row;

  RETURN v_row;
END;
$$;

CREATE OR REPLACE FUNCTION public.snooze_engagement_follow_up(
  p_reminder_id uuid,
  p_snoozed_until timestamptz,
  p_assigned_to uuid DEFAULT NULL
)
RETURNS public.engagement_follow_up_reminders
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_row public.engagement_follow_up_reminders;
BEGIN
  UPDATE public.engagement_follow_up_reminders
  SET status = 'snoozed',
      snoozed_until = p_snoozed_until,
      assigned_to = COALESCE(p_assigned_to, assigned_to),
      updated_at = NOW()
  WHERE id = p_reminder_id
  RETURNING * INTO v_row;

  RETURN v_row;
END;
$$;

CREATE OR REPLACE FUNCTION public.complete_engagement_follow_up(
  p_reminder_id uuid,
  p_completed_by uuid DEFAULT NULL
)
RETURNS public.engagement_follow_up_reminders
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_row public.engagement_follow_up_reminders;
BEGIN
  UPDATE public.engagement_follow_up_reminders
  SET status = 'completed',
      completed_by = COALESCE(p_completed_by, completed_by),
      completed_at = NOW(),
      updated_at = NOW()
  WHERE id = p_reminder_id
  RETURNING * INTO v_row;

  RETURN v_row;
END;
$$;

CREATE OR REPLACE FUNCTION public.escalate_engagement_response(
  p_tenant_id uuid,
  p_prospect_id uuid DEFAULT NULL,
  p_thread_id uuid,
  p_message_id uuid DEFAULT NULL,
  p_classification_id uuid DEFAULT NULL,
  p_escalation_type text,
  p_severity text DEFAULT 'medium',
  p_reason text,
  p_status text DEFAULT 'open',
  p_assigned_to uuid DEFAULT NULL,
  p_work_queue_item_id uuid DEFAULT NULL
)
RETURNS public.engagement_escalations
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_row public.engagement_escalations;
BEGIN
  INSERT INTO public.engagement_escalations (
    tenant_id, prospect_id, thread_id, message_id, classification_id,
    escalation_type, severity, reason, status, assigned_to, work_queue_item_id, created_at
  ) VALUES (
    p_tenant_id, p_prospect_id, p_thread_id, p_message_id, p_classification_id,
    p_escalation_type, p_severity, p_reason, p_status, p_assigned_to, p_work_queue_item_id, NOW()
  ) RETURNING * INTO v_row;

  RETURN v_row;
END;
$$;

CREATE OR REPLACE FUNCTION public.resolve_engagement_escalation(
  p_escalation_id uuid,
  p_resolved_by uuid DEFAULT NULL,
  p_resolution_notes text DEFAULT NULL
)
RETURNS public.engagement_escalations
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_row public.engagement_escalations;
BEGIN
  UPDATE public.engagement_escalations
  SET status = 'resolved',
      resolved_at = NOW(),
      resolved_by = p_resolved_by,
      resolution_notes = p_resolution_notes
  WHERE id = p_escalation_id
  RETURNING * INTO v_row;

  RETURN v_row;
END;
$$;

CREATE OR REPLACE FUNCTION public.get_ai_engagement_review_queue(p_tenant_id uuid DEFAULT NULL)
RETURNS TABLE (
  id uuid,
  prospect_id uuid,
  platform text,
  channel text,
  suggestion_type text,
  status text,
  confidence_score numeric,
  created_at timestamptz,
  content text
)
LANGUAGE sql
SECURITY DEFINER
SET search_path = public, auth
AS $$
  SELECT id, prospect_id, platform, channel, suggestion_type, status, confidence_score, generated_at, content
  FROM public.ai_engagement_suggestions
  WHERE (p_tenant_id IS NULL OR tenant_id = p_tenant_id)
    AND status IN ('generated', 'needs_review', 'approved')
  ORDER BY generated_at DESC;
$$;

CREATE OR REPLACE FUNCTION public.get_engagement_timeline(p_tenant_id uuid DEFAULT NULL, p_prospect_id uuid DEFAULT NULL)
RETURNS TABLE (
  object_type text,
  object_id uuid,
  related_thread_id uuid,
  created_at timestamptz,
  status text,
  summary text
)
LANGUAGE sql
SECURITY DEFINER
SET search_path = public, auth
AS $$
  SELECT 'suggestion'::text, id, engagement_thread_id, generated_at, status, content
  FROM public.ai_engagement_suggestions
  WHERE (p_tenant_id IS NULL OR tenant_id = p_tenant_id)
    AND (p_prospect_id IS NULL OR prospect_id = p_prospect_id)
  UNION ALL
  SELECT 'attempt', id, thread_id, attempted_at, status, COALESCE(content_snapshot, 'outreach attempt')
  FROM public.engagement_outreach_attempts
  WHERE (p_tenant_id IS NULL OR tenant_id = p_tenant_id)
    AND (p_prospect_id IS NULL OR prospect_id = p_prospect_id)
  UNION ALL
  SELECT 'reminder', id, thread_id, created_at, status, reason
  FROM public.engagement_follow_up_reminders
  WHERE (p_tenant_id IS NULL OR tenant_id = p_tenant_id)
    AND (p_prospect_id IS NULL OR prospect_id = p_prospect_id)
  ORDER BY created_at DESC;
$$;

COMMIT;
