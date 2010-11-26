class ExperimentOutcomesController < ApplicationController
  unloadable

  before_filter :find_project, :authorize

  verify :method => :post, :render => {:nothing => true, :status => :unprocessable_entity }, :params => :experiment_outcome

  accept_key_auth :index, :create

  def create
    @issue = Issue.find(params[:experiment_outcome][:id]) rescue @project.issues.new

    if @issue.new_record?
      @issue.author = User.current
      @issue.subject = params[:experiment_outcome][:subject]
      @issue.tracker = Tracker.first
      @issue.custom_field_values = {IssueCustomField.find_by_name('Test bed').id => params[:experiment_outcome][:testbed]}
      @issue.reservation = Reservation.find(params[:experiment_outcome][:reservation][:id])
    end

    script = params[:experiment_outcome][:script]
    if @issue.experiment.nil?
      @issue.experiment = Experiment.create!(:identifier => script[:identifier] + rand(1000).to_s,
                                    :experiment_type => script[:experiment_type],
                                    :project => @project,
                                    :user => User.current)
    end

    @issue.experiment.commit(script[:source], "File commited by http POST (updated by #{User.current.login} at #{Time.now.strftime('%Y-%m-%d %H:%M:%S')})")

    @issue.experiment_version = @issue.experiment.revision.sha
    @issue.experiment_attributes = params[:experiment_outcome][:properties]
    @issue.start_date = Time.parse(params[:experiment_outcome][:start])

    if @issue.save!
      respond_to do |format|
        format.xml  { render(:xml => @issue, :status => :ok); return }
      end
    else
      respond_to do |format|
        format.xml  { render(:xml => "<errors>Haha</errors>", :status => :unprocessable_entity); return }
      end
    end
  end

  private

  def find_project
    @project = Project.find(params[:project_id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end
end
