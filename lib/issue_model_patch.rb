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
      alias_method_chain :copy_from, :attachments
    end
  end

  module ClassMethods
  end

  module InstanceMethods
    def copy_from_with_attachments(arg)
      issue = arg.is_a?(Issue) ? arg : Issue.visible.find(arg)
      self.attributes = issue.attributes.dup.except("id", "root_id", "parent_id", "lft", "rgt", "created_on", "updated_on")
      self.custom_field_values = issue.custom_field_values.inject({}) {|h,v| h[v.custom_field_id] = v.value; h}
      self.status = issue.status
      self.attachments = issue.attachments
      self
    end
  end
end

