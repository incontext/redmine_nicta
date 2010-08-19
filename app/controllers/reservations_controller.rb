class ReservationsController < ApplicationController
  unloadable

  before_filter :authorize_global
  before_filter :find_reservation, :only => [:update, :edit, :destroy, :deny, :approve]

  def new
    @reservation = Reservation.new
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
      redirect_to reservations_url
    else
      flash[:error] = 'Failed to deny reservation'
      redirect_to :back
    end
  end

  def approve
    if @reservation.approve!
      flash[:notice] = 'Reservation approved successfully'
      redirect_to reservations_url
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
      redirect_to reservations_url
    else
      render :template => 'reservations/new'
    end
  end

  private

  def find_reservation
    @reservation = Reservation.find(params[:id])
  end
end
