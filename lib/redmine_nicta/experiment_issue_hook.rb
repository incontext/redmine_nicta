module RedmineNicta
  class ExperimentIssueHook < Redmine::Hook::ViewListener
    render_on :view_issues_show_details_bottom,
              :partial => 'hooks/redmine_nicta/view_issues_show_details_bottom'

    render_on :view_issues_form_details_bottom,
              :partial => 'hooks/redmine_nicta/view_issues_form_details_bottom'

    def set_experiment_properties(context)
      [:experiment_attributes, :experiment_id, :experiment_version, :reservation_id].each do |v|
        context[:issue].send("#{v.to_s}=", context[:params][:issue][v])
      end
    end

    def controller_issues_new_before_save(context)
      set_experiment_properties(context)
    end

    def controller_issues_edit_before_save(context)
      set_experiment_properties(context)
    end

    #controller_issues_move_before_save, { :params => params, :issue => issue, :target_project => @target_project, :copy => !!@copy })
    def controller_issues_move_before_save(context)
      issue = context[:issue]
      source_experiment = issue.experiment
      source_project = issue.project
      target_project = context[:target_project]

      if source_experiment && source_project
        target_experiment = Experiment.new(
          :identifier => source_experiment.identifier,
          :project => target_project,
          :experiment_type => source_experiment.experiment_type,
          :user => User.current)
        target_experiment = target_experiment.copy_to_project(source_experiment, issue.experiment_version)
        issue.experiment_id = target_experiment.id
        issue.experiment_version = target_experiment.revision.sha if target_experiment.script_committed?
      end
    end
  end
end
