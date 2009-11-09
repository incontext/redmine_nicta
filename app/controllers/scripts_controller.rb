class ScriptsController < ApplicationController
  unloadable

  before_filter :find_project
  before_filter :define_git_repo

  def edit
    @filename = params[:script]
    unless @repo.lib.ls_files(@filename).empty?
      @script = @repo.gblob("#{params[:version] || 'HEAD'}:#{@filename}")
      @commits = @repo.gblob(@filename).log
      @commit = @commits.find {|v| v.sha == params[:version]} || @commits.first
      @contents = params[:contents] || @script.contents
    end
  end

  def commit
    @filename = params[:script]
    @latest_commit_id = params[:latest_commit_id]
    begin
      @repo.chdir do
        dirname = File.dirname(@filename)
        File.makedirs dirname unless File.exist?(dirname)
        f = File.new(@filename, 'w')
        f.write(params[:contents])
        f.close
        @repo.add(@filename)
        @repo.commit_all(params[:message])
      end
      flash[:notice] = 'Script committed to repository'
      redirect_to "/projects/#{@project.identifier}/scripts/master/#{@filename}"
    rescue => e
      flash[:error] = e.message
      @repo.reset_hard
      unless @repo.lib.ls_files(@filename).empty?
        @script = @repo.gblob("#{params[:version] || 'HEAD'}:#{@filename}")
        @commits = @repo.gblob(@filename).log
        @commit = @commits.find {|v| v.sha == @latest_commit_id}
      end
      @contents = params[:contents] || @script.contents
      render :action => 'edit'
    end
  end

  private

  def define_git_repo
    @repo = Git.open(AppConfig['git_dir'] + @project.identifier)
  end

  def find_project
    @project = Project.find(params[:project_id])
  end
end
