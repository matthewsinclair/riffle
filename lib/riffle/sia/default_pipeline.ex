defmodule Riffle.Sia.DefaultPipeline do
  @moduledoc """
  Riffle's sense-infer-act definitions, in module form.

  `priv/sia/sia.pred` carries the same definitions as a `.pred` file. The two
  are deliberately identical: a run from this module and a run from that file
  must produce the same items with the same tags, and `sources_test` holds
  them to it with the evaluation cache off, so the agreement is real rather
  than a cache hit.

  Three loops -- signal, inference, action -- and the pattern layer takes each
  loop as one stage. Sense-infer-act is what these particular definitions say,
  not a shape `Riffle.Sia` imposes.

  Point `config :riffle, :default_pipeline` at this module to make it the
  `:default_module` source. That configuration is also how the engine resolves
  a bare predicate reference: the engine names no pipeline module of its own,
  and this is the injection that replaced the hardcoded reference the ported
  code arrived with.
  """

  use Riffle.Predicate.Dsl.Macro
  use Riffle.Predicate.DefaultPipelineConfig

  @pred_path "sia/sia.pred"

  @doc """
  The path to the `.pred` file carrying these same definitions.

  Resolved through the application directory rather than the source tree, so
  it holds in a release.
  """
  @spec pred_path() :: Path.t()
  def pred_path, do: Application.app_dir(:riffle, Path.join("priv", @pred_path))

  # -- sense: what the raw fields say -----------------------------------------

  defpredicate :signal_high_activity, "Users with high login activity" do
    expr(@login_count > 50)
  end

  defpredicate :signal_churn_risk, "Active users who have not logged in recently" do
    expr(@days_since_login > 30 && @subscription_status == "active")
  end

  defpredicate :signal_premium_account, "Users on a premium account" do
    expr(@account_type == "premium")
  end

  # -- infer: what the signals mean -------------------------------------------

  defpredicate :inference_high_value_user, "Identifies high-value users" do
    expr(
      has_tag(:signal_high_activity) ||
        (has_tag(:signal_premium_account) && has_tag(:signal_high_activity))
    )
  end

  defpredicate :inference_upsell_opportunity, "Identifies upsell opportunities" do
    expr(has_tag(:signal_high_activity) && !has_tag(:signal_premium_account))
  end

  # -- act: what follows from the inferences ----------------------------------

  defpredicate :action_send_promotion, "Sends a promotion to high-value users" do
    expr(has_tag(:inference_high_value_user))
  end

  defpredicate :action_create_upsell, "Creates an upsell opportunity" do
    expr(has_tag(:inference_upsell_opportunity))
  end

  # -- the stages -------------------------------------------------------------

  defloop :signal_loop, "Signal detection" do
    predicate(:signal_high_activity)
    predicate(:signal_churn_risk)
    predicate(:signal_premium_account)
  end

  defloop :inference_loop, "Inference generation" do
    predicate(:inference_high_value_user)
    predicate(:inference_upsell_opportunity)
  end

  defloop :action_loop, "Action execution" do
    predicate(:action_send_promotion)
    predicate(:action_create_upsell)
  end

  # -- the entry points -------------------------------------------------------
  #
  # A loop ORs its predicates and a pipeline ANDs its loops, so each pipeline
  # below is a strictly narrower cut than the one before it.

  defpipeline :sense_pipeline, "Signal detection only" do
    loop(:signal_loop)
  end

  defpipeline :infer_pipeline, "Signal detection and inference" do
    loop(:signal_loop)
    loop(:inference_loop)
  end

  defpipeline :main, "The complete sense-infer-act pipeline" do
    loop(:signal_loop)
    loop(:inference_loop)
    loop(:action_loop)
  end
end
