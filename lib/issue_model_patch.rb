require_dependency 'issue'

module IssueModelPatch
  def self.included(base)
    base.extend(ClassMethods)
    base.send(:include, InstanceMethods)

    # Same as typing in the class
    base.class_eval do
      unloadable # Send unloadable so it will not be unloaded in development
      validates_uniqueness_of :identifier, :scope => :project_id unless 'identifier.nil?'
      validates_format_of :identifier, :with => /^[A-Za-z0-9]+$/ unless 'identifier.nil?'
    end

  end

  module ClassMethods
  end

  module InstanceMethods
  end
end

