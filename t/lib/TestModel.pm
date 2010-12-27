package TestModel::Base;
use strict;
use warnings;
use base qw(Maro);
__PACKAGE__->key_space('MaroTest');

package TestModel::StandardUTF8;
use strict;
use warnings;
use base qw(TestModel::Base);
__PACKAGE__->column_family('StandardUTF8');

package TestModel::StandardTime;
use strict;
use warnings;
use base qw(TestModel::Base);
__PACKAGE__->column_family('StandardTime');

package TestModel::SuperUTF8;
use strict;
use warnings;
use base qw(TestModel::Base);
__PACKAGE__->column_family('SuperUTF8');

package TestModel::SuperTime;
use strict;
use warnings;
use base qw(TestModel::Base);
__PACKAGE__->column_family('SuperTime');

1;

