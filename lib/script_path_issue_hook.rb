# Hooks to attach to the Redmine Issues.
class ScriptPathIssueHook  < Redmine::Hook::ViewListener

  # Context:
  # * :issue => Issue being rendered
  #
  def view_issues_show_details_bottom(context = { })
    if context[:issue].tracker.name == 'Script'
      script_path = html_escape(context[:issue].script_path)
      identifier = html_escape(context[:issue].identifier)
      data = "<td><b>Script path :</b></td>"
      if context[:issue].identifier
        data << "<td><a href= '/projects/#{context[:project].identifier}/scripts/master/#{context[:issue].identifier}/#{script_path}'>#{script_path}</a></td>"
      else
        data << "<td>#{script_path}</td>"
      end
      data << "
        <td><b>Indentifier :</b></td>
        <td>#{identifier}</td>"
      return "<tr>#{data}<td></td></tr>"
    else
      return ''
    end
  end

  # Context:
  # * :form => Edit form
  # * :project => Current project
  #
  def view_issues_form_details_bottom(context = { })
    if context[:issue].tracker.name == 'Script'
      script_path_text_field = context[:form].text_field :script_path
      identifier_text_field = ''
      begin
        g = Git.open(AppConfig['git_dir'] + context[:project].identifier)
        g.chdir do
          if context[:issue].identifier and File.exist?(context[:issue].identifier)
            identifier_text_field = context[:form].text_field :identifier, :disabled => 'disabled'
          else
            identifier_text_field = context[:form].text_field :identifier
          end
        end
      rescue
        identifier_text_field = context[:form].text_field :identifier
      end
      return "<p>#{script_path_text_field}</p><p>#{identifier_text_field}</p>"
    else
      return ''
    end
  end

end
