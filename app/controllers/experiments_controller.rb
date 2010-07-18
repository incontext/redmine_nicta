class ExperimentsController < ApplicationController
  unloadable

  before_filter :find_project, :authorize
  before_filter :define_git_repo, :only => [:edit, :commit]

  def index
    @experiments = @project.experiments.all
  end

  def new
    @experiment = Experiment.new(:project_id => @project)
  end

  def create
    @experiment = Experiment.new(params[:experiment])
    @experiment.project = @project
    @experiment.user = find_current_user
    if @experiment.save
      flash[:notice] = 'Experiment created successfully'
      redirect_to experiments_url(:project_id => @project)
    else
      render :template => 'experiments/new'
    end
  end

  def edit
    @experiment = Experiment.find(params[:id])
    @script_path = @experiment.script_path
    tree = @repo.tree("#{params[:version] || 'HEAD'}", @script_path)
    unless tree.contents.empty?
      @script = tree.contents.first
      @commits = @repo.log('HEAD', @script_path)
      @commit = @commits.find {|v| v.sha == params[:version].to_s} || @commits.first
      @content = @script.data
    end
  end

  def commit
    @experiment = Experiment.find(params[:id])
    @script_path = @experiment.script_path

    begin
      Dir.chdir(NICTA['git_dir'] + @project.identifier) do
        f = File.open(@script_path, 'w')
        f.write(params[:script_content])
        f.close
        @repo.add(@script_path)
        @repo.commit_index(params[:message] + " (updated by #{User.current.login} at #{Time.now.to_s})")
      end
      flash[:notice] = 'Experiment script committed to repository'
      redirect_to experiments_url(:project_id => @project)
    rescue => e
      Dir.chdir(NICTA['git_dir'] + @project.identifier) do
        system "git reset --hard"
      end
      flash[:error] = 'Failed to commit changes.' + e.message
      redirect_to edit_experiment_url(@experiment, :project_id => @project)
    end
  end

  private

  def define_git_repo
    @repo = Grit::Repo.new(NICTA['git_dir'] + @project.identifier)
  end

  def find_project
    @project = Project.find(params[:project_id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end
end
