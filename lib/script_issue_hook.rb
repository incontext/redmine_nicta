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
      script_version = html_escape(context[:issue].script_version)
      if context[:issue].parent and context[:issue].parent.identifier and context[:issue].parent.script_path and script_version != ''
        data = "<tr><td><b>Script version :</b></td>"
        data << "<td><a href= '/projects/#{context[:project].identifier}/scripts/#{script_version}/#{context[:issue].parent.identifier}/#{context[:issue].parent.script_path}'>#{script_version}</a></td></tr>"
      else
        data = "<tr><td><b>Script version :</b></td><td>#{script_version}</td></tr>"
      end

      attribute_text = html_escape(context[:issue].attribute_text)
      attribute_text_display = "<div style='height: 100px; overflow: auto;'><table width=100%>"
      display_content = attribute_text.split(',').inject '' do |str, v|
        v_pair = v.split(':')
        str << "<tr><td>#{v_pair[0]}</td><td>#{v_pair[1]}</td></tr>"
        str
      end
      attribute_text_display << display_content
      attribute_text_display << "</table></div>"
      data << "<tr><td valign='top'><b>Attribute text :</b></td><td colspan=3>#{attribute_text_display}</td></tr>"
      log_data = html_escape(context[:issue].log_data)
      data << "<tr><td valign='top'><b>Log data :</b></td><td colspan=3>"
      data << (log_data != '' ? "#{log_data[0, 64]}... (<a href='#' onclick=\"$('log_data').toggle();\">more</a>)<div id='log_data' style='display: none; height: 100px; margin-top: 10px; overflow: auto;'>#{log_data}</div>" : '')
      data << "</td></tr>"
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
      status_done = context[:issue].status.name == 'Done'
      script_version_field = ''
      begin
        g =  Git.open(AppConfig['git_dir'] + context[:project].identifier)
        parent_issue = context[:issue].parent
        commits = g.gblob("#{parent_issue.identifier}/#{parent_issue.script_path}").log
        script_version_field = context[:form].select(:script_version, commits.collect {|v| [v.message, v.sha]}, {:disabled => status_done ? 'restricted' : ''})
      rescue
        script_version_field = context[:form].select(:script_version, [[]], {:disabled => status_done ? 'restricted' : ''})
      end
      attribute_text_field = context[:form].text_area :attribute_text, :rows => 3, :style => 'width: 90%', :disabled => status_done ? 'disabled' : ''
      log_data_field = context[:form].text_area :log_data, :rows => 3, :style => 'width: 90%', :disabled => status_done ? 'disabled' : ''
      return "<p>#{script_version_field}</p><p>#{attribute_text_field}</p><p>#{log_data_field}</p>"
    else
      return ''
    end
  end

end
