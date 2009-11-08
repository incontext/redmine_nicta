require 'redmine'
require 'git'

#require_dependency 'user_model_patch'
#require_dependency 'account_controller_patch'

# Hooks
require_dependency 'script_path_issue_hook'

Redmine::Plugin.register :redmine_nicta do
  name 'Nicta Redmine plugin'
  author 'InContext'
  description 'This is a plugin for Nicta'
  version '0.0.5'
end
