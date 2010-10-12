class ExperimentsController < ApplicationController
  unloadable

  before_filter :find_project, :authorize
  before_filter :find_experiment, :authorize, :only => [:show, :edit, :edit_copy, :commit]
  before_filter :define_git_repo, :only => [:show, :edit, :commit, :change_experiment, :change_experiment_version, :copy]

  attr_accessor :experiment_properties

  def index
    @experiments = @project.experiments.all
  end

  def new
    @experiment = Experiment.new(:project_id => @project)
  end

  def show
    tree = @repo.tree("#{params[:version] || 'HEAD'}", @experiment.script_path)
    unless tree.contents.empty?
      @script = tree.contents.first
      @commits = @experiment.commits
      @commit = @commits.find {|v| v.sha == params[:version].to_s} || @commits.first
      @content = @script.data
    end
    if @content.nil?
      render_404
    else
      send_data @content, :filename => @experiment.script_path
    end
  end

  def create
    @experiment = Experiment.new(params[:experiment])
    @experiment.project = @project
    @experiment.user = find_current_user
    if @experiment.save
      flash[:notice] = 'Experiment created successfully'
      redirect_to project_experiments_path(@project)
    else
      render :template => 'experiments/new'
    end
  end

  def edit
    @script_path = @experiment.script_path
    tree = @repo.tree("#{params[:version] || 'HEAD'}", @script_path)
    unless tree.contents.empty?
      @script = tree.contents.first
      @commits = @experiment.commits
      @commit = @commits.find {|v| v.sha == params[:version].to_s} || @commits.first
      @content = @script.data
    end
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
    @script_path = @experiment.script_path

    begin
      Dir.chdir(AppConfig.git_dir + @project.identifier) do
        f = File.open(@script_path, 'w')
        f.write(params[:script_content])
        f.close
        @repo.add(@script_path)
        @repo.commit_index(params[:message] + " (updated by #{User.current.login} at #{Time.now.to_s})")
      end
      flash[:notice] = 'Experiment script committed to repository'
      redirect_to experiments_url(:project_id => @project)
    rescue => e
      Dir.chdir(AppConfig.git_dir + @project.identifier) do
        system "git reset --hard"
      end
      flash[:error] = 'Failed to commit changes.' + e.message
      redirect_to edit_project_experiments_path(@project, @experiment)
    end
  end

  def change_experiment_version
    @experiment = Experiment.find(params[:experiment_id])
    @script_path = @experiment.script_path
    tree = @repo.tree(params[:experiment_version], @script_path)
    define_attributes(tree.contents.first.data)
    form_fields = ""
    render :update do |page|
      @experiment_properties.each do |p|
        form_fields << "<p>"
        form_fields << label_tag(p[0]) + text_field_tag("issue[experiment_attributes][#{p[0]}]", p[1])
        form_fields << "</p>"
      end
      page.replace_html "experiment_properties", form_fields
    end
  end

  def change_experiment
    @experiment = Experiment.find(params[:experiment_id])
    @script_path = @experiment.script_path
    tree = @repo.tree('HEAD', @script_path)
    define_attributes(tree.contents.first.data)
    form_fields = ""
    render :update do |page|
      @experiment_properties.each do |p|
        form_fields << "<p>"
        form_fields << label_tag(p[0]) + text_field_tag("issue[experiment_attributes][#{p[0]}]", p[1])
        form_fields << "</p>"
      end
      page.replace_html "experiment_properties", form_fields
      page.replace_html "issue_experiment_version", options_for_select(@experiment.commits.collect {|v| v.sha})
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

  def define_git_repo
    @repo = Grit::Repo.new(AppConfig.git_dir + @project.identifier)
  end

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
end
