#
# Some date/time formatting tweaks for the index

date = thread.date
from = Time.now

if date.is_the_same_day? from
  # same day
  date.strftime("%H:%M")
elsif date.is_the_day_before? from
  # yesterday
  date.nearest_hour.strftime("Yest. %Hh")
else
  if date.year != from.year
    # different year
    date.strftime("%d %b %Y")
  #elsif date.month != from.month
    # same year
    #date.strftime("%b %d %Hh")
  else
    # same month
    date.strftime("%b %d %Hh")
  end
end
