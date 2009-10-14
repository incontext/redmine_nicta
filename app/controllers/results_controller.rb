require 'hpricot'

class ResultsController < ApplicationController
  unloadable

  before_filter :basic_authenticate

  def create
    doc, items = Hpricot::XML(request.raw_post), []
    outcome = (doc/"experiment-outcome").first
    outcome_script = (doc/"experiment-outcome"/"script").first
    outcome_measurments = (doc/"experiment-outcome"/"measurements").first

    project = Project.find_by_identifier(outcome.at('project').innerHTML)
    user = User.find_by_login(outcome.at('userid').innerHTML)
    script = Issue.find_by_subject(project.identifier + '_' + outcome.at('id').innerHTML) || Issue.new

    ActiveRecord::Base.transaction do
      begin
        if script.new_record?
          script.project = project
          script.author = user
          script.subject = project.identifier + '_' + outcome.at('id').innerHTML
          script.tracker = Tracker.find_by_name('Script')
          field_values = [['Type', 'Wifi'], ['Batch', '1'], ['Resume', '1']].inject ({}) do |hash, field_value|
            field = IssueCustomField.find_by_name(field_value[0])
            hash[field.id] = field_value[1] if field
            hash
          end
          script.custom_field_values = field_values
          script.save!
        end

        script_run = Issue.new
        script_run.tracker = Tracker.find_by_name('Script run')
        script_run.project = project
        script_run.author = user
        script_run.subject = 'Experiment outcome for ' + script.subject
        field_values = [['Script version', outcome_script.at('revision').innerHTML],
         ['Script uri', outcome_script.at('uri').innerHTML],
         ['Log file', outcome_measurments.at('log').innerHTML],
         ['Log data', outcome_measurments.at('logdata').innerHTML],
         ['Run start time', Time.parse(outcome.at('start').innerHTML).strftime('%I:%M:%S %p')],
         ['Run duration', outcome.at('duration').innerHTML],
         ['Measurements DB', outcome_measurments.at('database').innerHTML],
         ['Measurements metadata', outcome_measurments.at('metadata').innerHTML]].inject ({}) do |hash, field_value|
          field = IssueCustomField.find_by_name(field_value[0])
          hash[field.id] = field_value[1] if field
          hash
        end
        script_run.custom_field_values = field_values
        script_run.save!
        script_run.move_to_child_of(script)
        render :xml => {:notice => 'Added experiment outcome'}, :status => 201
      rescue
        render :xml => {:error => 'Failed to add experiment outcome' + e.backtrace.join(' ')}, :status => 500
      end
    end
  end

  private
  def basic_authenticate
    authenticate_or_request_with_http_basic('application') do |uname, password|
      User.find_by_login(uname).check_password?(password)
    end
  end
end
