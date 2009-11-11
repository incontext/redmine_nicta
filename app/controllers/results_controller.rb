
require 'hpricot'

class ResultsController < ApplicationController
  unloadable

  before_filter :basic_authenticate

  def create
    ActiveRecord::Base.transaction do
      begin
        doc, items = Hpricot::XML(request.raw_post), []
        outcome = (doc/"experiment-outcome").first
        outcome_script = (doc/"experiment-outcome"/"script").first
        outcome_measurments = (doc/"experiment-outcome"/"measurements").first
        outcome_properties = (doc/"experiment-outcome"/"properties"/"property")

        project = Project.find_by_identifier(outcome.at('project').innerHTML)
        user = User.find_by_login(outcome.at('userid').innerHTML)
        raise 'Project not found' unless project

        script = project.issues.find_by_identifier(outcome.at('id').innerHTML) || Issue.new

        if script.new_record?
          script.project = project
          script.author = user
          script.subject = outcome.at('id').innerHTML
          script.identifier = outcome.at('id').innerHTML
          script.tracker = Tracker.find_by_name('Script')
          field_values = [['Type', 'Wifi'], ['Batch', '0'], ['Resume', '0']].inject ({}) do |hash, field_value|
            field = IssueCustomField.find_by_name(field_value[0])
            hash[field.id] = field_value[1] if field
            hash
          end
          script.custom_field_values = field_values
        end

        #Check script source
        script_uri = outcome_script.at('uri').innerHTML
        script_source = outcome_script.at('source').innerHTML
        script_version = outcome_script.at('revision').innerHTML

        uri = URI.split(script_uri)
        uri_project, uri_dir, uri_path = uri[5].scan(/(\w+)\.git\/(\w+)\/(.+)/)[0]
        raise "Repository name doesn't match project identifier" if uri_project != project.identifier
        raise "Directory name doesn't match experiment identifier" if uri_dir != script.identifier

        script.script_path = uri_path

        g = Git.open(AppConfig['git_dir'] + project.identifier)

        if g.lib.ls_files("#{uri_dir}/#{uri_path}").empty?
          begin
            g.chdir do
              dirname = File.dirname("#{uri_dir}/#{uri_path}")
              File.makedirs dirname unless File.exist?(dirname)
              f = File.new("#{uri_dir}/#{uri_path}", 'w')
              f.write(script_source)
              f.close
              g.add("#{uri_dir}/#{uri_path}")
              g.commit_all("New file commited by http post at #{Time.now.to_s}")
            end
            script_version = g.gblob("#{uri_dir}/#{uri_path}").log.first.sha
          rescue => e
            g.reset_hard
            raise e.message
          end
        else
          contents = g.gblob("HEAD:#{uri_dir}/#{uri_path}").contents
          if contents != script_source
            begin
              g.chdir do
                f = File.new("#{uri_dir}/#{uri_path}", 'w')
                f.write(script_source)
                f.close
                g.add("#{uri_dir}/#{uri_path}")
                g.commit_all("File updated by http post at #{Time.now.to_s}")
              end
              script_version = g.gblob("#{uri_dir}/#{uri_path}").log.first.sha
            rescue => e
              g.reset_hard
              raise e.message
            end
          else
            script_version = g.gblob("#{uri_dir}/#{uri_path}").log.first.sha
          end
        end

        script.save!

        script_run = Issue.new
        script_run.tracker = Tracker.find_by_name('Script run')
        script_run.status = IssueStatus.find_by_name('Done')
        script_run.project = project
        script_run.author = user
        script_run.subject = 'Experiment outcome for ' + script.identifier
        field_values = [
          ['Log file', outcome_measurments.at('log').innerHTML],
          ['Run start time', Time.parse(outcome.at('start').innerHTML).strftime('%m/%d/%Y %I:%M:%S %p %Z')],
          ['Run duration', outcome.at('duration').innerHTML],
          ['Measurements DB', outcome_measurments.at('database').innerHTML],
          ['Measurements metadata', outcome_measurments.at('metadata').innerHTML]].inject ({}) do |hash, field_value|
          field = IssueCustomField.find_by_name(field_value[0])
          hash[field.id] = field_value[1] if field
          hash
        end

        script_run.script_version = script_version
        script_run.log_data = outcome_measurments.at('logdata').innerHTML
        #parse propertities data to attributes
        attribute_text = outcome_properties.map {|v| "#{v.attributes['name']}: #{v.innerHTML}"}.join(', ')
        script_run.attribute_text = attribute_text

        script_run.custom_field_values = field_values
        script_run.save!
        script_run.move_to_child_of(script)
        render :xml => {:notice => 'Added experiment outcome'}, :status => 201
      rescue => e
        render :xml => {:error => 'Failed to add experiment outcome', :message => e.message}, :status => 500
      end
    end
  end

  private
  def basic_authenticate
    authenticate_or_request_with_http_basic('application') do |uname, password|
      User.find_by_login(uname).check_password?(password)
    end
  end

  # overwrite require_login method in application controller, make this controller use basic auth only
  def require_login
    true
  end
end
