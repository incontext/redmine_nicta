# Hooks to attach to the Redmine Issues.
class ScriptPathIssueHook  < Redmine::Hook::ViewListener

  # Renders the Script path
  #
  # Context:
  # * :issue => Issue being rendered
  #
  def view_issues_show_details_bottom(context = { })
    if context[:issue].tracker.name == 'Script'
      script_path = html_escape(context[:issue].script_path)
      data = "<td><b>Script path :</b></td><td><a href= '/projects/#{context[:project].identifier}/scripts/master/#{context[:issue].subject}/#{script_path}'>#{script_path}</a></td>"
      return "<tr>#{data}<td></td></tr>"
    else
      return ''
    end
  end

  # Renders a select tag with all the Objectives
  #
  # Context:
  # * :form => Edit form
  # * :project => Current project
  #
  def view_issues_form_details_bottom(context = { })
    if context[:issue].tracker.name == 'Script'
      text_field = context[:form].text_field :script_path
      return "<p>#{text_field}</p>"
    else
      return ''
    end
  end

end
