class ReservationsController < ApplicationController
  unloadable

  before_filter :find_project, :authorize
  before_filter :find_reservation, :only => [:update, :edit, :destroy, :deny, :approve]
  before_filter :find_resource, :only => [:new, :edit, :update, :create]

  def new
    @reservation = Reservation.new(:project_id => @project)
  end

  def edit
  end

  def update
    if @reservation.update_attributes(params[:reservation])
      flash[:notice] = 'Reservation updated successfully'
      redirect_to reservations_url(:project_id => @project)
    else
      render :template => 'reservations/edit'
    end
  end

  def destroy
    if @reservation.deny!
      flash[:notice] = 'Reservation denied successfully'
      redirect_to reservations_url(:project_id => @project)
    else
      flash[:error] = 'Failed to deny reservation'
      redirect_to :back
    end
  end

  def approve
    if @reservation.approve!
      flash[:notice] = 'Reservation approved successfully'
      redirect_to reservations_url(:project_id => @project)
    else
      flash[:error] = 'Failed to approve reservation'
      redirect_to :back
    end
  end

  def index
    @reservations = Reservation.all
    respond_to do |format|
      format.html
      format.xml { render :xml => Reservation.approved.to_xml }
    end
  end

  def create
    @reservation = Reservation.new(params[:reservation])
    @reservation.user = find_current_user
    if @reservation.save
      flash[:notice] = 'Reservation created successfully'
      redirect_to reservations_url(:project_id => @project)
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
