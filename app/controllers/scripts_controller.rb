class ScriptsController < ApplicationController
  unloadable

  REPO = '/var/tmp/nicta/dev/mojo'

  before_filter :define_git_repo

  def show
    @filename = params[:filename]
    @script = @repo.gtree(params[:version] || 'master').blobs[@filename]
    render_404 if @script.nil?
    @commits = @repo.gblob(@filename).log
    @commit = @commits.find {|v| v.sha == params[:version]}
  end

  def new
  end

  def edit
  end

  def create
    @filename = params[:filename]

    @repo.chdir do
      f = File.new(@filename, 'w')
      f.write(params[:script])
      f.close
      @repo.add(@filename)
      @repo.commit_all(params[:message])
    end

    redirect_to :controller => :scripts, :action => :show, :filename => @filename
  end

  private

  def define_git_repo
    @repo = Git.open(REPO)
  end
end
