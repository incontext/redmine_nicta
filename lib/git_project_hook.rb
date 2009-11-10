# Hooks to attach to the Redmine project
class GitProjectHook  < Redmine::Hook::ViewListener
  # Context :project, :form
  def view_projects_form(context = {})
    begin
      g = Git.open(AppConfig['git_dir'] + context[:project].identifier)
      html = "<p><label for='create git repository'>Git repository path</label>#{g.repo}</p>"
    rescue
      html = "<p>
                <label for='create git repository'>Create Git repository</label>
                <input name='project[git_repository]' type='hidden' value='0' />
                <input id='project_git_repository' name='project[git_repository]' type='checkbox' value='1' />
              </p>"
    end
    return html
  end
end