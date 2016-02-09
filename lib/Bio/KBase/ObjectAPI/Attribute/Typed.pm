package Bio::KBase::ObjectAPI::Attribute::Typed;
use strict;
use warnings;
use Moose;
use namespace::autoclean;
extends 'Moose::Meta::Attribute';
has type => (
      is        => 'rw',
      isa       => 'Str',
      predicate => 'has_type',
);

has printOrder => (
      is        => 'rw',
      isa       => 'Int',
      predicate => 'has_printOrder',
      default => '-1',
);

has singleton => (
      is        => 'rw',
      isa       => 'Int',
      predicate => 'has_singleton',
      default => '0',
);
1;

package Moose::Meta::Attribute::Custom::Typed;
sub register_implementation { 'Bio::KBase::ObjectAPI::Attribute::Typed' }
1;
