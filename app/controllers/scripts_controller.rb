class ScriptsController < ApplicationController
  unloadable

  REPO = "/var/tmp/nicta/#{RAILS_ENV}/"

  before_filter :find_project
  before_filter :define_git_repo

  def show
    begin
      @filename = params[:script]
      @script = @repo.gtree(params[:version] || 'master').blobs[@filename]
      @commits = @repo.gblob(@filename).log
      @commit = @commits.find {|v| v.sha == params[:version]} || @commits.first
      @contents = params[:contents] || @script.contents
    rescue
      render_404
    end
  end

  def new
  end

  def commit
    @filename = params[:script]
    @latest_commit_id = params[:latest_commit_id]
    begin
      @repo.chdir do
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
      @script = @repo.gtree(params[:version] || 'master').blobs[@filename]
      @commits = @repo.gblob(@filename).log
      @commit = @commits.find {|v| v.sha == @latest_commit_id}
      @contents = params[:contents] || @script.contents
      render :action => 'show'
    end
  end

  private

  def define_git_repo
    @repo = Git.open(REPO + @project.identifier)
  end

  def find_project
    @project = Project.find(params[:project_id])
  end
end
