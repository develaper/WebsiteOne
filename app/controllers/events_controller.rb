class EventsController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show]
  before_action :set_event, only: [:show, :edit, :update, :destroy, :update_only_url]

  def new
    @event = Event.new(new_params)
    @event.set_repeat_ends_string
    @projects = Project.all
  end

  def show
    @event_schedule = @event.next_occurrences
    @recent_hangout = @event.recent_hangouts.first
    render partial: 'hangouts_management' if request.xhr?
  end

  def index
    @projects = Project.all
    list_all_upcoming_events_with_repeats_by(specified_project)
  end

  def edit
    @event.set_repeat_ends_string
    @projects = Project.all
  end

  def create
    @event = CreateEvent.with(self, params)
    if @event.save
      flash[:notice] = 'Event Created'
      redirect_to event_path(@event)
    else
      flash[:notice] = @event.errors.full_messages.to_sentence
      @projects = Project.all
      render :new
    end
  end

  def update
    if UpdateEvent.with(self, params, @event)
      flash[:notice] = 'Event Updated'
      redirect_to event_path(@event)
    else
      flash[:alert] = ['Failed to update event:', @event.errors.full_messages].join(' ')
      redirect_to edit_event_path(@event)
    end
  end

  def destroy
    @event.destroy
    redirect_to events_path
  end

  private

  def specified_project
    @project = Project.friendly.find(params[:project_id]) unless params[:project_id].blank?
  end

  def list_all_upcoming_events_with_repeats_by(project = nil)
    base_events = project.nil? ? Event.all : Event.where(project_id: project)
    @events = list_upcoming_events_chronologically_with_repeats(base_events)
  end

  def list_upcoming_events_chronologically_with_repeats(base_events)
    base_events.inject([]) do |memo, event|
      memo << event.next_occurrences
    end.flatten.sort_by { |e| e[:time] }
  end

  def set_event
    @event = Event.friendly.find(params[:id])
  end

  def new_params
    params[:project_id] = Project.friendly.find(params[:project]).id.to_s if params[:project]
    params.permit(:name, :category, :project_id).merge(start_datetime: Time.now.utc, duration: 30, repeat_ends: true)
  end
end

