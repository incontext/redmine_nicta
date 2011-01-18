class ExperimentOutcomesController < ApplicationController
  unloadable

  protect_from_forgery :except => :create

  before_filter :find_project, :authorize

  verify :method => :post, :render => {:nothing => true, :status => :unprocessable_entity }, :params => :experiment_outcome

  accept_key_auth :create

  def create
    ActiveRecord::Base.transaction do
      begin
        @issue = Issue.find(params[:experiment_outcome][:id]) rescue @project.issues.new

        if @issue.new_record?
          @issue.author = User.current
          @issue.subject = params[:experiment_outcome][:subject]
          @issue.tracker = Tracker.find_by_name("Experiment")
          @issue.custom_field_values = {IssueCustomField.find_by_name('Test bed').id => params[:experiment_outcome][:testbed]}
          @issue.reservation = Reservation.find(params[:experiment_outcome][:reservation][:id])
        end

        script = params[:experiment_outcome][:script]
        if @issue.experiment.nil?
          @issue.experiment = Experiment.create!(:identifier => script[:identifier],
                                                 :experiment_type => script[:experiment_type],
                                                 :project => @project,
                                                 :user => User.current)
        end

        @issue.experiment.commit(script[:source], "File commited by http POST (updated by #{User.current.login} at #{Time.now.strftime('%Y-%m-%d %H:%M:%S')})")

        @issue.experiment_version = @issue.experiment.revision.sha
        @issue.experiment_attributes = params[:experiment_outcome][:properties]
        @issue.start_date = Time.parse(params[:experiment_outcome][:start])

        attachments = params[:experiment_outcome][:files]

        if @issue.save!
          Attachment.attach_files(@issue, attachments)
          respond_to do |format|
            format.xml  { render(:xml => @issue.to_xml, :status => :ok); return }
          end
        else
          respond_to do |format|
            format.xml  { render(:xml => "<errors>Fail to save experiment</errors>", :status => :unprocessable_entity); return }
          end
        end
      rescue => e
        respond_to do |format|
          format.xml { render(:xml => "<errors>#{e.message}</errors>", :status => 500); return }
        end
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
