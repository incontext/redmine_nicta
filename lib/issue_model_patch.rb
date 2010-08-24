require_dependency 'issue'

module IssueModelPatch
  def self.included(base)
    base.extend(ClassMethods)
    base.send(:include, InstanceMethods)

    # Same as typing in the class
    base.class_eval do
      unloadable # Send unloadable so it will not be unloaded in development
      belongs_to :experiment
      belongs_to :reservation
    end
  end

  module ClassMethods
  end

  module InstanceMethods
  end
end

