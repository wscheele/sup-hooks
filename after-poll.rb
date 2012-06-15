#
# uses the notify-send in my Ubuntu to send a desktop notification with the amount of polled mails
system "notify-send 'New Mail' '#{num} new mails' -t 3000 -i notification-message-email" if num > 0
