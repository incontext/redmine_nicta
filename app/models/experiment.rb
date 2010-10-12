class Experiment < ActiveRecord::Base
  has_many :issues
  belongs_to :project
  belongs_to :user
  validates_presence_of :identifier, :experiment_type, :project_id, :user_id
  validates_uniqueness_of :identifier, :scope => [:project_id]

  attr_accessor :experiment_properties

  def script_path
    "#{identifier}.rb"
  end

  def script_committed?
    return !revisions.empty?
  end

  def revisions(sha = nil)
    repo = Grit::Repo.new(AppConfig.git_dir + project.identifier)
    repo.log('HEAD', script_path)
  end

  def revision(sha = nil)
    sha.nil? ? revisions.first : revisions.find {|v| v.sha == sha}
  end

  def script_content(sha = nil)
    repo = Grit::Repo.new(AppConfig.git_dir + project.identifier)
    tree = repo.tree(sha || "HEAD", script_path)
    !tree.contents.empty? && tree.contents.first.data
  end

  def pretty_commit_id(sha)
    rs = revisions
    r = rs.find {|v| v.sha == sha} if !rs.empty?
    r ? "#{rs.size - rs.index(r)}: #{r.message}" : nil
  end

  def commit(content, message = 'Default Commit Message')
    repo = Grit::Repo.new(AppConfig.git_dir + project.identifier)
    dir = AppConfig.git_dir + project.identifier
    commit_index(repo, dir, script_path, content, message)
  end

  def copy_to_project(source_experiment, version = "HEAD")
    destination_project = project
    source_project = source_experiment.project

    destination_repo = Grit::Repo.new(AppConfig.git_dir + destination_project.identifier)
    source_repo = Grit::Repo.new(AppConfig.git_dir + source_project.identifier)

    source_tree = source_repo.tree(version, source_experiment.script_path)
    script_content = source_tree.contents.first.data unless source_tree.contents.empty?

    commit_index(destination_repo,
                 AppConfig.git_dir + destination_project.identifier,
                 script_path,
                 script_content,
                 "Copied from #{source_project.identifier} (updated by #{user.login} at #{Time.now.to_s})")

    destination_tree = destination_repo.tree("HEAD", script_path)
    raise "Failed to copy script across" if destination_repo.contents.empty?
    target_experiment = Experiment.find_by_identifier_and_project_id(identifier, project_id)
    if target_experiment.nil?
      save!
      return self
    else
      return target_experiment
    end
  end

  def define_attributes(content)
    self.experiment_properties = []
    content.each do |line|
      if line =~ /^\s*defProperty\('.*'\)/
        eval(line)
      end
    end
  end

  private

  def commit_index(repo, dir, file_path, file_content, message)
    begin
      Dir.chdir(dir) do
        f = File.open(file_path, 'w')
        f.write(file_content)
        f.close
        repo.add(file_path)
        repo.commit_index(message)
      end
    rescue => e
      logger.error e.message
      logger.error e.backtrace
      Dir.chdir(dir) do
        system "git reset --hard"
      end
      raise e
    end
  end

  def defProperty(name, default, desc)
    self.experiment_properties << [name, default]
  end
end
