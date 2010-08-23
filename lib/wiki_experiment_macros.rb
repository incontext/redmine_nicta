require 'redmine'

module WikiExperimentMacros
  Redmine::WikiFormatting::Macros.register do
    desc "Display experiments of the page."
    macro :experiment_script do |obj, args|
      @project = Project.find(args[0])
      @experiment = Experiment.find_by_identifier(args[1])
      version = args[2] || 'HEAD'

      allowed = User.current.allowed_to?({:controller => 'experiments', :action => 'edit'}, @project)

      if allowed
        @script_path = @experiment.script_path
        @repo = Grit::Repo.new(AppConfig.git_dir + @project.identifier)
        tree = @repo.tree(version, @script_path)
        unless tree.contents.empty?
          @script = tree.contents.first
          @commits = @experiment.commits
          @commit = @commits.find {|v| v.sha == version} || @commits.first
          textilizable "<pre><code class=\"ruby\">#{@script.data}</code></pre>"
        else
          raise "Empty script"
        end
      else
        raise "Access to experiment script #{@experiment.identifier} denied"
      end
    end
  end
end
