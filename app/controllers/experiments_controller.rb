class ExperimentsController < ApplicationController
  unloadable

  before_filter :find_project, :authorize

  def new
    @experiment = Experiment.new
  end

  def edit
  end

  def create
    experiment = WikiExtensionsExperiment.new
	  experiment.wiki_page_id = params[:wiki_page_id].to_i
    experiment.user_id = @user.id
    experiment.comment = params[:experiment]
    experiment.save
    page = WikiPage.find(experiment.wiki_page_id)
    redirect_to :controller => 'wiki', :action => 'index', :id => @project, :page => page.title
  end

  def destroy
    experiment_id = params[:comment_id].to_i
    experiment = WikiExtensionsExperiment.find(experiment_id)
    unless User.current.admin or User.current.id == experiment.user.id
      render_403
      return false
    end

    page = WikiPage.find(experiment.wiki_page_id)
    experiment.destroy
    redirect_to :controller => 'wiki', :action => 'index', :id => @project, :page => page.title
  end

  def update
    experiment_id = params[:experiment_id].to_i
    #/puts experiment_id/
    experiment = WikiExtensionsExperiment.find(experiment_id)
    unless User.current.admin or User.current.id == experiment.user.id
      render_403
      return false
    end

    page = WikiPage.find(experiment.wiki_page_id)
    experiment.comment = params[:experiment]
    experiment.save
    redirect_to :controller => 'wiki', :action => 'index', :id => @project, :page => page.title
  end

  def generate
    experiment_id = params[:comment_id].to_i
    experiment = WikiExtensionsExperiment.find(experiment_id)

    @exp_name = nil

    experiment.comment.each_line do |line|
      if ( line =~ /^\s*defName\('.*'\)/ )
        eval(line)
      end
    end

    if (@exp_name != nil)
      if !(Tracker.find_by_name(@exp_name))
        # add new tracker
        @exp = Tracker.new(:name => @exp_name, :project_ids => [@project.id, ''])
        @exp.save
        @exp.move_to_top
        source = Tracker.find(1)
        @exp.workflows.copy(source)
        @exp.reload
        # add experiment script as a custom field in the tracker's issues
        r = IssueCustomField.find(:first, :conditions => { :name => @exp_name })
        if (r == nil)
          r = IssueCustomField.new(:name => @exp_name,
                                   :field_format => 'text',
                                   :default_value => experiment.comment,
                                   :tracker_ids => [@exp.id, ''],
                                   :project_ids => [@project.id, ''])
          r.save
          r.move_to_top
        end
        experiment.comment.each_line do |line|
          if ( line =~ /^\s*defProperty\('.*'\)/ )
            eval(line)
          end
        end

        # TODO: check for deleted tracker ids in IssueCustomField

        # IssueCustomField.find(:all).each do |field|
        #   field.trackers.each do |tracker|
        #
        #   end
        # end

        flash[:notice] = l(:notice_successful_create)
      else
        flash[:error] = l(:error_experiment_exists)
      end
    else
      flash[:error] = l(:error_experiment_name_missing)
    end

    unless User.current.admin or User.current.id == experiment.user.id
      render_403
      return false
    end

    page = WikiPage.find(experiment.wiki_page_id)
    experiment.comment = params[:experiment]
    experiment.save
    redirect_to :controller => 'wiki', :action => 'index', :id => @project, :page => page.title
  end

  private

  def find_project
    @project = Project.find(params[:project_id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def defProperty(name, default, desc)
    r = IssueCustomField.find(:first, :conditions => { :name => name })
    if (r == nil)
      r = IssueCustomField.new(:name => name,
                               :field_format => 'string',
                               :default_value => default,
                               :tracker_ids => [@exp.id, ''],
                               :project_ids => [@project.id, ''])
    else
      r.trackers << @exp
    end
    r.save
  end

  def defName(name)
    @exp_name = name
  end
end
