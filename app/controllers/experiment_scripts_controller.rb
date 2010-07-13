class ExperimentScriptsController < ApplicationController
  unloadable

  before_filter :authorize_global

  helper :attachments

  def index
    @experiment_scripts = {}.tap do |hash|
       ExperimentScript.all(:order => :script_updated_at).each do |es|
        hash[es.script_file_name] ||= []
        hash[es.script_file_name] << es
      end
    end
  end

  def new
    @experiment_script = ExperimentScript.new
  end

  def show
    @experiment_script = ExperimentScript.find(params[:id])
    @content = File.new(@experiment_script.script.path, 'r').readlines
  end

  def create
    @experiment_script = ExperimentScript.new(params[:experiment_script])
    if @experiment_script.script.file?
      @experiment_script = ExperimentScript.create(params[:experiment_script])
    else
      if params[:script_file_name] and params[:content]
        tempfile = Tempfile.new(params[:script_file_name])
        tempfile.write(params[:content])
        @experiment_script.script.assign tempfile
        @experiment_script.script.instance_write(:file_name, params[:script_file_name])
        @experiment_script.save!
        tempfile.close!
      else
        flash[:error] = 'Please choose a file'
        redirect_to new_experiment_script_url
        return
      end
    end
    flash[:notice] = 'Script created successfully'
    redirect_to @experiment_script
  end

  def edit
    @experiment_script = ExperimentScript.find(params[:id])
    @content = File.new(@experiment_script.script.path, 'r').readlines
  end

end
