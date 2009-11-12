require_dependency 'project'

module ProjectModelPatch
  def self.included(base)
    base.extend(ClassMethods)
    base.send(:include, InstanceMethods)

    # Same as typing in the class
    base.class_eval do
      unloadable # Send unloadable so it will not be unloaded in development
      after_save :init_git_repository
    end

  end

  module ClassMethods
  end

  module InstanceMethods
    private

    def init_git_repository
      begin
        g = Git.init(AppConfig['git_dir'] + identifier) if git_repository
        g.chdir do
          f = File.open('README', 'w')
          f.write('Git repository for project: ' + identifier)
          f.close
          g.add('README')
          g.commit('Initial commit for project: ' + identifier)
        end
      rescue => e
        logger.error e.message
      end
    end
  end
end

