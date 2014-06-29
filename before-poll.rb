if (@last_fetchmail_time || Time.at(0)) < Time.now - 60
    say "Running mbsync..."
    system "pidof mbsync > /dev/null 2>&1 || (ping -c 1 10.0.62.33 -q > /dev/null 2>&1 && mbsync -q SFMail)"
    say "Done running mbsync."
end
@last_fetchmail_time = Time.now
