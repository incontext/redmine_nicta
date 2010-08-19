class ExperimentIssueHook  < Redmine::Hook::Listener
  def controller_issues_new_before_save(context)
    context[:issue].experiment_attributes  = context[:params][:issue][:experiment_attributes]
    context[:issue].experiment_id  = context[:params][:issue][:experiment_id]
    context[:issue].experiment_version  = context[:params][:issue][:experiment_version]
  end
end
