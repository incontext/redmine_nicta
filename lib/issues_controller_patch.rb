require_dependency 'issues_controller'

module IssuesControllerPatch
  def self.included(base)
    base.extend(ClassMethods)
    base.send(:include, InstanceMethods)

    # Same as typing in the class
    base.class_eval do
      include ExperimentsHelper
      helper :experiments
    end
  end

  module ClassMethods
  end

  module InstanceMethods
  end
end

