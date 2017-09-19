# fba_tools Developer ~~Guide~~ Introduction

This document is by no means complete but will hopefully help orient you in 
in the ~70K lines of Perl and 30K lines of C++ in this package. 

## Structure

Superficially, the organisation of this module resembles any other [SDK module](https://github.com/kbase/kb_sdk/blob/master/doc/module_overview.md)
However, while the logic of many modules are confined to an Impl file and a few
additional collocated source files, fba_tools has two additional directries
with program logic: [MFAToolkit](MFAToolkit) and the [ObjectAPI](lib/Bio/Kbase).
MFAToolkit contains the C++ code that sets up and solves Flux Balance problems
with LP solvers like CPLEX. It's seldom necessary to change or extend this code.

The ObjectAPI directory contains the bulk of the logic for this project. 
fba_tools uses [Moose](http://search.cpan.org/~ether/Moose-2.2006/lib/Moose/Manual.pod)
to define object types which parallel to KBase typed objects (or are components
of typed objects) and these are organized in directories which correspond to 
"module" in KBase. Within each module directory there are two sets of 
identically named object files: The files in the top directory contain most of
the object methods and get heavy use. The files in the `DB` directory for each
module define the the attributes of each object type. generally these only need
to be edited when a corresponding KBase type is extended or updated. Finally,
the ObjectAPI folder contains a `functions.pm` and `utilities.pm` file that
help implement module functions but most execution logic can be found in the
relevant object's methods.

## Tips
- This modules uses almost exclusively [array references](https://perlmaven.com/array-references-in-perl)
not arrays. Be consistent with this and your objects will save without error.
- Don't use `Data::Dumper` on an attribute of a Moose object (e.g. `print Dumper($phenotypeSet->phenotypes());`)
you with get way more output than you bargained for (the whole damn Moose object).
- Perl is loosely typed so you may occasionally coerce variables into the type
specified in the workspace object spec file. For example `$var_x += 0;` will 
ensure `$var_x` is saved as a float.
- Many functions in `functions.pm` avoid dependency on the SDK callback server
which means they can be called directly for debugging.
- Moose validates the types of every attribute in an object and its sub-objects
for something like a genome with many features that can add an enormous amount 
of overhead and this validation duplicates checking already done by the 
workspace.