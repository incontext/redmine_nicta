module ReservationsHelper
  def time_calendar_for(field_id)
    include_calendar_headers_tags
    image_tag("calendar.png", {:id => "#{field_id}_trigger",:class => "calendar-trigger"}) +
    javascript_tag("Calendar.setup({inputField : '#{field_id}', ifFormat : '%Y-%m-%d %H:%M:%S', showsTime: true, button : '#{field_id}_trigger' });")
  end
end
