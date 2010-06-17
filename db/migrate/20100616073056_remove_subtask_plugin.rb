class RemoveSubtaskPlugin < ActiveRecord::Migration
  def self.up
    issue_columns = Issue.column_names
    query_columns = Query.column_names

    if Redmine::Plugin.all.find {|v| v.id == :redmine_subtasks}
      remove_column :issues, :parent_id if issue_columns.include? :parent_id.to_s
      remove_column :issues, :lft if issue_columns.include? :lft.to_s
      remove_column :issues, :rgt if issue_columns.include? :rgt.to_s
      remove_column :queries, :view_options if query_columns.include? :view_options.to_s
    end
  end

  def self.down
  end
end
