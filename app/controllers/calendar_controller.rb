# Calendar controller
class CalendarController < ApplicationController
  include CalendarHelper

  def index
    logger.info ">>>>> DEBUG: session keys #{session.keys}"
    # Get the IANA identifier of the user's time zone
    time_zone = view_context.get_iana_from_windows(user_timezone)

    # Calculate the start and end of week in the user's time zone
    start_datetime = Date.today.beginning_of_week(:sunday).in_time_zone(time_zone).to_time
    end_datetime = start_datetime.advance(:days => 180)
    #logger.info ">>>>> get_cal_view args: #{access_token} #{start_datetime} #{end_datetime} #{user_timezone}"
    @events = get_calendar_view access_token, start_datetime, end_datetime, user_timezone || []
    @calendars = get_all_calendars(access_token)
    logger.info "calendars object: #{@calendars.inspect}"
    @calendarGroups = get_all_calendar_groups(access_token)
    if @calendarGroups
      #logger.info ">>>>>> CALENDAR GROUPS:\n#{@calendarGroups.inspect}"
      @cals = {}
      @calendarGroups.each do |cal_group|
        logger.info ">>>> CAL GROUP: #{cal_group.inspect}"
        #if cal_group[:id]
        #  @cals << {cal_group[:id].to_s => get_calendars_for(access_token, cal_group[:id])}
        #end
      end

    end
    #render json: @events
  rescue RuntimeError => e
    @errors = [
        {
            :message => 'Microsoft Graph API returned an error getting events.',
            :debug => e
        }
    ]
  end

  def create
    # Semicolon-delimited list, split to an array
    attendees = params[:ev_attendees].split(';')

    # Create the event
    create_event access_token,
                 user_timezone,
                 params[:ev_subject],
                 params[:ev_start],
                 params[:ev_end],
                 attendees,
                 params[:ev_body]

    # Redirect back to the calendar list
    redirect_to({ :action => 'index' })
  rescue RuntimeError => e
    @errors = [
        {
            :message => 'Microsoft Graph returned an error creating the event.',
            :debug => e
        }
    ]
  end

  def create_event(token, timezone, subject, start_datetime, end_datetime, attendees, body)
    create_event_url = '/v1.0/me/events'

    # Create an event object
    # https://docs.microsoft.com/graph/api/resources/event?view=graph-rest-1.0
    new_event = {
        'subject' => subject,
        'start' => {
            'dateTime' => start_datetime,
            'timeZone' => timezone
        },
        'end' => {
            'dateTime' => end_datetime,
            'timeZone' => timezone
        }
    }

    unless attendees.empty?
      attendee_array = []
      # Create an attendee object
      # https://docs.microsoft.com/graph/api/resources/attendee?view=graph-rest-1.0
      attendees.each { |email| attendee_array.push({ 'type' => 'required', 'emailAddress' => { 'address' => email } }) }
      new_event['attendees'] = attendee_array
    end

    unless body.empty?
      # Create an itemBody object
      # https://docs.microsoft.com/graph/api/resources/itembody?view=graph-rest-1.0
      new_event['body'] = {
          'contentType' => 'text',
          'content' => body
      }
    end

    response = make_api_call 'POST',
                             create_event_url,
                             token,
                             nil,
                             nil,
                             new_event

    raise response.parsed_response.to_s || "Request returned #{response.code}" unless response.code == 201
  end

end