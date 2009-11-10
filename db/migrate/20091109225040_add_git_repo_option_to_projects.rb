class AddGitRepoOptionToProjects < ActiveRecord::Migration
  def self.up
    add_column :projects, :git_repository, :boolean
  end

  def self.down
    remove_column :projects, :git_repository
  end
end
