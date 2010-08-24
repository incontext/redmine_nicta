# Hooks to attach to the Redmine Issues.

require 'sqlite3'

class ExperimentIssueHook < Redmine::Hook::ViewListener

  attr_accessor :experiment_properties

  def protect_against_forgery?
    false
  end

  # Context:
  # * :issue => Issue being rendered
  #
  def view_issues_show_details_bottom(context = { })
    script_path = html_escape(context[:issue].script_path)
    identifier = html_escape(context[:issue].identifier)
    log_data = html_escape(context[:issue].log_data)
    experiment = context[:issue].experiment
    if experiment
      details = javascript_include_tag('dygraph-combined.js', :plugin => 'redmine_nicta')
      details << stylesheet_link_tag('graph', :plugin => 'redmine_nicta')
      if context[:issue].experiment_attributes
        experiment_attributes = YAML::load(context[:issue].experiment_attributes)
        details <<  "<table class='attributes'>"
        experiment_attributes.each_pair do |k, v|
          details << "<tr><th>#{k}</th><td>#{v}</td></tr>"
        end
      end
      details << "<tr><th>Experiment script</th><td>#{experiment.script_path}</td></tr>"
      details << "<tr><th>Experiment version</th><td>#{context[:issue].experiment_version}</td></tr>"
      details << "</table>"
      #render sqlite3 result
      context[:issue].attachments.find_all {|v| v.filename =~ /\.sq3$/}.each do |attachment|
        details << render_graph(attachment.diskfile)
      end
      return details
    end
  end

  # Context:
  # * :form => Edit form
  # * :project => Current project
  #
  def view_issues_form_details_bottom(context = { })
    experiments = context[:project].committed_experiments

    if !experiments.empty?
      experiment_field = context[:form].select :experiment_id, (experiments.each.collect {|v, index| ["#{v.identifier}", v.id]}), :required => true
      experiment_version_field = context[:form].select :experiment_version, (experiments.first.commits.each.collect {|v| v.sha}), :required => true

      repo = Grit::Repo.new(AppConfig.git_dir + context[:project].identifier)
      tree = repo.tree('HEAD', experiments.first.script_path)

      define_attributes(tree.contents.first.data)

      form_fields = "<p>#{experiment_field}</p><p>#{experiment_version_field}</p>"
      form_fields << "<div id = 'experiment_properties'>"
      experiment_properties.each do |p|
        form_fields << "<p>"
        form_fields << label_tag(p[0]) + text_field_tag("issue[experiment_attributes][#{p[0]}]", p[1])
        form_fields << "</p>"
      end
      form_fields << "</div>"
      experiment_observer = observe_field(
        "issue_experiment_id",
        :url=>{:controller=>:experiments, :action=>:change_experiment, :project_id => context[:project]}, :with => 'experiment_id')
      return form_fields + experiment_observer
    end
  end

  def controller_issues_new_before_save(context)
    context[:issue].experiment_attributes  = context[:params][:issue][:experiment_attributes]
    context[:issue].experiment_id  = context[:params][:issue][:experiment_id]
    context[:issue].experiment_version  = context[:params][:issue][:experiment_version]
  end

  #controller_issues_move_before_save, { :params => params, :issue => issue, :target_project => @target_project, :copy => !!@copy })
  def controller_issues_move_before_save(context)
    issue = context[:issue]
    source_experiment = issue.experiment
    source_project = issue.project
    target_project = context[:target_project]

    if source_experiment && source_project
      target_experiment = Experiment.new
      unique_identifier = "#{source_project.identifier}_#{source_experiment.identifier}"
      target_experiment.identifier = unique_identifier
      target_experiment.project = target_project
      target_experiment.experiment_type = source_experiment.experiment_type
      target_experiment.user = User.current
      target_experiment = target_experiment.copy_to_project(source_experiment, issue.experiment_version)
      issue.experiment_id = target_experiment.id
      issue.experiment_version = target_experiment.commits.first.sha if target_experiment.script_committed?
    end
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

  def render_graph(result_filename)
    db = SQLite3::Database.new(result_filename)
    db.results_as_hash = true
    tables = db.execute( "select name from sqlite_master where type = 'table'" ).map {|v| v['name']}.flatten.find_all {|v| !(v =~ /^_/)}
    tables.map do |table|
      rows = db.execute( "select * from #{table} join _senders where oml_sender_id = _senders.id")
      graph_rows = rows.map do |row|
        {}.tap do |hash|
          row.keys.each do |key|
            if !(key =~ /^oml/ || key =~ /id$/ || key.class == Fixnum) && row[key] =~ /^(-|\.|[0-9])+$/
              hash[key] = row[key]
            end
          end
          hash['oml_ts_server'] = row['oml_ts_server']
        end
      end
      build_graph(table, graph_rows) unless graph_rows.empty? || graph_rows.first.keys.size < 2
    end.join("")
  end

  def build_graph(table, rows)
    "
    <hr />
    <p><b>Graph #{table}</b></p>
    <div class=\"graph\" id=\"graph_#{table}\" style=\"width: 550px; height: 350px;\"></div>
    <script type=\"text/javascript\">
      g = new Dygraph(
        document.getElementById(\"graph_#{table}\"),
    " +
    "\"oml_ts_server,#{(rows.first.keys-['oml_ts_server']).join(',')}\\n\" + " +
    rows.map { |row| "\"#{([row['oml_ts_server']] + row.except('oml_ts_server').values).join(',')}\\n\"" }.join(' + ') +
    "
      );
      function stockchange(el) {
        g.setVisibility(el.id, el.checked);
      }
    </script>
    <p>Display:
    " +
    (rows.first.keys-['oml_ts_server']).each_with_index.map do |key, index|
      "
      <input type=\"checkbox\" checked=\"\" onclick=\"stockchange(this)\" id=\"#{index}\">
      <label for=\"#{index}\"> #{key} </label>
      "
    end.join("") +
    "
    </p>
    "
  end
end
