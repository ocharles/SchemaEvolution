package SchemaEvolution::Types;
use MooseX::Types (-declare => [qw( DBH )]);

class_type DBH, { class => 'DBI::db' };

1;
