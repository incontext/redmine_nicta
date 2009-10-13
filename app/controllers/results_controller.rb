require 'hpricot'

class ResultsController < ApplicationController
  unloadable

  before_filter :basic_authenticate

  def create
    doc, items = Hpricot::XML(request.raw_post), []
    outcome = (doc/"experiment-outcome").first

    project = Project.find_by_identifier(outcome.at('project').innerHTML)
    user = User.find_by_login(outcome.at('userid').innerHTML)
    script = Issue.find_by_subject(outcome.at('id').innerHTML) || Issue.new

    if script.new_record?
      script.project = project
      script.author = user
      script.subject = project.identifier + '_' + outcome.at('id').innerHTML
      script.tracker = Tracker.find_by_name('Script')
      #script.save!
    end

    #script_run = Issue.new
    #script_run.project = project
    #script_run.author = user
    #script_run.subject = project.identifier + '_' + outcome.at('id').innerHTML
    #script_run.tracker = Tracker.find_by_name('Script')
    #script_run.save!

    if script.save!
      render :xml => {:notice => 'Added experiment outcome'}, :status => 201
    else
      render :xml => {:error => 'Failed to add experiment outcome' + issue.errors.to_s}
    end
  end

  private
  def basic_authenticate
    authenticate_or_request_with_http_basic('application') do |uname, password|
      User.find_by_login(uname).check_password?(password)
    end
  end
end
