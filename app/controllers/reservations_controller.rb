class ReservationsController < ApplicationController
  unloadable

  before_filter :find_project, :authorize

  def new
    @reservation = Reservation.new
  end

  def edit
    @reservation = Reservation.find(params[:id])
  end

  def update
    @reservation = Reservation.find(params[:id])
    if @reservation.update_attributes(params[:reservation])
      flash[:notice] = 'Reservation updated successfully'
      redirect_to reservations_url(:project_id => @project)
    else
      render :template => 'reservations/edit'
    end
  end

  def destroy
    @reservation = Reservation.find(params[:id])
    if @reservation.destroy
      flash[:notice] = 'Reservation denied successfully'
      redirect_to reservations_url(:project_id => @project)
    else
      flash[:errot] = 'Failed to deny reservation'
      redirect_to :back
    end
  end

  def approve
    @reservation = Reservation.find(params[:id])
    if @reservation.approve
      flash[:notice] = 'Reservation approved successfully'
      redirect_to reservations_url(:project_id => @project)
    else
      flash[:errot] = 'Failed to approve reservation'
      redirect_to :back
    end
  end

  def index
    @date = Time.parse("#{params[:start_date]} || Time.now.utc")
    @starts_date = Date.new(@date.year, @date.month, @date.day)
    @reservations = @project.reservations.find(:all, :conditions => ['starts_at between ? and ?', @starts_date, @starts_date + 7])

    respond_to do |format|
        format.html
        format.xml { render :xml => @project.reservations.all(:conditions => "status = 'approved'").to_xml }
    end
  end

  def create
    @reservation = Reservation.new(params[:reservation])
    @reservation.project = @project
    @reservation.user = find_current_user
    if @reservation.save
      flash[:notice] = 'Reservation created successfully'
      redirect_to reservations_url(:project_id => @project)
    else
      render :template => 'reservations/new'
    end

  end

  private

  def find_project
    @project = Project.find(params[:project_id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end
end
