# Hooks to attach to the Redmine Issues.
class ScriptIssueHook  < Redmine::Hook::ViewListener

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
      experiment_attributes = YAML::load(context[:issue].experiment_attributes)
      details = ""
      details <<  "<table class='attributes'>"
      experiment_attributes.each_pair do |k, v|
        details << "<tr><th>#{k}</th><td>#{v}</td></tr>"
      end
      details << "<tr><th>Experiment script</th><td>#{experiment.script_path if experiment}</td></tr>"
      details << "<tr><th>Experiment version</th><td>#{context[:issue].experiment_version}</td></tr>"
      details << "</table>"
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

      repo = Grit::Repo.new(AppConfig.git_dir + context[:project].identifier)
      tree = repo.tree('HEAD', experiments.first.script_path)

      define_attributes(tree.contents.first.data)

      form_fields = "<p>#{experiment_field}</p>"
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
