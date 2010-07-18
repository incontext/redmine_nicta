# Hooks to attach to the Redmine Issues.
class ScriptIssueHook  < Redmine::Hook::ViewListener

  attr_accessor :experiment_properties

  # Context:
  # * :issue => Issue being rendered
  #
  def view_issues_show_details_bottom(context = { })
    case context[:issue].tracker.name
    when 'Script'
      script_path = html_escape(context[:issue].script_path)
      identifier = html_escape(context[:issue].identifier)
      data = "<td><b>Script path :</b></td>"
      if context[:issue].identifier and context[:project].git_repository
        data << "<td><a href= '/projects/#{context[:project].identifier}/scripts/master/#{context[:issue].identifier}/#{script_path}'>#{script_path}</a></td>"
      else
        data << "<td>#{script_path}</td>"
      end
      data << "
        <td><b>Identifier :</b></td>
        <td>#{identifier}</td>"
      return "<tr>#{data}<td></td></tr>"
    when 'Script run'
      script_version = html_escape(context[:issue].script_version)
      if context[:parent_issue] and context[:parent_issue].identifier and context[:parent_issue].script_path and script_version != ''
        data = "<tr><td><b>Script version :</b></td>"
        begin
          g = Git.open(AppConfig['git_dir'] + context[:project].identifier)
          script_path = "#{context[:parent_issue].identifier}/#{context[:parent_issue].script_path}"
          commits = g.gblob(script_path).log
          data << "<td><a href= '/projects/#{context[:project].identifier}/scripts/#{script_version}/#{script_path}'>#{script_path} -- v #{commits.size - commits.to_a.index {|v| v.sha == script_version}}</a></td></tr>"
        rescue => e
          data << "<td>#{script_version} (#{e.message})</td>"
        end
      else
        data = "<tr><td><b>Script version :</b></td><td>#{script_version}</td></tr>"
      end

      attribute_text = html_escape(context[:issue].attribute_text)
      attribute_text_display = "<div style='height: 100px; overflow: auto;'><table width=50%>"
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
      #return ''
      attribute_text.to_s
    end
  end

  # Context:
  # * :form => Edit form
  # * :project => Current project
  #
  def view_issues_form_details_bottom(context = { })
    #case context[:issue].tracker.name
    #when 'Script run'
    #  status_done = context[:issue].status.name == 'Done'
    #  script_version_field = ''
    #  begin
    #    g =  Git.open(AppConfig['git_dir'] + context[:project].identifier)
    #    parent_issue = context[:parent_issue]
    #    commits = g.gblob("#{parent_issue.identifier}/#{parent_issue.script_path}").log
    #    script_version_field = context[:form].select :script_version, commits.each_with_index.collect {|v, index| ["#{commits.size - index} #{v.message}", v.sha]}
    #  rescue
    #    script_version_field = context[:form].select :script_version, [[]]
    #  end
    #  attribute_text_field = context[:form].text_area :attribute_text, :rows => 3, :style => 'width: 90%'
    #  log_data_field = context[:form].text_area :log_data, :rows => 3, :style => 'width: 90%'
#
    # hide_fields_script =
    #    "<script type='text/javascript'>
    #        var form_fields = $('issue-form').getElements();
    #        for (x in form_fields) {
    #          var field = form_fields[x];
    #          if (field.id != 'issue_status_id' && field.id != 'issue_subject' && field.id != 'issue_description') {
    #            field.disable();
    #          }
    #        }
    #    </script>" if status_done
    #  return "<p>#{script_version_field}</p><p>#{attribute_text_field}</p><p>#{log_data_field}</p>#{hide_fields_script}"
    #when 'Experiment run'
    scripts = ExperimentScript.all
    experiment_script_field = context[:form].select :experiment_script_id, scripts.each.collect {|v, index| ["#{v.script_file_name} #{v.script_updated_at}", v.id]}
    #define_attributes(File.new(scripts.first.script.path, 'r').readlines)

    form_fields = [experiment_script_field]
    #experiment_properties.each do |p|
    #  form_fields << label_tag(p[0]) + text_field_tag("issue[attribute_text][#{p[0]}]", p[1])
    #end
    return form_fields.map {|v| "<p>#{v}</p>"}.join('')
  end

  private

  def define_attributes(content)
    self.experiment_properties = []
    content.each do |line|
      if line =~ /^\s*defProperty\('.*'\)/
        eval(line)
      end
    end
  end

  def defProperty(name, default, desc)
    self.experiment_properties << [name, default]
  end
end
