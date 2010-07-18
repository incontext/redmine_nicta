require 'redmine'
require 'ftools'
require 'dispatcher'

#require_dependency 'user_model_patch'
#require_dependency 'account_controller_patch'

# Patches
require_dependency 'project_model_patch'
require_dependency 'issue_model_patch'

Dispatcher.to_prepare do
  Project.send(:include, ProjectModelPatch)
  Issue.send(:include, IssueModelPatch)
end

# Hooks
require_dependency 'script_issue_hook'
require_dependency 'git_project_hook'

# Wiki Macros
require_dependency 'wiki_experiment_macros'

Redmine::Plugin.register :redmine_nicta do
  name 'Nicta Redmine plugin'
  author 'InContext'
  description 'This is a experiement management plugin for Nicta'
  version '0.1.0'

  menu :project_menu, :reservations, {:controller => 'reservations', :action => 'index'}, :caption => :label_reservation_plural
  menu :project_menu, :experiments, {:controller => 'experiments', :action => 'index'}, :param => :project_id, :caption => :label_experiment_plural

  permission :access_experiments, :experiments => [:new, :index, :edit, :create, :commit]
  permission :reservations, :reservations => [:new, :index, :create]
end

#Redmine::MenuManager.map :project_menu do |menu|
  #menu.delete :issues
  #menu.delete :new_issue
  #menu.push :issues, { :controller => 'issues', :action => 'index' }, :param => :project_id, :caption => :label_experiment_plural, :after => :roadmap
  #menu.push :new_issue, { :controller => 'issues', :action => 'new' }, :param => :project_id, :caption => :label_experiment_new, :before => :news,
  #            :html => { :accesskey => Redmine::AccessKeys.key_for(:new_issue) }
#end
