class ScriptsController < ApplicationController
  unloadable

  before_filter :find_project, :authorize
  before_filter :define_git_repo

  def edit
    @filename = params[:script]
    @issue = Issue.find_by_identifier(@filename.split('/').first) if @filename
    tree = @repo.tree("#{params[:version] || 'HEAD'}", @filename)
    unless tree.contents.empty?
      @script = tree.contents.first
      @commits = @repo.log('HEAD', @filename)
      @commit = @commits.find {|v| v.sha == params[:version].to_s} || @commits.first
      @contents = params[:contents] || @script.data
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
        @repo.commit_all(params[:message] + " (updated by #{User.current.login} at #{Time.now.to_s})")
      end
      flash[:notice] = 'Script committed to repository'
      redirect_to "/projects/#{@project.identifier}/scripts/master/#{@filename}"
    rescue => e
      flash[:error] = e.message
      @repo.reset_hard
      @issue = Issue.find_by_identifier(@filename.split('/').first) if @filename
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
    @repo = Grit::Repo.new(AppConfig.git_dir + @project.identifier)
  end

  def find_project
    @project = Project.find(params[:project_id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end
end
