require 'redmine'

module WikiExperimentMacros
  Redmine::WikiFormatting::Macros.register do
    desc "Display experiments of the page."
    macro :oedl_script do |obj, args|
      @project = Project.find(args[0])
      @experiment = @project.experiments.find(:first, :conditions => {:identifier => args[1] })
      version = args[2] || 'HEAD'

      allowed = User.current.allowed_to?({:controller => 'experiments', :action => 'show'}, @project)

      if allowed
        if @experiment.script_committed?
          textilizable "<pre><code class=\"ruby\">#{@experiment.script_content(version)}</code></pre>"
        else
          raise "Empty script"
        end
      else
        raise "Access to experiment script #{@experiment.identifier} denied"
      end
    end
  end
end
