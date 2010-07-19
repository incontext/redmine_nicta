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
      belongs_to :experiment
    end

  end

  module ClassMethods
  end

  module InstanceMethods
    private

    def assign_identifier_and_script_path
      self.identifier ||= "script#{id}"
      self.script_path ||= "script#{id}.rb"
      repo = Grit::Repo.new(NICTA['git_dir'] + project.identifier)
      log = repo.log('HEAD', experiment.script_path)
      self.experiment_version = log.first.sha
      self.save!
    end
  end
end

