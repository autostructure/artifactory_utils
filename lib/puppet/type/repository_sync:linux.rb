Puppet::Type.type(:repository_sync).provide :linux do
  desc "User management via `useradd` and its ilk.  Note that you will need to
    install Ruby's shadow password library (often known as `ruby-libshadow`)
    if you wish to manage user passwords."
