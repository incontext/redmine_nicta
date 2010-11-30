class ReservationsController < ApplicationController
  unloadable

  before_filter :find_project, :authorize
  before_filter :find_reservation, :only => [:update, :edit, :destroy, :deny, :approve]
  before_filter :find_resource, :only => [:new, :edit, :update, :create]

  def new
    @reservation = Reservation.new(:project_id => @project.id)
  end

  def edit
  end

  def update
    if @reservation.update_attributes(params[:reservation])
      flash[:notice] = 'Reservation updated successfully'
      redirect_to project_reservations_url(@project)
    else
      render :template => 'reservations/edit'
    end
  end

  def destroy
    if @reservation.deny!
      flash[:notice] = 'Reservation denied successfully'
      redirect_to project_reservations_url(@project)
    else
      flash[:error] = 'Failed to deny reservation'
      redirect_to :back
    end
  end

  def approve
    if @reservation.approve!
      flash[:notice] = 'Reservation approved successfully'
      redirect_to project_reservations_url(@project)
    else
      flash[:error] = 'Failed to approve reservation'
      redirect_to :back
    end
  end

  def index
    conditions = params[:filter] == 'pending' ? " status = 'pending' " : ""

    @reservation_pages, @reservations = paginate :reservations,
      :per_page => 10,
      :conditions => conditions,
      :order => 'reservations.starts_at desc'

    respond_to do |format|
      format.html { render :layout => false if request.xhr? }
      format.xml { render :xml => Reservation.approved.to_xml }
    end
  end

  def show
    @reservation = Reservation.find(params[:id])
    respond_to do |format|
      format.xml { render :xml => @reservation.to_xml }
    end
  end

  def calendar
    @resource_cal = AppConfig.resources.find {|v| v.identifier == params[:cal]} || AppConfig.resources.first
    @calendar_src = URI.encode("http://www.google.com/calendar/embed?src=#{@resource_cal.gcal}&pvttk=#{@resource_cal.pvttk}&color=#{@resource_cal.colour}&ctz=#{AppConfig.gcal.ctz}&showTitle=0&showCalendars=0")
  end

  def create
    @reservation = Reservation.new(params[:reservation])
    @reservation.user = find_current_user
    if @reservation.save
      flash[:notice] = 'Reservation created successfully'
      redirect_to project_reservations_url(@project)
    else
      render :template => 'reservations/new'
    end
  end

  private

  def find_reservation
    @reservation = Reservation.find(params[:id])
  end

  def find_resource
    @resource = (@reservation && YAML::load(@reservation.resource)) ||
      (params[:reservation] && params[:reservation][:resource]) || []
  end

  def find_project
    @project = Project.find(params[:project_id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end
end
