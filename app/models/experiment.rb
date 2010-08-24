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
    return !commits.empty?
  end

  def commits
    repo = Grit::Repo.new(AppConfig.git_dir + project.identifier)
    repo.log('HEAD', script_path)
  end

  def copy_to_project(source_experiment)
    destination_project = project
    source_project = source_experiment.project

    destination_repo = Grit::Repo.new(AppConfig.git_dir + destination_project.identifier)
    source_repo = Grit::Repo.new(AppConfig.git_dir + source_project.identifier)

    source_tree = source_repo.tree("HEAD", source_experiment.script_path)
    script_content = source_tree.contents.first.data unless source_tree.contents.empty?

    begin
      Dir.chdir(AppConfig.git_dir + destination_project.identifier) do
        f = File.open(script_path, 'w')
        f.write(script_content)
        f.close
        destination_repo.add(script_path)
        destination_repo.commit_index("Copied from #{source_project.identifier} (updated by #{user.login} at #{Time.now.to_s})")
      end
    rescue => e
      logger.error e.message
      logger.error e.backtrace
      Dir.chdir(AppConfig.git_dir + destination_project.identifier) do
        system "git reset --hard"
      end
    end

    destination_tree = source_repo.tree("HEAD", script_path)
    raise "Failed to copy script across" if source_tree.contents.empty?
    save! if Experiment.find_by_identifier_and_project_id(identifier, project_id).nil?
  end
end
