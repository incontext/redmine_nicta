require_dependency 'project'

module ProjectModelPatch
  def self.included(base)
    base.extend(ClassMethods)
    base.send(:include, InstanceMethods)

    # Same as typing in the class
    base.class_eval do
      unloadable # Send unloadable so it will not be unloaded in development
      has_many :experiments
      has_many :reservations
      after_save :init_git_repository
    end

  end

  module ClassMethods
  end

  module InstanceMethods
    def committed_experiments
      experiments.find_all {|v| v.script_committed?}
    end

    def available_reservations
      reservations.approved.find(:all, :conditions => ["starts_at > ?", Time.now])
    end

    private

    def init_git_repository
      begin
        unless File.exist?(AppConfig.git_dir + identifier + '/.git')
          FileUtils.mkdir_p(AppConfig.git_dir + identifier)
          Dir.chdir(AppConfig.git_dir + identifier) do
            system "git init" unless File.exist?(AppConfig.git_dir + identifier + '/.git')
            g = Grit::Repo.new('.')
            f = File.open('README', 'w')
            f.write('Git repository for project: ' + identifier)
            f.close
            g.add('README')
            g.commit_index('Initial commit for project: ' + identifier)
          end
        end
        repository = Repository.factory('Git')
        repository.project = self if @repository
        repository.attributes = {:url => AppConfig.git_dir + identifier + '/.git'}
        repository.save
      rescue => e
        logger.error e.message
      end
    end
  end
end

