package Emailesque;
# ABSTRACT: Lightweight To-The-Point Email

BEGIN {
    use Exporter();
    use vars qw( @ISA @EXPORT @EXPORT_OK );
    @ISA    = qw( Exporter );
    @EXPORT = qw(email);
}

use Hash::Merge;
use Email::Stuff;
use Email::AddressParser;

# use Data::Dumper qw/Dumper/;

sub new { 
    my $class  = shift;
    my $params = shift;
    
    $params->{driver} = 'sendmail' unless defined $params->{driver};
    $params->{path}   = '/usr/bin/sendmail' unless defined $params->{path};
    
    my $self   = { settings => $params };
    bless $self, $class; 
    return $self;
}

sub email {
    return Emailesque->new(@_)->send({});
}

sub send {
    my ($this, $options, @arguments)  = @_;
    my $self = Email::Stuff->new;
    my $settings = $this->{settings};
    #$options = Hash::Merge->new( 'LEFT_PRECEDENT' )->merge($settings, $options);
    $options = Hash::Merge->new( 'LEFT_PRECEDENT' )->merge($options, $settings); # requested by igor.bujna@post.cz
    
    # process to
    if ($options->{to}) {
        $self->to(
        join ",", Email::AddressParser->parse( $options->{to} ) );
    }
    
    # process from
    if ($options->{from}) {
        $self->from($options->{from});
    }
    
    # process cc
    if ($options->{cc}) {
        $self->cc(
        join ",", Email::AddressParser->parse( $options->{cc} ) );
    }
    
    # process bcc
    if ($options->{bcc}) {
        $self->bcc(
        join ",", Email::AddressParser->parse( $options->{bcc} ) );
    }
    
    # process reply_to
    if ($options->{reply_to}) {
        $self->header("Return-Path" => $options->{reply_to});
    }
    
    # process subject
    if ($options->{subject}) {
        $self->subject($options->{subject});
    }
    
    # process message
    if ($options->{message}) {
        # multipart send using plain text and html
        if (lc($options->{type}) eq 'multi') {
            if (ref($options->{message}) eq "HASH") {
                $self->html_body($options->{message}->{html})
                    if defined $options->{message}->{html};
                $self->text_body($options->{message}->{text})
                    if defined $options->{message}->{text};
            }
        }
        else {
            # standard send using html or plain text
            if (lc($options->{type}) eq 'html') {
                $self->html_body($options->{message});
            }
            else {
                $self->text_body($options->{message});
            }
        }
    }
    
    # process additional headers
    if ($options->{headers} && ref($options->{headers}) eq "HASH") {
        foreach my $header (keys %{ $options->{headers} }) {
            $self->header( $header => $options->{headers}->{$header} );
        }
    }
    
    # process attachments
    if ($options->{attach}) {
        if (ref($options->{attach}) eq "ARRAY") {
            my %files = @{$options->{attach}};
            foreach my $file (keys %files) {
                $self->attach($file, 'filename' => $files{$file});
            }
        }
    }

    # some light error handling
    die 'specify type multi if sending text and html'
        if lc($options->{type}) eq 'multi' && "HASH" eq ref $options->{type};
        
    # okay, go team, go
    if (defined $settings->{driver}) {
        if (lc($settings->{driver}) eq lc("sendmail")) {
            $self->{send_using} = ['Sendmail', $settings->{path}];
            # failsafe
            
            $Email::Send::Sendmail::SENDMAIL = $settings->{path} if
                defined $settings->{path};
            
            #$Email::Send::Sendmail::SENDMAIL = $settings->{path} unless
            #    $Email::Send::Sendmail::SENDMAIL;
        }
        if (lc($settings->{driver}) eq lc("smtp")) {
            if ($settings->{host} && $settings->{user} && $settings->{pass}) {
                
                my   @parameters = ();
                push @parameters, 'Host' => $settings->{host} if $settings->{host};
                push @parameters, 'Port'  => $settings->{port} if $settings->{port};
                
                push @parameters, 'username' => $settings->{user} if $settings->{user};
                push @parameters, 'password' => $settings->{pass} if $settings->{pass};
                push @parameters, 'ssl'      => $settings->{ssl} if $settings->{ssl};
                
                push @parameters, 'Proto' => 'tcp';
                push @parameters, 'Reuse' => 1;
                
                push @parameters, 'Debug' => 1 if $settings->{debug};
                
                $self->{send_using} = ['SMTP', @parameters];
            }
            else {
                $self->{send_using} = ['SMTP', Host => $settings->{host}];
            }
        }
        if (lc($settings->{driver}) eq lc("qmail")) {
            $self->{send_using} = ['Qmail', $settings->{path}];
            # fail safe
            $Email::Send::Qmail::QMAIL = $settings->{path} unless
                $Email::Send::Qmail::QMAIL;
        }
        if (lc($settings->{driver}) eq lc("nntp")) {
            $self->{send_using} = ['NNTP', $settings->{host}];
        }
        my $email = $self->email or return undef;
        # die Dumper $email->as_string;
        return $self->mailer->send( $email );
    }
    else {
        $self->using(@arguments) if @arguments; # Arguments passed to ->using
        my $email = $self->email or return undef;
        return $self->mailer->send( $email );
    }
};


