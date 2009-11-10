require 'redmine'
require 'git'
require 'ftools'
require 'dispatcher'

#require_dependency 'user_model_patch'
#require_dependency 'account_controller_patch'

# Patches
require_dependency 'project_model_patch'

Dispatcher.to_prepare do
  Project.send(:include, ProjectModelPatch)
end

# Hooks
require_dependency 'script_path_issue_hook'
require_dependency 'git_project_hook'

Redmine::Plugin.register :redmine_nicta do
  name 'Nicta Redmine plugin'
  author 'InContext'
  description 'This is a plugin for Nicta'
  version '0.0.5'
end
