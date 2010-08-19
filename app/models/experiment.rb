class Experiment < ActiveRecord::Base
  has_many :issues
  belongs_to :project
  belongs_to :user
  validates_presence_of :identifier, :experiment_type, :project_id, :user_id
  validates_uniqueness_of :identifier, :scope => [:project_id]

  def script_path
    "#{identifier}.rb"
  end

  def script_committed?
    repo = Grit::Repo.new(AppConfig.git_dir + project.identifier)
    tree = repo.tree("HEAD", script_path)
    return !tree.contents.empty?
  end
end
