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
      after_create :assign_identifier_and_script_path
      after_create :create_event
    end

  end

  module ClassMethods
  end

  module InstanceMethods
    private

    def assign_identifier_and_script_path
      self.identifier ||= "script#{id}"
      self.script_path ||= "script#{id}.rb"
      self.save!
    end

    def create_event
      Event.create!(:name => subject, :start_at => Time.zone.now, :end_at => 2.hours.from_now)
    end
  end
end

