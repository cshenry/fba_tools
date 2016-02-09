use fba_tools::fba_toolsImpl;

use fba_tools::fba_toolsServer;
use Plack::Middleware::CrossOrigin;



my @dispatch;

{
    my $obj = fba_tools::fba_toolsImpl->new;
    push(@dispatch, 'fba_tools' => $obj);
}


my $server = fba_tools::fba_toolsServer->new(instance_dispatch => { @dispatch },
				allow_get => 0,
			       );

my $handler = sub { $server->handle_input(@_) };

$handler = Plack::Middleware::CrossOrigin->wrap( $handler, origins => "*", headers => "*");