1;

__END__
=pod

=head1 NAME

Emailesque - Lightweight To-The-Point Email

=head1 VERSION

version 1.110090

=head1 SYNOPSIS

    use Emailesque qw/email/;
    
    email {
      to      => '...',
      from    => '...',
      subject => '...',
      message => '...',
      attach  => [
          '/path/to/file' => 'filename'
      ],
      driver  => 'sendmail'
    };
    
    or
    
    use Emailesque;
    
    my $message = Emailesque->new({ driver  => 'sendmail' });
    
    $message->send({
      to      => '...',
      from    => '...',
      subject => '...',
      message => '...',
    });

Important Note! The default email format is plain-text, this can be changed to
html by setting the option 'type' to 'html' in the hashref passed to the new
function or email keyword. The following are options that can
be passed within the hashref of arguments:

    # send message to
    to => $email_recipient
    
    # send messages from
    from => $mail_sender
    
    # email subject
    subject => 'email subject line'
    
    # message body
    message => 'html or plain-text data'
    message => {
        text => $text_message,
        html => $html_messase,
        # type must be 'multi'
    }
    
    # email message content type
    type => 'text'
    type => 'html'
    type => 'multi'
    
    # carbon-copy other email addresses
    cc => 'user@site.com'
    cc => 'user_a@site.com, user_b@site.com, user_c@site.com'
    cc => join ', ', @email_addresses
    
    # blind carbon-copy other email addresses
    bcc => 'user@site.com'
    bcc => 'user_a@site.com, user_b@site.com, user_c@site.com'
    bcc => join ', ', @email_addresses
    
    # specify where email responses should be directed
    reply_to => 'other_email@website.com'
    
    # attach files to the email
    attach => [
        $file_location => $attachment_name,
    ]
    
    # send additional (specialized) headers
    headers => {
        "X-Mailer" => "SPAM-THE-WORLD-BOT 1.23456789"
    }

=head1 DESCRIPTION

Provides an easy way of handling text or html email messages with or without
attachments. Simply define how you wish to send the email, then call the email
keyword passing the necessary parameters as outlined above. This module is basically
a wrapper around the unsupported and ____y/(____ie) email library Email::Stuff, which
is now awesome thanks to me.

=head1 USAGE EXAMPLES

    # Handle Email Failures
    
    my $msg = email {
            to      => '...',
            subject => '...',
            message => $msg,
            attach  => [
                '/path/to/file' => 'filename'
            ]
        };
        
    die $msg unless $msg;
    
    # Add More Email Headers
    
    email {
        to      => '...',
        subject => '...',
        message => $msg,
        headers => {
            "X-Mailer" => 'This fine application',
            "X-Accept-Language" => 'en'
        }
    };
    
    # Send Text and HTML Email together
    
    email {
        to      => '...',
        subject => '...',
        type    => 'multi',
        message => {
            text => $txt,
            html => $html,
        }
    };

    # Send mail via SMTP with SASL authentication
    
    {
        ...,
        driver  => 'smtp',
        host    => 'smtp.website.com',
        user    => 'account@gmail.com',
        pass    => '****'
    }
    
    # Send mail to/from Google (gmail)
    
    {
        ...,
        ssl     => 1,
        driver  => 'smtp',
        host    => 'smtp.website.com',
        port    => 465,
        user    => 'account@gmail.com',
        pass    => '****'
    }
   
    # Send mail to/from Google (gmail) using TLS
    
    {
        ...,
        tls     => 1,
        driver  => 'smtp',
        host    => 'smtp.website.com',
        port    => 587,
        user    => 'account@gmail.com',
        pass    => '****'
    }
        
    # Debug email server communications, prints negotiation to console
    
    {
        ...,
        debug => 1
    }
        
    # Set headers to be issued with message
    
    {
        ...,
        from => '...',
        subject => '...',
        headers => {
            'X-Mailer' => 'MyApp 1.0',
            'X-Accept-Language' => 'en'
        }
    }
    
    # Send email using sendmail, path is optional
    
    {
        ...,
        driver  => 'sendmail',
        path    => '/usr/bin/sendmail',
    }

=head1 AUTHOR

Al Newkirk <awncorp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by awncorp.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

