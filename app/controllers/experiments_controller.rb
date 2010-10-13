class ExperimentsController < ApplicationController
  unloadable

  before_filter :find_project, :authorize
  before_filter :find_experiment, :authorize, :only => [:show, :edit, :edit_copy, :commit, :change_experiment_version, :change_experiment]

  def index
    @experiments = @project.experiments.all
  end

  def new
    @experiment = Experiment.new(:project_id => @project)
  end

  def show
    version = params[:version] || 'HEAD'
    script_content = @experiment.script_content(version)
    if script_content.nil?
      render_404
    else
      send_data script_content, :filename => @experiment.script_path
    end
  end

  def create
    @experiment = Experiment.new(params[:experiment])
    @experiment.user = find_current_user
    if @experiment.save
      flash[:notice] = 'Experiment created successfully'
      redirect_to project_experiments_path(@project)
    else
      render :template => 'experiments/new'
    end
  end

  def edit
    @revision = @experiment.revision(params[:version])
  end

  def edit_copy
    unique_identifier = "#{@project.identifier}_#{@experiment.identifier}"
    @experiment.identifier = unique_identifier
  end

  def copy
    @source_experiment = Experiment.find(params[:id])
    @experiment = Experiment.new(params[:experiment])
    @experiment.user = find_current_user
    begin
      @experiment.copy_to_project(@source_experiment)
      flash[:notice] = 'Experiment copied successfully'
    rescue => e
      flash[:error] = 'Failed to copy experiment' + e.message
    end
    redirect_to project_experiments_path(@project)
  end

  def commit
    script_path = @experiment.script_path
    @experiment.commit(params[:script_content],
                       params[:message] + " (updated by #{User.current.login} at #{Time.now.to_s})")
    flash[:notice] = 'Experiment script committed to repository'
    redirect_to project_experiments_url(:project_id => @project)
  rescue => e
    flash[:error] = 'Failed to commit changes.' + e.message
    redirect_to edit_project_experiment_path(@project, @experiment)
  end

  def change_experiment_version
    @experiment.define_attributes(@experiment.script_content(params[:version]))
    render :update do |page|
      page.replace_html "experiment_properties", render_properties(@experiment.experiment_properties)
    end
  end

  def change_experiment
    @experiment.define_attributes(@experiment.script_content)
    form_fields = ""
    render :update do |page|
      page.replace_html "experiment_properties", render_properties(@experiment.experiment_properties)
      page.replace_html "issue_experiment_version", options_for_select(@experiment.revisions.map {|v| [@experiment.pretty_commit_id(v.sha), v.sha]})
    end
  end

  private

  def find_project
    @project = Project.find(params[:project_id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_experiment
    @experiment = Experiment.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def render_properties(properties)
    properties.map do |p|
      "<p>" +  label_tag(p[0]) + text_field_tag("issue[experiment_attributes][#{p[0]}]", p[1]) + "</p>"
    end.join("\n")
  end
end
