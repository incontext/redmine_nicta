class ReservationsController < ApplicationController
  unloadable

  before_filter :find_project, :authorize, :except => :create

  def new
    @reservation = Reservation.new(
      :project_id => @project.id,
      :all_day => false
    )
  end

  def index
    @month = Time.zone.now.month
    @year = Time.zone.now.year
    @shown_month = Date.civil(@year, @month)
    @event_strips = Reservation.event_strips_for_month(@shown_month)
    respond_to do |format|
        format.html
        format.xml { render :xml => Reservation.all.to_xml }
    end
  end

  def create
    @reservation = Reservation.create!(params[:reservation])
    redirect_to reservations_url(:project_id => @reservation.project_id)
  end

  private

  def find_project
    @project = Project.find(params[:project_id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end
end
