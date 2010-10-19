# Hooks to attach to the Redmine project
class GitProjectHook  < Redmine::Hook::ViewListener
  # Context :project, :form
  def view_projects_form(context = {})
    begin
      g = Grit::Repo.new(AppConfig.git_dir + context[:project].identifier)
      html = "<p><label for='create git repository'>Git repository path</label>#{g.git.work_tree}</p>"
    rescue
      html = "<p>
                <input name='project[git_repository]' type='hidden' value='1' />
              </p>"
    end
    return html
  end
end
