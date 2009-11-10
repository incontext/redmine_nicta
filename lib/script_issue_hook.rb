# Hooks to attach to the Redmine Issues.
class ScriptIssueHook  < Redmine::Hook::ViewListener

  # Context:
  # * :issue => Issue being rendered
  #
  def view_issues_show_details_bottom(context = { })
    case context[:issue].tracker.name
    when 'Script'
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
    when 'Script run'
      data = "<td><b>Script version :</b></td><td>#{html_escape(context[:issue].script_version)}</td>"
    else
      return ''
    end
  end

  # Context:
  # * :form => Edit form
  # * :project => Current project
  #
  def view_issues_form_details_bottom(context = { })
    case context[:issue].tracker.name
    when 'Script'
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
    when 'Script run'
      script_version_field = ''
      begin
        g =  Git.open(AppConfig['git_dir'] + context[:project].identifier)
        parent_issue = context[:issue].parent
        commits = g.gblob("#{parent_issue.identifier}/#{parent_issue.script_path}").log
        script_version_field = context[:form].select :script_version, commits.collect {|v| [v.message, v.sha]}
      rescue
        script_version_field = context[:form].select :script_version, [[]]
      end
      attribute_text_field = context[:form].text_area :attribute_text, :rows => 3, :style => 'width: 90%'
      log_data_field = context[:form].text_area :log_data, :rows => 3, :style => 'width: 90%'
      return "<p>#{script_version_field}</p><p>#{attribute_text_field}</p><p>#{log_data_field}</p>"
    else
      return ''
    end
  end

end
