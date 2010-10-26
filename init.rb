require 'redmine'
require 'ftools'
require 'dispatcher'

#require_dependency 'user_model_patch'
#require_dependency 'account_controller_patch'

# Patches
require_dependency 'project_model_patch'
require_dependency 'issue_model_patch'
require_dependency 'issues_controller_patch'

Dispatcher.to_prepare do
  Project.send(:include, ProjectModelPatch)
  Issue.send(:include, IssueModelPatch)
  IssuesController.send(:include, IssuesControllerPatch)
end

# Hooks
require_dependency 'redmine_nicta/git_project_hook'
require_dependency 'redmine_nicta/experiment_issue_hook'
require_dependency 'redmine_nicta/user_project_hook'

# Wiki Macros
require_dependency 'wiki_experiment_macros'

Redmine::Plugin.register :redmine_nicta do
  name 'Nicta Redmine plugin'
  author 'InContext'
  description 'This is a experiement management plugin for Nicta'
  version '0.2'

  menu :project_menu, :experiments, {:controller => 'experiments', :action => 'index'}, :param => :project_id, :caption => :label_experiment_plural, :after => :files, :if => Proc.new { User.current.logged? }
  menu :project_menu, :reservations, {:controller => 'reservations', :action => 'index'}, :param => :project_id, :caption => :label_reservation_plural, :after => :files, :if => Proc.new { User.current.logged? }

  project_module :nicta do
    permission :view_experiments, :experiments => [:show, :index]
    permission :manage_experiments, :experiments => [:new, :edit, :create, :commit, :change_experiment, :change_experiment_version, :edit_copy, :copy]
    permission :view_reservations, :reservations => [:index]
    permission :edit_reservations, :reservations => [:new, :create, :update, :edit]
    permission :manage_reservations, :reservations => [:approve, :destroy]
  end
end
