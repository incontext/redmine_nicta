class ExperimentsController < ApplicationController
  unloadable

  before_filter :find_project, :authorize
  before_filter :define_git_repo, :only => [:edit, :commit, :change_experiment, :copy]

  attr_accessor :experiment_properties

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
      @commits = @experiment.commits
      @commit = @commits.find {|v| v.sha == params[:version].to_s} || @commits.first
      @content = @script.data
    end
  end

  def edit_copy
    @experiment = Experiment.find(params[:id])
  end

  def copy
    @old_experiment = Experiment.find(params[:id])
    @experiment = Experiment.new(params[:experiment])
    @experiment.user = find_current_user
    @new_project = @experiment.project

    tree = @repo.tree("HEAD", @old_experiment.script_path)
    @content = tree.contents.first.data unless tree.contents.empty?

    @new_repo = Grit::Repo.new(AppConfig.git_dir + @new_project.identifier)
    begin
      Dir.chdir(AppConfig.git_dir + @new_project.identifier) do
        f = File.open(@experiment.script_path, 'w')
        f.write(@content)
        f.close
        @new_repo.add(@experiment.script_path)
        @new_repo.commit_index("Copied from #{@project.identifier} (updated by #{User.current.login} at #{Time.now.to_s})")
      end
      begin
        @experiment.save!
        flash[:notice] = 'Experiment copied successfully'
      rescue => e
        flash[:error] = 'Failed to copy experiment' + e.message
      end
      redirect_to experiments_url(:project_id => @project)
    rescue => e
      Dir.chdir(AppConfig.git_dir + @experiment.project.identifier) do
        system "git reset --hard"
      end
      flash[:error] = 'Failed to copy experiment' + e.message
      redirect_to experiments_url(:project_id => @project)
    end
  end

  def commit
    @experiment = Experiment.find(params[:id])
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
      redirect_to edit_experiment_url(@experiment, :project_id => @project)
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
end
