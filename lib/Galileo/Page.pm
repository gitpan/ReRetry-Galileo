package Galileo::Page;
use Mojo::Base 'Mojolicious::Controller';

use Mojo::JSON 'j';

sub show {
  my $self = shift;
  my $name = $self->param('name');

  my $page = $self->schema->resultset('Page')->single({ name => $name });
  if ($page) {
    $self->render( page => $page );
  } else {
    if ($self->session->{username}) {
      $self->redirect_to("/edit/$name");
    } else {
      $self->render_not_found;
    }
  }
}

sub edit {
  my $self = shift;
  my $name = $self->param('name');
  $self->title( "Editing Page: $name" );
  $self->content_for( banner => "Editing Page: $name" );

  my $schema = $self->schema;

  my $page = $schema->resultset('Page')->single({name => $name});
  if ($page) {
    my $title = $page->title;
    $self->stash( title_value => $title );
    $self->stash( input => $page->md );
  } else {
    $self->stash( title_value => '' );
    $self->stash( input => "Hello World" );
  }

  $self->stash( sanitize => $self->config->{sanitize} // 1 );   #/# highlight fix

  $self->render;
}

sub store {
  my $self = shift;
  $self->on( text => sub {
    my ($self, $message) = @_;
    my $data = j( $message );

    my $schema = $self->schema;

    unless($data->{title}) {
      $self->send({ text => j({
        message => 'Not saved! A title is required!',
        success => \0,
      }) });
      return;
    }
    my $author = $schema->resultset('User')->single({name=>$self->session->{username}});
    $data->{author_id} = $author->id;
    $schema->resultset('Page')->update_or_create(
      $data, {key => 'pages_name'},
    );
    $self->expire('main');
    $self->send({ text => j({
      message => 'Changes saved',
      success => \1,
    }) });
  });
}

1;

